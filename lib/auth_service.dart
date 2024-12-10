import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in (can be used on app startup)
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // Register a new user and save additional user info to Firestore
  Future<void> registerUser(String email, String password, String username, String state) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await userCredential.user?.sendEmailVerification();

      // Save additional user info in Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'username': username,
        'state': state,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(_handleAuthError(e)); // Pass `Object` to `_handleAuthError`
    }
  }

  // Login an existing user and check email verification
  Future<void> loginUser(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!userCredential.user!.emailVerified) {
        throw Exception('Email not verified. Please verify your email to log in.');
      }
    } catch (e) {
      throw Exception(_handleAuthError(e)); // Pass `Object` to `_handleAuthError`
    }
  }

  // Reset user password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception(_handleAuthError(e)); // Pass `Object` to `_handleAuthError`
    }
  }

  // Logout the current user
  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Handle FirebaseAuth errors (accept `Object` type)
  String _handleAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Email is already registered. Use another email or login.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'invalid-email':
          return 'Invalid email format.';
        case 'user-not-found':
          return 'No account found for this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        default:
          return 'An unknown error occurred.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
