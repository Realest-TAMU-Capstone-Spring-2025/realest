//firestore listing entity
import 'package:cloud_firestore/cloud_firestore.dart';


//subject to change
class Listing {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final double price;
  final String address;
  final String realtorId;
  final bool isFavorite;

  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.address,
    required this.realtorId,
    required this.isFavorite,
  });

  factory Listing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Listing(
      id: doc.id,
      title: data['title'],
      description: data['description'],
      imageUrl: data['imageUrl'],
      price: data['price'],
      address: data['address'],
      realtorId: data['realtorId'],
      isFavorite: data['isFavorite'],
    );
  }
}