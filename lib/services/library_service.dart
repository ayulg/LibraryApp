import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/book.dart';
import '../models/issue_record.dart';
import '../models/user.dart';
import '../models/notification.dart';
import 'package:intl/intl.dart';

class LibraryProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Book> _books = [];
  List<IssueRecord> _issueRecords = [];
  List<NotificationModel> _notifications = [];
  List<User> _users = [];
  User? currentUser;

  StreamSubscription? _booksSub;
  StreamSubscription? _recordsSub;
  StreamSubscription? _notificationsSub;
  StreamSubscription? _usersSub;

  bool _isNotificationsLoaded = false;
  
  LibraryProvider() {
    _initListeners();
  }

  void _initListeners() {
    _booksSub = _db.collection('books').snapshots().listen((snapshot) {
      _books = snapshot.docs.map((doc) => Book.fromFirestore(doc.data(), doc.id)).toList();
      notifyListeners();
      _checkAndSeedBooks();
    });

    _recordsSub = _db.collection('issue_records').snapshots().listen((snapshot) {
      _issueRecords = snapshot.docs.map((doc) => IssueRecord.fromFirestore(doc.data(), doc.id)).toList();
      notifyListeners();
    });

    _notificationsSub = _db.collection('notifications').orderBy('date', descending: true).snapshots().listen((snapshot) {
      _notifications = snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc.data(), doc.id)).toList();
      _isNotificationsLoaded = true;
      notifyListeners();
    });

    _usersSub = _db.collection('users').snapshots().listen((snapshot) {
      _users = snapshot.docs.map((doc) => User.fromFirestore(doc.data(), doc.id)).toList();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _booksSub?.cancel();
    _recordsSub?.cancel();
    _notificationsSub?.cancel();
    _usersSub?.cancel();
    super.dispose();
  }

  // Configuration
  final int borrowingLimit = 3;
  final double finePerDay = 5.0;
  final double maxAllowedFine = 50.0;

  List<Book> get books => [..._books];
  List<IssueRecord> get issueRecords => [..._issueRecords];
  List<NotificationModel> get notifications => [..._notifications];
  
  List<NotificationModel> getNotificationsForUser(String userId) {
    return _notifications.where((n) => n.userId == userId).toList();
  }

  int getUnreadNotificationCount(String userId) {
    return _notifications.where((n) => n.userId == userId && !n.isRead).length;
  }

  Future<void> markNotificationsAsRead(String userId) async {
    final batch = _db.batch();
    final unread = _notifications.where((n) => n.userId == userId && !n.isRead);
    for (var n in unread) {
      batch.update(_db.collection('notifications').doc(n.id), {'isRead': true});
    }
    await batch.commit();
  }

  void updateCurrentUser(User? user) {
    currentUser = user;
    notifyListeners();
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  Future<void> addBook(Book book) async {
    await _db.collection('books').add(book.toFirestore());
  }

  Future<void> updateBook(Book book) async {
    await _db.collection('books').doc(book.id).update(book.toFirestore());
  }

  Future<void> removeBook(String id) async {
    await _db.collection('books').doc(id).delete();
  }

  List<Book> searchBooks(String query) {
    if (query.isEmpty) return books;
    return _books.where((book) {
      final titleLower = book.title.toLowerCase();
      final authorLower = book.author.toLowerCase();
      final genreLower = book.genre.toLowerCase();
      final searchLower = query.toLowerCase();
      return titleLower.contains(searchLower) ||
             authorLower.contains(searchLower) ||
             genreLower.contains(searchLower);
    }).toList();
  }

  int getAvailableCopies(String bookId) {
    final book = getBookById(bookId);
    if (book == null) return 0;
    final activeIssues = _issueRecords.where((r) => r.bookId == bookId && r.returnDate == null).length;
    return book.quantity - activeIssues;
  }

  List<User> getAllStudents() {
    return _users.where((u) => !u.isAdmin).toList();
  }

  User? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  User? getUserByStudentId(String studentId) {
    try {
      return _users.firstWhere((u) => u.studentId == studentId);
    } catch (e) {
      return null;
    }
  }

  Future<void> toggleUserBlock(String userId, bool isBlocked) async {
    await _db.collection('users').doc(userId).update({'isBlocked': isBlocked});
  }

  Future<void> issueBook(String bookId, String studentId) async {
    // Check if user exists and is blocked
    final student = _users.firstWhere((u) => u.studentId == studentId, orElse: () => throw Exception('Student not found.'));
    if (student.isBlocked) {
      throw Exception('Issuance blocked! Student account is manually blocked by admin.');
    }

    // Check borrowing limit
    final activeIssues = _issueRecords.where((r) => r.studentId == studentId && r.returnDate == null).length;
    if (activeIssues >= borrowingLimit) {
      throw Exception('Borrowing limit reached ($borrowingLimit books max).');
    }

    // Check fine threshold
    final unpaidFines = calculateFines(studentId);
    if (unpaidFines >= maxAllowedFine) {
      throw Exception('Issuance blocked! You have Br ${unpaidFines.toStringAsFixed(2)} in unpaid fines.');
    }

    final book = getBookById(bookId);
    if (book != null) {
      final availableCopies = getAvailableCopies(bookId);
      bool canIssue = availableCopies > 0;

      if (!canIssue) {
        throw Exception('Book is out of stock.');
      }

      final batch = _db.batch();
      
      // Update book
      final updatedQueue = List<String>.from(book.reservationQueue);
      updatedQueue.remove(studentId); // Remove the student being issued the book
      
      batch.update(_db.collection('books').doc(bookId), {
        'issueCount': FieldValue.increment(1),
        'reservationQueue': updatedQueue,
      });

      // Create record
      final recordRef = _db.collection('issue_records').doc();
      final record = {
        'bookId': bookId,
        'studentId': studentId,
        'issueDate': DateTime.now(),
        'dueDate': DateTime.now().add(const Duration(days: 5)),
        'returnDate': null,
        'fineAmount': 0.0,
        'isFinePaid': false,
      };
      batch.set(recordRef, record);

      await batch.commit();
    } else {
      throw Exception('Book not found.');
    }
  }

  Future<void> returnBook(String recordId) async {
    final record = _issueRecords.firstWhere((r) => r.id == recordId);
    if (record.returnDate == null) {
      final now = DateTime.now();
      double fine = 0.0;
      if (now.isAfter(record.dueDate)) {
        final daysLate = now.difference(record.dueDate).inDays;
        fine = daysLate * finePerDay;
      }

      final book = getBookById(record.bookId);
      final batch = _db.batch();

      // Update record
      batch.update(_db.collection('issue_records').doc(recordId), {
        'returnDate': now,
        'fineAmount': fine,
      });

      // Update book
      if (book != null) {
        if (book.reservationQueue.isNotEmpty) {
          // Notify next user
          final nextUserId = book.reservationQueue.first;
          _addNotificationToFirestore(
            nextUserId,
            'Book Available!',
            'The book "${book.title}" you reserved is now available for pickup.',
          );
        }
      }

      await batch.commit();
    }
  }

  Future<void> reserveBook(String bookId, String userId) async {
    final book = getBookById(bookId);
    if (book != null && getAvailableCopies(bookId) == 0) {
      if (!book.reservationQueue.contains(userId)) {
        await _db.collection('books').doc(bookId).update({
          'reservationQueue': FieldValue.arrayUnion([userId]),
        });
      }
    }
  }

  Future<void> cancelReservation(String bookId, String userId) async {
    final book = getBookById(bookId);
    if (book != null) {
      final updatedQueue = List<String>.from(book.reservationQueue);
      updatedQueue.remove(userId);
      
      final Map<String, dynamic> updates = {'reservationQueue': updatedQueue};
      await _db.collection('books').doc(bookId).update(updates);
    }
  }

  Future<void> _addNotificationToFirestore(String userId, String title, String message) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'title': title,
      'message': message,
      'date': DateTime.now(),
      'isRead': false,
    });
  }

  List<IssueRecord> getOverdueBooks() {
    return _issueRecords.where((record) => record.isOverdue).toList();
  }

  Future<int> sendSystemNotifications() async {
    int count = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (!_isNotificationsLoaded) return 0; // Prevent spam if data hasn't synced yet

    for (var r in _issueRecords) {
      // Find the user object to get the Firebase UID (user.id)
      final user = _users.firstWhere(
        (u) => u.studentId == r.studentId, 
        orElse: () => User(id: '', name: '', studentId: '', email: '')
      );
      if (user.id.isEmpty) continue;

      final book = getBookById(r.bookId);
      final bookTitle = book?.title ?? 'Unknown Book';

      // 1. Due Soon Reminder (0 to 3 days left)
      if (r.returnDate == null) {
        final daysLeft = r.dueDate.difference(now).inDays;
        if (daysLeft >= 0 && daysLeft <= 3) {
          final title = 'Reminder: Book Due Soon';
          final message = 'Your book "$bookTitle" is due in $daysLeft days (${DateFormat('MMM dd').format(r.dueDate)}).';
          
          if (!_isNotificationAlreadySent(user.id, title, today)) {
            await _addNotificationToFirestore(user.id, title, message);
            count++;
          }
        }
      }

      // 2. Overdue Alert
      if (r.isOverdue) {
        final daysOverdue = now.difference(r.dueDate).inDays;
        String title;
        String message;

        if (daysOverdue >= 4) {
          title = 'URGENT: Return Warning';
          message = 'Your book "$bookTitle" is $daysOverdue days overdue. This is your FINAL WARNING. Failure to return the book and pay fines immediately will result in your account being BLOCKED.';
        } else {
          title = 'Overdue Alert!';
          message = 'Your book "$bookTitle" is overdue. Please return it immediately to avoid further fines.';
        }
        
        if (!_isNotificationAlreadySent(user.id, title, today)) {
          await _addNotificationToFirestore(user.id, title, message);
          count++;
        }
      }
    }

    // 3. Unpaid Fines Alert (Once per student)
    final studentsWithFines = _users.where((u) => calculateFines(u.studentId) > 0);
    for (var student in studentsWithFines) {
      final totalFine = calculateFines(student.studentId);
      final title = 'Unpaid Fines';
      final message = 'You have Br ${totalFine.toStringAsFixed(2)} in unpaid fines. Please settle them at the library.';
      
      if (!_isNotificationAlreadySent(student.id, title, today)) {
        await _addNotificationToFirestore(student.id, title, message);
        count++;
      }
    }

    return count;
  }

  bool _isNotificationAlreadySent(String userId, String title, DateTime date) {
    return _notifications.any((n) => 
      n.userId == userId && 
      n.title == title && 
      n.date.year == date.year && 
      n.date.month == date.month && 
      n.date.day == date.day
    );
  }

  List<IssueRecord> getUnpaidRecords() {
    return _issueRecords.where((r) => !r.isFinePaid && (r.isOverdue || r.fineAmount > 0)).toList();
  }

  List<IssueRecord> getUserUnpaidFines(String studentId) {
    return _issueRecords.where((r) => r.studentId == studentId && !r.isFinePaid && (r.isOverdue || r.fineAmount > 0)).toList();
  }

  Future<void> payFine(String recordId) async {
    await _db.collection('issue_records').doc(recordId).update({'isFinePaid': true});
  }

  Future<void> payAllFines(String studentId) async {
    final unpaid = getUserUnpaidFines(studentId);
    final batch = _db.batch();
    for (var r in unpaid) {
      final updates = {
        'isFinePaid': true,
        'fineAmount': r.accruedFine, // Store the amount paid
      };
      batch.update(_db.collection('issue_records').doc(r.id), updates);
    }
    await batch.commit();
  }

  double calculateFines(String studentId) {
    return _issueRecords
      .where((record) => record.studentId == studentId && !record.isFinePaid)
      .fold(0.0, (total, record) => total + record.accruedFine);
  }

  Map<String, dynamic> generateReports() {
    final totalBooks = _books.fold<int>(0, (total, book) => total + book.quantity);
    final issuedBooks = _issueRecords.where((r) => r.returnDate == null).length;
    final reservedBooks = _books.where((b) => b.reservationQueue.isNotEmpty).length;
    final overdueBooks = getOverdueBooks().length;
    
    final totalFinesCollected = _issueRecords
        .where((r) => r.isFinePaid)
        .fold(0.0, (total, record) => total + record.fineAmount);
    
    final totalUnpaidFines = _issueRecords
        .where((r) => !r.isFinePaid)
        .fold(0.0, (total, record) => total + record.accruedFine);

    List<Book> topBooks = [..._books];
    topBooks.sort((a, b) => b.issueCount.compareTo(a.issueCount));
    final mostPopularBooks = topBooks.take(3).toList();

    return {
      'totalBooks': totalBooks,
      'issuedBooks': issuedBooks,
      'reservedBooks': reservedBooks,
      'overdueBooks': overdueBooks,
      'totalFinesCollected': totalFinesCollected,
      'totalUnpaidFines': totalUnpaidFines,
      'mostPopularBook': mostPopularBooks.isNotEmpty ? mostPopularBooks.first : null,
      'topBooks': mostPopularBooks,
    };
  }

  List<IssueRecord> getRecordsForStudent(String studentId) {
    return _issueRecords.where((record) => record.studentId == studentId).toList();
  }

  Book? getBookById(String id) {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Book? getBookByIdOrTitle(String query) {
    final q = query.trim().toLowerCase();
    try {
      return _books.firstWhere(
        (b) => b.id.toLowerCase() == q || b.title.toLowerCase() == q,
      );
    } catch (_) {
      return null;
    }
  }

  bool _isSeeded = false;

  void _checkAndSeedBooks() async {
    if (_isSeeded) return;
    _isSeeded = true;

    final listToSeed = [
      {
        'id': 'PD001',
        'title': 'The 7 Habits of Highly Effective People',
        'author': 'Stephen R. Covey',
        'genre': 'Personal Development',
        'isbn': '9781471131820',
        'quantity': 3,
        'coverImageUrl': 'assets/images/the_7_habits_of_highly_effective_people.png',
        'pdfAssetPath': 'assets/pdfs/the_7_habits_of_highly_effective_people.pdf.bytes',
      },
      {
        'id': 'PD002',
        'title': 'The Alchemist',
        'author': 'Paulo Coelho',
        'genre': 'Personal Development',
        'isbn': '9780061122415',
        'quantity': 3,
        'coverImageUrl': 'assets/images/the_alchemist.png',
        'pdfAssetPath': 'assets/pdfs/the_alchemist.pdf.bytes',
      },
      {
        'id': 'PD003',
        'title': 'Rich Dad Poor Dad',
        'author': 'Robert T. Kiyosaki',
        'genre': 'Personal Development',
        'isbn': '9781612680194',
        'quantity': 3,
        'coverImageUrl': 'assets/images/rich_dad_poor_dad.png',
        'pdfAssetPath': 'assets/pdfs/rich_dad_poor_dad.pdf.bytes',
      },
      {
        'id': 'PD004',
        'title': 'Atomic Habits',
        'author': 'James Clear',
        'genre': 'Personal Development',
        'isbn': '9780735211292',
        'quantity': 3,
        'coverImageUrl': 'assets/images/atomic_habits.png',
        'pdfAssetPath': 'assets/pdfs/atomic_habits.pdf.bytes',
      },
      {
        'id': 'PD005',
        'title': '21 Success Secrets of Self-Made Millionaires',
        'author': 'Brian Tracy',
        'genre': 'Personal Development',
        'isbn': '9781583762059',
        'quantity': 3,
        'coverImageUrl': 'assets/images/21_success_secrets.png',
        'pdfAssetPath': 'assets/pdfs/21_success_secrets.pdf.bytes',
      },
      {
        'id': 'TB001',
        'title': 'Fundamentals of Chemistry',
        'author': 'David Goldberg',
        'genre': 'Textbooks',
        'isbn': '9780073402741',
        'quantity': 3,
        'coverImageUrl': 'assets/images/fundamentals_of_chemistry.png',
        'pdfAssetPath': 'assets/pdfs/fundamentals_of_chemistry.pdf.bytes',
      },
      {
        'id': 'TB002',
        'title': 'የአማርኛ ምሳሌያዊ ንግግሮች 1',
        'author': 'Traditional',
        'genre': 'Textbooks',
        'isbn': '9789994401832',
        'quantity': 3,
        'coverImageUrl': '',
        'pdfAssetPath': 'assets/pdfs/amharic_proverbs_1.pdf.bytes',
      },
      {
        'id': 'TB003',
        'title': 'Oxford Dictionary (Hasan)',
        'author': 'Oxford University Press',
        'genre': 'Textbooks',
        'isbn': '9780194799003',
        'quantity': 3,
        'coverImageUrl': '',
        'pdfAssetPath': 'assets/pdfs/oxford_dictionary_hasan.pdf.bytes',
      },
      {
        'id': 'RM001',
        'title': 'Healing Her Heart',
        'author': 'Laura Scott',
        'genre': 'Romance',
        'isbn': '9781301416952',
        'quantity': 3,
        'coverImageUrl': 'assets/images/healing_her_heart.png',
        'pdfAssetPath': 'assets/pdfs/healing_her_heart.pdf.bytes',
      },
      {
        'id': 'RM002',
        'title': 'The Unveiling',
        'author': 'Tamara Leigh',
        'genre': 'Romance',
        'isbn': '9781940134017',
        'quantity': 3,
        'coverImageUrl': 'assets/images/the_unveiling.png',
        'pdfAssetPath': 'assets/pdfs/the_unveiling.pdf.bytes',
      },
      {
        'id': 'RM003',
        'title': 'The Demon Girl',
        'author': 'Joanne Macgregor',
        'genre': 'Romance',
        'isbn': '9780992226817',
        'quantity': 3,
        'coverImageUrl': 'assets/images/the_demon_girl.png',
        'pdfAssetPath': 'assets/pdfs/the_demon_girl.pdf.bytes',
      },
      {
        'id': 'RM004',
        'title': 'Lost to You',
        'author': 'A.L. Jackson',
        'genre': 'Romance',
        'isbn': '9781938404283',
        'quantity': 3,
        'coverImageUrl': 'assets/images/lost_to_you.png',
        'pdfAssetPath': 'assets/pdfs/lost_to_you.pdf.bytes',
      },
      {
        'id': 'SF001',
        'title': 'The Invisible Man',
        'author': 'H. G. Wells',
        'genre': 'Science Fiction',
        'isbn': '9780141439976',
        'quantity': 3,
        'coverImageUrl': 'assets/images/the_invisible_man.png',
        'pdfAssetPath': 'assets/pdfs/the_invisible_man.pdf.bytes',
      },
      {
        'id': 'SF002',
        'title': 'Brain Twister',
        'author': 'Randall Garrett',
        'genre': 'Science Fiction',
        'isbn': '9781434407849',
        'quantity': 3,
        'coverImageUrl': 'assets/images/brain_twister.png',
        'pdfAssetPath': 'assets/pdfs/brain_twister.pdf.bytes',
      },
      {
        'id': 'SF003',
        'title': 'Overclocked',
        'author': 'Cory Doctorow',
        'genre': 'Science Fiction',
        'isbn': '9781568583457',
        'quantity': 3,
        'coverImageUrl': 'assets/images/overclocked.png',
        'pdfAssetPath': 'assets/pdfs/overclocked.pdf.bytes',
      },
      {
        'id': 'SF004',
        'title': 'The Dark World',
        'author': 'Henry Kuttner',
        'genre': 'Science Fiction',
        'isbn': '9781605436661',
        'quantity': 3,
        'coverImageUrl': 'assets/images/the_dark_world.png',
        'pdfAssetPath': 'assets/pdfs/the_dark_world.pdf.bytes',
      },
      {
        'id': 'FT001',
        'title': 'The King In Yellow',
        'author': 'Robert W. Chambers',
        'genre': 'Fantasy',
        'isbn': '9781406560762',
        'quantity': 3,
        'coverImageUrl': 'assets/images/the_king_in_yellow.png',
        'pdfAssetPath': 'assets/pdfs/the_king_in_yellow.pdf.bytes',
      },
      {
        'id': 'FT002',
        'title': 'The Man Who Was Thursday',
        'author': 'G. K. Chesterton',
        'genre': 'Fantasy',
        'isbn': '9781604595291',
        'quantity': 3,
        'coverImageUrl': 'assets/images/the_man_who_was_thursday.png',
        'pdfAssetPath': 'assets/pdfs/the_man_who_was_thursday.pdf.bytes',
      },
      {
        'id': 'FT003',
        'title': 'Dracula',
        'author': 'Bram Stoker',
        'genre': 'Fantasy',
        'isbn': '9780486411095',
        'quantity': 3,
        'coverImageUrl': 'assets/images/dracula.png',
        'pdfAssetPath': 'assets/pdfs/dracula.pdf.bytes',
      },
      {
        'id': 'FT004',
        'title': 'Alice In Wonderland',
        'author': 'Lewis Carroll',
        'genre': 'Fantasy',
        'isbn': '9781503222649',
        'quantity': 3,
        'coverImageUrl': 'assets/images/alice_in_wonderland.png',
        'pdfAssetPath': 'assets/pdfs/alice_in_wonderland.pdf.bytes',
      },
    ];

    for (var item in listToSeed) {
      final exists = _books.any((b) => b.title.toLowerCase() == item['title'].toString().toLowerCase() || b.id == item['id']);
      if (!exists) {
        final book = Book(
          id: item['id'].toString(),
          title: item['title'].toString(),
          author: item['author'].toString(),
          genre: item['genre'].toString(),
          isbn: item['isbn'].toString(),
          quantity: item['quantity'] as int,
          coverImageUrl: item['coverImageUrl'].toString(),
          pdfAssetPath: item['pdfAssetPath'].toString(),
          reservationQueue: [],
          issueCount: 0,
        );
        await _db.collection('books').doc(book.id).set(book.toFirestore());
      } else {
        // Auto-sync the pdfAssetPath for existing books to bypass IDM interception
        final dbBook = _books.firstWhere(
          (b) => b.id == item['id'] || b.title.toLowerCase() == item['title'].toString().toLowerCase(),
        );
        if (dbBook.pdfAssetPath != item['pdfAssetPath'].toString() || dbBook.coverImageUrl != item['coverImageUrl'].toString()) {
          await _db.collection('books').doc(dbBook.id).update({
            'pdfAssetPath': item['pdfAssetPath'].toString(),
            'coverImageUrl': item['coverImageUrl'].toString(),
          });
        }
      }
    }
  }
}
