import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import '../config/global_variables.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home.dart';

class CustomLoginPage extends StatefulWidget {
  const CustomLoginPage({Key? key}) : super(key: key);

  @override
  _CustomLoginPageState createState() => _CustomLoginPageState();
}

class _CustomLoginPageState extends State<CustomLoginPage> {
  bool _isRegister = false;
  bool _justRegistered = false; // flag to indicate a new registration
  bool _hasNavigated = false; // new flag to prevent repeated navigation
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    try {
      setState(() {
        _isLoading = true;
      });
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Auth state change will trigger navigation.
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing in: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      // Clear fields after operation.
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    }
  }

  Future<void> _createAccount() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    try {
      setState(() {
        _isLoading = true;
      });
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Mark registration as successful.
      setState(() {
        _justRegistered = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating account: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        // Clear fields and revert to sign-in mode.
        _isRegister = false;
      });
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing in with Google: ${e.toString()}')),
      );
    }
  }

  Future<void> _signInWithApple() async {
    // Implement Apple sign-in logic here.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple Sign-In is not implemented yet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        // When the user is authenticated...
        if (snapshot.hasData && !_hasNavigated) {
          _hasNavigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_justRegistered && userRole == "Investor") {
              Navigator.pushReplacementNamed(context, "/enterInvitationCode");
            } else {
              Navigator.pushReplacementNamed(context, "/realtorHome");
            }
          });
          // Return an empty container while navigation is pending.
          return Container();
        }
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26.0),
              child: Column(
                children: [
                  // Back arrow
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black, size: 50),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, "/roleSelection");
                      },
                    ),
                  ),
                  Image.asset(
                    'assets/images/logo.png',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome $userRole!',
                    style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _isRegister ? 'Please Sign Up' : 'Please Sign In',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Email field with rounded borders
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      hintText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  // Password field with rounded borders
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[200],
                      hintText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  // Confirm Password field (only in Register mode)
                  if (_isRegister)
                    TextField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        hintText: 'Confirm Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      obscureText: true,
                    ),
                  if (_isRegister) const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isRegister ? _createAccount : _signInWithEmail,
                      style: ElevatedButton.styleFrom(
                        textStyle: GoogleFonts.openSans(fontSize: 20, fontWeight: FontWeight.bold),
                        backgroundColor: const Color(0xFF212834),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(_isRegister ? 'REGISTER' : 'LOGIN'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Or continue with:',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SignInButton(
                        Buttons.Google,
                        onPressed: _signInWithGoogle,
                      ),
                      const SizedBox(width: 16),
                      SignInButton(
                        Buttons.Apple,
                        onPressed: _signInWithApple,
                      ),
                    ],
                  ),
                  if (_isRegister) const SizedBox(height: 8) else const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isRegister ? 'Already have an account?' : 'Don\'t have an account?',
                        style: GoogleFonts.openSans(fontSize: 20),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.all(5.0),
                          minimumSize: const Size(0, 0),
                        ),
                        onPressed: () {
                          setState(() {
                            _isRegister = !_isRegister;
                          });
                        },
                        child: Text(
                          _isRegister ? 'Sign In' : 'Register',
                          style: GoogleFonts.openSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
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
