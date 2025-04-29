import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:realest/user_provider.dart';
import 'package:realest/src/views/profile_pic.dart';
import 'package:realest/user_provider.dart';
import '../../../util/mock_firebase_util.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realest/src/views/investor/investor_settings.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

// Mock implementation for ImagePicker
class MockImagePicker {
  static XFile? _mockImage;

  static void setMockImage(Uint8List imageBytes) {
    _mockImage = XFile.fromData(imageBytes, name: 'mock_image.jpg');
  }

  static Future<XFile?> pickImage({required ImageSource source}) async {
    return _mockImage;
  }
}

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mocks = await MockFirebaseUtil.initializeMockFirebase();
    mockAuth = mocks['auth'] as MockFirebaseAuth;
    mockFirestore = mocks['firestore'] as FakeFirebaseFirestore;
  });

  setUp(() {
    mockAuth.signOut();
    SharedPreferences.setMockInitialValues({});
    mockAuth.signInWithEmailAndPassword(
      email: 'investor@example.com',
      password: 'password123',
    );
  });

  Future<void> _buildInvestorSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => UserProvider(auth: mockAuth, firestore: mockFirestore),
          child: InvestorSettings(
            toggleTheme: () {},
            isDarkMode: false,
          ),
        ),
      ),
    );
  }

  testWidgets('InvestorSettings loads user data correctly', (WidgetTester tester) async {
    // Mock Firestore data
    await _buildInvestorSettings(tester);
    await tester.pumpAndSettle();

    expect(find.text('Jane'), findsOneWidget); //pulls from mock util sufficient for unit test, see coverage
  });

  testWidgets('InvestorSettings picker', (WidgetTester tester) async {
    await _buildInvestorSettings(tester);
    await tester.pumpAndSettle();
    // Mock ImagePicker
    final Uint8List mockImageBytes = Uint8List.fromList([0, 1, 2, 3]);
    MockImagePicker.setMockImage(mockImageBytes);

    // Tap on the profile picture to pick a new image
    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();
  });

  testWidgets('InvestorSettings saves updated data', (WidgetTester tester) async {
    await _buildInvestorSettings(tester);
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 1));

    // Find all TextField widgets
    final textFields = find.byType(TextField);
    // Ensure there are at least two TextField widgets
    expect(textFields, findsAtLeastNWidgets(2));

    // Update the first two TextField widgets
    await tester.enterText(textFields.at(0), 'John');
    await tester.enterText(textFields.at(1), 'Doe');
    await tester.pumpAndSettle();

    final saveButton = find.text('Save Changes');
    await tester.ensureVisible(saveButton);

    // Save changes
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Verify that the updated data is saved to Firestore
    final userDoc = await mockFirestore.collection('investors').doc(mockAuth.currentUser!.uid).get();
    expect(userDoc.data()!['firstName'], 'John');
    expect(userDoc.data()!['lastName'], 'Doe');
  });

  testWidgets('Save Investor Defaults', (WidgetTester tester) async {
    await _buildInvestorSettings(tester);
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 1));

    final defaults = find.text('Investment Defaults');
    await tester.ensureVisible(defaults);
    await tester.tap(defaults);
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    expect(textFields, findsAtLeastNWidgets(8));

    await tester.enterText(textFields.at(6), '20');

    // Save changes
    final saveDefaultsButton = find.text('Save Defaults');
    await tester.ensureVisible(saveDefaultsButton);
    await tester.tap(saveDefaultsButton);
    await tester.pumpAndSettle();

    // Verify Firestore is updated
    final updatedDoc = await mockFirestore.collection('investors').doc(mockAuth.currentUser!.uid).get();
    expect(updatedDoc['cashFlowDefaults']['downPayment'], 0.2); // 25% converted to 0.25
  });

}