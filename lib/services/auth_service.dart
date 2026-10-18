import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
    } else {
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        _currentUser = User.fromFirestore(doc.data()!, firebaseUser.uid);
      } else {
        _currentUser = null;
      }
    }
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String studentId,
    bool isAdmin = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = User(
        id: result.user!.uid,
        name: name,
        studentId: studentId,
        email: email,
        isAdmin: isAdmin,
      );

      await _db.collection('users').doc(user.id).set(user.toFirestore());
      _currentUser = user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Default Admin Credentials check
      if (email == 'admin@library.com' && password == 'Admin123') {
        try {
          await _auth.signInWithEmailAndPassword(email: email, password: password);
        } on auth.FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'invalid-email') {
            // Auto-create initial admin account
            final result = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );

            final user = User(
              id: result.user!.uid,
              name: 'Admin',
              studentId: 'ADMIN-001',
              email: email,
              isAdmin: true,
              isFirstLogin: true, // Mandatory setup on first login
            );

            await _db.collection('users').doc(user.id).set(user.toFirestore());
            _currentUser = user;
            return;
          }
          rethrow;
        }
      } else {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeAdminSetup(String newEmail, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user.');

      // Update email and password in Firebase Auth
      await user.verifyBeforeUpdateEmail(newEmail);
      await user.updatePassword(newPassword);

      // Update Firestore document
      final updatedUser = User(
        id: user.uid,
        name: _currentUser?.name ?? 'Admin',
        studentId: _currentUser?.studentId ?? 'ADMIN-001',
        email: newEmail,
        isAdmin: true,
        isFirstLogin: false,
      );

      await _db.collection('users').doc(user.uid).set(updatedUser.toFirestore());
      _currentUser = updatedUser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<dynamic> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final auth.AuthCredential credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      final firebaseUser = result.user;

      if (firebaseUser != null) {
        final doc = await _db.collection('users').doc(firebaseUser.uid).get();
        if (!doc.exists) {
          return firebaseUser; // Signal that registration is needed
        } else {
          final user = User.fromFirestore(doc.data()!, firebaseUser.uid);
          if (user.isAdmin) {
            await _auth.signOut();
            throw Exception('Admin accounts must use Email/Password login for security.');
          }
          _currentUser = user;
          return _currentUser; // Return the existing student user
        }
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> registerGoogleUser(auth.User firebaseUser, String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Google User',
        studentId: studentId,
        email: firebaseUser.email ?? '',
        isAdmin: false,
      );

      await _db.collection('users').doc(user.id).set(user.toFirestore());
      _currentUser = user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
