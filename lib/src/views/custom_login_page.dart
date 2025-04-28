import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:realest/user_provider.dart';
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

  // Validation states
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  double _passwordStrength = 0.0;
  bool _showPasswordStrength = false;

  // Password requirement states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  // Password visibility states
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final queryParams = GoRouterState.of(context).uri.queryParameters;
      setState(() {
        _isRegister = queryParams['register'] == 'true';
      });
    });

    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _emailController.removeListener(_validateEmail);
    _passwordController.removeListener(_validatePassword);
    _confirmPasswordController.removeListener(_validateConfirmPassword);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() {
      _emailError = email.isEmpty
          ? 'Email is required'
          : !emailRegex.hasMatch(email)
          ? 'Enter a valid email'
          : null;
    });
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _showPasswordStrength = _isRegister && password.isNotEmpty;
      if (password.isEmpty) {
        _passwordError = 'Password is required';
        _hasMinLength = false;
        _hasUppercase = false;
        _hasLowercase = false;
        _hasNumber = false;
        _hasSpecialChar = false;
        _passwordStrength = 0.0;
      } else if (_isRegister) {
        _hasMinLength = password.length >= 8;
        _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
        _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
        _hasNumber = RegExp(r'[0-9]').hasMatch(password);
        _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

        if (!_hasMinLength) {
          _passwordError = 'Password must be at least 8 characters';
        } else if (!_hasUppercase) {
          _passwordError = 'Password must contain an uppercase letter';
        } else if (!_hasLowercase) {
          _passwordError = 'Password must contain a lowercase letter';
        } else if (!_hasNumber) {
          _passwordError = 'Password must contain a number';
        } else if (!_hasSpecialChar) {
          _passwordError = 'Password must contain a special character';
        } else {
          _passwordError = null;
        }

        _passwordStrength = _calculatePasswordStrength(password);
      } else {
        _passwordError = null;
        _hasMinLength = false;
        _hasUppercase = false;
        _hasLowercase = false;
        _hasNumber = false;
        _hasSpecialChar = false;
        _passwordStrength = 0.0;
      }
    });
  }

  double _calculatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    return strength / 5.0;
  }

  void _validateConfirmPassword() {
    final confirmPassword = _confirmPasswordController.text;
    setState(() {
      _confirmPasswordError = _isRegister && confirmPassword.isEmpty
          ? 'Confirm password is required'
          : _isRegister && confirmPassword != _passwordController.text
          ? 'Passwords do not match'
          : null;
    });
  }

  void _resetFields() {
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _showPasswordStrength = false;
      _hasMinLength = false;
      _hasUppercase = false;
      _hasLowercase = false;
      _hasNumber = false;
      _hasSpecialChar = false;
      _passwordStrength = 0.0;
      _obscurePassword = true;
      _obscureConfirmPassword = true;
    });
  }

  List<String> _validateFields() {
    List<String> errors = [];
    _validateEmail();
    _validatePassword();
    if (_isRegister) _validateConfirmPassword();

    if (_emailError != null) errors.add(_emailError!);
    if (_passwordError != null) errors.add(_passwordError!);
    if (_isRegister && _confirmPasswordError != null) errors.add(_confirmPasswordError!);

    return errors;
  }

  Future<void> _authenticate() async {
    List<String> errors = _validateFields();
    if (errors.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Validation Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors.map((error) => Text('• $error')).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

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
      QuerySnapshot investorQuery = await _firestore
          .collection('investors')
          .where('contactEmail', isEqualTo: _emailController.text.trim())
          .where('tempPassword', isEqualTo: _passwordController.text.trim())
          .limit(1)
          .get();

      if (investorQuery.docs.isNotEmpty) {
        DocumentSnapshot investorDoc = investorQuery.docs.first;
        String uid = investorDoc.id;

        await _firestore.collection('users').doc(uid).set({
          'email': _emailController.text.trim(),
          'role': 'investor',
          'createdAt': FieldValue.serverTimestamp(),
          'completedSetup': false,
        }, SetOptions(merge: true));

        Provider.of<UserProvider>(context, listen: false).fetchUserData();
        if (mounted) context.go('/setup');
      } else {
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
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    await _createUserDocument(userCredential.user!);
    Provider.of<UserProvider>(context, listen: false).fetchUserData();
    _navigateAfterRegistration();
  }

  Future<void> _createUserDocument(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'role': 'realtor',
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

  List<Widget> _buildFormChildren(Color neonPurple, bool isMobile) {
    const baseDelay = 300;
    const delayIncrement = 200;
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
        child: _buildAlignedField(
          'Email',
          _emailController,
          false,
          false,
          isMobile,
          error: _emailError,
        ),
      ),
    );
    index++;

    children.add(SizedBox(height: isMobile ? 12 : 16));

    children.add(
      DelayedFadeIn(
        delay: Duration(milliseconds: baseDelay + index * delayIncrement),
        duration: const Duration(milliseconds: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlignedField(
              'Password',
              _passwordController,
              _obscurePassword,
              !_isRegister,
              isMobile,
              error: _passwordError,
              toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
              isPassword: true,
            ),
            if (_showPasswordStrength) ...[
              const SizedBox(height: 8),
              _buildPasswordRequirements(isMobile),
              const SizedBox(height: 8),
              _buildPasswordStrengthBar(isMobile),
            ],
          ],
        ),
      ),
    );
    index++;

    if (_isRegister) {
      children.add(SizedBox(height: isMobile ? 12 : 16));
      children.add(
        DelayedFadeIn(
          delay: Duration(milliseconds: baseDelay + index * delayIncrement),
          duration: const Duration(milliseconds: 1000),
          child: _buildAlignedField(
            'Confirm Password',
            _confirmPasswordController,
            _obscureConfirmPassword,
            true,
            isMobile,
            error: _confirmPasswordError,
            toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            isPassword: true,
          ),
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

  Widget _buildAlignedField(
      String label,
      TextEditingController controller,
      bool obscure,
      bool isLastField,
      bool isMobile, {
        String? error,
        VoidCallback? toggleObscure,
        bool isPassword = false,
      }) {
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
          child: _buildTextField(
            controller,
            obscure,
            isLastField,
            isMobile,
            error,
            toggleObscure,
            isPassword,
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: TextStyle(color: Colors.red, fontSize: isMobile ? 12 : 14),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      bool obscure,
      bool isLastField,
      bool isMobile,
      String? error,
      VoidCallback? toggleObscure,
      bool isPassword,
      ) {
    const Color neonPurple = Color(0xFFa78cde);
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[900],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(
            color: error != null ? Colors.red : neonPurple,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: BorderSide(
            color: error != null ? Colors.red : neonPurple,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.0),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
          ),
          onPressed: toggleObscure,
        )
            : null,
      ),
      style: TextStyle(color: Colors.white, fontSize: isMobile ? 14 : 16),
      obscureText: obscure,
      keyboardType: isPassword ? TextInputType.text : TextInputType.emailAddress,
      textInputAction: isLastField ? TextInputAction.done : TextInputAction.next,
      onSubmitted: (value) {
        if (isLastField) {
          _authenticate();
        }
      },
    );
  }

  Widget _buildPasswordRequirements(bool isMobile) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildRequirementText(
          _hasMinLength ? '✔️ 8 characters' : 'x 8 characters',
          _hasMinLength,
          isMobile,
        ),
        _buildRequirementText(
          _hasUppercase ? '✔️ Uppercase' : 'x Uppercase',
          _hasUppercase,
          isMobile,
        ),
        _buildRequirementText(
          _hasLowercase ? '✔️ Lowercase' : 'x Lowercase',
          _hasLowercase,
          isMobile,
        ),
        _buildRequirementText(
          _hasNumber ? '✔️ Number' : 'x Number',
          _hasNumber,
          isMobile,
        ),
        _buildRequirementText(
          _hasSpecialChar ? '✔️ Special Character' : 'x Special character',
          _hasSpecialChar,
          isMobile,
        ),
      ],
    );
  }

  Widget _buildRequirementText(String text, bool isMet, bool isMobile) {
    return Text(
      text,
      style: TextStyle(
        color: isMet ? Colors.green : Colors.red,
        fontSize: isMobile ? 12 : 14,
      ),
    );
  }

  Widget _buildPasswordStrengthBar(bool isMobile) {
    Color strengthColor;
    String strengthText;
    if (_passwordStrength < 0.4) {
      strengthColor = Colors.red;
      strengthText = 'Weak';
    } else if (_passwordStrength < 0.8) {
      strengthColor = Colors.yellow;
      strengthText = 'Medium';
    } else {
      strengthColor = Colors.green;
      strengthText = 'Strong';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: _passwordStrength,
          backgroundColor: Colors.grey[700],
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          minHeight: 5,
        ),
        const SizedBox(height: 4),
        Text(
          'Password Strength: $strengthText',
          style: TextStyle(
            color: strengthColor,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
      ],
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
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8.0,
      children: [
        Text(
          _isRegister ? 'Already have an account?' : 'Don\'t have an account?',
          style: GoogleFonts.openSans(fontSize: isMobile ? 16 : 20, color: Colors.white),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isRegister = !_isRegister;
              _resetFields();
            });
          },
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