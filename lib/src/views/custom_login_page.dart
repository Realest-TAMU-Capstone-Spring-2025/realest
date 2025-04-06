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
          context.go("/realtorDashboard");
        } else {
          context.go("/investorHome");
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
    if (_errorTimer != null) {
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
    const Color neonPurple = Color(0xFFa78cde);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          isMobile
              ? _buildMobileLayout(neonPurple, isMobile) // Pass isMobile to adjust sizes
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
                      fontSize: isMobile ? 20 : 24, // Smaller on mobile
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile layout with reduced sizes
  Widget _buildMobileLayout(Color neonPurple, bool isMobile) {
    return Container(
      color: const Color(0xFF1f1e25),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0), // Reduced padding
                  child: SizedBox(
                    width: 400, // Reduced max width for mobile
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

  // Desktop layout
  Widget _buildFormColumn(Color neonPurple, bool isMobile) {
    return Container(
      color: const Color(0xFF1f1e25),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
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

  // Form children with conditional sizing
  List<Widget> _buildFormChildren(Color neonPurple, bool isMobile) {
    return [
      Center(
        child: Text(
          _isRegister ? 'Create your account' : 'Welcome back',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 32 : 46, // Reduced from 46 to 32
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 10),
      Center(
        child: Text(
          _errorMessage ?? (_isRegister ? 'Please Sign Up' : 'Please Sign In'),
          style: _errorMessage != null
              ? TextStyle(color: Colors.red, fontSize: isMobile ? 12 : 14) // Reduced from 14 to 12
              : GoogleFonts.poppins(fontSize: isMobile ? 16 : 20, color: Colors.white70), // Reduced from 20 to 16
        ),
      ),
      SizedBox(height: isMobile ? 20 : 40), // Reduced spacing
      _buildAlignedField('Email', _emailController, false, false, isMobile),
      SizedBox(height: isMobile ? 12 : 16), // Reduced spacing
      _buildAlignedField('Password', _passwordController, true, !_isRegister, isMobile),
      if (_isRegister) ...[
        SizedBox(height: isMobile ? 12 : 16), // Reduced spacing
        _buildAlignedField('Confirm Password', _confirmPasswordController, true, true, isMobile),
        SizedBox(height: isMobile ? 12 : 16), // Reduced spacing
        Center(child: _buildRoleToggle(isMobile)),
      ],
      SizedBox(height: isMobile ? 16 : 20), // Reduced spacing
      Center(child: _buildActionButton(isMobile)),
      SizedBox(height: isMobile ? 12 : 16), // Reduced spacing
      Center(child: _buildToggleAuthText(isMobile)),
      if (_isLoading)
        Center(
          child: Padding(
            padding: EdgeInsets.only(top: isMobile ? 12.0 : 16.0), // Adjusted padding
            child: const CircularProgressIndicator(color: Color(0xFFD500F9)),
          ),
        ),
    ];
  }

  Widget _buildAlignedField(String label, TextEditingController controller, bool obscure, bool isLastField, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, color: Colors.white), // Reduced from 18 to 16
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: isMobile ? 400 : 500, // Reduced width for mobile
          child: _buildTextField(controller, obscure, isLastField, isMobile),
        ),
      ],
    );
  }

  Widget _buildRoleToggle(bool isMobile) {
    const Color neonPurple = Color(0xFFa78cde);
    return ToggleButtons(
      borderRadius: BorderRadius.circular(30),
      constraints: BoxConstraints(minHeight: isMobile ? 36 : 40, minWidth: isMobile ? 80 : 100), // Smaller on mobile
      isSelected: [_selectedRole == 'investor', _selectedRole == 'realtor'],
      onPressed: (int index) => setState(() => _selectedRole = index == 0 ? 'investor' : 'realtor'),
      color: Colors.white,
      selectedColor: Colors.white,
      fillColor: neonPurple,
      borderColor: neonPurple,
      selectedBorderColor: neonPurple,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
          child: Text('Investor', style: TextStyle(fontSize: isMobile ? 16 : 18)), // Reduced from 18 to 16
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
          child: Text('Realtor', style: TextStyle(fontSize: isMobile ? 16 : 18)), // Reduced from 18 to 16
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
      style: TextStyle(color: Colors.white, fontSize: isMobile ? 14 : 16), // Reduced font size for mobile
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
      width: isMobile ? 400 : 500, // Reduced width for mobile
      height: isMobile ? 45 : 50, // Reduced height for mobile
      child: ElevatedButton(
        onPressed: _authenticate,
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.openSans(
            fontSize: isMobile ? 18 : 22, // Reduced from 22 to 18
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: neonPurple,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15), // Adjusted padding
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
          style: GoogleFonts.openSans(fontSize: isMobile ? 16 : 20, color: Colors.white), // Reduced from 20 to 16
        ),
        TextButton(
          onPressed: () => setState(() => _isRegister = !_isRegister),
          child: Text(
            _isRegister ? 'Sign In' : 'Register',
            style: GoogleFonts.openSans(
              fontSize: isMobile ? 16 : 20, // Reduced from 20 to 16
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