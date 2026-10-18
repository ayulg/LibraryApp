import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/library_service.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final report = lib.generateReports();
    final overdue = lib.getOverdueBooks();
    final allRecords = lib.issueRecords;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Stats grid
        const Text('System Summary', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _StatTile(label: 'Total Books', value: '${report['totalBooks']}', icon: Icons.library_books_rounded, color: const Color(0xFF6C63FF))),
          const SizedBox(width: 12),
          Expanded(child: _StatTile(label: 'Currently Issued', value: '${report['issuedBooks']}', icon: Icons.outbox_rounded, color: const Color(0xFF00D4AA))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatTile(label: 'Available', value: '${(report['totalBooks'] as int) - (report['issuedBooks'] as int)}', icon: Icons.check_circle_rounded, color: const Color(0xFF4FC3F7))),
          const SizedBox(width: 12),
          Expanded(child: _StatTile(label: 'Overdue Books', value: '${report['overdueBooks']}', icon: Icons.warning_amber_rounded, color: const Color(0xFFFF6B6B))),
        ]),
        const SizedBox(height: 16),
        // Fines row
        Row(children: [
          Expanded(child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF00D4AA).withValues(alpha: 0.1), const Color(0xFF00D4AA).withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00D4AA).withValues(alpha: 0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Fines Collected', style: TextStyle(color: Color(0xFF9090B0), fontSize: 11)),
              const SizedBox(height: 4),
              Text('Br ${(report['totalFinesCollected'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
          )),
          const SizedBox(width: 12),
          Expanded(child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFFFF6B6B).withValues(alpha: 0.1), const Color(0xFFFF6B6B).withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Unpaid Fines', style: TextStyle(color: Color(0xFF9090B0), fontSize: 11)),
              const SizedBox(height: 4),
              Text('Br ${(report['totalUnpaidFines'] as double).toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
          )),
        ]),

        // Usage Analytics
        if (report['topBooks'] != null && (report['topBooks'] as List).isNotEmpty) ...[
          const SizedBox(height: 28),
          const Text('Usage Analytics', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2A4A)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Book Popularity', style: TextStyle(color: Color(0xFF9090B0), fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              ... (report['topBooks'] as List).map((book) {
                final double maxIssues = (report['topBooks'] as List).first.issueCount.toDouble();
                final double progress = maxIssues > 0 ? (book.issueCount / maxIssues) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(book.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Text('${book.issueCount} loans', style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 11, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFF2A2A3E),
                        color: const Color(0xFF00D4AA),
                        minHeight: 6,
                      ),
                    ),
                  ]),
                );
              }),
            ]),
          ),
        ],

        // Admin Actions
        const SizedBox(height: 28),
        const Text('System Management', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final count = await lib.sendSystemNotifications();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$count new notifications broadcasted to students!'),
                  backgroundColor: const Color(0xFF6C63FF),
                ));
              }
            },
            icon: const Icon(Icons.notifications_active_rounded),
            label: const Text('Broadcast Reminders & Alerts'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.15),
              foregroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF6C63FF), width: 1)),
            ),
          ),
        ),

        // All issue records
        const SizedBox(height: 32),
        Row(children: [
          const Text('All Transaction Records', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('${allRecords.length} total', style: const TextStyle(color: Color(0xFF9090B0), fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        if (allRecords.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('No transaction records yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
          ))
        else
          ...allRecords.reversed.map((r) {
            final book = lib.getBookById(r.bookId);
            final isReturned = r.returnDate != null;
            final isOverdue = r.isOverdue;
            Color statusColor = isReturned
                ? const Color(0xFF9090B0)
                : isOverdue ? const Color(0xFFFF6B6B) : const Color(0xFF00D4AA);
            String statusLabel = isReturned ? 'Returned' : isOverdue ? 'Overdue Books' : 'Active';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isOverdue && !isReturned ? const Color(0xFFFF6B6B).withValues(alpha: 0.25) : const Color(0xFF2A2A4A)),
              ),
              child: Row(children: [
                Container(width: 4, height: 48, decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(book?.title ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('ID: ${r.studentId}  •  Due: ${DateFormat('MMM dd').format(r.dueDate)}', style: const TextStyle(color: Color(0xFF9090B0), fontSize: 11)),
                  if (r.fineAmount > 0)
                    Text('Fine: Br ${r.fineAmount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11, fontWeight: FontWeight.w600)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
            );
          }),

        // Overdue section
        if (overdue.isNotEmpty) ...[
          const SizedBox(height: 32),
          Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B), size: 18),
            const SizedBox(width: 8),
            const Text('Overdue Books Reports', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${overdue.length} critical', style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          ...overdue.map((r) {
            final book = lib.getBookById(r.bookId);
            final daysLate = DateTime.now().difference(r.dueDate).inDays;
            final fine = daysLate * lib.finePerDay;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(book?.title ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Student: ${r.studentId}  •  $daysLate days late', style: const TextStyle(color: Color(0xFF9090B0), fontSize: 11)),
                ])),
                Text('Br ${fine.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
            );
          }),
        ],
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)]),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFF9090B0), fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(icon, color: color.withValues(alpha: 0.6), size: 16),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
