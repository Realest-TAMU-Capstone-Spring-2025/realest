// test/listing_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:realest/data/db/entity/listing.dart';

/// Minimal fake for [DocumentSnapshot] so we can control `id` and `data()`.
class FakeDocumentSnapshot extends Fake implements DocumentSnapshot {
  @override
  final String id;
  final Map<String, dynamic>? _rawData;

  FakeDocumentSnapshot(this.id, this._rawData);

  @override
  dynamic data() => _rawData;
}

void main() {
  group('Listing.fromFirestore', () {
    test('☀️ Sunny day: parses all fields correctly', () {
      // arrange: create a doc with every expected key & correct types
      final doc = FakeDocumentSnapshot('listing123', {
        'title':       'Charming Bungalow',
        'description': 'A cozy 2‑bedroom home.',
        'imageUrl':    'https://example.com/house.jpg',
        'price':       250000.0,
        'address':     '123 Main St, Anytown',
        'realtorId':   'agent007',
        'isFavorite':  true,
      });

      // act
      final listing = Listing.fromFirestore(doc);

      // assert
      expect(listing.id,         equals('listing123'));
      expect(listing.title,      equals('Charming Bungalow'));
      expect(listing.description,equals('A cozy 2‑bedroom home.'));
      expect(listing.imageUrl,   equals('https://example.com/house.jpg'));
      expect(listing.price,      equals(250000.0));
      expect(listing.address,    equals('123 Main St, Anytown'));
      expect(listing.realtorId,  equals('agent007'));
      expect(listing.isFavorite, equals(true));
    });

    test('🌧️ Rainy day: missing required field throws', () {
      // arrange: omit the 'title' key (or any other required key)
      final doc = FakeDocumentSnapshot('badListing', {
        // 'title' key is missing
        'description': 'No title here',
        'imageUrl':    'https://example.com/house.jpg',
        'price':       100000.0,
        'address':     'Unknown',
        'realtorId':   'agent007',
        'isFavorite':  false,
      });

      // act / assert: casting or null lookup should fail at runtime
      expect(
        () => Listing.fromFirestore(doc),
        throwsA(isA<TypeError>()), // a cast or null‑dependent lookup will throw
      );
    });
  });
}
