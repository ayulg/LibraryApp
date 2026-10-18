import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/library_service.dart';
import 'cbe_payment_screen.dart';

class MyBooksScreen extends StatelessWidget {
  const MyBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final sid = lib.currentUser?.studentId ?? 'S001';
    final active = lib.getRecordsForStudent(sid).where((r) => r.returnDate == null).toList();
    final history = lib.getRecordsForStudent(sid).where((r) => r.returnDate != null).toList();
    final unpaidFines = lib.getUserUnpaidFines(sid);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              labelColor: const Color(0xFF6C63FF),
              unselectedLabelColor: const Color(0xFF9090B0),
              indicator: const BoxDecoration(
                color: Color(0xFF6C63FF),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Currently Issued'),
                Tab(text: 'History'),
                Tab(text: 'Unpaid Fines'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [
                // Active books
                active.isEmpty
                    ? _emptyState('No books currently issued', Icons.bookmark_border_rounded)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: active.length,
                        itemBuilder: (_, i) {
                          final r = active[i];
                          final book = lib.getBookById(r.bookId);
                          final isOverdue = r.isOverdue;
                          final daysLeft = r.dueDate.difference(DateTime.now()).inDays;
                          final isDueSoon = !isOverdue && daysLeft <= 3;

                          Color statusColor = const Color(0xFF00D4AA);
                          String statusText = 'Due in $daysLeft days';
                          IconData statusIcon = Icons.schedule_rounded;
                          if (isOverdue) {
                            statusColor = const Color(0xFFFF6B6B);
                            statusText = '${-daysLeft} days OVERDUE';
                            statusIcon = Icons.warning_amber_rounded;
                          } else if (isDueSoon) {
                            statusColor = const Color(0xFFFFB347);
                            statusText = 'Due in $daysLeft day${daysLeft != 1 ? 's' : ''} — Soon!';
                            statusIcon = Icons.timer_rounded;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isOverdue ? const Color(0xFFFF6B6B).withValues(alpha: 0.3) : const Color(0xFF2A2A4A)),
                            ),
                            child: Column(children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                    child: Icon(Icons.menu_book_rounded, color: statusColor, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(book?.title ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 3),
                                    Text(book?.author ?? '', style: const TextStyle(color: Color(0xFF9090B0), fontSize: 12)),
                                    const SizedBox(height: 6),
                                    Row(children: [
                                      Icon(statusIcon, color: statusColor, size: 14),
                                      const SizedBox(width: 4),
                                      Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ]),
                                  ])),
                                ]),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: const BoxDecoration(
                                  border: Border(top: BorderSide(color: Color(0xFF2A2A4A))),
                                ),
                                child: Row(children: [
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text('Issued: ${DateFormat('MMM dd').format(r.issueDate)}', style: const TextStyle(color: Color(0xFF9090B0), fontSize: 11)),
                                    Text('Due: ${DateFormat('MMM dd, yyyy').format(r.dueDate)}', style: const TextStyle(color: Color(0xFF9090B0), fontSize: 11)),
                                  ])),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      lib.returnBook(r.id);
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book returned successfully!')));
                                    },
                                    icon: const Icon(Icons.assignment_return_rounded, size: 16),
                                    label: const Text('Return'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6C63FF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ]),
                              ),
                            ]),
                          );
                        },
                      ),
                // History
                history.isEmpty
                    ? _emptyState('No borrowing history yet', Icons.history_rounded)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: history.length,
                        itemBuilder: (_, i) {
                          final r = history[i];
                          final book = lib.getBookById(r.bookId);
                          final hadFine = r.fineAmount > 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2E),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF2A2A4A)),
                            ),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFF2A2A3E), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF00D4AA), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(book?.title ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 3),
                                Text('Returned: ${DateFormat('MMM dd, yyyy').format(r.returnDate!)}', style: const TextStyle(color: Color(0xFF9090B0), fontSize: 11)),
                              ])),
                              if (hadFine)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFFF6B6B).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                  child: Text('Fine: Br ${r.fineAmount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11, fontWeight: FontWeight.w600)),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFF00D4AA).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('On time', style: TextStyle(color: Color(0xFF00D4AA), fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                            ]),
                          );
                        },
                      ),
                // Unpaid Fines
                unpaidFines.isEmpty
                    ? _emptyState('No unpaid fines', Icons.verified_rounded)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: unpaidFines.length,
                        itemBuilder: (_, i) {
                          final r = unpaidFines[i];
                          final book = lib.getBookById(r.bookId);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.2)),
                            ),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: const Color(0xFFFF6B6B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFFF6B6B), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(book?.title ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 3),
                                Text('Fine: Br ${r.fineAmount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13, fontWeight: FontWeight.w700)),
                              ])),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.account_balance_wallet_rounded, size: 16),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CbePaymentScreen(
                                        recordId: r.id,
                                        amount: r.fineAmount,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4B237B), // CBE Purple
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                                label: const Text('Pay with CBE Birr'),
                              ),
                            ]),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.1)),
      const SizedBox(height: 12),
      Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 15)),
    ]));
  }
}
