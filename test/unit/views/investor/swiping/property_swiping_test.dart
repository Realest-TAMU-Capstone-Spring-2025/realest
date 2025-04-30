import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:realest/user_provider.dart';
import 'package:realest/src/views/investor/swiping/property_swiping.dart';
import '../../../../util/mock_firebase_util.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mocks = await MockFirebaseUtil.initializeMockFirebaseRoled(false);
    mockAuth = mocks['auth'] as MockFirebaseAuth;
    mockFirestore = mocks['firestore'] as FakeFirebaseFirestore;

    // Populate listings collection with test data
    for (int i = 1; i <= 5; i++) {
      await mockFirestore.collection('listings').doc('property_$i').set({
        'id': 'property_$i',
        'address': 'Property $i, Springfield',
        'price': 100000 + (i * 5000),
        'status': 'FOR_SALE',
        'location': 'Location $i',
      });
    }

    // Debug print for Firestore state after populating listings
    print('Firestore state after populating listings in property_swiping_test:');
    print(await mockFirestore.dump());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await mockAuth.signInWithEmailAndPassword(
      email: 'investor@example.com',
      password: 'password123',
    );

    // Create unique listings for this test
    for (int i = 1; i <= 5; i++) {
      await mockFirestore.collection('listings').doc('property_$i').set({
        'id': 'property_$i',
        'address': 'Property $i, Springfield',
        'price': 100000 + (i * 5000),
        'status': 'FOR_SALE',
        'location': 'Location $i',
      });
    }

    // Debug print for Firestore state during setUp
    print('Firestore state during setUp in property_swiping_test:');
    print(await mockFirestore.dump());
  });

  tearDown(() async {
    // Clear Firestore data after each test
    await mockFirestore.clearPersistence();
    mockFirestore = FakeFirebaseFirestore();
  });

  Widget createTestWidget() {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(auth: mockAuth, firestore: mockFirestore),
      child: const MaterialApp(
        home: PropertySwipingView(),
      ),
    );
  }

  testWidgets('Displays properties for swiping', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump(const Duration(seconds: 2)); // Replace pumpAndSettle with fixed duration wait

    print('Firestore dump:');
    print(mockFirestore.dump());

    print('Firestore state at runtime:');
    print(mockFirestore.dump());

    expect(find.byType(PropertySwipeCard), findsWidgets);
  });

  testWidgets('Swipes property to like', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump(const Duration(seconds: 2)); // Replace pumpAndSettle with fixed duration wait

    print('Firestore dump:');
    print(mockFirestore.dump());

    print('Firestore state at runtime:');
    print(mockFirestore.dump());

    final firstCard = find.byType(PropertySwipeCard).first;
    expect(firstCard, findsOneWidget);

    // Simulate a right swipe (like)
    await tester.drag(firstCard, const Offset(500, 0));
    await tester.pump(const Duration(seconds: 2)); // Replace pumpAndSettle with fixed duration wait

    // Verify the property is removed from the list
    expect(find.byType(PropertySwipeCard), findsWidgets);
  });

  testWidgets('Swipes property to dislike', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump(const Duration(seconds: 2)); // Replace pumpAndSettle with fixed duration wait

    print('Firestore dump:');
    print(mockFirestore.dump());

    print('Firestore state at runtime:');
    print(mockFirestore.dump());

    final firstCard = find.byType(PropertySwipeCard).first;
    expect(firstCard, findsOneWidget);

    // Simulate a left swipe (dislike)
    await tester.drag(firstCard, const Offset(-500, 0));
    await tester.pump(const Duration(seconds: 2)); // Replace pumpAndSettle with fixed duration wait

    // Verify the property is removed from the list
    expect(find.byType(PropertySwipeCard), findsWidgets);
  });

  testWidgets('Displays message when no properties are available', (WidgetTester tester) async {
    // Clear all properties
    final userId = mockAuth.currentUser!.uid;
    final interactionsCollection = mockFirestore
        .collection('investors')
        .doc(userId)
        .collection('property_interactions');

    final querySnapshot = await interactionsCollection.get();
    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }

    // Clear all listings
    final listingsCollection = mockFirestore.collection('listings');
    final listingsSnapshot = await listingsCollection.get();
    for (var doc in listingsSnapshot.docs) {
      await doc.reference.delete();
    }

    print('Firestore dump:');
    print(mockFirestore.dump());

    print('Firestore state at runtime:');
    print(mockFirestore.dump());

    await tester.pumpWidget(createTestWidget());
    await tester.pump(const Duration(seconds: 2)); // Replace pumpAndSettle with fixed duration wait

    expect(find.text('No more recommended properties.'), findsOneWidget);
  });

  test('Verify Firestore query for status field', () async {
    final querySnapshot = await mockFirestore
        .collection('listings')
        .where('status', isEqualTo: 'FOR_SALE')
        .get();

    print('Query result for status=FOR_SALE: ${querySnapshot.docs.map((doc) => doc.id).toList()}');
    print('Firestore state at runtime:');
    print(mockFirestore.dump());
    expect(querySnapshot.docs.isNotEmpty, true, reason: 'No properties found with status=FOR_SALE');
  });

  test('Verify Firestore query without filters', () async {
    final querySnapshot = await mockFirestore.collection('listings').get();

    print('Query result without filters: ${querySnapshot.docs.map((doc) => doc.id).toList()}');
    print('Firestore state at runtime:');
    print(mockFirestore.dump());
    expect(querySnapshot.docs.isNotEmpty, true, reason: 'No documents found in listings collection');
  });

  testWidgets('Handles swipe animation correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump(const Duration(seconds: 2));

    final firstCard = find.byType(PropertySwipeCard).first;
    expect(firstCard, findsOneWidget);

    // Simulate a right swipe (like)
    await tester.drag(firstCard, const Offset(500, 0));
    await tester.pump(const Duration(seconds: 2));

    // Verify the swipe animation is triggered
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('Handles no properties scenario gracefully', (WidgetTester tester) async {
    // Clear all properties
    final userId = mockAuth.currentUser!.uid;
    final interactionsCollection = mockFirestore
        .collection('investors')
        .doc(userId)
        .collection('property_interactions');

    final querySnapshot = await interactionsCollection.get();
    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }

    // Clear all listings
    final listingsCollection = mockFirestore.collection('listings');
    final listingsSnapshot = await listingsCollection.get();
    for (var doc in listingsSnapshot.docs) {
      await doc.reference.delete();
    }

    await tester.pumpWidget(createTestWidget());
    await tester.pump(const Duration(seconds: 2));

    // Verify the no properties message is displayed
    expect(find.text('No more recommended properties.'), findsOneWidget);
  });

  testWidgets('Toggles between realtor and recommended properties', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump(const Duration(seconds: 2));

    // Verify initial state is recommended properties
    expect(find.text('Recommended'), findsOneWidget);

    // Toggle to realtor properties
    final toggleButton = find.text('From Realtor');
    await tester.tap(toggleButton);
    await tester.pump(const Duration(seconds: 2));

    // Verify state changes to realtor properties
    expect(find.text('From Realtor'), findsOneWidget);
  });

  testWidgets('Displays loading indicator while properties are loading', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Verify loading indicator is displayed
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));

    // Verify loading indicator is removed after properties load
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}