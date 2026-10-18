import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';
import '../models/book.dart';

class ManageInventoryScreen extends StatefulWidget {
  const ManageInventoryScreen({super.key});
  @override
  State<ManageInventoryScreen> createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen> {
  String _search = '';
  final _idCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _genreCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _idCtrl.dispose(); _titleCtrl.dispose(); _authorCtrl.dispose(); _genreCtrl.dispose();
    super.dispose();
  }

  void _showAddOrEditDialog({Book? book}) {
    final isEdit = book != null;
    if (isEdit) {
      _idCtrl.text = book.id;
      _titleCtrl.text = book.title;
      _authorCtrl.text = book.author;
      _genreCtrl.text = book.genre;
    } else {
      _idCtrl.clear(); _titleCtrl.clear(); _authorCtrl.clear(); _genreCtrl.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF6C63FF).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                  child: Icon(isEdit ? Icons.edit_rounded : Icons.add_circle_rounded, color: const Color(0xFF6C63FF))),
                const SizedBox(width: 12),
                Text(isEdit ? 'Edit Book' : 'Add New Book', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 20),
              _field(_idCtrl, 'Book ID', Icons.qr_code_rounded, 'e.g. B008', enabled: !isEdit),
              const SizedBox(height: 12),
              _field(_titleCtrl, 'Title', Icons.title_rounded, 'e.g. The Great Gatsby'),
              const SizedBox(height: 12),
              _field(_authorCtrl, 'Author', Icons.person_rounded, 'e.g. F. Scott Fitzgerald'),
              const SizedBox(height: 12),
              _field(_genreCtrl, 'Genre', Icons.category_rounded, 'e.g. Fiction'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final lib = Provider.of<LibraryProvider>(context, listen: false);
                      final newBook = Book(
                        id: _idCtrl.text.trim(),
                        title: _titleCtrl.text.trim(),
                        author: _authorCtrl.text.trim(),
                        genre: _genreCtrl.text.trim(),
                        isbn: book?.isbn ?? '',
                        quantity: book?.quantity ?? 1,
                        coverImageUrl: book?.coverImageUrl ?? '',
                        reservationQueue: book?.reservationQueue ?? [],
                        issueCount: book?.issueCount ?? 0,
                      );

                      if (isEdit) {
                        lib.updateBook(newBook).then((_) {
                          if (!mounted) return;
                          Navigator.pop(context);
                          _showSuccess('Book updated successfully!');
                        });
                      } else {
                        lib.addBook(newBook).then((_) {
                          if (!mounted) return;
                          Navigator.pop(context);
                          _showSuccess('Book added successfully!');
                        });
                      }
                    }
                  },
                  icon: Icon(isEdit ? Icons.save_rounded : Icons.add_rounded),
                  label: Text(isEdit ? 'SAVE CHANGES' : 'ADD TO INVENTORY'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF00D4AA)),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.white))),
      ]),
      backgroundColor: const Color(0xFF2A2A3E),
    ));
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, String hint, {bool enabled = true, bool required = true, bool isNumber = false}) => TextFormField(
    controller: ctrl,
    enabled: enabled,
    keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    style: TextStyle(color: enabled ? Colors.white : Colors.white54),
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), hintText: hint),
    validator: (v) {
      if (required && v!.trim().isEmpty) return 'Required';
      if (isNumber && v != null && v.isNotEmpty && int.tryParse(v) == null) return 'Must be a number';
      return null;
    },
  );

  void _confirmDelete(LibraryProvider lib, Book book) {
    final available = lib.getAvailableCopies(book.id);
    if (available < book.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete a book with active issues!')));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Book?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Remove "${book.title}" from inventory?', style: const TextStyle(color: Color(0xFF9090B0))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF9090B0)))),
          ElevatedButton(
            onPressed: () {
              lib.removeBook(book.id).then((_) {
                if (!mounted) return;
                Navigator.pop(context);
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B6B), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final books = _search.isEmpty
        ? lib.books
        : lib.books.where((b) => b.title.toLowerCase().contains(_search.toLowerCase()) || b.id.toLowerCase().contains(_search.toLowerCase())).toList();
    final totalCount = lib.books.fold<int>(0, (sum, b) => sum + b.quantity);
    final availCount = lib.books.fold<int>(0, (sum, b) => sum + lib.getAvailableCopies(b.id));
    final issuedCount = totalCount - availCount;

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(backgroundColor: const Color(0xFF12121F), title: const Text('Manage Inventory'), foregroundColor: Colors.white),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            Expanded(child: _chip('$totalCount', 'Total Copies', const Color(0xFF6C63FF))),
            const SizedBox(width: 10),
            Expanded(child: _chip('$availCount', 'Available', const Color(0xFF00D4AA))),
            const SizedBox(width: 10),
            Expanded(child: _chip('$issuedCount', 'Issued', const Color(0xFFFF6B6B))),
          ]),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by title or ID…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Color(0xFF6B6B8A)), onPressed: () => setState(() => _search = '')) : null,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: books.isEmpty
              ? Center(child: Text('No books found', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: books.length,
                  itemBuilder: (_, i) {
                    final book = books[i];
                    final avail = lib.getAvailableCopies(book.id);
                    final isAvail = avail > 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF2A2A4A))),
                      child: Row(children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF6C63FF).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.menu_book_rounded, color: Color(0xFF6C63FF), size: 20)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(book.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text('ID: ${book.id}  •  ${book.author}', style: const TextStyle(color: Color(0xFF9090B0), fontSize: 11)),
                          const SizedBox(height: 5),
                          Row(children: [
                            _tagChip(book.genre, const Color(0xFF6C63FF)),
                            const SizedBox(width: 6),
                            _tagChip(isAvail ? '$avail Available' : 'Out of Stock', isAvail ? const Color(0xFF00D4AA) : const Color(0xFFFF6B6B)),
                          ]),
                        ])),
                        IconButton(icon: const Icon(Icons.edit_rounded, color: Color(0xFF00D4AA)), onPressed: () => _showAddOrEditDialog(book: book)),
                        IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF6B6B)), onPressed: () => _confirmDelete(lib, book)),
                      ]),
                    );
                  },
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditDialog(),
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _chip(String value, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
    child: Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
      Text(label, style: const TextStyle(color: Color(0xFF9090B0), fontSize: 11)),
    ]),
  );

  Widget _tagChip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}
