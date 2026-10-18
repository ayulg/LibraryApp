import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});
  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final allStudents = lib.getAllStudents();
    final students = _search.isEmpty
        ? allStudents
        : allStudents.where((u) => u.name.toLowerCase().contains(_search.toLowerCase()) || u.studentId.toLowerCase().contains(_search.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(backgroundColor: const Color(0xFF12121F), title: const Text('Manage Students'), foregroundColor: Colors.white),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by name or ID...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, color: Color(0xFF6B6B8A)), onPressed: () => setState(() => _search = '')) : null,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: students.isEmpty
              ? Center(child: Text('No students found', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: students.length,
                  itemBuilder: (_, i) {
                    final student = students[i];
                    final activeIssues = lib.getRecordsForStudent(student.studentId).where((r) => r.returnDate == null).length;
                    final totalFines = lib.calculateFines(student.studentId);
                    final isBlocked = student.isBlocked;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF2A2A4A))),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                            child: Text(student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S', style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(student.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              if (totalFines > 0 && !isBlocked) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFFF6B6B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('PAYMENT NEEDED', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ]
                            ]),
                            const SizedBox(height: 2),
                            Text('ID: ${student.studentId} • ${student.email}', style: const TextStyle(color: Color(0xFF9090B0), fontSize: 12)),
                          ])),
                          Switch(
                            value: isBlocked,
                            activeThumbColor: const Color(0xFFFF6B6B),
                            inactiveTrackColor: const Color(0xFF2A2A4A),
                            onChanged: (val) {
                              lib.toggleUserBlock(student.id, val);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? 'Student blocked' : 'Student unblocked')));
                            },
                          ),
                        ]),
                        const SizedBox(height: 14),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                          _statCol('Active Issues', '$activeIssues', const Color(0xFF00D4AA)),
                          _statCol('Unpaid Fines', 'Br ${totalFines.toStringAsFixed(2)}', totalFines > 0 ? const Color(0xFFFF6B6B) : const Color(0xFF00D4AA)),
                          _statCol('Status', isBlocked ? 'Blocked' : 'Active', isBlocked ? const Color(0xFFFF6B6B) : const Color(0xFF00D4AA)),
                        ]),
                      ]),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  Widget _statCol(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Color(0xFF9090B0), fontSize: 11)),
    ]);
  }
}
