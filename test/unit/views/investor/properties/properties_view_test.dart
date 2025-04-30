import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:realest/user_provider.dart';
import '../../../../util/mock_firebase_util.dart';
import 'package:realest/src/views/investor/properties/properties_view.dart';
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
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await mockAuth.signInWithEmailAndPassword(
      email: 'investor@example.com',
      password: 'password123',
    );
  });

  Widget createTestWidget(String propertyId) {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(auth: mockAuth, firestore: mockFirestore),
      child: MaterialApp(
        home: PropertiesView(propertyId: propertyId),
      ),
    );
  }

  testWidgets('Displays property details correctly', (WidgetTester tester) async {
    final propertyId = 'property_7'; // Property not liked or disliked

    await tester.pumpWidget(createTestWidget(propertyId));
    await tester.pumpAndSettle();

    expect(find.text('Property Details'), findsOneWidget);
    expect(find.text('Street 7'), findsOneWidget);
    expect(find.text('City 7'), findsOneWidget);
    expect(find.text('State 7'), findsOneWidget);
    expect(find.text('Neighborhood 7'), findsOneWidget);
  });

  testWidgets('Toggles save status for a property', (WidgetTester tester) async {
    final propertyId = 'property_8'; // Property not liked or disliked

    await tester.pumpWidget(createTestWidget(propertyId));
    await tester.pumpAndSettle();

    final saveButtonFinder = find.byIcon(Icons.favorite_border);
    expect(saveButtonFinder, findsOneWidget);

    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('Displays message when property is not found', (WidgetTester tester) async {
    final propertyId = 'non_existent_property';

    await tester.pumpWidget(createTestWidget(propertyId));
    await tester.pumpAndSettle();

    expect(find.text('Property not found.'), findsOneWidget);
  });
}