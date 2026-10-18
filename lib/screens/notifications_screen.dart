import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/library_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final user = lib.currentUser;
    final notifications = user != null ? lib.getNotificationsForUser(user.id) : [];

    return Scaffold(
      backgroundColor: const Color(0xFF12121F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        title: const Text('Notifications'),
        foregroundColor: Colors.white,
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () => lib.markNotificationsAsRead(user!.id),
              child: const Text('Mark all as read', style: TextStyle(color: Color(0xFF6C63FF))),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (_, i) {
                final note = notifications[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: note.isRead ? const Color(0xFF1E1E2E) : const Color(0xFF252545),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: note.isRead ? const Color(0xFF2A2A4A) : const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_active_rounded, color: const Color(0xFF6C63FF), size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(note.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                Text(
                                  DateFormat('HH:mm').format(note.date),
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(note.message, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4)),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('MMM dd, yyyy').format(note.date),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
