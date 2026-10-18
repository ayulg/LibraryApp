import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';

class ManageReservationsScreen extends StatelessWidget {
  const ManageReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final reservedBooks = lib.books.where((b) => b.reservationQueue.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(backgroundColor: const Color(0xFF12121F), title: const Text('Reservations'), foregroundColor: Colors.white),
      body: reservedBooks.isEmpty
          ? Center(child: Text('No active reservations', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reservedBooks.length,
              itemBuilder: (_, i) {
                final book = reservedBooks[i];
                final available = lib.getAvailableCopies(book.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2A2A4A))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.bookmark_rounded, color: Color(0xFFFFB347), size: 24),
                      const SizedBox(width: 12),
                      Expanded(child: Text(book.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      _badge('${book.reservationQueue.length} in queue', const Color(0xFFFFB347)),
                      const SizedBox(width: 8),
                      _badge('$available copies available', available > 0 ? const Color(0xFF00D4AA) : const Color(0xFFFF6B6B)),
                    ]),
                    const SizedBox(height: 12),
                    const Text('Queue:', style: TextStyle(color: Color(0xFF9090B0), fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ...book.reservationQueue.asMap().entries.map((entry) {
                      final pos = entry.key + 1;
                      final uid = entry.value;
                      final user = lib.getUserById(uid);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(children: [
                          Text('#$pos', style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(user?.name ?? 'User $uid', style: const TextStyle(color: Colors.white))),
                          Text(user?.studentId ?? '', style: const TextStyle(color: Color(0xFF9090B0), fontSize: 12)),
                        ]),
                      );
                    }),
                  ]),
                );
              },
            ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
