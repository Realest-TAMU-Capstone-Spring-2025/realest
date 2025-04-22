// test/user_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:realest/data/db/entity/user.dart';

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
  group('User.fromFirestore', () {
    test('☀️ Sunny day: parses all fields correctly', () {
      // arrange: doc has every expected key & correct types
      final timestamp = Timestamp.fromDate(
        DateTime(2025, 1, 1, 12, 0, 0),
      );
      final doc = FakeDocumentSnapshot('user123', {
        'email':         'test@example.com',
        'lastLoginTime': timestamp,
        'isRealtor':     true,
        'isNewUser':     false,
      });

      // act
      final user = User.fromFirestore(doc);

      // assert
      expect(user.id,            equals('user123'));
      expect(user.email,         equals('test@example.com'));
      expect(user.lastLoginTime, equals(timestamp.toDate()));
      expect(user.isRealtor,     isTrue);
      expect(user.isNewUser,     isFalse);
    });

    test('🌧️ Rainy day: missing required field throws', () {
      // arrange: omit the 'email' key
      final timestamp = Timestamp.fromDate(DateTime.now());
      final doc = FakeDocumentSnapshot('badUser', {
        // 'email' missing
        'lastLoginTime': timestamp,
        'isRealtor':     false,
        'isNewUser':     true,
      });

      // act / assert: data['email'] → null on non‑nullable String → TypeError
      expect(
        () => User.fromFirestore(doc),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
