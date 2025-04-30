import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:realest/main.dart' as app;
import 'package:flutter/material.dart';

Future<void> login(WidgetTester tester, String username, String password) async {
  await tester.enterText(find.byKey(Key('username')), username);
  await tester.enterText(find.byKey(Key('password')), password);
  await tester.tap(find.byKey(Key('loginButton')));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login tests', () {
    testWidgets('User 1 login and actions', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await login(tester, 'real2@gmail.com', 'password');
      // Add actions/assertions for user 1
    });

    testWidgets('User 2 login and actions', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await login(tester, 'invtest2@gmail.com', 'password');
      // Add actions/assertions for user 2
    });
  });
}
