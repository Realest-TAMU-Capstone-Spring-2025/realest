import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:realest/main.dart' as app;
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full app test', (WidgetTester tester) async {
    app.main(); // Launches your app as it would run in production`
    await tester.pumpAndSettle();
  });

  testWidgets('Realtor sign-in and actions', (WidgetTester tester) async {
    app.main(); // Launches the app
    await tester.pumpAndSettle();
    await tester.pumpAndSettle(const Duration(seconds: 2));


    //click login button
    final loginButton = find.text('Login');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Enter login credentials

    final emailField = find.byKey(Key('Email'));
    final passwordField = find.byKey(Key('Password'));

    await tester.enterText(emailField, 'real2@gmail.com');
    await tester.enterText(passwordField, 'password');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verify navigation to the home page
    expect(find.text('Home Page'), findsOneWidget);

    // Perform actions as a realtor
    // Navigate to settings
    final settingsButton = find.byIcon(Icons.settings);
    await tester.tap(settingsButton);
    await tester.pumpAndSettle();

    // Update profile information
    final firstNameField = find.byKey(Key('firstNameField'));
    final lastNameField = find.byKey(Key('lastNameField'));
    final saveChangesButton = find.text('Save Changes');

    await tester.enterText(firstNameField, 'UpdatedFirstName');
    await tester.enterText(lastNameField, 'UpdatedLastName');
    await tester.tap(saveChangesButton);
    await tester.pumpAndSettle();

    // Verify success message
    expect(find.text('Profile updated successfully!'), findsOneWidget);
  });
}
