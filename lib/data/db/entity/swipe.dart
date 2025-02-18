import 'package:cloud_firestore/cloud_firestore.dart';

//stores swipe decisions
class Swipe {
  final String id;
  final String userId;
  final String listingId;
  final bool isLiked; //false means disliked

  Swipe({
    required this.id,
    required this.userId,
    required this.listingId,
    required this.isLiked,
  });

  factory Swipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Swipe(
      id: doc.id,
      userId: data['userId'],
      listingId: data['listingId'],
      isLiked: data['isLiked'],
    );
  }
}