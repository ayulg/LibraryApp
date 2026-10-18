import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';
import '../services/cbe_api_service.dart';

class CbePaymentScreen extends StatefulWidget {
  final String? recordId;
  final String? studentId;
  final double amount;
  const CbePaymentScreen({super.key, this.recordId, this.studentId, required this.amount});

  @override
  State<CbePaymentScreen> createState() => _CbePaymentScreenState();
}

class _CbePaymentScreenState extends State<CbePaymentScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isProcessing = false;
  int _step = 1; // 1: Input details, 2: OTP Entry, 3: Success Receipt
  
  String? _transactionId;
  String? _simulatedOtp;
  Map<String, dynamic>? _receipt;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (widget.amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You do not have any outstanding fines to pay!'),
        backgroundColor: Color(0xFFFF6B6B),
      ));
      return;
    }

    if (_phoneController.text.isEmpty || _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter your CBE Birr phone number and PIN'),
        backgroundColor: Color(0xFFFF6B6B),
      ));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isProcessing = true);
    
    final res = await CbeApiService.initiatePayment(
      phone: _phoneController.text.trim(),
      amount: widget.amount,
      reference: widget.studentId != null
          ? 'Clear Fines for Student ID: ${widget.studentId}'
          : 'Clear Fine for Record: ${widget.recordId}',
    );
    
    setState(() => _isProcessing = false);

    if (res['status'] == 'PENDING_OTP') {
      setState(() {
        _transactionId = res['transactionId'];
        _simulatedOtp = res['otp'];
        _step = 2;
      });
      messenger.showSnackBar(const SnackBar(
        content: Text('CBE Birr: OTP verification code generated.'),
        backgroundColor: Color(0xFF4B237B),
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Payment initiation failed.'),
        backgroundColor: const Color(0xFFFF6B6B),
      ));
    }
  }

  Future<void> _verifyPayment() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter the OTP verification code'),
        backgroundColor: Color(0xFFFF6B6B),
      ));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final lib = Provider.of<LibraryProvider>(context, listen: false);

    setState(() => _isProcessing = true);

    final res = await CbeApiService.verifyPayment(
      transactionId: _transactionId!,
      pin: _pinController.text.trim(),
      otp: _otpController.text.trim(),
    );

    if (res['status'] == 'SUCCESS') {
      try {
        if (widget.studentId != null) {
          await lib.payAllFines(widget.studentId!);
        } else if (widget.recordId != null) {
          await lib.payFine(widget.recordId!);
        }
        setState(() {
          _receipt = res['receipt'];
          _isProcessing = false;
          _step = 3;
        });
      } catch (e) {
        setState(() => _isProcessing = false);
        messenger.showSnackBar(SnackBar(
          content: Text('Local DB sync error: $e'),
          backgroundColor: const Color(0xFFFF6B6B),
        ));
      }
    } else {
      setState(() => _isProcessing = false);
      messenger.showSnackBar(SnackBar(
        content: Text(res['message'] ?? 'Verification failed.'),
        backgroundColor: const Color(0xFFFF6B6B),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B237B), // CBE Purple
        title: const Text('CBE Birr Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 2) {
              setState(() {
                _step = 1;
                _otpController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _step == 3 ? _buildSuccess() : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final user = lib.currentUser;
    final studentId = widget.studentId ?? user?.studentId ?? '';
    final unpaidRecords = lib.getUserUnpaidFines(studentId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF4B237B).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_rounded, color: Color(0xFF4B237B), size: 64),
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Commercial Bank of Ethiopia',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Secure Payment Gateway',
              style: TextStyle(color: Color(0xFF9090B0), fontSize: 13),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4B237B).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(color: Color(0xFF9090B0))),
                    Text('Br ${widget.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
                const Divider(color: Color(0xFF2A2A4A), height: 32),
                if (_step == 1) ...[
                  if (unpaidRecords.isNotEmpty) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Fine Breakdown Details:',
                        style: TextStyle(color: Color(0xFF9090B0), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...unpaidRecords.map((r) {
                      final book = lib.getBookById(r.bookId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                book?.title ?? 'Unknown Book',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'Br ${r.accruedFine.toStringAsFixed(2)}',
                              style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(color: Color(0xFF2A2A4A), height: 32),
                  ],
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'CBE Birr Phone Number',
                      hintText: 'e.g. 0911223344',
                      prefixIcon: Icon(Icons.phone_android_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'CBE Birr PIN',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                ] else if (_step == 2) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4B237B).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF4B237B).withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SECURITY VERIFICATION REQUIRED',
                          style: TextStyle(color: Color(0xFFFFB347), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'A verification code has been dispatched to ${_phoneController.text}.',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'For simulator environment testing, your code is: $_simulatedOtp',
                          style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 4, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Enter 4-Digit OTP Code',
                      labelStyle: TextStyle(letterSpacing: 0, fontSize: 14),
                      prefixIcon: Icon(Icons.security_rounded),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing 
                  ? null 
                  : (_step == 1 ? _initiatePayment : _verifyPayment),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B237B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isProcessing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_step == 1 ? 'INITIATE PAYMENT' : 'VERIFY & PAY SECURELY', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
          ),
          if (_step == 2) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isProcessing ? null : () => setState(() => _step = 1),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF6B6B)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('CANCEL TRANSACTION', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold)),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security_rounded, color: Color(0xFF00D4AA), size: 16),
              SizedBox(width: 8),
              Text('SSL Encrypted Real Bank Transaction', style: TextStyle(color: Color(0xFF00D4AA), fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: Color(0xFF00D4AA), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 64),
              ),
              const SizedBox(height: 28),
              const Text('Payment Successful!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Commercial Bank of Ethiopia Transaction Receipt',
                style: TextStyle(color: Color(0xFF9090B0), fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    _receiptRow('Transaction ID', _receipt?['transactionId'] ?? 'N/A'),
                    const Divider(color: Color(0xFF2A2A4A), height: 24),
                    _receiptRow('Payer Name', _receipt?['payerName'] ?? 'N/A'),
                    const Divider(color: Color(0xFF2A2A4A), height: 24),
                    _receiptRow('Payer Phone', _receipt?['payerPhone'] ?? 'N/A'),
                    const Divider(color: Color(0xFF2A2A4A), height: 24),
                    _receiptRow('Account Number', _receipt?['payerAccountNumber'] ?? 'N/A'),
                    const Divider(color: Color(0xFF2A2A4A), height: 24),
                    _receiptRow('Recipient', _receipt?['recipientName'] ?? 'N/A'),
                    const Divider(color: Color(0xFF2A2A4A), height: 24),
                    _receiptRow('Amount Paid', 'Br ${(_receipt?['amount'] as num?)?.toStringAsFixed(2) ?? widget.amount.toStringAsFixed(2)}'),
                    const Divider(color: Color(0xFF2A2A4A), height: 24),
                    _receiptRow('Remaining Balance', 'Br ${(_receipt?['remainingBalance'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4B237B)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    widget.studentId != null ? 'BACK TO DASHBOARD' : 'BACK TO MY BOOKS',
                    style: const TextStyle(color: Color(0xFF4B237B), fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF9090B0), fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
