import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../config/global_variables.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // User is already signed in; navigate automatically to the home screen.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/realtorHome');
          });
          return Container();
        }
        // Otherwise, show the role selection UI.
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo aligned to top left.
                  Align(
                    alignment: Alignment.topLeft,
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 50,
                      height: 50,
                    ),
                  ),
                  // Lottie animation.
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Lottie.asset(
                      'assets/lottie/building.json',
                      width: 350,
                      height: 400,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -130),
                    child: Text(
                      'Welcome to RealEst',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Additional text.
                  Transform.translate(
                    offset: const Offset(0, -130),
                    child: Text(
                      'Are you a Realtor or Investor?',
                      style: GoogleFonts.poppins(fontSize: 22, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Realtor button.
                  ElevatedButton(
                    onPressed: () {
                      userRole = 'Realtor';
                      Navigator.pushReplacementNamed(context, '/customLogin');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF212834),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      textStyle: GoogleFonts.openSans(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Realtor'),
                  ),
                  const SizedBox(height: 50),
                  // Investor button.
                  ElevatedButton(
                    onPressed: () {
                      userRole = 'Investor';
                      Navigator.pushReplacementNamed(context, '/customLogin');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF212834),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 115, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      textStyle: GoogleFonts.openSans(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Investor'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
