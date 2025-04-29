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

  setUp(() {
    mockAuth.signOut();
    SharedPreferences.setMockInitialValues({});
    mockAuth.signInWithEmailAndPassword(
      email: 'investor@example.com',
      password: 'password123',
    );
    print("user id is: ${mockAuth.currentUser!.uid}");
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget() {

    return ChangeNotifierProvider(
      create: (_) => UserProvider(auth: mockAuth, firestore: mockFirestore),
      child: MaterialApp(
        home: DislikedProperties(),
      ),
    );
  }

  testWidgets('Displays disliked properties', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump(Durations.medium2);
    dumpAllTextInWidgetTree(tester);
  });
}