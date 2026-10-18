// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';
import 'dart:math';

// Persistent file paths
const String accountsFile = 'cbe_bank_server/cbe_accounts.json';
const String transactionsFile = 'cbe_bank_server/cbe_transactions.json';

// In-memory data
List<dynamic> accounts = [];
List<dynamic> transactions = [];
Map<String, String> pendingOtps = {}; // maps txnId -> otp
Map<String, dynamic> activeTransactions = {}; // maps txnId -> txnData

void main() async {
  // Load databases
  loadDatabase();

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8082);
  print('==================================================');
  print(' CBE Bank & Payment Server running on port 8082');
  print(' Core Banking URL: http://localhost:8082');
  print('==================================================');

  await for (HttpRequest request in server) {
    handleRequest(request);
  }
}

void loadDatabase() {
  try {
    final accFile = File(accountsFile);
    if (accFile.existsSync()) {
      accounts = jsonDecode(accFile.readAsStringSync());
    } else {
      accounts = [
        {
          "accountNumber": "1000123456789",
          "phone": "0911223344",
          "name": "Student Tester",
          "balance": 500.0,
          "pin": "1234"
        },
        {
          "accountNumber": "1000553647828",
          "phone": "0900000000",
          "name": "WKU Library Merchant",
          "balance": 10000.0,
          "pin": "0000"
        }
      ];
      saveAccounts();
    }

    final txnFile = File(transactionsFile);
    if (txnFile.existsSync()) {
      transactions = jsonDecode(txnFile.readAsStringSync());
    } else {
      transactions = [];
      saveTransactions();
    }
    print('Databases loaded. Accounts: ${accounts.length}, Transactions: ${transactions.length}');
  } catch (e) {
    print('Error loading databases: $e');
  }
}

void saveAccounts() {
  File(accountsFile).writeAsStringSync(jsonEncode(accounts));
}

void saveTransactions() {
  File(transactionsFile).writeAsStringSync(jsonEncode(transactions));
}

void handleRequest(HttpRequest request) async {
  // Enable CORS
  request.response.headers.add('Access-Control-Allow-Origin', '*');
  request.response.headers.add('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
  request.response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept');

  // Handle preflight OPTIONS request
  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.ok;
    request.response.close();
    return;
  }

  final path = request.uri.path;
  print('[${DateTime.now()}] ${request.method} $path');

  if (request.method == 'GET' && path == '/') {
    serveDashboard(request);
  } else if (request.method == 'POST' && path == '/api/cbe/payment/initiate') {
    await handlePaymentInitiate(request);
  } else if (request.method == 'POST' && path == '/api/cbe/payment/verify') {
    await handlePaymentVerify(request);
  } else if (request.method == 'POST' && path == '/api/cbe/transfer') {
    await handleDirectTransfer(request);
  } else if (request.method == 'GET' && path.startsWith('/api/cbe/status/')) {
    handleTransactionStatus(request);
  } else {
    request.response.statusCode = HttpStatus.notFound;
    request.response.write(jsonEncode({'error': 'Endpoint not found'}));
    request.response.close();
  }
}

