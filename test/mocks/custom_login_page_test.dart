import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import the generated mock file (assuming you have run build_runner)
import 'firebase_mocks.mocks.dart';
// Import your AuthService
import 'package:realest/services/auth_service.dart';

void main() {
  group('CustomLoginPage Auth Service Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockFirebaseFirestore mockFirestore;
    late AuthService authService;

    // Optional: We might need these further
    late MockUserCredential mockUserCredential;
    late MockUser mockUser;
    late MockDocumentSnapshot<Map<String, dynamic>> mockDocSnapshot;
    late MockCollectionReference<Map<String, dynamic>> mockCollection;
    late MockDocumentReference<Map<String, dynamic>> mockDocRef;

    setUp(() {
      // Instantiate mocks
      mockAuth = MockFirebaseAuth();
      mockFirestore = MockFirebaseFirestore();

      mockUserCredential = MockUserCredential();
      mockUser = MockUser();
      mockDocSnapshot = MockDocumentSnapshot<Map<String, dynamic>>();
      mockCollection = MockCollectionReference<Map<String, dynamic>>();
      mockDocRef = MockDocumentReference<Map<String, dynamic>>();

      // Create the service with mocked dependencies
      authService = AuthService(
        auth: mockAuth,
        firestore: mockFirestore,
      );
    });

    test('signInWithEmail returns "investor" when user role is investor', () async {
      // ARRANGE
      // 1) Mock signIn result
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      // 2) Mock user object
      when(mockUser.uid).thenReturn('testUID');
      when(mockUserCredential.user).thenReturn(mockUser);

      // 3) Mock Firestore calls
      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc('testUID')).thenReturn(mockDocRef);
      when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);

      // 4) Mock that the doc exists and has 'role' = 'investor'
      when(mockDocSnapshot.exists).thenReturn(true);
      when(mockDocSnapshot['role']).thenReturn('investor');

      // ACT
      final role = await authService.signInWithEmail('test@example.com', 'password123');

      // ASSERT
      expect(role, equals('investor'));
      verify(mockAuth.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'password123',
      )).called(1);
    });

    test('signInWithEmail returns error code when signIn fails', () async {
      // ARRANGE
      when(mockAuth.signInWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenThrow(
        FirebaseAuthException(code: 'user-not-found'),
      );

      // ACT
      final result = await authService.signInWithEmail('missing@user.com', 'wrongpass');

      // ASSERT
      expect(result, equals('user-not-found'));
    });

    test('createAccount returns "password-mismatch" if passwords differ', () async {
      // ARRANGE: no mocks needed for this scenario

      // ACT
      final result = await authService.createAccount(
        email: 'abc@example.com',
        password: 'test123',
        confirmPassword: 'test456',
        role: 'investor',
      );

      // ASSERT
      expect(result, equals('password-mismatch'));
      verifyNever(mockAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ));
    });

    test('createAccount sets Firestore doc for new user', () async {
      // ARRANGE
      when(mockAuth.createUserWithEmailAndPassword(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => mockUserCredential);

      when(mockUser.uid).thenReturn('newUID');
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.email).thenReturn('test@example.com');

      // Mock Firestore doc set
      when(mockFirestore.collection('users')).thenReturn(mockCollection);
      when(mockCollection.doc('newUID')).thenReturn(mockDocRef);
      when(mockDocRef.set(any)).thenAnswer((_) async {});

      // ACT
      final result = await authService.createAccount(
        email: 'myuser@example.com',
        password: 'test123',
        confirmPassword: 'test123',
        role: 'realtor',
      );

      // ASSERT
      expect(result, equals('realtor'));
      verify(mockAuth.createUserWithEmailAndPassword(
        email: 'myuser@example.com',
        password: 'test123',
      )).called(1);
      verify(mockDocRef.set(argThat(
        containsPair('role', 'realtor'),
      ))).called(1);
    });
  });
}
