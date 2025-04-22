// test/settings_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:realest/data/db/entity/settings.dart'; // adjust the import to your actual file

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
  group('Settings.fromFirestore', () {
    test('☀️ Sunny day: parses all fields correctly', () {
      // arrange: doc has every key with correct types
      final doc = FakeDocumentSnapshot('settings123', {
        'userId':                  'user_abc',
        'isDarkMode':              true,
        'isNotificationsEnabled':  false,
        'isLocationEnabled':       true,
      });

      // act
      final settings = Settings.fromFirestore(doc);

      // assert
      expect(settings.id,                     equals('settings123'));
      expect(settings.userId,                 equals('user_abc'));
      expect(settings.isDarkMode,             isTrue);
      expect(settings.isNotificationsEnabled, isFalse);
      expect(settings.isLocationEnabled,      isTrue);
    });

    test('🌧️ Rainy day: missing required field throws', () {
      // arrange: omit the 'userId' key
      final doc = FakeDocumentSnapshot('badSettings', {
        // 'userId' is missing
        'isDarkMode':             false,
        'isNotificationsEnabled': true,
        'isLocationEnabled':      false,
      });

      // act / assert: accessing data['userId'] → null non-nullable String → TypeError
      expect(
        () => Settings.fromFirestore(doc),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
