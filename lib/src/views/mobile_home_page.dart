import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// The main landing page for mobile users, displaying a welcome screen with login and signup options.
class MobileHomePage extends StatefulWidget {
  const MobileHomePage({Key? key}) : super(key: key);

  @override
  _MobileHomePageState createState() => _MobileHomePageState();
}

/// State for [MobileHomePage], handling animations and authentication status.
class _MobileHomePageState extends State<MobileHomePage> with TickerProviderStateMixin {
  /// Controller for logo animation.
  late AnimationController _logoController;

  /// Controller for welcome text animation.
  late AnimationController _welcomeController;

  /// Controller for subtext animation.
  late AnimationController _subtextController;

  /// Controller for buttons animation.
  late AnimationController _buttonsController;

  /// Animation for sliding the logo into view.
  late Animation<Offset> _logoAnimation;

  /// Animation for sliding the welcome text into view.
  late Animation<Offset> _welcomeAnimation;

  /// Animation for sliding the subtext into view.
  late Animation<Offset> _subtextAnimation;

  /// Animation for sliding the buttons into view.
  late Animation<Offset> _buttonsAnimation;

  @override
  void initState() {
    super.initState();

    // Check authentication status after the frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });

    // Initialize animation controllers with a 1000ms duration.
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _subtextController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Define slide animations from top to original position using easeInOut curve.
    _logoAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    _welcomeAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeInOut),
    );
    _subtextAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _subtextController, curve: Curves.easeInOut),
    );
    _buttonsAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeInOut),
    );

    // Start animations with staggered delays for a smooth effect.
    Future.delayed(Duration.zero, () {
      _logoController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _welcomeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _subtextController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      _buttonsController.forward();
    });
  }

  /// Checks if a user is logged in and navigates accordingly.
  Future<void> _checkAuthStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      // User is logged in, fetch user data from Firestore.
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          String role = userDoc['role'];
          bool completedSetup = userDoc['completedSetup'] ?? false;

          // Navigate based on role and setup status.
          if (role == 'realtor' || role == 'investor') {
            context.go(completedSetup ? '/home' : '/setup');
          } else {
            // Handle invalid role by signing out and showing an error.
            await FirebaseAuth.instance.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Invalid user role. Please contact support.')),
            );
          }
        } else {
          // User document doesn't exist, sign out and show error.
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data not found. Please sign in again.')),
          );
        }
      } catch (e) {
        // Handle Firestore errors with a user-friendly message.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking user status: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Dispose animation controllers to free resources.
    _logoController.dispose();
    _welcomeController.dispose();
    _subtextController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1f1e25), // Dark background color.
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15), // Top spacing.
            // Animated logo icon sliding into view.
            SlideTransition(
              position: _logoAnimation,
              child: const Icon(
                Icons.real_estate_agent,
                size: 150,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Animated welcome text sliding into view.
            SlideTransition(
              position: _welcomeAnimation,
              child: Text(
                'Welcome to RealEst',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Animated subtext sliding into view.
            SlideTransition(
              position: _subtextAnimation,
              child: Text(
                'Automate Analysis, Multiply Deals',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  color: Color(0xFFa78cde),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(), // Pushes buttons to the bottom.
            // Animated buttons sliding into view.
            SlideTransition(
              position: _buttonsAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Log In button.
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          context.go('/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFa78cde), // Purple button color.
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Log In',
                          style: GoogleFonts.openSans(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sign Up button.
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          context.go('/login?register=true');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1f1e25),
                          foregroundColor: Color(0xFFa78cde),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: const BorderSide(color: Color(0xFFa78cde)),
                          ),
                        ),
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.openSans(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40), // Bottom spacing.
          ],
        ),
      ),
    );
  }
}