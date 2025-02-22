import 'package:flutter/material.dart';
import 'src/views/role_selection_screen.dart';
import 'src/views/auth_gate.dart';
import 'src/views/custom_login_page.dart';
import 'src/views/enter_invitation_code.dart';
import 'src/views/home.dart';
import 'src/views/realtor_home_screen.dart';
import 'src/views/realtor_settings_screen.dart';
import 'src/views/realtor_clients_screen.dart';
import 'src/views/realtor_filters_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Property Investment App',
      home: const RoleSelectionScreen(),
      routes: {
        '/roleSelection': (context) => RoleSelectionScreen(),
        '/authGate': (context) => AuthGate(),
        '/customLogin': (context) => CustomLoginPage(),
        '/enterInvitationCode': (context) => EnterInvitationCodeScreen(),
        '/home': (context) => HomeScreen(),
        '/realtorHome': (context) => RealtorHomeScreen(),
        // '/realtorSettings': (context) => RealtorSettingsScreen(),
        // '/realtorClients': (context) => RealtorClientsScreen(),
        '/filters': (context) => FiltersPage(),
      },
    );
  }
}
