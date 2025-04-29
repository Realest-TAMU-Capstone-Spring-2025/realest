import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:realest/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full app test', (WidgetTester tester) async {
    app.main(); // Launches your app as it would run in production
    await tester.pumpAndSettle();

    // Now interact with your app using tester.tap, tester.enterText, etc.
    // For example, tap a button:
    // await tester.tap(find.byKey(Key('yourButtonKey')));
    // await tester.pumpAndSettle();

    // Add assertions as needed
    // expect(find.text('Expected Text'), findsOneWidget);
  });
}
