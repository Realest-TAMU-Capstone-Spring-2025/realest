// firestore listing entity
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Represents a real estate listing stored in Firestore.
/// Subject to change as requirements evolve.
class Listing {
  /// Unique identifier for the listing.
  final String id;

  /// Title of the listing.
  final String title;

  /// Detailed description of the listing.
  final String description;

  /// URL of the listing's primary image.
  final String imageUrl;

  /// Price of the property.
  final double price;

  /// Address of the property.
  final String address;

  /// ID of the realtor managing the listing.
  final String realtorId;

  /// Indicates if the listing is marked as a favorite.
  final bool isFavorite;

  /// Creates a [Listing] instance with required properties.
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

  /// Constructs a [Listing] from a Firestore document snapshot.
  /// Expects fields: title, description, imageUrl, price, address, realtorId, isFavorite.
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