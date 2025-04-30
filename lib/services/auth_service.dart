import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A service to handle user authentication and role-based account setup using Firebase.
class AuthService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  /// Creates an instance of [AuthService] with required Firebase services.
  AuthService({
    required this.auth,
    required this.firestore,
  });

  /// Signs in a user with email and password.
  ///
  /// Returns the user's role (`"investor"` or `"realtor"`) if successful,
  /// or a Firebase error code string if login fails.
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = userCredential.user!.uid;
      final userDoc = await firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        return 'error-no-user-document';
      }

      final role = userDoc['role'] as String?;
      if (role == null) {
        return 'error-no-role-found';
      }

      return role;
    } on FirebaseAuthException catch (e) {
      return e.code; // e.g., 'user-not-found', 'wrong-password'
    }
  }

  /// Creates a new user account with email, password, and assigned role.
  ///
  /// Returns the role on success or an error code string if registration fails.
  Future<String?> createAccount({
    required String email,
    required String password,
    required String confirmPassword,
    required String role, // Should be either 'investor' or 'realtor'
  }) async {
    if (password != confirmPassword) {
      return 'error-password-mismatch';
    }

    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user!;

      await firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'completedSetup': false,
      });

      return role;
    } on FirebaseAuthException catch (e) {
      return e.code; // e.g., 'email-already-in-use', 'weak-password'
    }
  }
}
