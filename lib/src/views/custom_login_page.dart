import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

/// A helper widget that fades in its child after a given delay.
class DelayedFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const DelayedFadeIn({
    Key? key,
    required this.child,
    required this.delay,
    required this.duration,
  }) : super(key: key);

  @override
  _DelayedFadeInState createState() => _DelayedFadeInState();
}

class _DelayedFadeInState extends State<DelayedFadeIn> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Trigger fade in after the specified delay.
    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: widget.duration,
      child: widget.child,
    );
  }
}

class CustomLoginPage extends StatefulWidget {
  const CustomLoginPage({Key? key}) : super(key: key);

  @override
  _CustomLoginPageState createState() => _CustomLoginPageState();
}

class _CustomLoginPageState extends State<CustomLoginPage>
    with SingleTickerProviderStateMixin {
  bool _isRegister = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _errorTimer;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // No outer fade controller; instead each widget fades in individually.
  }

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
      // Check for temp password login in the investors collection
      QuerySnapshot investorQuery = await _firestore
          .collection('investors')
          .where('contactEmail', isEqualTo: _emailController.text.trim())
          .where('tempPassword', isEqualTo: _passwordController.text.trim())
          .limit(1)
          .get();

      if (investorQuery.docs.isNotEmpty) {
        // Temp password login detected
        DocumentSnapshot investorDoc = investorQuery.docs.first;
        String uid = investorDoc.id;

        // Sign in with Firebase Auth
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Update Firestore: Set user role (do NOT invalidate tempPassword here)
        await _firestore.collection('users').doc(uid).set({
          'email': _emailController.text.trim(),
          'role': 'investor',
          'createdAt': FieldValue.serverTimestamp(),
          'completedSetup': false,
        }, SetOptions(merge: true));

        // Fetch user data and redirect to investor setup
        Provider.of<UserProvider>(context, listen: false).fetchUserData();
        if (mounted) context.go('/setup');
      } else {
        // Regular login flow
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String uid = userCredential.user!.uid;
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();

        if (userDoc.exists && mounted) {
          String role = userDoc['role'];
          bool completedSetup = userDoc['completedSetup'] ?? false;

          Provider.of<UserProvider>(context, listen: false).fetchUserData();

          if (role == 'realtor') {
            context.go(completedSetup ? '/home' : '/setup');
          } else if (role == 'investor') {
            context.go(completedSetup ? '/home' : '/setup');
          }
        } else if (mounted) {
          setState(() {
            _errorMessage = "User role not found. Please contact support.";
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _getAuthErrorMessage(e));
      }
    }
  }

  Future<void> _createAccount() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      throw FirebaseAuthException(
          code: 'password-mismatch', message: 'Passwords do not match');
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
      'role': 'realtor', // All new accounts default to Realtor
      'createdAt': FieldValue.serverTimestamp(),
      'completedSetup': false,
    });
  }

  void _navigateAfterRegistration() {
    if (mounted) context.go('/setup');
  }

  String _getAuthErrorMessage(FirebaseAuthException e) {
    _errorTimer?.cancel();
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
    const Color neonPurple = Color(0xFFa78cde);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          isMobile
              ? _buildMobileLayout(neonPurple, isMobile)
              : Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildFormColumn(neonPurple, isMobile),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  color: const Color(0x33D500F9),
                  child: Image.asset(
                    'assets/images/login.png',
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 20,
            left: 20,
            child: DelayedFadeIn(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 500),
              child: GestureDetector(
                onTap: () {
                  context.go("/");
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.real_estate_agent,
                      size: 32,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'RealEst',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 20 : 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(Color neonPurple, bool isMobile) {
    return Container(
      color: const Color(0xFF1f1e25),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
                  child: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildFormChildren(neonPurple, isMobile),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormColumn(Color neonPurple, bool isMobile) {
    return Container(
      color: const Color(0xFF1f1e25),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildFormChildren(neonPurple, isMobile),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build the list of form children with staggered fade-in animations.
  List<Widget> _buildFormChildren(Color neonPurple, bool isMobile) {
    // We'll assign a base delay and an increment for each successive widget.
    const baseDelay = 300; // in milliseconds
    const delayIncrement = 200; // in milliseconds
    int index = 0;

    List<Widget> children = [];

    children.add(
      DelayedFadeIn(
        delay: Duration(milliseconds: baseDelay + index * delayIncrement),
        duration: const Duration(milliseconds: 1000),
        child: Center(
          child: Text(
            _isRegister ? 'Create your account' : 'Welcome to RealEst',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 32 : 46,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
    index++;

    children.add(const SizedBox(height: 10));

    children.add(
      DelayedFadeIn(
        delay: Duration(milliseconds: baseDelay + index * delayIncrement),
        duration: const Duration(milliseconds: 1000),
        child: Center(
          child: Text(
            _errorMessage ?? (_isRegister ? 'Please Sign Up' : 'Please Sign In'),
            style: _errorMessage != null
                ? TextStyle(color: Colors.red, fontSize: isMobile ? 12 : 14)
                : GoogleFonts.poppins(fontSize: isMobile ? 16 : 20, color: Colors.white70),
          ),
        ),
      ),
    );
    index++;

    children.add(SizedBox(height: isMobile ? 20 : 40));

    children.add(
      DelayedFadeIn(
        delay: Duration(milliseconds: baseDelay + index * delayIncrement),
        duration: const Duration(milliseconds: 1000),
        child: _buildAlignedField('Email', _emailController, false, false, isMobile),
      ),
    );
    index++;

    children.add(SizedBox(height: isMobile ? 12 : 16));

    children.add(
      DelayedFadeIn(
        delay: Duration(milliseconds: baseDelay + index * delayIncrement),
        duration: const Duration(milliseconds: 1000),
        child: _buildAlignedField('Password', _passwordController, true, !_isRegister, isMobile),
      ),
    );
    index++;

    if (_isRegister) {
      children.add(SizedBox(height: isMobile ? 12 : 16));
      children.add(
        DelayedFadeIn(
          delay: Duration(milliseconds: baseDelay + index * delayIncrement),
          duration: const Duration(milliseconds: 1000),
          child: _buildAlignedField('Confirm Password', _confirmPasswordController, true, true, isMobile),
        ),
      );
      index++;
    }

    children.add(SizedBox(height: isMobile ? 16 : 20));

    children.add(
      DelayedFadeIn(
        delay: Duration(milliseconds: baseDelay + index * delayIncrement),
        duration: const Duration(milliseconds: 1000),
        child: Center(child: _buildActionButton(isMobile)),
      ),
    );
    index++;

    children.add(SizedBox(height: isMobile ? 12 : 16));

    children.add(
      DelayedFadeIn(
        delay: Duration(milliseconds: baseDelay + index * delayIncrement),
        duration: const Duration(milliseconds: 1000),
        child: Center(child: _buildToggleAuthText(isMobile)),
      ),
    );
    index++;

    if (_isLoading) {
      children.add(
        DelayedFadeIn(
          delay: Duration(milliseconds: baseDelay + index * delayIncrement),
          duration: const Duration(milliseconds: 1000),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: isMobile ? 12.0 : 16.0),
              child: const CircularProgressIndicator(color: Color(0xFFD500F9)),
            ),
          ),
        ),
      );
      index++;
    }

    return children;
  }

  Widget _buildAlignedField(String label, TextEditingController controller, bool obscure, bool isLastField, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, color: Colors.white),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: isMobile ? 400 : 500,
          child: _buildTextField(controller, obscure, isLastField, isMobile),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, bool obscure, bool isLastField, bool isMobile) {
    const Color neonPurple = Color(0xFFa78cde);
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[900],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: neonPurple, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: neonPurple, width: 2),
        ),
      ),
      style: TextStyle(color: Colors.white, fontSize: isMobile ? 14 : 16),
      obscureText: obscure,
      keyboardType: obscure ? TextInputType.text : TextInputType.emailAddress,
      textInputAction: isLastField ? TextInputAction.done : TextInputAction.next,
      onSubmitted: (value) {
        if (isLastField) {
          _authenticate();
        }
      },
    );
  }

  Widget _buildActionButton(bool isMobile) {
    const Color neonPurple = Color(0xFFa78cde);
    return SizedBox(
      width: isMobile ? 400 : 500,
      height: isMobile ? 45 : 50,
      child: ElevatedButton(
        onPressed: _authenticate,
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.openSans(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold),
          backgroundColor: neonPurple,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
        ),
        child: Text(_isRegister ? 'REGISTER' : 'LOGIN'),
      ),
    );
  }

  Widget _buildToggleAuthText(bool isMobile) {
    const Color neonPurple = Color(0xFFa78cde);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isRegister ? 'Already have an account?' : 'Don\'t have an account?',
          style: GoogleFonts.openSans(fontSize: isMobile ? 16 : 20, color: Colors.white),
        ),
        TextButton(
          onPressed: () => setState(() => _isRegister = !_isRegister),
          child: Text(
            _isRegister ? 'Sign In' : 'Register',
            style: GoogleFonts.openSans(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: neonPurple,
              decoration: TextDecoration.underline,
              decorationColor: neonPurple,
            ),
          ),
        ),
      ],
    );
  }
}
