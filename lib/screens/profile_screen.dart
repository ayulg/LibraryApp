import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final user = lib.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF12121F),
        appBar: AppBar(title: const Text('Profile'), backgroundColor: const Color(0xFF12121F)),
        body: const Center(child: Text('Not logged in', style: TextStyle(color: Colors.white))),
      );
    }

    final allRecords = lib.getRecordsForStudent(user.studentId);
    final activeCount = allRecords.where((r) => r.returnDate == null).length;
    final totalFines = lib.calculateFines(user.studentId);
    final totalBorrowed = allRecords.length;

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF12121F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
            child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U', style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 40, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(user.email, style: const TextStyle(color: Color(0xFF9090B0), fontSize: 14)),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: user.isBlocked ? const Color(0xFFFF6B6B).withValues(alpha: 0.3) : const Color(0xFF00D4AA).withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(user.isBlocked ? Icons.block_rounded : Icons.verified_user_rounded, color: user.isBlocked ? const Color(0xFFFF6B6B) : const Color(0xFF00D4AA), size: 28),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Account Status', style: TextStyle(color: Color(0xFF9090B0), fontSize: 12)),
                Text(user.isBlocked ? 'Blocked' : 'Active', style: TextStyle(color: user.isBlocked ? const Color(0xFFFF6B6B) : const Color(0xFF00D4AA), fontWeight: FontWeight.bold, fontSize: 16)),
              ])),
            ]),
          ),
          
          const SizedBox(height: 24),
          const Align(alignment: Alignment.centerLeft, child: Text('My Statistics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),
          
          Row(children: [
            Expanded(child: _statCard('Total Borrowed', '$totalBorrowed', Icons.library_books_rounded, const Color(0xFF6C63FF))),
            const SizedBox(width: 16),
            Expanded(child: _statCard('Currently Active', '$activeCount', Icons.bookmark_rounded, const Color(0xFF4FC3F7))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _statCard('Unpaid Fines', 'Br ${totalFines.toStringAsFixed(2)}', Icons.receipt_long_rounded, totalFines > 0 ? const Color(0xFFFF6B6B) : const Color(0xFF00D4AA))),
            const SizedBox(width: 16),
            Expanded(child: _statCard('Student ID', user.studentId, Icons.badge_rounded, const Color(0xFFFFB347))),
          ]),
        ]),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF9090B0), fontSize: 12)),
      ]),
    );
  }
}
