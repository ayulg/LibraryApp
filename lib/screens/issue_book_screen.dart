import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';

class IssueBookScreen extends StatefulWidget {
  const IssueBookScreen({super.key});
  @override
  State<IssueBookScreen> createState() => _IssueBookScreenState();
}

class _IssueBookScreenState extends State<IssueBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdCtrl = TextEditingController();
  final _bookIdCtrl = TextEditingController();
  bool _isLoading = false;
  String? _previewBookTitle;
  String? _previewError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<LibraryProvider>(context, listen: false).currentUser;
      if (user != null && !user.isAdmin) {
        _studentIdCtrl.text = user.studentId;
      }
    });
  }

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _bookIdCtrl.dispose();
    super.dispose();
  }

  void _onBookIdChanged(String val) {
    final lib = Provider.of<LibraryProvider>(context, listen: false);
    final book = lib.getBookById(val.trim());
    setState(() {
      if (val.trim().isEmpty) {
        _previewBookTitle = null;
        _previewError = null;
      } else if (book == null) {
        _previewBookTitle = null;
        _previewError = 'Book not found';
      } else if (lib.getAvailableCopies(book.id) == 0) {
        _previewBookTitle = book.title;
        _previewError = 'Out of Stock';
      } else {
        _previewBookTitle = book.title;
        _previewError = null;
      }
    });
  }

  Future<void> _issueBook() async {
    if (!_formKey.currentState!.validate()) return;
    final lib = Provider.of<LibraryProvider>(context, listen: false);
    final bookId = _bookIdCtrl.text.trim();
    final studentId = _studentIdCtrl.text.trim();
    final book = lib.getBookById(bookId);

    if (book == null) {
      _showError('Book not found!');
      return;
    }
    if (lib.getAvailableCopies(bookId) == 0) {
      _showError('This book is out of stock!');
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    try {
      await lib.issueBook(bookId, studentId);
      await lib.cancelReservation(bookId, lib.currentUser!.id);
      setState(() { _isLoading = false; _previewBookTitle = null; _previewError = null; });
      _studentIdCtrl.clear();
      _bookIdCtrl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF00D4AA)),
          const SizedBox(width: 10),
          Expanded(child: Text('"${book.title}" issued to $studentId\nDue in 5 days.', style: const TextStyle(color: Colors.white))),
        ]),
        backgroundColor: const Color(0xFF2A2A3E),
      ));
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_rounded, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: const Color(0xFFFF6B6B),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        title: const Text('Issue a Book'),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF00D4AA).withValues(alpha: 0.15), const Color(0xFF00C9A0).withValues(alpha: 0.05)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF00D4AA).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.outbox_rounded, color: Color(0xFF00D4AA), size: 26)),
                const SizedBox(width: 14),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Issue a Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Assign a library book to a student for 5 days', style: TextStyle(color: Color(0xFF9090B0), fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 28),
            const Text('Student Details', style: TextStyle(color: Color(0xFF9090B0), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _studentIdCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Student ID', prefixIcon: Icon(Icons.badge_rounded), hintText: 'e.g. STU001'),
              validator: (v) => v!.trim().isEmpty ? 'Enter student ID' : null,
            ),
            const SizedBox(height: 24),
            const Text('Book Details', style: TextStyle(color: Color(0xFF9090B0), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _bookIdCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Book ID', prefixIcon: Icon(Icons.qr_code_rounded), hintText: 'e.g. B001'),
              onChanged: _onBookIdChanged,
              validator: (v) => v!.trim().isEmpty ? 'Enter book ID' : null,
            ),
            if (_previewBookTitle != null || _previewError != null) ...[
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _previewError != null ? const Color(0xFFFF6B6B).withValues(alpha: 0.08) : const Color(0xFF00D4AA).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _previewError != null ? const Color(0xFFFF6B6B).withValues(alpha: 0.3) : const Color(0xFF00D4AA).withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(
                    _previewError != null ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                    color: _previewError != null ? const Color(0xFFFF6B6B) : const Color(0xFF00D4AA),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    _previewError ?? _previewBookTitle!,
                    style: TextStyle(color: _previewError != null ? const Color(0xFFFF6B6B) : const Color(0xFF00D4AA), fontSize: 13),
                  )),
                ]),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _issueBook,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.outbox_rounded),
                label: Text(_isLoading ? 'Issuing...' : 'ISSUE BOOK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4AA),
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
}
