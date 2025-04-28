// test/main_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:fake_async/fake_async.dart';

import 'firebase_core_mocks.dart';
import 'package:realest/main.dart';
import 'package:realest/user_provider.dart';
import 'package:realest/src/views/home/overview/overview_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Mock implementation of AuthCredential
class MockAuthCredential extends AuthCredential {
  MockAuthCredential() : super(providerId: 'mock', signInMethod: 'mock');
}

void main() {
  // 1) Install Firebase core method‐channel mocks once.
  setupFirebaseAuthMocks();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
  });

  setUp(() {
    // Clear any persisted prefs before each test
    SharedPreferences.setMockInitialValues({});
  });

  /// Helper to create & initialize your real UserProvider.
  Future<UserProvider> makeProvider({
    required FakeFirebaseFirestore firestore,
    required MockFirebaseAuth auth,
  }) async {
    // Sign in so auth.currentUser != null
    await auth.signInWithCredential(MockAuthCredential());
    final provider = UserProvider(auth: auth, firestore: firestore);
    await provider.initializeUser();
    return provider;
  }

  testWidgets('HomePage shows initially', (tester) async {
    FakeAsync().run((async) async {
      final fb = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth();
      final provider = await makeProvider(firestore: fb, auth: auth);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MyApp(),
        ),
      );

      async.elapse(const Duration(seconds: 5)); //video render
      await tester.pump();

      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    });
  });
}
