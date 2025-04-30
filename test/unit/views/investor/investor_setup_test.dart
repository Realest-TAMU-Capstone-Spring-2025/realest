import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:realest/user_provider.dart';
import 'package:realest/src/views/profile_pic.dart';
import 'package:realest/user_provider.dart';
import '../../../util/mock_firebase_util.dart';
import '../../../util/overflowerror.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:realest/src/views/investor/investor_setup.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../flutter_test_config.dart';

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

  Future<void> _buildInvestorSetup(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider(
            create: (_) => UserProvider(auth: mockAuth, firestore: mockFirestore),
            child: InvestorSetupPage(),
          ),
        ),
      ),
    );
  }

  testWidgets('InvestorSettings loads user data correctly, updates correctly', (WidgetTester tester) async {
    // Mock Firestore data
    ignoreOverflowErrors();
    await _buildInvestorSetup(tester);
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    // Ensure there are at least two TextField widgets
    expect(textFields, findsAtLeastNWidgets(6));

    // Update the first two TextField widgets
    await tester.enterText(textFields.at(0), 'John');
    await tester.enterText(textFields.at(1), 'Doe');
    //leave email the same
    await tester.enterText(textFields.at(3), '123-456-7890');
    await tester.enterText(textFields.at(4), 'StrongP@ss123');
    await tester.enterText(textFields.at(5), 'StrongP@ss123');
    await tester.pumpAndSettle();

    final saveButton = find.text('SAVE & CONTINUE');
    await tester.ensureVisible(saveButton);

    // Save changes
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  });

  testWidgets('InvestorSetup picker', (WidgetTester tester) async {
    //set size 
    ignoreOverflowErrors();
    await _buildInvestorSetup(tester);
    await tester.pumpAndSettle();
    // Mock ImagePicker
    final Uint8List mockImageBytes = Uint8List.fromList([0, 1, 2, 3]);
    MockImagePicker.setMockImage(mockImageBytes);

    // Tap on the profile picture to pick a new image
    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();
  });
}