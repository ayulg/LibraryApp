import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/library_service.dart';
import '../models/issue_record.dart';

class OverdueReportScreen extends StatefulWidget {
  const OverdueReportScreen({super.key});

  @override
  State<OverdueReportScreen> createState() => _OverdueReportScreenState();
}

class _OverdueReportScreenState extends State<OverdueReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final unpaidRecords = lib.getUnpaidRecords();
    
    final activeOverdue = unpaidRecords.where((r) => r.returnDate == null && r.isOverdue).toList();
    final pendingFines = unpaidRecords.where((r) => r.returnDate != null && !r.isFinePaid).toList();

    final totalAccrued = unpaidRecords.fold(0.0, (sum, r) => sum + r.accruedFine);

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        elevation: 0,
        title: const Text('Overdue Books Reports', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded, color: Color(0xFF6C63FF)),
            onPressed: () => _showBroadcastConfirm(context, lib),
            tooltip: 'Broadcast Reminders',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryHeader(totalAccrued, activeOverdue.length + pendingFines.length),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF6C63FF),
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF6B6B8A),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(text: 'ACTIVE OVERDUE BOOKS (${activeOverdue.length})'),
              Tab(text: 'PENDING FINES (${pendingFines.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecordsList(context, lib, activeOverdue, true),
                _buildRecordsList(context, lib, pendingFines, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(double totalFines, int count) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4A3FBF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TOTAL OUTSTANDING',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  'Br ${totalFines.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'From $count identified issues',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList(BuildContext context, LibraryProvider lib, List<IssueRecord> records, bool isActive) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.verified_user_rounded : Icons.check_circle_outline_rounded,
              size: 80,
              color: const Color(0xFF00D4AA).withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No active overdue books!' : 'No pending fines!',
              style: const TextStyle(color: Color(0xFF6B6B8A), fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final r = records[index];
        final book = lib.getBookById(r.bookId);
        final student = lib.getUserByStudentId(r.studentId);
        final fine = r.accruedFine;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? const Color(0xFFFF6B6B).withValues(alpha: 0.2) : const Color(0xFF6C63FF).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      width: 50,
                      decoration: BoxDecoration(
                        color: (isActive ? const Color(0xFFFF6B6B) : const Color(0xFF6C63FF)).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isActive ? Icons.timer_rounded : Icons.assignment_turned_in_rounded,
                        color: isActive ? const Color(0xFFFF6B6B) : const Color(0xFF6C63FF),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book?.title ?? 'Unknown Book',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Student: ${student?.name ?? r.studentId}',
                            style: const TextStyle(color: Color(0xFF9090B0), fontSize: 12),
                          ),
                          Text(
                            'ID: ${r.studentId}',
                            style: const TextStyle(color: Color(0xFF6B6B8A), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Br ${fine.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isActive ? const Color(0xFFFF6B6B) : const Color(0xFF00D4AA),
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const Text(
                          'penalty',
                          style: TextStyle(color: Color(0xFF6B6B8A), fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: const Color(0xFF6B6B8A)),
                        const SizedBox(width: 6),
                        Text(
                          isActive 
                            ? 'Due: ${DateFormat('MMM dd, yyyy').format(r.dueDate)}'
                            : 'Returned: ${DateFormat('MMM dd, yyyy').format(r.returnDate!)}',
                          style: const TextStyle(color: Color(0xFF9090B0), fontSize: 12),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        if (isActive && student != null)
                          _ActionButton(
                            label: student.isBlocked ? 'UNBLOCK' : 'BLOCK',
                            color: student.isBlocked ? const Color(0xFF00D4AA) : const Color(0xFFFF6B6B),
                            onTap: () => lib.toggleUserBlock(student.id, !student.isBlocked),
                          ),
                        const SizedBox(width: 8),
                        _ActionButton(
                          label: 'MARK PAID',
                          color: const Color(0xFF00D4AA),
                          onTap: () => _showPayConfirm(context, lib, r, fine),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBroadcastConfirm(BuildContext context, LibraryProvider lib) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('Broadcast Reminders?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will send automated notifications to all students with overdue books or unpaid fines.',
          style: TextStyle(color: Color(0xFF9090B0)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () async {
              Navigator.pop(context);
              final count = await lib.sendSystemNotifications();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$count notifications broadcasted successfully!'),
                  backgroundColor: const Color(0xFF6C63FF),
                ));
              }
            },
            child: const Text('SEND ALL'),
          ),
        ],
      ),
    );
  }

  void _showPayConfirm(BuildContext context, LibraryProvider lib, IssueRecord record, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Cash Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Verify that the student has paid the following amount in cash:', style: TextStyle(color: Color(0xFF9090B0))),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Br ${amount.toStringAsFixed(2)}',
                style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 32, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF6B6B8A))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              lib.payFine(record.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Payment recorded successfully!'),
                backgroundColor: Color(0xFF00D4AA),
              ));
            },
            child: const Text('CONFIRM PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}
