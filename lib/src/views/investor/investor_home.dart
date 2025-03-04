import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'swiping/property_swiping.dart';
import 'properties/saved_properties.dart';

class InvestorHomePage extends StatelessWidget {
  const InvestorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // return kIsWeb || defaultTargetPlatform == TargetPlatform.macOS
    //     ? const InvestorMobileApp()
    //     : const WebWarningWidget();
    return const InvestorMobileApp();
  }
}

class InvestorMobileApp extends StatefulWidget {
  const InvestorMobileApp({super.key});

  @override
  State<InvestorMobileApp> createState() => _InvestorMobileAppState();
}

class _InvestorMobileAppState extends State<InvestorMobileApp> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    PropertySwipingView(),
    SavedProperties(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      FirebaseAuth.instance.signOut();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
        onTap: _onItemTapped,
      ),
    );
  }
}

class WebWarningWidget extends StatelessWidget {
  const WebWarningWidget({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mobile_friendly, size: 100, color: Colors.blue[700]),
              const Text("Mobile App Required", style: TextStyle(fontSize: 28)),
              const Text("Please use our mobile app for full investor features"),
              ElevatedButton.icon(
                onPressed: () => _signOut(context),
                icon: const Icon(Icons.logout),
                label: const Text("Sign Out"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}