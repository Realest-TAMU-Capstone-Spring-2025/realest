import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:realest/user_provider.dart';
import 'package:realest/src/views/investor/properties/disliked_properties.dart';
import '../../../../util/mock_firebase_util.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realest/src/views/realtor/widgets/property_card/property_card.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_sheet.dart';
import 'package:realest/src/views/investor/properties/properties_view.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mocks = await MockFirebaseUtil.initializeMockFirebaseRoled(false);
    mockAuth = mocks['auth'] as MockFirebaseAuth;
    mockFirestore = mocks['firestore'] as FakeFirebaseFirestore;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await mockAuth.signInWithEmailAndPassword(
      email: 'investor@example.com',
      password: 'password123',
    );

    // Ensure the Firestore document for property_4 exists
    final propertyId = 'property_4';
    await mockFirestore
        .collection('investors')
        .doc(mockAuth.currentUser!.uid)
        .collection('property_interactions')
        .doc(propertyId)
        .set({'propertyId': propertyId, 'status': 'disliked'});

    // Ensure the Firestore document for the realtor interaction exists
    final realtorId = 'realtor-uid-123';
    final interactionDocId = 'property_4_${mockAuth.currentUser!.uid}';
    await mockFirestore
        .collection('realtors')
        .doc(realtorId)
        .collection('interactions')
        .doc(interactionDocId)
        .set({'status': 'disliked'});
  });

  Widget createTestWidget() {

    return ChangeNotifierProvider(
      create: (_) => UserProvider(auth: mockAuth, firestore: mockFirestore),
      child: MaterialApp(
        home: DislikedProperties(),
      ),
    );
  }

  testWidgets('Displays disliked properties, details', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Street 4'), findsOneWidget);
    expect(find.text('Street 5'), findsOneWidget);
    String propertyId = 'property_4';

    // Simulate user action to move property to liked
    final propertyCardFinder = find.byWidgetPredicate(
      (widget) => widget is PropertyCard && widget.property['id'] == propertyId,
    );

    await tester.tap(propertyCardFinder);
    await tester.pumpAndSettle();
    //tap "Move to Liked" button
    final moveToLikedButtonFinder = find.text('See Details');
    await tester.tap(moveToLikedButtonFinder);
    await tester.pumpAndSettle();
  });

  testWidgets('Displays message when user ID is null', (WidgetTester tester) async {
    mockAuth.signOut();
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('User not logged in'), findsOneWidget);
  });

  testWidgets('Moves property to liked when action is triggered', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    String propertyId = 'property_4';

    // Simulate user action to move property to liked
    final propertyCardFinder = find.byWidgetPredicate(
      (widget) => widget is PropertyCard && widget.property['id'] == propertyId,
    );

    await tester.tap(propertyCardFinder);
    await tester.pumpAndSettle();
    //tap "Move to Liked" button
    final moveToLikedButtonFinder = find.text('Move to Liked');
    await tester.tap(moveToLikedButtonFinder);
    await tester.pumpAndSettle();


    expect(
      (await mockFirestore
              .collection('investors')
              .doc(mockAuth.currentUser!.uid)
              .collection('property_interactions')
              .doc(propertyId)
              .get())
          .data()!['status'],
      'liked',
    );
  });

  testWidgets('Displays message when no disliked properties exist', (WidgetTester tester) async {
    // Clear any existing disliked properties
    final userId = mockAuth.currentUser!.uid;
    final interactionsCollection = mockFirestore
        .collection('investors')
        .doc(userId)
        .collection('property_interactions');

    final querySnapshot = await interactionsCollection.get();
    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('No disliked properties.'), findsOneWidget);
  });

}