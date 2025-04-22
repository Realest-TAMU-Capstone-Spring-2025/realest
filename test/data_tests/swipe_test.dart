// test/swipe_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:realest/data/db/entity/swipe.dart'; // adjust to your actual path

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
  group('Swipe.fromFirestore', () {
    test('☀️ Sunny day: parses all fields correctly', () {
      // arrange: doc has every expected key & correct types
      final doc = FakeDocumentSnapshot('swipe123', {
        'userId':    'user_1',
        'listingId': 'listing_1',
        'isLiked':   true,
      });

      // act
      final swipe = Swipe.fromFirestore(doc);

      // assert
      expect(swipe.id,        equals('swipe123'));
      expect(swipe.userId,    equals('user_1'));
      expect(swipe.listingId, equals('listing_1'));
      expect(swipe.isLiked,   isTrue);
    });

    test('🌧️ Rainy day: missing required field throws', () {
      // arrange: omit the 'listingId' key
      final doc = FakeDocumentSnapshot('badSwipe', {
        'userId':  'user_1',
        // 'listingId' missing
        'isLiked': false,
      });

      // act / assert: data['listingId'] → null on non-nullable String → TypeError
      expect(
        () => Swipe.fromFirestore(doc),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
