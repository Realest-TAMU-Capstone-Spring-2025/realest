import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Import the generated mocks
import 'firebase_mocks.mocks.dart';

// Import the service
import 'package:realest/services/realtor_settings_service.dart';

void main() {
  group('RealtorSettingsService Tests', () {
    late RealtorSettingsService service;
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late MockUser mockUser;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnap;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();
      mockUser = MockUser();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>();
      mockDocSnap = MockDocumentSnapshot<Map<String, dynamic>>();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();

      // Instantiate service with these mocks
      service = RealtorSettingsService(
        auth: mockAuth,
        firestore: mockFirestore,
      );
    });

    group('loadRealtorData', () {
      test('Throws exception if user is not signed in', () async {
        // ARRANGE
        when(mockAuth.currentUser).thenReturn(null);

        // ACT & ASSERT
        expect(() => service.loadRealtorData(), throwsA(isA<Exception>()));
      });

      test('Returns empty Map if the doc does not exist', () async {
        // ARRANGE
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('testUID');

        when(mockFirestore.collection('realtors')).thenReturn(mockCollection);
        when(mockCollection.doc('testUID')).thenReturn(mockDocRef);

        // doc.get() => mockDocSnap
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        // doc.exists => false
        when(mockDocSnap.exists).thenReturn(false);

        // ACT
        final result = await service.loadRealtorData();

        // ASSERT
        expect(result, isEmpty);
      });

      test('Returns data if document exists', () async {
        // ARRANGE
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('testUID');

        when(mockFirestore.collection('realtors')).thenReturn(mockCollection);
        when(mockCollection.doc('testUID')).thenReturn(mockDocRef);

        // doc.get() => mockDocSnap
        when(mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
        when(mockDocSnap.exists).thenReturn(true);

        // Return a map from doc.data()
        final dataMap = {
          'firstName': 'Arjun',
          'lastName': 'Doe',
          // ...whatever fields
        };
        when(mockDocSnap.data()).thenReturn(dataMap);

        // ACT
        final result = await service.loadRealtorData();

        // ASSERT
        expect(result, equals(dataMap));
      });
    });

    group('updateRealtorData', () {
      test('Throws exception if user is not signed in', () async {
        // ARRANGE
        when(mockAuth.currentUser).thenReturn(null);

        // ACT & ASSERT
        expect(() => service.updateRealtorData({}), throwsA(isA<Exception>()));
      });

      test('Successfully updates Firestore', () async {
        // ARRANGE
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('testUID');

        when(mockFirestore.collection('realtors')).thenReturn(mockCollection);
        when(mockCollection.doc('testUID')).thenReturn(mockDocRef);

        // We want to ensure docRef.update(...) is called
        when(mockDocRef.update(any)).thenAnswer((_) async {});

        final updateMap = {
          'firstName': 'Arjun',
          'lastName': 'Doe',
          // etc...
        };

        // ACT
        await service.updateRealtorData(updateMap);

        // ASSERT
        verify(mockDocRef.update(argThat(containsPair('firstName', 'Arjun'))))
            .called(1);
      });

      test('Throws on Firestore error', () async {
        // ARRANGE
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.uid).thenReturn('testUID');

        when(mockFirestore.collection('realtors')).thenReturn(mockCollection);
        when(mockCollection.doc('testUID')).thenReturn(mockDocRef);

        // Simulate an exception when calling update()
        when(mockDocRef.update(any)).thenThrow(Exception('Firestore update failed'));

        // ACT & ASSERT
        expect(
              () => service.updateRealtorData({'firstName': 'Jane'}),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