// REST APIs
Future<void> handlePaymentInitiate(HttpRequest request) async {
  try {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body);
    final phone = data['phone']?.toString().trim();
    final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
    final reference = data['reference']?.toString() ?? 'Library Fine Payment';

    if (phone == null || phone.isEmpty || amount <= 0) {
      sendJsonResponse(request, HttpStatus.badRequest, {
        'status': 'FAILED',
        'message': 'Invalid input parameters. Phone and positive amount are required.'
      });
      return;
    }

    // Find account by phone number
    final account = accounts.firstWhere(
      (a) => a['phone'] == phone,
      orElse: () => null,
    );

    if (account == null) {
      sendJsonResponse(request, HttpStatus.notFound, {
        'status': 'FAILED',
        'message': 'No CBE account associated with this phone number.'
      });
      return;
    }

    // Check balance
    if (account['balance'] < amount) {
      sendJsonResponse(request, HttpStatus.badRequest, {
        'status': 'FAILED',
        'message': 'Insufficient balance in CBE Birr account.'
      });
      return;
    }

    // Generate transaction ID & OTP
    final txnId = 'CBE-TXN-${Random().nextInt(900000) + 100000}';
    final otp = (Random().nextInt(9000) + 1000).toString(); // 4 digit OTP for easy input

    pendingOtps[txnId] = otp;
    activeTransactions[txnId] = {
      'txnId': txnId,
      'phone': phone,
      'amount': amount,
      'reference': reference,
      'payerName': account['name'],
      'payerAccountNumber': account['accountNumber'],
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('Payment initiated for $phone. TxnId: $txnId, OTP: $otp');

    sendJsonResponse(request, HttpStatus.ok, {
      'status': 'PENDING_OTP',
      'transactionId': txnId,
      'otp': otp, // In a real system, sent via SMS. We return it here for testing.
      'message': 'OTP verification code has been sent.'
    });
  } catch (e) {
    sendJsonResponse(request, HttpStatus.internalServerError, {
      'status': 'FAILED',
      'message': 'Internal Server Error: $e'
    });
  }
}

Future<void> handlePaymentVerify(HttpRequest request) async {
  try {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body);
    final txnId = data['transactionId']?.toString();
    final pin = data['pin']?.toString().trim();
    final otp = data['otp']?.toString().trim();

    if (txnId == null || pin == null || otp == null) {
      sendJsonResponse(request, HttpStatus.badRequest, {
        'status': 'FAILED',
        'message': 'Transaction ID, PIN, and OTP are required.'
      });
      return;
    }

    final txnData = activeTransactions[txnId];
    if (txnData == null) {
      sendJsonResponse(request, HttpStatus.notFound, {
        'status': 'FAILED',
        'message': 'Transaction not found or expired.'
      });
      return;
    }

    // Verify OTP
    if (pendingOtps[txnId] != otp) {
      sendJsonResponse(request, HttpStatus.badRequest, {
        'status': 'FAILED',
        'message': 'Invalid OTP code.'
      });
      return;
    }

    // Verify PIN
    final phone = txnData['phone'];
    final account = accounts.firstWhere((a) => a['phone'] == phone);
    if (account['pin'] != pin) {
      sendJsonResponse(request, HttpStatus.badRequest, {
        'status': 'FAILED',
        'message': 'Invalid CBE Birr PIN.'
      });
      return;
    }

    // Process money transfer
    final amount = txnData['amount'];
    if (account['balance'] < amount) {
      sendJsonResponse(request, HttpStatus.badRequest, {
        'status': 'FAILED',
        'message': 'Insufficient funds for this transaction.'
      });
      return;
    }

    // Find Merchant Account (WKU Library Merchant)
    final merchant = accounts.firstWhere(
      (a) => a['accountNumber'] == '1000553647828',
      orElse: () => null,
    );

    if (merchant == null) {
      sendJsonResponse(request, HttpStatus.internalServerError, {
        'status': 'FAILED',
        'message': 'Library merchant account not found.'
      });
      return;
    }

    // Deduct and Credit
    account['balance'] = (account['balance'] - amount);
    merchant['balance'] = (merchant['balance'] + amount);
    saveAccounts();

    // Create completed transaction ledger entry
    final receipt = {
      'transactionId': txnId,
      'payerName': account['name'],
      'payerPhone': phone,
      'payerAccountNumber': account['accountNumber'],
      'recipientName': merchant['name'],
      'recipientAccountNumber': merchant['accountNumber'],
      'amount': amount,
      'reference': txnData['reference'],
      'date': DateTime.now().toIso8601String(),
      'status': 'SUCCESS',
      'remainingBalance': account['balance'],
    };

    transactions.insert(0, receipt);
    saveTransactions();

    // Clear active transaction caching
    activeTransactions.remove(txnId);
    pendingOtps.remove(txnId);

    sendJsonResponse(request, HttpStatus.ok, {
      'status': 'SUCCESS',
      'message': 'Payment completed successfully.',
      'receipt': receipt
    });
  } catch (e) {
    sendJsonResponse(request, HttpStatus.internalServerError, {
      'status': 'FAILED',
      'message': 'Verification failed: $e'
    });
  }
}

