import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final DateTime lastLoginTime;
  final bool isRealtor;
  final bool isNewUser;

  User({
    required this.id,
    required this.email,
    required this.lastLoginTime,
    required this.isRealtor,
    required this.isNewUser,
  });

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