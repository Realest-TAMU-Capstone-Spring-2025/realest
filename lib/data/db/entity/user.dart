import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user profile stored in Firestore.
class User {
  /// Unique identifier for the user.
  final String id;

  /// User's email address.
  final String email;

  /// Timestamp of the user's last login.
  final DateTime lastLoginTime;

  /// Indicates if the user is a realtor.
  final bool isRealtor;

  /// Indicates if the user is new (e.g., hasn't completed setup).
  final bool isNewUser;

  /// Creates a [User] instance with required properties.
  User({
    required this.id,
    required this.email,
    required this.lastLoginTime,
    required this.isRealtor,
    required this.isNewUser,
  });

  /// Constructs a [User] from a Firestore document snapshot.
  /// Expects fields: email, lastLoginTime, isRealtor, isNewUser.
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      email: data['email'],
      lastLoginTime: (data['lastLoginTime'] as Timestamp).toDate(),
      isRealtor: data['isRealtor'],
      isNewUser: data['isNewUser'],
    );
  }
}