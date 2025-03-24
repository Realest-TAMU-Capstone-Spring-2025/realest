import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomLoginPage extends StatefulWidget {
  const CustomLoginPage({Key? key}) : super(key: key);

  @override
  _CustomLoginPageState createState() => _CustomLoginPageState();
}

class _CustomLoginPageState extends State<CustomLoginPage> {
  bool _isRegister = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedRole = 'investor'; // Default role
  Timer? _errorTimer;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
     _errorTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_isRegister) {
        await _createAccount();
      } else {
        await _signInWithEmail();
      }
    } on FirebaseAuthException catch (e) {
      final message = _getAuthErrorMessage(e);
      setState(() => _errorMessage = message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists && mounted) {
        setState(() {
          _selectedRole = userDoc['role'];
        });

        Provider.of<UserProvider>(context, listen: false).fetchUserData();
        if (_selectedRole == "realtor") {

          context.go( "/realtorDashboard");
        } else {
          context.go( "/investorHome");
        }
      } else if (mounted) {
        setState(() {
          _errorMessage = "User role not found. Please contact support.";
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _getAuthErrorMessage(e));
      }
    }
  }



  Future<void> _createAccount() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      throw FirebaseAuthException(code: 'password-mismatch', message: 'Passwords do not match');
    }
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    await _createUserDocument(userCredential.user!);
    _navigateAfterRegistration();
  }

  Future<void> _createUserDocument(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'role': _selectedRole,
      'createdAt': FieldValue.serverTimestamp(),
      'completedSetup': false,
    });
  }
  void _navigateAfterRegistration() {
    if (_selectedRole == "investor") {
      context.go('/investorSetup');
    } else {
      context.go("/realtorSetup");
    }
  }


  String _getAuthErrorMessage(FirebaseAuthException e) {
    // print(e.code);
    if(_errorTimer != null) {
      _errorTimer!.cancel();
    }
    _errorTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _errorMessage = null);
      }
    });
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'invalid-credential':
        return 'Invalid Credentials. Please check your email and password and try again.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Your password is too weak. Please use a stronger password.';
      case 'password-mismatch':
        return 'Passwords do not match.';
      default:
        return 'An unexpected error occurred. Please try again later.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.network(
              'https://photos.zillowstatic.com/fp/f92e12421954f63424e6788ca770bdc4-cc_ft_1536.webp',
              fit: BoxFit.cover,
            ),
          ),


          // Semi-transparent white overlay
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(.90), // Adjust opacity as needed
            ),
          ),

          // Login form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400.0),
                child: Column(
                  children: [
                    const Icon(Icons.real_estate_agent, size: 200, color: Colors.black),
                    Text(
                      'Realest',
                      style: GoogleFonts.poppins(fontSize: 40, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _errorMessage ?? (_isRegister ? 'Please Sign Up' : 'Please Sign In'),
                      style: _errorMessage != null
                          ? const TextStyle(color: Colors.red, fontSize: 14)
                          : GoogleFonts.poppins(
                              fontSize: 20,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    _buildTextField(_emailController, 'Email', false),
                    const SizedBox(height: 16),
                    _buildTextField(_passwordController, 'Password', true),
                    if (_isRegister) ...[
                      const SizedBox(height: 16),
                      _buildTextField(_confirmPasswordController, 'Confirm Password', true),
                      const SizedBox(height: 16),
                      ToggleButtons(
                        borderRadius: BorderRadius.circular(30),
                        constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
                        isSelected: [
                          _selectedRole == 'investor',
                          _selectedRole == 'realtor',
                        ],
                        onPressed: (int index) {
                          setState(() {
                            _selectedRole = index == 0 ? 'investor' : 'realtor';
                          });
                        },
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Investor'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Realtor'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildActionButton(),
                    const SizedBox(height: 16),
                    _buildToggleAuthText(),
                    if (_isLoading) const Padding(padding: EdgeInsets.only(top: 16.0), child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, bool obscure) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200], // Keeps the background color
        hintText: hint,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: Colors.purple, width: 1), // Purple border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: Colors.deepPurple, width: 2), // Deeper purple when focused
        ),
      ),
      obscureText: obscure,
      keyboardType: obscure ? TextInputType.text : TextInputType.emailAddress,
    );
  }


  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _authenticate,
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.openSans(fontSize: 20, fontWeight: FontWeight.bold),
          backgroundColor: const Color(0xFF212834),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(_isRegister ? 'REGISTER' : 'LOGIN'),
      ),
    );
  }

  Widget _buildToggleAuthText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_isRegister ? 'Already have an account?' : 'Don\'t have an account?', style: GoogleFonts.openSans(fontSize: 20)),
        TextButton(
          onPressed: () => setState(() => _isRegister = !_isRegister),
          child: Text(_isRegister ? 'Sign In' : 'Register', style: GoogleFonts.openSans(fontSize: 20, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
        ),
      ],
    );
  }
}