import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';
import 'book_detail_screen.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});
  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  String _searchQuery = '';
  String _filterGenre = 'All';
  bool _onlyAvailable = false;

  static const _genreColors = {
    'Technology': Color(0xFF6C63FF),
    'Fiction': Color(0xFF00D4AA),
    'History': Color(0xFFFFB347),
    'Science': Color(0xFF4FC3F7),
    'Romance': Color(0xFFFF6B6B),
    'Science Fiction': Color(0xFF9C27B0),
    'Fantasy': Color(0xFFE91E63),
    'Textbooks': Color(0xFF3F51B5),
    'Personal Development': Color(0xFF00BCD4),
    'All': Colors.white,
  };

  Color _genreColor(String genre) => _genreColors[genre] ?? const Color(0xFF9090B0);

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    var books = lib.searchBooks(_searchQuery);
    if (_filterGenre != 'All') {
      books = books.where((b) => b.genre == _filterGenre).toList();
    }
    if (_onlyAvailable) {
      books = books.where((b) => lib.getAvailableCopies(b.id) > 0).toList();
    }
    final requestedGenres = [
      'Romance', 'Science Fiction', 'Fantasy', 'Textbooks', 
      'Personal Development'
    ];
    final existingGenres = lib.books.map((b) => b.genre).toSet();
    final genres = ['All', ...requestedGenres, ...existingGenres.where((g) => !requestedGenres.contains(g))];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by title, author, genre…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, color: Color(0xFF6B6B8A)), onPressed: () => setState(() => _searchQuery = ''))
                  : null,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: genres.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final g = genres[i];
              final selected = _filterGenre == g;
              final c = _genreColor(g);
              return GestureDetector(
                onTap: () => setState(() => _filterGenre = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? c.withValues(alpha: 0.15) : const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? c : const Color(0xFF2A2A4A)),
                  ),
                  child: Text(g, style: TextStyle(color: selected ? c : const Color(0xFF9090B0), fontWeight: selected ? FontWeight.w700 : FontWeight.normal, fontSize: 13)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${books.length} book${books.length != 1 ? 's' : ''} found', style: const TextStyle(color: Color(0xFF9090B0), fontSize: 12)),
              Row(
                children: [
                  const Text('Available Only', style: TextStyle(color: Color(0xFF9090B0), fontSize: 12)),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 24,
                    width: 40,
                    child: Switch(
                      value: _onlyAvailable,
                      onChanged: (val) => setState(() => _onlyAvailable = val),
                      activeThumbColor: const Color(0xFF00D4AA),
                      inactiveTrackColor: const Color(0xFF2A2A4A),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: books.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.search_off_rounded, size: 64, color: Colors.white.withValues(alpha: 0.15)),
                    const SizedBox(height: 12),
                    Text('No books found', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16)),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: books.length,
                  itemBuilder: (_, i) {
                    final book = books[i];
                    final availableCopies = lib.getAvailableCopies(book.id);
                    final isAvailable = availableCopies > 0;
                    final genreColor = _genreColor(book.genre);
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: book.id))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2A2A4A)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 52,
                            height: 70,
                            decoration: BoxDecoration(
                              color: genreColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: genreColor.withValues(alpha: 0.25)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: book.coverImageUrl.isNotEmpty
                                  ? (book.coverImageUrl.startsWith('assets/')
                                      ? Image.asset(book.coverImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.menu_book_rounded, color: genreColor, size: 28))
                                      : Image.network(book.coverImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.menu_book_rounded, color: genreColor, size: 28)))
                                  : Icon(Icons.menu_book_rounded, color: genreColor, size: 28),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(book.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(book.author, style: const TextStyle(color: Color(0xFF9090B0), fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: genreColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                                child: Text(book.genre, style: TextStyle(color: genreColor, fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isAvailable ? const Color(0xFF00D4AA).withValues(alpha: 0.12) : const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(children: [
                                  Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isAvailable ? const Color(0xFF00D4AA) : const Color(0xFFFF6B6B))),
                                  const SizedBox(width: 5),
                                  Text(isAvailable ? '$availableCopies of ${book.quantity} Available' : 'Out of Stock', style: TextStyle(color: isAvailable ? const Color(0xFF00D4AA) : const Color(0xFFFF6B6B), fontSize: 11, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            ]),
                          ])),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
