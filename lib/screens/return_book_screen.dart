import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/library_service.dart';

class ReturnBookScreen extends StatefulWidget {
  const ReturnBookScreen({super.key});
  @override
  State<ReturnBookScreen> createState() => _ReturnBookScreenState();
}

class _ReturnBookScreenState extends State<ReturnBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recordIdCtrl = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _preview;

  @override
  void dispose() {
    _recordIdCtrl.dispose();
    super.dispose();
  }

  void _onRecordIdChanged(String val) {
    final lib = Provider.of<LibraryProvider>(context, listen: false);
    final id = val.trim();
    if (id.isEmpty) { setState(() => _preview = null); return; }
    try {
      final record = lib.issueRecords.firstWhere((r) => r.id == id);
      final book = lib.getBookById(record.bookId);
      final isReturned = record.returnDate != null;
      final isOverdue = record.isOverdue;
      final daysLate = isOverdue ? DateTime.now().difference(record.dueDate).inDays : 0;
      final fine = daysLate * lib.finePerDay;
      setState(() => _preview = {
        'found': true,
        'returned': isReturned,
        'bookTitle': book?.title ?? 'Unknown',
        'studentId': record.studentId,
        'dueDate': record.dueDate,
        'isOverdue': isOverdue,
        'daysLate': daysLate,
        'fine': fine,
        'record': record,
      });
    } catch (_) {
      setState(() => _preview = {'found': false});
    }
  }

  Future<void> _returnBook() async {
    if (!_formKey.currentState!.validate()) return;
    final lib = Provider.of<LibraryProvider>(context, listen: false);
    final id = _recordIdCtrl.text.trim();

    try {
      final record = lib.issueRecords.firstWhere((r) => r.id == id);
      if (record.returnDate != null) {
        _showError('This book has already been returned!');
        return;
      }
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      await lib.returnBook(id);
      final fine = _preview?['fine'] ?? 0.0;
      setState(() { _isLoading = false; _preview = null; });
      _recordIdCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF00D4AA)),
          const SizedBox(width: 10),
          Expanded(child: Text(fine > 0 ? 'Book returned. Fine to collect: Br ${fine.toStringAsFixed(2)}' : 'Book returned successfully!', style: const TextStyle(color: Colors.white))),
        ]),
        backgroundColor: const Color(0xFF2A2A3E),
        duration: const Duration(seconds: 4),
      ));
    } catch (_) {
      _showError('Issue record not found!');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_rounded, color: Color(0xFFFF6B6B)),
        const SizedBox(width: 10),
        Text(msg, style: const TextStyle(color: Colors.white)),
      ]),
      backgroundColor: const Color(0xFF2A2A3E),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = _preview;
    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(backgroundColor: const Color(0xFF12121F), title: const Text('Return a Book'), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFFFFB347).withValues(alpha: 0.12), const Color(0xFFFF8E53).withValues(alpha: 0.05)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFB347).withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFFFB347).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.assignment_return_rounded, color: Color(0xFFFFB347), size: 26)),
                const SizedBox(width: 14),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Record a Return', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Enter the issue record ID to process return', style: TextStyle(color: Color(0xFF9090B0), fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 28),
            const Text('Record ID', style: TextStyle(color: Color(0xFF9090B0), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _recordIdCtrl,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
              decoration: const InputDecoration(labelText: 'Issue Record ID', prefixIcon: Icon(Icons.receipt_long_rounded), hintText: 'Found in My Books or Reports'),
              onChanged: _onRecordIdChanged,
              validator: (v) => v!.trim().isEmpty ? 'Enter record ID' : null,
            ),
            // Preview card
            if (p != null) ...[
              const SizedBox(height: 14),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: !p['found']! ? const Color(0xFFFF6B6B).withValues(alpha: 0.3)
                        : p['returned']! ? const Color(0xFF9090B0).withValues(alpha: 0.3)
                        : p['isOverdue']! ? const Color(0xFFFF6B6B).withValues(alpha: 0.3)
                        : const Color(0xFF00D4AA).withValues(alpha: 0.3),
                  ),
                ),
                child: p['found'] != true
                    ? const Row(children: [
                        Icon(Icons.search_off_rounded, color: Color(0xFFFF6B6B)),
                        SizedBox(width: 10),
                        Text('Issue record not found', style: TextStyle(color: Color(0xFFFF6B6B))),
                      ])
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.menu_book_rounded, color: Color(0xFF6C63FF), size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(p['bookTitle'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                        ]),
                        const SizedBox(height: 10),
                        _row('Student ID', p['studentId']),
                        _row('Due Date', DateFormat('MMM dd, yyyy').format(p['dueDate'])),
                        if (p['returned'] == true)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Row(children: [
                              Icon(Icons.info_outline_rounded, color: Color(0xFF9090B0), size: 16),
                              SizedBox(width: 6),
                              Text('Already returned', style: TextStyle(color: Color(0xFF9090B0))),
                            ]),
                          )
                        else if (p['isOverdue'] == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFFFF6B6B).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Row(children: [
                                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B), size: 16),
                                  const SizedBox(width: 6),
                                  Text('${p['daysLate']} days overdue', style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w600)),
                                ]),
                                Text('Fine: Br ${(p['fine'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w800, fontSize: 15)),
                              ]),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(children: [
                              const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF00D4AA), size: 16),
                              const SizedBox(width: 6),
                              const Text('On time — No fine', style: TextStyle(color: Color(0xFF00D4AA))),
                            ]),
                          ),
                      ]),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _returnBook,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.assignment_return_rounded),
                label: Text(_isLoading ? 'Processing...' : 'CONFIRM RETURN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB347),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Color(0xFF9090B0), fontSize: 12)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    ]),
  );
}
