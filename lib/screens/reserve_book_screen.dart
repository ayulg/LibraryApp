import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';

class ReserveBookScreen extends StatefulWidget {
  const ReserveBookScreen({super.key});
  @override
  State<ReserveBookScreen> createState() => _ReserveBookScreenState();
}

class _ReserveBookScreenState extends State<ReserveBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _studentIdCtrl = TextEditingController();
  final _bookInputCtrl = TextEditingController();
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
    _bookInputCtrl.dispose();
    super.dispose();
  }

  void _onBookInputChanged(String val) {
    final lib = Provider.of<LibraryProvider>(context, listen: false);
    final book = lib.getBookByIdOrTitle(val.trim());
    setState(() {
      if (val.trim().isEmpty) {
        _previewBookTitle = null;
        _previewError = null;
      } else if (book == null) {
        _previewBookTitle = null;
        _previewError = 'Book not found';
      } else {
        _previewBookTitle = book.title;
        final available = lib.getAvailableCopies(book.id);
        if (available > 0) {
          _previewError = 'This book is available! Please use "Issue Book" instead.';
        } else {
          // Check if the student entered is already in the queue
          // We'll check this during submission properly, but can preview if student id is valid
          _previewError = null;
        }
      }
    });
  }

  Future<void> _reserveBook() async {
    if (!_formKey.currentState!.validate()) return;
    final lib = Provider.of<LibraryProvider>(context, listen: false);
    final bookInput = _bookInputCtrl.text.trim();
    final studentId = _studentIdCtrl.text.trim();
    
    final book = lib.getBookByIdOrTitle(bookInput);
    if (book == null) {
      _showError('Book not found!');
      return;
    }

    final student = lib.getUserByStudentId(studentId);
    if (student == null) {
      _showError('Student not found!');
      return;
    }
    
    final available = lib.getAvailableCopies(book.id);
    if (available > 0) {
      _showError('This book is available! Please use "Issue Book" instead.');
      return;
    }

    if (book.reservationQueue.contains(student.id)) {
      _showError('This student has already reserved this book.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await lib.reserveBook(book.id, student.id);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF6C63FF)),
          const SizedBox(width: 10),
          Expanded(child: Text('"${book.title}" reserved for ${student.name}! We\'ll notify them when it\'s available.', style: const TextStyle(color: Colors.white))),
        ]),
        backgroundColor: const Color(0xFF2A2A3E),
      ));
      Navigator.pop(context);
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
    final user = Provider.of<LibraryProvider>(context).currentUser;
    final isAdmin = user?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        title: const Text('Reserve a Book'),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF6C63FF).withValues(alpha: 0.15), const Color(0xFF4A3FBF).withValues(alpha: 0.05)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.2)),
              ),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF6C63FF).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.bookmark_add_rounded, color: Color(0xFF6C63FF), size: 26)),
                const SizedBox(width: 14),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Reserve a Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Join the waitlist for a book that is currently out of stock', style: TextStyle(color: Color(0xFF9090B0), fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 28),
            const Text('Student Details', style: TextStyle(color: Color(0xFF9090B0), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _studentIdCtrl,
              readOnly: !isAdmin,
              style: TextStyle(color: isAdmin ? Colors.white : const Color(0xFF9090B0)),
              decoration: const InputDecoration(labelText: 'Student ID', prefixIcon: Icon(Icons.badge_rounded), hintText: 'e.g. STU001'),
              validator: (v) => v!.trim().isEmpty ? 'Enter student ID' : null,
            ),
            const SizedBox(height: 24),
            const Text('Book Details', style: TextStyle(color: Color(0xFF9090B0), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _bookInputCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Book ID or Title', prefixIcon: Icon(Icons.search_rounded), hintText: 'e.g. B001 or Flutter Mastery'),
              onChanged: _onBookInputChanged,
              validator: (v) => v!.trim().isEmpty ? 'Enter book ID or title' : null,
            ),
            if (_previewBookTitle != null || _previewError != null) ...[
              const SizedBox(height: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _previewError != null ? const Color(0xFFFF6B6B).withValues(alpha: 0.08) : const Color(0xFF6C63FF).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _previewError != null ? const Color(0xFFFF6B6B).withValues(alpha: 0.3) : const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(
                    _previewError != null ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                    color: _previewError != null ? const Color(0xFFFF6B6B) : const Color(0xFF6C63FF),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    _previewError ?? _previewBookTitle!,
                    style: TextStyle(color: _previewError != null ? const Color(0xFFFF6B6B) : const Color(0xFF6C63FF), fontSize: 13),
                  )),
                ]),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _reserveBook,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.bookmark_add_rounded),
                label: Text(_isLoading ? 'Reserving...' : 'RESERVE BOOK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
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
