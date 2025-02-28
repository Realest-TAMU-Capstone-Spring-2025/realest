import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:realest/firebase_options.dart';
import 'src/views/custom_login_page.dart';
import 'src/views/investor/investor_home.dart';
import 'src/views/realtor/realtor_home.dart';
import 'src/views/realtor/realtor_setup.dart';
import 'src/views/realtor/realtor_calculators.dart';
import 'src/views/realtor/realtor_clients.dart';
import 'src/views/realtor/realtor_reports.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => AuthGate(),
        '/login': (context) => const CustomLoginPage(),
        '/investorHome': (context) => const InvestorHomePage(),
        '/realtorHome': (context) => const RealtorHomePage(),
        '/realtorSetup': (context) => const RealtorSetupPage(),
        '/realtorCalculators': (context) => const RealtorCalculators(),
        '/realtorClients': (context) => const RealtorClients(),
        '/realtorReports': (context) => const RealtorReports(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.idTokenChanges(), // Syncs login state across tabs
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user == null) {
          return const CustomLoginPage();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final role = userSnapshot.data!['role'];
              if (role == "investor") {
                return const InvestorHomePage();
              } else {
                return const RealtorHomePage();
              }
            }

            return const CustomLoginPage();
          },
        );
      },
    );
  }
}
