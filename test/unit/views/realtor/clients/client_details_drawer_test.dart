import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:realest/src/views/realtor/clients/client_details_drawer.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;
  late String uniqueClientUid;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mocks = await MockFirebaseUtil.initializeMockFirebaseRoled(true);
    mockAuth = mocks['auth'] as MockFirebaseAuth;
    mockFirestore = mocks['firestore'] as FakeFirebaseFirestore;

    // Debug print for Firestore state after initialization
    print('Firestore state after initializeMockFirebase in client_details_drawer_test:');
    print(await mockFirestore.dump());

    // Debug print for Firestore state after initialization
    print('Firestore state after initializeMockFirebaseRoled in client_details_drawer_test:');
    print(await mockFirestore.dump());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await mockAuth.signInWithEmailAndPassword(
      email: 'realtor@example.com',
      password: 'password123',
    );

    // Create a unique client for this test
    final clientDoc = await mockFirestore.collection('investors').add({
      'firstName': 'Test',
      'lastName': 'Client',
      'contactPhone': '123-456-7890',
      'contactEmail': 'testclient@example.com',
      'profilePicUrl': 'assets/images/profile.png',
      'notes': 'Test client notes.',
      'realtorId': 'realtor-uid-123',
      'status': 'client',
      'createdAt': FieldValue.serverTimestamp(),
    });
    uniqueClientUid = clientDoc.id;

    // Debug print for Firestore state during setUp
    print('Firestore state during setUp in client_details_drawer_test:');
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
      child: MaterialApp(
        home: ClientDetailsDrawer(
          clientUid: uniqueClientUid, // Use unique client UID
          onClose: () {},
        ),
      ),
    );
  }

  testWidgets('Deletes client successfully', (WidgetTester tester) async {
    bool onDeleteCalled = false;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => UserProvider(auth: mockAuth, firestore: mockFirestore),
        child: MaterialApp(
          home: ClientDetailsDrawer(
            clientUid: uniqueClientUid,
            onClose: () {},
            onDelete: (uid, name) {
              onDeleteCalled = true;
              expect(uid, uniqueClientUid);
              expect(name, 'Jane Smith');
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete user'));
    await tester.pumpAndSettle();

    // Verify onDelete callback is called
    expect(onDeleteCalled, isTrue);
  });

  testWidgets('Edits notes successfully', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Open the popup menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Open the edit notes dialog
    await tester.tap(find.text('Edit Notes'));
    await tester.pumpAndSettle();

    // Enter new notes
    final notesField = find.byType(TextField);
    await tester.enterText(notesField, 'Updated notes');

    // Save the notes
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify notes are updated
    final updatedDoc = await mockFirestore
        .collection('investors')
        .doc(uniqueClientUid)
        .get();
    expect(updatedDoc['notes'], 'Updated notes');
  });

  testWidgets('Loads client data successfully', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Verify loading indicator is shown initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the widget to load data
    await tester.pumpAndSettle();

    // Verify client data is displayed
    expect(find.text('Jane Smith'), findsOneWidget);
    expect(find.text('client'.toUpperCase()), findsOneWidget);
    expect(find.text('987-654-3210'), findsOneWidget);
    expect(find.text('investor@example.com'), findsOneWidget);
  });

  testWidgets('Handles error during data loading', (WidgetTester tester) async {
    // Simulate an error by clearing mock Firestore data
    mockFirestore = FakeFirebaseFirestore();

    await tester.pumpWidget(createTestWidget());

    // Wait for the widget to load data
    await tester.pumpAndSettle();

    // Verify error message is displayed
    expect(find.textContaining('Error'), findsOneWidget);
  });
}