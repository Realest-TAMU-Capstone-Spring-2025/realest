import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:realest/user_provider.dart';
import 'package:realest/src/views/realtor/realtor_setup.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../../util/mock_firebase_util.dart';
import '../../../util/overflowerror.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      email: 'realtor@example.com',
      password: 'password123',
    );
  });

  Future<void> _buildRealtorSetup(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider(
            create: (_) => UserProvider(auth: mockAuth, firestore: mockFirestore),
            child: RealtorSetupPage(),
          ),
        ),
      ),
    );
  }

  testWidgets('RealtorSetup loads user data correctly, updates correctly', (WidgetTester tester) async {
    ignoreOverflowErrors();
    await _buildRealtorSetup(tester);
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    expect(textFields, findsAtLeastNWidgets(7));

    // Update the first two TextField widgets
    await tester.enterText(textFields.at(0), 'Jane');
    await tester.enterText(textFields.at(1), 'Smith');
    await tester.enterText(textFields.at(2), 'Dream Agency');
    await tester.enterText(textFields.at(3), '12345');
    await tester.enterText(textFields.at(4), 'realtor@example.com');
    await tester.enterText(textFields.at(5), '123-456-7890');
    await tester.enterText(textFields.at(6), '123 Main St');
    await tester.pumpAndSettle();

    final saveButton = find.text('COMPLETE SETUP');
    await tester.ensureVisible(saveButton);

    // Save changes
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  });

  testWidgets('RealtorSetup picker', (WidgetTester tester) async {
    ignoreOverflowErrors();
    await _buildRealtorSetup(tester);
    await tester.pumpAndSettle();

    // Mock ImagePicker
    final Uint8List mockImageBytes = Uint8List.fromList([0, 1, 2, 3]);
    MockImagePicker.setMockImage(mockImageBytes);

    // Tap on the profile picture to pick a new image
    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();
  });
}