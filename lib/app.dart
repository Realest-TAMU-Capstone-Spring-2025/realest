import 'package:flutter/material.dart';
import 'src/views/role_selection_screen.dart';
import 'src/views/custom_login_page.dart';
import 'src/views/investor/enter_invitation_code.dart';
import 'src/views/realtor/realtor_home_screen.dart';
import 'src/views/realtor/realtor_settings_screen.dart';
import 'src/views/realtor/realtor_clients_screen.dart';
import 'src/views/realtor/realtor_filters_screen.dart';
import 'src/views/investor/investor_home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Property Investment App',
      home: const RoleSelectionScreen(),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
      ),
      routes: {
        '/roleSelection': (context) => RoleSelectionScreen(),
        '/customLogin': (context) => CustomLoginPage(),
        '/enterInvitationCode': (context) => EnterInvitationCodeScreen(),
        '/realtorHome': (context) => RealtorHomeScreen(),
        '/realtorSettings': (context) => SettingsPage(),
        '/realtorClients': (context) => ClientsPage(),
        '/filters': (context) => FiltersPage(initialFilters: []),
        '/investorHome': (context) => InvestorHomeScreen(),
      },
    );
  }
}