Future<void> handleDirectTransfer(HttpRequest request) async {
  try {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body);
    final srcAcc = data['sourceAccount']?.toString().trim();
    final destAcc = data['destinationAccount']?.toString().trim();
    final amount = double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
    final pin = data['pin']?.toString().trim();

    if (srcAcc == null || destAcc == null || amount <= 0 || pin == null) {
      sendJsonResponse(request, HttpStatus.badRequest, {
        'status': 'FAILED',
        'message': 'Source Account, Destination Account, Amount, and PIN are required.'
      });
      return;
    }

    final source = accounts.firstWhere((a) => a['accountNumber'] == srcAcc, orElse: () => null);
    final dest = accounts.firstWhere((a) => a['accountNumber'] == destAcc, orElse: () => null);

    if (source == null) {
      sendJsonResponse(request, HttpStatus.notFound, {
        'status': 'FAILED',
        'message': 'Source account not found.'
      });
      return;
    }

    if (dest == null) {
      sendJsonResponse(request, HttpStatus.notFound, {
        'status': 'FAILED',
        'message': 'Destination account not found.'
      });
      return;
    }

    if (source['pin'] != pin) {
      sendJsonResponse(request, HttpStatus.badRequest, {
        'status': 'FAILED',
        'message': 'Invalid PIN.'
      });
      return;
    }

    if (source['balance'] < amount) {
      sendJsonResponse(request, HttpStatus.badRequest, {
        'status': 'FAILED',
        'message': 'Insufficient funds.'
      });
      return;
    }

    source['balance'] = (source['balance'] - amount);
    dest['balance'] = (dest['balance'] + amount);
    saveAccounts();

    final txnId = 'CBE-TXN-${Random().nextInt(900000) + 100000}';
    final receipt = {
      'transactionId': txnId,
      'payerName': source['name'],
      'payerPhone': source['phone'],
      'payerAccountNumber': srcAcc,
      'recipientName': dest['name'],
      'recipientAccountNumber': destAcc,
      'amount': amount,
      'reference': 'Direct Fund Transfer',
      'date': DateTime.now().toIso8601String(),
      'status': 'SUCCESS',
      'remainingBalance': source['balance'],
    };

    transactions.insert(0, receipt);
    saveTransactions();

    sendJsonResponse(request, HttpStatus.ok, {
      'status': 'SUCCESS',
      'message': 'Transfer completed.',
      'receipt': receipt
    });
  } catch (e) {
    sendJsonResponse(request, HttpStatus.internalServerError, {
      'status': 'FAILED',
      'message': 'Transfer failed: $e'
    });
  }
}

void handleTransactionStatus(HttpRequest request) {
  final path = request.uri.path;
  final parts = path.split('/');
  final txnId = parts.last;

  final txn = transactions.firstWhere(
    (t) => t['transactionId'] == txnId,
    orElse: () => null,
  );

  if (txn != null) {
    sendJsonResponse(request, HttpStatus.ok, txn);
  } else {
    // Check pending
    final pending = activeTransactions[txnId];
    if (pending != null) {
      sendJsonResponse(request, HttpStatus.ok, {
        'transactionId': txnId,
        'status': 'PENDING_OTP'
      });
    } else {
      sendJsonResponse(request, HttpStatus.notFound, {
        'status': 'UNKNOWN',
        'message': 'Transaction not found.'
      });
    }
  }
}

void sendJsonResponse(HttpRequest request, int statusCode, Map<String, dynamic> responseData) {
  request.response.statusCode = statusCode;
  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(responseData));
  request.response.close();
}

