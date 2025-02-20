import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'home.dart';
import '../config/global_variables.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing in with Google: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(
            providers: [EmailAuthProvider()],
            headerBuilder: (context, constraints, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 50,
                    height: 50,
                  ),
                ),
              );
            },
            subtitleBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: action == AuthAction.signIn
                    ? const Text('Welcome to Realest, please sign in!')
                    : const Text('Welcome to Realest, please sign up!'),
              );
            },
            footerBuilder: (context, action) {
              return Column(
                children: [
                  const SizedBox(height: 20),
                  _ThirdPartyAuthButtons(
                    onGooglePressed: () => _signInWithGoogle(context),
                    onApplePressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Apple Sign-In is not implemented yet'),
                        ),
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'By signing in, you agree to our terms and conditions.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              );
            },
          );
        }
        return const HomeScreen();
      },
    );
  }
}

class _ThirdPartyAuthButtons extends StatelessWidget {
  final VoidCallback onGooglePressed;
  final VoidCallback onApplePressed;

  const _ThirdPartyAuthButtons({
    required this.onGooglePressed,
    required this.onApplePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Or continue with'),
        const SizedBox(height: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SignInButton(
              Buttons.GoogleDark,
              onPressed: onGooglePressed,
            ),
            const SizedBox(width: 24),
            SignInButton(
              Buttons.Apple,
              onPressed: onApplePressed,
            ),
          ],
        ),
      ],
    );
  }
}