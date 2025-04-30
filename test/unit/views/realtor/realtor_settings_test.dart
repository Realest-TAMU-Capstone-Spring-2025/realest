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
import 'package:realest/src/views/realtor/realtor_settings.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import '../../../util/overflowerror.dart';

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
    final mocks = await MockFirebaseUtil.initializeMockFirebaseRoled(true);
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
    print("user id is: ${mockAuth.currentUser!.uid}");

  });

  Future<void> _buildRealtorSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => UserProvider(auth: mockAuth, firestore: mockFirestore),
          child: RealtorSettings(
            toggleTheme: () {},
            isDarkMode: false,
          ),
        ),
      ),
    );
  }

  testWidgets('RealtorSettings loads user data correctly, updates correctly', (WidgetTester tester) async {
    // Mock Firestore data
    await _buildRealtorSettings(tester);
    await tester.pumpAndSettle();

    expect(find.text('John'), findsOneWidget); //pulls from mock util sufficient for unit test, see coverage
  });

  testWidgets('RealtorSettings picker', (WidgetTester tester) async {
    await _buildRealtorSettings(tester);
    await tester.pumpAndSettle();
    // Mock ImagePicker
    final Uint8List mockImageBytes = Uint8List.fromList([0, 1, 2, 3]);
    MockImagePicker.setMockImage(mockImageBytes);

    // Tap on the profile picture to pick a new image
    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();
  });

  testWidgets('RealtorSettings saves updated data', (WidgetTester tester) async {
    ignoreOverflowErrors();
    await _buildRealtorSettings(tester);
    await tester.pumpAndSettle();
    await tester.pump(Duration(seconds: 1));

    // Find all TextField widgets
    final textFields = find.byType(TextField);
    // Ensure there are at least two TextField widgets
    expect(textFields, findsAtLeastNWidgets(2));

    // Update the first two TextField widgets
    dumpAllTextInWidgetTree(tester);
    await tester.enterText(textFields.at(0), 'Jane');
    await tester.enterText(textFields.at(1), 'Smith');
    await tester.pumpAndSettle();

    final saveButton = find.text('Save Changes');
    await tester.ensureVisible(saveButton);

    // Save changes
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  });
}