void serveDashboard(HttpRequest request) {
  final response = request.response;
  response.headers.contentType = ContentType.html;

  final accountRows = accounts.map((a) => '''
    <tr>
      <td>${a['name']}</td>
      <td><code>${a['accountNumber']}</code></td>
      <td>${a['phone']}</td>
      <td class="amount font-bold">Br ${a['balance'].toStringAsFixed(2)}</td>
      <td><code>****</code></td>
    </tr>
  ''').join('\n');

  final transactionRows = transactions.isEmpty 
    ? '<tr><td colspan="7" class="text-center">No transactions registered yet.</td></tr>'
    : transactions.map((t) => '''
    <tr>
      <td><code>${t['transactionId']}</code></td>
      <td>${t['payerName']}<br><span class="sub">${t['payerPhone']}</span></td>
      <td><code>${t['payerAccountNumber']}</code></td>
      <td>${t['recipientName']}</td>
      <td class="amount text-success font-bold">Br ${t['amount'].toStringAsFixed(2)}</td>
      <td><span class="badge badge-success">${t['status']}</span></td>
      <td>${t['date'].toString().substring(11, 19)}<br><span class="sub">${t['date'].toString().substring(0, 10)}</span></td>
    </tr>
  ''').join('\n');

  final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>CBE Core Banking Server Portal</title>
  <style>
    :root {
      --cbe-purple: #4B237B;
      --cbe-gold: #FFD700;
      --bg-dark: #12121E;
      --card-dark: #1A1A2E;
      --border-color: #2D2D4A;
      --text-white: #FFFFFF;
      --text-gray: #9090B0;
      --success: #00D4AA;
    }
    body {
      background-color: var(--bg-dark);
      color: var(--text-white);
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      margin: 0;
      padding: 0;
    }
    header {
      background-color: var(--cbe-purple);
      border-bottom: 3px solid var(--cbe-gold);
      padding: 15px 30px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      box-shadow: 0 4px 20px rgba(0,0,0,0.3);
    }
    .brand {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .brand h1 {
      margin: 0;
      font-size: 20px;
      font-weight: 800;
      letter-spacing: 0.5px;
    }
    .brand h1 span {
      color: var(--cbe-gold);
    }
    .status-badge {
      display: flex;
      align-items: center;
      gap: 8px;
      background: rgba(0, 212, 170, 0.1);
      border: 1px solid var(--success);
      color: var(--success);
      padding: 6px 14px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: bold;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      background-color: var(--success);
      border-radius: 50%;
      animation: pulse 1.5s infinite;
    }
    @keyframes pulse {
      0% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(0, 212, 170, 0.7); }
      70% { transform: scale(1); box-shadow: 0 0 0 6px rgba(0, 212, 170, 0); }
      100% { transform: scale(0.95); box-shadow: 0 0 0 0 rgba(0, 212, 170, 0); }
    }
    .container {
      max-width: 1200px;
      margin: 40px auto;
      padding: 0 20px;
    }
    .grid {
      display: grid;
      grid-template-columns: 1fr;
      gap: 30px;
    }
    @media (min-width: 900px) {
      .grid {
        grid-template-columns: 2fr 1fr;
      }
    }
    .card {
      background-color: var(--card-dark);
      border: 1px solid var(--border-color);
      border-radius: 16px;
      padding: 24px;
      box-shadow: 0 8px 30px rgba(0,0,0,0.2);
    }
    .card h2 {
      margin-top: 0;
      margin-bottom: 20px;
      font-size: 18px;
      border-bottom: 1px solid var(--border-color);
      padding-bottom: 12px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .card h2 span {
      font-size: 11px;
      color: var(--text-gray);
      font-weight: normal;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      text-align: left;
    }
    th, td {
      padding: 12px 16px;
      border-bottom: 1px solid var(--border-color);
      font-size: 14px;
    }
    th {
      color: var(--text-gray);
      font-weight: 600;
      text-transform: uppercase;
      font-size: 11px;
      letter-spacing: 0.5px;
    }
    tr:last-child td {
      border-bottom: none;
    }
    code {
      background-color: rgba(255,255,255,0.06);
      padding: 3px 6px;
      border-radius: 4px;
      color: #FFB347;
      font-size: 13px;
    }
    .amount {
      font-family: 'Courier New', Courier, monospace;
    }
    .text-success { color: var(--success); }
    .font-bold { font-weight: bold; }
    .badge {
      display: inline-block;
      padding: 4px 8px;
      border-radius: 6px;
      font-size: 11px;
      font-weight: bold;
      text-transform: uppercase;
    }
    .badge-success {
      background-color: rgba(0, 212, 170, 0.15);
      color: var(--success);
    }
    .sub {
      font-size: 11px;
      color: var(--text-gray);
    }
    .info-bar {
      display: flex;
      gap: 20px;
      margin-bottom: 30px;
    }
    .info-card {
      background-color: var(--card-dark);
      border: 1px solid var(--border-color);
      border-radius: 12px;
      padding: 16px;
      flex: 1;
      display: flex;
      flex-direction: column;
    }
    .info-card span.val {
      font-size: 24px;
      font-weight: 800;
      color: var(--cbe-gold);
      margin-top: 6px;
    }
    .info-card span.lbl {
      font-size: 12px;
      color: var(--text-gray);
    }
    .text-center { text-align: center; }
  </style>
</head>
<body>
  <header>
    <div class="brand">
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color: var(--cbe-gold)"><rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect><rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect><line x1="6" y1="6" x2="6.01" y2="6"></line><line x1="6" y1="18" x2="6.01" y2="18"></line></svg>
      <h1>Commercial Bank of Ethiopia <span>Core Server</span></h1>
    </div>
    <div class="status-badge">
      <div class="status-dot"></div>
      BANK API SYSTEM ONLINE (PORT 8082)
    </div>
  </header>

  <div class="container">
    <div class="info-bar">
      <div class="info-card">
        <span class="lbl">Total Registered Accounts</span>
        <span class="val">${accounts.length}</span>
      </div>
      <div class="info-card">
        <span class="lbl">Total Settled Transactions</span>
        <span class="val">${transactions.length}</span>
      </div>
      <div class="info-card">
        <span class="lbl">CBE Birr API Gateway</span>
        <span class="val" style="color: var(--success)">ACTIVE</span>
      </div>
    </div>

    <div class="grid">
      <div class="card">
        <h2>Real-Time Transaction Ledger <span>Updated live on API callback</span></h2>
        <div style="overflow-x: auto;">
          <table>
            <thead>
              <tr>
                <th>Txn ID</th>
                <th>Payer</th>
                <th>Payer Account</th>
                <th>Recipient</th>
                <th>Amount</th>
                <th>Status</th>
                <th>Time (UTC)</th>
              </tr>
            </thead>
            <tbody>
              $transactionRows
            </tbody>
          </table>
        </div>
      </div>

      <div class="card">
        <h2>Bank Accounts Database</h2>
        <div style="overflow-x: auto;">
          <table>
            <thead>
              <tr>
                <th>Owner Name</th>
                <th>Account No.</th>
                <th>Phone</th>
                <th>Balance</th>
                <th>PIN</th>
              </tr>
            </thead>
            <tbody>
              $accountRows
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>

  <script>
    // Simple auto-reload every 5 seconds to show transaction updates
    setInterval(() => {
      fetch(window.location.href)
        .then(response => response.text())
        .then(html => {
          const parser = new DOMParser();
          const doc = parser.parseFromString(html, 'text/html');
          document.querySelector('.grid').innerHTML = doc.querySelector('.grid').innerHTML;
          document.querySelector('.info-bar').innerHTML = doc.querySelector('.info-bar').innerHTML;
        });
    }, 2500);
  </script>
</body>
</html>
  ''';
  response.write(html);
  response.close();
}
