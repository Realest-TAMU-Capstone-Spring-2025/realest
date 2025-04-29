import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user's swipe decision on a listing in Firestore.
class Swipe {
  /// Unique identifier for the swipe document.
  final String id;

  /// ID of the user who made the swipe.
  final String userId;

  /// ID of the listing being swiped on.
  final String listingId;

  /// Indicates if the listing was liked (true) or disliked (false).
  final bool isLiked;

  /// Creates a [Swipe] instance with required properties.
  Swipe({
    required this.id,
    required this.userId,
    required this.listingId,
    required this.isLiked,
  });

  /// Constructs a [Swipe] from a Firestore document snapshot.
  /// Expects fields: userId, listingId, isLiked.
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