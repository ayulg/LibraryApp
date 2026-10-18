import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/library_service.dart';
import 'book_list_screen.dart';
import 'my_books_screen.dart';
import 'reports_screen.dart';
import 'issue_book_screen.dart';
import 'return_book_screen.dart';
import 'overdue_report_screen.dart';
import 'manage_inventory_screen.dart';
import 'notifications_screen.dart';
import 'student_management_screen.dart';
import 'manage_reservations_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import 'reserve_book_screen.dart';
import 'setup_admin_screen.dart';
import '../models/notification.dart';
import 'cbe_payment_screen.dart';
import '../services/cbe_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isDarkMode = true;
  bool _isEyeComfort = false;
  late AuthService _auth;

  @override
  void initState() {
    super.initState();
    _auth = Provider.of<AuthService>(context, listen: false);
    _auth.addListener(_syncUser);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUser();
    });
  }

  void _syncUser() {
    if (!mounted) return;
    final lib = Provider.of<LibraryProvider>(context, listen: false);

    // Keep LibraryProvider's user in sync with AuthService
    if (_auth.currentUser != lib.currentUser) {
      lib.updateCurrentUser(_auth.currentUser);
      // Automatically check for notifications for students
      if (_auth.currentUser != null && !_auth.currentUser!.isAdmin) {
        lib.sendSystemNotifications();
      }
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_syncUser);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final user = lib.currentUser;
    final isAdmin = user?.isAdmin ?? false;
    final isFirstLogin = user?.isFirstLogin ?? false;

    if (isAdmin && isFirstLogin) {
      return const SetupAdminScreen();
    }

    final pages = isAdmin
        ? [
            const _AdminDashboard(),
            const BookListScreen(),
            const ReportsScreen(),
          ]
        : [_StudentDashboard(), const BookListScreen(), const MyBooksScreen()];

    final navItems = isAdmin
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_rounded),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Reports',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_rounded),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_rounded),
              label: 'My Books',
            ),
          ];

    return Scaffold(
      backgroundColor: _isDarkMode
          ? const Color(0xFF12121F)
          : const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: _isDarkMode ? const Color(0xFF12121F) : Colors.white,
        elevation: _isDarkMode ? 0 : 2,
        foregroundColor: _isDarkMode ? Colors.white : Colors.black87,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9C95FF)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('LibraFlow'),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
              if (user != null && lib.getUnreadNotificationCount(user.id) > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '${lib.getUnreadNotificationCount(user.id)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            color: const Color(0xFF2A2A3E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
              child: Text(
                (user?.name.isNotEmpty == true)
                    ? user!.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onSelected: (v) async {
              if (v == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              } else if (v == 'dark_mode') {
                setState(() => _isDarkMode = !_isDarkMode);
              } else if (v == 'eye_comfort') {
                setState(() => _isEyeComfort = !_isEyeComfort);
              } else if (v == 'logout') {
                final auth = Provider.of<AuthService>(context, listen: false);
                final lib = Provider.of<LibraryProvider>(
                  context,
                  listen: false,
                );
                final navigator = Navigator.of(context);

                await auth.signOut();
                lib.logout();

                navigator.pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: Color(0xFF9090B0),
                        fontSize: 12,
                      ),
                    ),
                    const Divider(color: Color(0xFF3A3A5C)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF00D4AA),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'My Profile',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'dark_mode',
                child: Row(
                  children: [
                    Icon(
                      _isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: Colors.amber,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      _isDarkMode ? 'Dark Mode' : 'Light Mode',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'eye_comfort',
                child: Row(
                  children: [
                    Icon(
                      _isEyeComfort
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: Colors.orange,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Eye Comfort: ${_isEyeComfort ? "ON" : "OFF"}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout,
                      color: Color(0xFFFF6B6B),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Logout',
                      style: TextStyle(color: Color(0xFFFF6B6B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: _isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDarkMode
                      ? [const Color(0xFF6C63FF), const Color(0xFF4A3FBF)]
                      : [const Color(0xFF6C63FF), const Color(0xFF9C95FF)],
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        (user?.name.isNotEmpty == true)
                            ? user!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.person_rounded,
                color: Color(0xFF00D4AA),
              ),
              title: Text(
                'My Profile',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            SwitchListTile(
              secondary: const Icon(
                Icons.dark_mode_rounded,
                color: Colors.amber,
              ),
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              value: _isDarkMode,
              activeThumbColor: const Color(0xFF6C63FF),
              onChanged: (v) => setState(() => _isDarkMode = v),
            ),
            SwitchListTile(
              secondary: const Icon(
                Icons.visibility_rounded,
                color: Colors.orange,
              ),
              title: Text(
                'Eye Comfort',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              value: _isEyeComfort,
              activeThumbColor: const Color(0xFF6C63FF),
              onChanged: (v) => setState(() => _isEyeComfort = v),
            ),
            const Spacer(),
            const Divider(color: Color(0xFF3A3A5C)),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFFF6B6B)),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                final auth = Provider.of<AuthService>(context, listen: false);
                final lib = Provider.of<LibraryProvider>(
                  context,
                  listen: false,
                );
                final navigator = Navigator.of(context);
                await auth.signOut();
                lib.logout();
                navigator.pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: Stack(
        children: [
          pages[_currentIndex],
          if (_isEyeComfort)
            IgnorePointer(
              child: Container(color: Colors.orange.withValues(alpha: 0.1)),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          border: Border(top: BorderSide(color: Color(0xFF2A2A4A))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF6C63FF),
          unselectedItemColor: const Color(0xFF6B6B8A),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: navItems,
        ),
      ),
    );
  }
}

// ── STAT CARD ─────────────────────────────────────────────────────────────────
class LibStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const LibStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF9090B0), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── QUICK ACTION ──────────────────────────────────────────────────────────────
class LibQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const LibQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── ADMIN DASHBOARD ───────────────────────────────────────────────────────────
class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard();

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final report = lib.generateReports();
    final user = lib.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF4A3FBF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Librarian / Admin',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Hello, ${user?.name ?? 'Admin'} 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Here's your library overview",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Admin actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LibQuickAction(
                  icon: Icons.inventory_2_rounded,
                  label: 'Manage Inventory',
                  color: const Color(0xFF6C63FF),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageInventoryScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LibQuickAction(
                  icon: Icons.warning_amber_rounded,
                  label: 'Overdue Report',
                  color: const Color(0xFFFF6B6B),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OverdueReportScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LibQuickAction(
                  icon: Icons.people_alt_rounded,
                  label: 'Manage Students',
                  color: const Color(0xFF00D4AA),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentManagementScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LibQuickAction(
                  icon: Icons.bookmark_rounded,
                  label: 'Reservations',
                  color: const Color(0xFFFFB347),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageReservationsScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (report['mostPopularBook'] != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Most Popular Book',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00D4AA).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFF00D4AA),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['mostPopularBook'].title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${report['mostPopularBook'].issueCount} times issued',
                          style: const TextStyle(
                            color: Color(0xFF00D4AA),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── STUDENT DASHBOARD ─────────────────────────────────────────────────────────
class _StudentDashboard extends StatelessWidget {
  const _StudentDashboard();

  @override
  Widget build(BuildContext context) {
    final lib = Provider.of<LibraryProvider>(context);
    final user = lib.currentUser;
    final sid = user?.studentId ?? 'S001';
    final myRecords = lib
        .getRecordsForStudent(sid)
        .where((r) => r.returnDate == null)
        .toList();
    final totalFines = lib.calculateFines(sid);
    final overdueCount = myRecords.where((r) => r.isOverdue).length;
    final List<NotificationModel> unreadNotes = user != null 
        ? lib.getNotificationsForUser(user.id).where((n) => !n.isRead).toList() 
        : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5276), Color(0xFF00C9A0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4AA).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ID: ${user?.studentId ?? 'STU123'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Hello, ${user?.name ?? 'Student'} 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Keep reading. Keep growing.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          if (unreadNotes.isNotEmpty) ...[
            const SizedBox(height: 20),
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded,
                        color: Color(0xFF6C63FF)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Important Alert',
                            style: TextStyle(
                              color: Color(0xFF6C63FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            unreadNotes.first.message,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF6B6B8A)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Student actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: LibQuickAction(
                  icon: Icons.outbox_rounded,
                  label: 'Issue Book',
                  color: const Color(0xFF00D4AA),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IssueBookScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LibQuickAction(
                  icon: Icons.assignment_return_rounded,
                  label: 'Return Book',
                  color: const Color(0xFFFFB347),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReturnBookScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LibQuickAction(
                  icon: Icons.bookmark_add_rounded,
                  label: 'Reserve Book',
                  color: const Color(0xFF6C63FF),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReserveBookScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LibQuickAction(
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'CBE Payment',
                  color: const Color(0xFF4B237B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CbePaymentScreen(
                          studentId: sid,
                          amount: totalFines,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'My Status',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: LibStatCard(
                  label: 'Books Issued',
                  value: '${myRecords.length}',
                  icon: Icons.book_rounded,
                  color: const Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: LibStatCard(
                  label: 'Overdue Books',
                  value: '$overdueCount',
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: totalFines > 0
                ? () => _showPaymentModal(context, lib, sid, totalFines)
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: totalFines > 0
                    ? const Color(0xFFFF6B6B).withValues(alpha: 0.08)
                    : const Color(0xFF00D4AA).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: totalFines > 0
                      ? const Color(0xFFFF6B6B).withValues(alpha: 0.3)
                      : const Color(0xFF00D4AA).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        totalFines > 0
                            ? Icons.payment_rounded
                            : Icons.check_circle_rounded,
                        color: totalFines > 0
                            ? const Color(0xFFFF6B6B)
                            : const Color(0xFF00D4AA),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unpaid Fines',
                            style: TextStyle(
                              color: totalFines > 0
                                  ? const Color(0xFFFF6B6B)
                                  : const Color(0xFF00D4AA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (totalFines > 0)
                            const Text(
                              'Tap to pay with CBE Birr',
                              style: TextStyle(
                                color: Color(0xFFFF6B6B),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    'Br ${totalFines.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: totalFines > 0
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF00D4AA),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (myRecords.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text(
              'Currently Issued',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...myRecords.take(3).map((record) {
              final book = lib.getBookById(record.bookId);
              final isOverdue = record.isOverdue;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOverdue
                        ? const Color(0xFFFF6B6B).withValues(alpha: 0.4)
                        : const Color(0xFF2A2A4A),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? const Color(
                                    0xFFFF6B6B,
                                  ).withValues(alpha: 0.15)
                                : const Color(
                                    0xFF6C63FF,
                                  ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: isOverdue
                                ? const Color(0xFFFF6B6B)
                                : const Color(0xFF6C63FF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book?.title ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                isOverdue ? 'OVERDUE BOOKS' : 'Borrowed',
                                style: TextStyle(
                                  color: isOverdue
                                      ? const Color(0xFFFF6B6B)
                                      : const Color(0xFF00D4AA),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isOverdue)
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFFF6B6B),
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _dateCol(
                          'Issued',
                          DateFormat('MMM dd, yyyy').format(record.issueDate),
                        ),
                        _dateCol(
                          'Due Date',
                          DateFormat('MMM dd, yyyy').format(record.dueDate),
                          isCritical: isOverdue,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _dateCol(String label, String date, {bool isCritical = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF9090B0), fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: TextStyle(
            color: isCritical ? const Color(0xFFFF6B6B) : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showPaymentModal(
    BuildContext context,
    LibraryProvider lib,
    String studentId,
    double amount,
  ) {
    final phoneController = TextEditingController();
    final pinController = TextEditingController();
    final otpController = TextEditingController();
    
    int step = 1; // 1: Input details, 2: OTP verification
    String? transactionId;
    String? simulatedOtp;
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_rounded,
                    color: Color(0xFF4B237B),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    step == 1 ? 'CBE Birr Payment' : 'CBE Security Check',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4B237B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total to Pay:',
                      style: TextStyle(color: Color(0xFF9090B0)),
                    ),
                    Text(
                      'Br ${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (step == 1) ...[
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_android_rounded),
                    hintText: 'e.g. 0911223344',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'CBE Birr PIN',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B237B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF4B237B).withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OTP VERIFICATION CODE SENT',
                        style: TextStyle(color: Color(0xFFFFB347), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'For testing, use code: $simulatedOtp',
                        style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 4, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'Enter 4-Digit OTP Code',
                    labelStyle: TextStyle(letterSpacing: 0, fontSize: 13),
                    prefixIcon: Icon(Icons.security_rounded),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          if (step == 1) {
                            if (phoneController.text.isEmpty ||
                                pinController.text.isEmpty) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter phone number and PIN'),
                                ),
                              );
                              return;
                            }
                            setModalState(() => isProcessing = true);
                            final res = await CbeApiService.initiatePayment(
                              phone: phoneController.text.trim(),
                              amount: amount,
                              reference: 'Clear Fines for Student $studentId',
                            );
                            setModalState(() {
                              isProcessing = false;
                              if (res['status'] == 'PENDING_OTP') {
                                transactionId = res['transactionId'];
                                simulatedOtp = res['otp'];
                                step = 2;
                              } else {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Payment initiation failed.'),
                                    backgroundColor: const Color(0xFFFF6B6B),
                                  ),
                                );
                              }
                            });
                          } else {
                            if (otpController.text.isEmpty) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter OTP code'),
                                ),
                              );
                              return;
                            }
                            setModalState(() => isProcessing = true);
                            final res = await CbeApiService.verifyPayment(
                              transactionId: transactionId!,
                              pin: pinController.text.trim(),
                              otp: otpController.text.trim(),
                            );
                            setModalState(() => isProcessing = false);
                            if (res['status'] == 'SUCCESS') {
                              await lib.payAllFines(studentId);
                              if (context.mounted) {
                                navigator.pop();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Payment Successful! All fines cleared.',
                                    ),
                                    backgroundColor: Color(0xFF00D4AA),
                                  ),
                                );
                              }
                            } else {
                              if (context.mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(res['message'] ?? 'Verification failed.'),
                                    backgroundColor: const Color(0xFFFF6B6B),
                                  ),
                                );
                              }
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B237B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          step == 1 ? 'INITIATE PAYMENT' : 'VERIFY & PAY',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              if (step == 2) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isProcessing
                        ? null
                        : () => setModalState(() {
                              step = 1;
                              otpController.clear();
                            }),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF6B6B)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: Color(0xFF00D4AA),
                    size: 12,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Secured by Commercial Bank of Ethiopia',
                    style: TextStyle(color: Color(0xFF9090B0), fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
