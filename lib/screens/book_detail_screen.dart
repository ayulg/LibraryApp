import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/library_service.dart';
import 'pdf_viewer_screen.dart';

class BookDetailScreen extends StatelessWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

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
  };

  Color _genreColor(String genre) => _genreColors[genre] ?? const Color(0xFF9090B0);

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final book = lib.getBookById(bookId);

    if (book == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF12121F),
        appBar: AppBar(backgroundColor: const Color(0xFF12121F), title: const Text('Book Detail')),
        body: const Center(child: Text('Book not found', style: TextStyle(color: Colors.white))),
      );
    }

    final availableCopies = lib.getAvailableCopies(bookId);
    final isAvailable = availableCopies > 0;
    final isReserved = book.reservationQueue.isNotEmpty;
    final genreColor = _genreColor(book.genre);
    final activeRecord = lib.issueRecords.where((r) => r.bookId == bookId && r.returnDate == null).firstOrNull;
    final isAdmin = lib.currentUser?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF12121F),
            foregroundColor: Colors.white,
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [genreColor.withValues(alpha: 0.3), const Color(0xFF12121F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      Container(
                        width: 80,
                        height: 100,
                        decoration: BoxDecoration(
                          color: genreColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: genreColor.withValues(alpha: 0.3), width: 1.5),
                          boxShadow: [BoxShadow(color: genreColor.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14.5),
                          child: book.coverImageUrl.isNotEmpty
                              ? (book.coverImageUrl.startsWith('assets/')
                                  ? Image.asset(book.coverImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.menu_book_rounded, color: genreColor, size: 40))
                                  : Image.network(book.coverImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.menu_book_rounded, color: genreColor, size: 40)))
                              : Icon(Icons.menu_book_rounded, color: genreColor, size: 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: genreColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: Text(book.genre, style: TextStyle(color: genreColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isAvailable ? const Color(0xFF00D4AA).withValues(alpha: 0.12) : const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isAvailable ? const Color(0xFF00D4AA) : (isReserved ? const Color(0xFFFFB347) : const Color(0xFFFF6B6B)))),
                        const SizedBox(width: 5),
                        Text(isAvailable ? 'Available' : (isReserved ? 'Reserved' : 'Out of Stock'), style: TextStyle(color: isAvailable ? const Color(0xFF00D4AA) : (isReserved ? const Color(0xFFFFB347) : const Color(0xFFFF6B6B)), fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  Text(book.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.3)),
                  const SizedBox(height: 6),
                  Text('by ${book.author}', style: const TextStyle(color: Color(0xFF9090B0), fontSize: 15)),
                  const SizedBox(height: 24),
                  // Stats row
                  Row(children: [
                    _infoChip(Icons.confirmation_number_rounded, 'ID: ${book.id}', const Color(0xFF6C63FF)),
                    const SizedBox(width: 10),
                    _infoChip(Icons.library_books_rounded, '$availableCopies / ${book.quantity} left', const Color(0xFF00D4AA)),
                    if (book.reservationQueue.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      _infoChip(Icons.people_outline_rounded, '${book.reservationQueue.length} in queue', const Color(0xFFFFB347)),
                    ],
                  ]),
                  const SizedBox(height: 24),
                  // Issue record if currently issued
                  if (!isAvailable && activeRecord != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Current Issue Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        _detailRow('Student ID', activeRecord.studentId),
                        _detailRow('Issue Date', DateFormat('MMM dd, yyyy').format(activeRecord.issueDate)),
                        _detailRow('Due Date', DateFormat('MMM dd, yyyy').format(activeRecord.dueDate)),
                        _detailRow('Record ID', activeRecord.id, small: true),
                        if (activeRecord.isOverdue)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(children: [
                              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${DateTime.now().difference(activeRecord.dueDate).inDays} days overdue',
                                style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold),
                              ),
                            ]),
                          ),
                      ]),
                    ),
                  ],
                  if (book.pdfAssetPath.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00BCD4), Color(0xFF00E5FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00BCD4).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PdfViewerScreen(
                                  title: book.title,
                                  assetPath: book.pdfAssetPath,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
                          label: const Text('READ DIGITAL COPY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Action button
                  if (isAdmin) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isAvailable
                            ? null
                            : () {
                                if (activeRecord != null) {
                                  lib.returnBook(activeRecord.id).then((_) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book returned successfully!')));
                                    Navigator.pop(context);
                                  });
                                }
                              },
                        icon: Icon(activeRecord == null ? Icons.check_circle_rounded : Icons.assignment_return_rounded),
                        label: Text(activeRecord == null ? 'No Active Issues' : 'Mark 1 Copy as Returned'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeRecord == null ? const Color(0xFF2A2A3E) : const Color(0xFFFFB347),
                          foregroundColor: activeRecord == null ? const Color(0xFF9090B0) : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ] else if (isAvailable && !isAdmin) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (lib.currentUser != null) {
                            lib.issueBook(bookId, lib.currentUser!.studentId).then((_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Book "${book.title}" issued successfully!'),
                                backgroundColor: const Color(0xFF00D4AA),
                              ));
                            }).catchError((e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(e.toString().replaceAll('Exception: ', '')),
                                backgroundColor: const Color(0xFFFF6B6B),
                              ));
                            });
                          }
                        },
                        icon: const Icon(Icons.outbox_rounded),
                        label: const Text('Issue This Book'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D4AA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ] else if (!isAvailable && !isAdmin) ...[
                    // Student view for non-available books
                    if (lib.currentUser != null && book.reservationQueue.contains(lib.currentUser!.id)) ...[
                      Builder(builder: (ctx) {
                        final pos = book.reservationQueue.indexOf(lib.currentUser!.id) + 1;
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB347).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFFB347).withValues(alpha: 0.3)),
                          ),
                          child: Column(children: [
                            const Icon(Icons.people_alt_rounded, color: Color(0xFFFFB347), size: 28),
                            const SizedBox(height: 8),
                            Text('You are #$pos in the waitlist', style: const TextStyle(color: Color(0xFFFFB347), fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('We\'ll notify you when a copy is available.', style: TextStyle(color: Color(0xFF9090B0), fontSize: 12), textAlign: TextAlign.center),
                          ]),
                        );
                      }),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            lib.cancelReservation(bookId, lib.currentUser!.id).then((_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reservation cancelled.')));
                            });
                          },
                          icon: const Icon(Icons.bookmark_remove_rounded, color: Color(0xFFFF6B6B)),
                          label: const Text('Cancel Reservation', style: TextStyle(color: Color(0xFFFF6B6B))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFF6B6B)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (lib.currentUser != null) {
                              lib.reserveBook(bookId, lib.currentUser!.id).then((_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book reserved! You\'ll be notified when available.')));
                              });
                            }
                          },
                          icon: const Icon(Icons.bookmark_add_rounded),
                          label: const Text('Reserve This Book'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ],

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Row(children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _detailRow(String label, String value, {bool small = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Color(0xFF9090B0), fontSize: 13)),
        Text(value, style: TextStyle(color: Colors.white, fontSize: small ? 11 : 13, fontWeight: FontWeight.w600, fontFamily: small ? 'monospace' : null)),
      ]),
    );
  }
}
