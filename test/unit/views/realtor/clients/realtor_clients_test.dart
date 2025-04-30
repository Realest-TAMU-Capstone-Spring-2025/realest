import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:realest/user_provider.dart';
import 'package:realest/src/views/realtor/clients/realtor_clients.dart';
import '../../../../util/mock_firebase_util.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  late MockFirebaseAuth mockAuth;
  late FakeFirebaseFirestore mockFirestore;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mocks = await MockFirebaseUtil.initializeMockFirebaseRoled(true);
    mockAuth = mocks['auth'] as MockFirebaseAuth;
    mockFirestore = mocks['firestore'] as FakeFirebaseFirestore;

    // Mock environment variables
    DotEnv().testLoad(fileInput: '''
      API_KEY=mock_api_key
      AUTH_DOMAIN=mock_auth_domain
      PROJECT_ID=mock_project_id
      STORAGE_BUCKET=mock_storage_bucket
      MESSAGING_SENDER_ID=mock_messaging_sender_id
      APP_ID=mock_app_id
    ''');

    dotenv.testLoad(fileInput: '''ALGOLIA_APP_ID=test_app_id\nALGOLIA_API_KEY=test_api_key''');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await mockAuth.signInWithEmailAndPassword(
      email: 'realtor@example.com',
      password: 'password123',
    );
  });

  tearDown(() async {
    await mockFirestore.clearPersistence();
    mockFirestore = FakeFirebaseFirestore();
  });

  Widget createTestWidget() {
    return ChangeNotifierProvider(
      create: (_) => UserProvider(auth: mockAuth, firestore: mockFirestore),
      child: const MaterialApp(
        home: RealtorClients(),
      ),
    );
  }

  testWidgets('Displays client management title', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Client Management'), findsOneWidget);
  });

  testWidgets('Displays search bar', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('Displays panels for leads, qualified leads, and clients', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('New Leads'), findsOneWidget);
    expect(find.text('Qualified Leads'), findsOneWidget);
    expect(find.text('Clients'), findsOneWidget);
  });

  testWidgets('Handles empty client list gracefully', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('No leads available.'), findsOneWidget);
    expect(find.text('No qualified leads available.'), findsOneWidget);
    expect(find.text('No clients yet.'), findsOneWidget);
  });
}