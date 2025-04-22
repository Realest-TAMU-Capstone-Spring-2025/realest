// File: test/mocks/services_tests/auth_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:realest/services/auth_service.dart'; // ← adjust to your path

// ─── Mock classes ─────────────────────────────────────────────────────────────

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUserCredential extends Mock implements UserCredential {}
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
  // Register fallback values for any<T>()
  setUpAll(() {
    registerFallbackValue('');               // for any<String>()
    registerFallbackValue(<String, dynamic>{}); // for any<Map<String, dynamic>>()
  });

  late MockFirebaseAuth      mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late AuthService           authService;

  setUp(() {
    mockAuth      = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    authService   = AuthService(auth: mockAuth, firestore: mockFirestore);
  });

  group('signInWithEmail', () {
    const testEmail    = 'foo@bar.com';
    const testPassword = 'hunter2';
    const uid          = 'uid123';
    const userRole     = 'investor';

    late MockUserCredential     mockUserCred;
    late MockUser               mockUser;
    late MockCollectionReference usersCol;
    late MockDocumentReference   userDoc;
    late MockDocumentSnapshot    docSnap;

    setUp(() {
      mockUserCred = MockUserCredential();
      mockUser     = MockUser();
      usersCol     = MockCollectionReference();
      userDoc      = MockDocumentReference();
      docSnap      = MockDocumentSnapshot();

      // Stub the FirebaseAuth call
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockUserCred);

      when(() => mockUserCred.user).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(uid);

      // Stub Firestore collection/doc
      when(() => mockFirestore.collection('users')).thenReturn(usersCol);
      when(() => usersCol.doc(uid)).thenReturn(userDoc);
    });

    test('☀️ returns the user’s role when document exists', () async {
      // Stub getting the snapshot
      when(() => userDoc.get()).thenAnswer((_) async => docSnap);
      when(() => docSnap.exists).thenReturn(true);

      // **Stub the operator []**, since AuthService does userDoc['role']
      when(() => docSnap['role']).thenReturn(userRole);

      final result = await authService.signInWithEmail(testEmail, testPassword);
      expect(result, userRole);

      verify(() => mockAuth.signInWithEmailAndPassword(
            email: testEmail.trim(),
            password: testPassword.trim(),
          )).called(1);
      verify(() => userDoc.get()).called(1);
    });

    test('🌧 returns an error when the user document does not exist', () async {
      when(() => userDoc.get()).thenAnswer((_) async => docSnap);
      when(() => docSnap.exists).thenReturn(false);

      final result = await authService.signInWithEmail(testEmail, testPassword);
      expect(result, 'Error: No user document found');
    });
  });

  group('createAccount', () {
    const newEmail    = 'new@user.com';
    const newPassword = 'pass123';
    const newConfirm  = 'pass123';
    const newRole     = 'realtor';
    const newUid      = 'newUid';

    late MockUserCredential     mockUserCred;
    late MockUser               mockUser;
    late MockCollectionReference usersCol;
    late MockDocumentReference   userDoc;

    setUp(() {
      mockUserCred = MockUserCredential();
      mockUser     = MockUser();
      usersCol     = MockCollectionReference();
      userDoc      = MockDocumentReference();

      // Stub the createUser call
      when(() => mockAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockUserCred);

      when(() => mockUserCred.user).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(newUid);
      when(() => mockUser.email).thenReturn(newEmail);

      // Stub Firestore write
      when(() => mockFirestore.collection('users')).thenReturn(usersCol);
      when(() => usersCol.doc(newUid)).thenReturn(userDoc);
      when(() => userDoc.set(any())).thenAnswer((_) async {});
    });

    test('☀️ successfully creates an account and returns the role', () async {
      final result = await authService.createAccount(
        email:           newEmail,
        password:        newPassword,
        confirmPassword: newConfirm,
        role:            newRole,
      );
      expect(result, newRole);

      verify(() => mockAuth.createUserWithEmailAndPassword(
            email: newEmail.trim(),
            password: newPassword.trim(),
          )).called(1);

      // Capture the Map passed to .set(...)
      final captured = verify(() => userDoc.set(captureAny())).captured;
      expect(captured, hasLength(1));

      final data = captured.first as Map<String, dynamic>;
      expect(data['email'], newEmail);
      expect(data['role'], newRole);
      expect(data['completedSetup'], false);
      expect(data.containsKey('createdAt'), isTrue);
    });

    test('🌧 returns password-mismatch when passwords differ', () async {
      final result = await authService.createAccount(
        email:           newEmail,
        password:        'one',
        confirmPassword: 'two',
        role:            newRole,
      );
      expect(result, 'password-mismatch');

      // Should never call FirebaseAuth if passwords don’t match
      verifyNever(() => mockAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });
  });
}
