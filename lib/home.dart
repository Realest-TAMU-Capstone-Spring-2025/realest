import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: Center(
        child: Column(
          children: [
            // Image.asset('logo.png'),
            Text('Welcome to Realest!', style: Theme.of(context).textTheme.displaySmall),
          //sign out button
          //floating action button
          FloatingActionButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            child: const Icon(Icons.logout),
          ),
          ],
        ),
      ),
    );
  }
}