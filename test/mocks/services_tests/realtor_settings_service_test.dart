// File: test/services/realtor_settings_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:realest/services/realtor_settings_service.dart'; // adjust to your path

// ─── Mock classes ─────────────────────────────────────────────────────────────

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUser extends Mock implements User {}
class MockCollectionReference
    extends Mock
    implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference
    extends Mock
    implements DocumentReference<Map<String, dynamic>> {}
class MockDocumentSnapshot
    extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  // Provide fallback values for any<Map<String,dynamic>>() and any<String>()
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue('');
  });

  late MockFirebaseAuth      mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late RealtorSettingsService service;
  late MockUser              mockUser;
  late MockCollectionReference usersCol;
  late MockDocumentReference   userDoc;
  late MockDocumentSnapshot    docSnap;

  setUp(() {
    mockAuth      = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    service       = RealtorSettingsService(auth: mockAuth, firestore: mockFirestore);

    mockUser   = MockUser();
    usersCol   = MockCollectionReference();
    userDoc    = MockDocumentReference();
    docSnap    = MockDocumentSnapshot();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.uid).thenReturn('uid123');
    when(() => mockFirestore.collection('realtors')).thenReturn(usersCol);
    when(() => usersCol.doc('uid123')).thenReturn(userDoc);
  });

  group('loadRealtorData', () {
    test('☀️ returns data map when document exists', () async {
      // arrange: snapshot exists with data
      when(() => userDoc.get()).thenAnswer((_) async => docSnap);
      when(() => docSnap.exists).thenReturn(true);
      when(() => docSnap.data()).thenReturn({
        'firstName': 'Jane',
        'lastName': 'Doe',
        'agencyName': 'Acme Realty',
      });

      // act
      final result = await service.loadRealtorData();

      // assert
      expect(result, {
        'firstName': 'Jane',
        'lastName': 'Doe',
        'agencyName': 'Acme Realty',
      });
      verify(() => userDoc.get()).called(1);
    });

    test('🌧 throws when user not signed in', () {
      // arrange
      when(() => mockAuth.currentUser).thenReturn(null);

      // act / assert
      expect(
        () => service.loadRealtorData(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('User not signed in'))),
      );
    });
  });

  group('updateRealtorData', () {
    final input = {
      'firstName': 'John',
      'lastName': 'Smith',
      'agencyName': 'Best Homes',
      'licenseNumber': 'LIC123',
      'contactEmail': 'john@homes.com',
      'contactPhone': '555-1234',
      'address': '123 Main St',
    };

    test('☀️ updates Firestore with provided fields', () async {
      // arrange: allow update to complete
      when(() => userDoc.update(any())).thenAnswer((_) async {});

      // act
      await service.updateRealtorData(input);

      // assert: verify update called with correct merged map
      verify(() => userDoc.update({
        'firstName': 'John',
        'lastName': 'Smith',
        'agencyName': 'Best Homes',
        'licenseNumber': 'LIC123',
        'contactEmail': 'john@homes.com',
        'contactPhone': '555-1234',
        'address': '123 Main St',
      })).called(1);
    });

    test('🌧 throws when user not signed in', () {
      // arrange
      when(() => mockAuth.currentUser).thenReturn(null);

      // act / assert
      expect(
        () => service.updateRealtorData(input),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('User not signed in'))),
      );
    });
  });
}
