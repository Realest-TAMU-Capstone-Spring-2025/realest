import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthService({
    required this.auth,
    required this.firestore,
  });

  // For role-based sign-in
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = userCredential.user!.uid;
      final userDoc = await firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        return 'Error: No user document found';
      }
      final role = userDoc['role'] as String?;
      if (role == null) {
        return 'Error: No role in user document';
      }
      return role; // "investor" or "realtor"
    } on FirebaseAuthException catch (e) {
      return e.code; // Return the FirebaseAuth error code (e.g., "user-not-found")
    }
  }

  // For registering new users
  Future<String?> createAccount({
    required String email,
    required String password,
    required String confirmPassword,
    required String role,
  }) async {
    if (password != confirmPassword) {
      return 'password-mismatch';
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
      return e.code;
    }
  }
}
