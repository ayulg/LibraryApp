import 'dart:convert';
import 'package:http/http.dart' as http;

class CbeApiService {
  static const String baseUrl = 'http://127.0.0.1:8082';

  /// Initiate Payment
  /// Returns a map containing:
  /// - 'status': 'PENDING_OTP' or 'FAILED'
  /// - 'transactionId': String (if successful)
  /// - 'otp': String (the generated OTP, returned for easy demo verification)
  /// - 'message': String
  static Future<Map<String, dynamic>> initiatePayment({
    required String phone,
    required double amount,
    String reference = 'Library Fine Payment',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/cbe/payment/initiate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'amount': amount,
          'reference': reference,
        }),
      ).timeout(const Duration(seconds: 10));

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded;
      } else {
        return {
          'status': 'FAILED',
          'message': decoded['message'] ?? 'Failed to initiate payment.',
        };
      }
    } catch (e) {
      return {
        'status': 'FAILED',
        'message': 'CBE Bank Server Connection Error: Ensure backend is running on port 8082.',
      };
    }
  }

  /// Verify OTP and PIN to complete payment
  /// Returns a map containing:
  /// - 'status': 'SUCCESS' or 'FAILED'
  /// - 'message': String
  /// - 'receipt': Map (if successful)
  static Future<Map<String, dynamic>> verifyPayment({
    required String transactionId,
    required String pin,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/cbe/payment/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'transactionId': transactionId,
          'pin': pin,
          'otp': otp,
        }),
      ).timeout(const Duration(seconds: 10));

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded;
      } else {
        return {
          'status': 'FAILED',
          'message': decoded['message'] ?? 'Failed to verify payment.',
        };
      }
    } catch (e) {
      return {
        'status': 'FAILED',
        'message': 'Connection error: Unable to verify transaction with bank server.',
      };
    }
  }

  /// Direct Account-to-Account Money Transfer
  /// Returns a map containing:
  /// - 'status': 'SUCCESS' or 'FAILED'
  /// - 'message': String
  /// - 'receipt': Map (if successful)
  static Future<Map<String, dynamic>> transferFunds({
    required String sourceAccount,
    required String destinationAccount,
    required double amount,
    required String pin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/cbe/transfer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sourceAccount': sourceAccount,
          'destinationAccount': destinationAccount,
          'amount': amount,
          'pin': pin,
        }),
      ).timeout(const Duration(seconds: 10));

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded;
      } else {
        return {
          'status': 'FAILED',
          'message': decoded['message'] ?? 'Direct fund transfer failed.',
        };
      }
    } catch (e) {
      return {
        'status': 'FAILED',
        'message': 'Connection error: Direct transfer network unreachable.',
      };
    }
  }
}
