// Importing necessary Flutter and third-party packages
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase authentication for user sign-in and sign-up
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore for storing user data
import 'package:provider/provider.dart'; // State management provider for managing user data
import '../../user_provider.dart'; // Custom provider for user data management
import 'package:google_fonts/google_fonts.dart'; // Custom fonts for UI styling
import "package:realest/services/auth_service.dart";

// Stateful widget for the custom login page
class CustomLoginPage extends StatefulWidget {
  const CustomLoginPage({Key? key}) : super(key: key);

  @override
  _CustomLoginPageState createState() => _CustomLoginPageState();
}

// State class that holds login and registration logic
class _CustomLoginPageState extends State<CustomLoginPage> {
  bool _isRegister = false; // Determines if the user is in sign-up mode
  final _emailController = TextEditingController(); // Controller for email input
  final _passwordController = TextEditingController(); // Controller for password input
  final _confirmPasswordController = TextEditingController(); // Controller for confirming password in registration
  bool _isLoading = false; // State to show loading indicator
  String? _errorMessage; // Holds error messages from authentication
  String _selectedRole = 'investor'; // Default role


  // Firebase authentication and Firestore database instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final authService = AuthService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );


  // Dispose controllers when the widget is removed from the tree to prevent memory leaks
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  // Main authentication method to handle login and registration
  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Reset error message
    });
    try {
      if (_isRegister) {
        await authService.createAccount(
            email: _emailController.text,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            role: _selectedRole);
      } else {
        await authService.signInWithEmail(_emailController.text, _passwordController.text);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getAuthErrorMessage(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }


  // Handles sign-in using email and password
  Future<void> _signInWithEmail() async {
    try {
      // Authenticate the user with Firebase
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Retrieve the user's role from Firestore
      String uid = userCredential.user!.uid;

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists && mounted) {
        setState(() {
          _selectedRole = userDoc['role'];
        });

        // Navigate based on user role
        if (_selectedRole == "realtor") {
          Provider.of<UserProvider>(context, listen: false).fetchRealtorData();

          Navigator.pushNamedAndRemoveUntil(context, "/realtorHome", (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, "/investorHome", (route) => false);
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


  // Handles user registration
  Future<void> _createAccount() async {
    // Ensure passwords match before proceeding
    if (_passwordController.text != _confirmPasswordController.text) {
      throw FirebaseAuthException(code: 'password-mismatch', message: 'Passwords do not match');
    }
    // Create a new user account in Firebase
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // Store user details in Firestore
    await _createUserDocument(userCredential.user!);
    _navigateAfterRegistration();
  }


  // Creates a Firestore document for the new user
  Future<void> _createUserDocument(User user) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'role': _selectedRole,
      'createdAt': FieldValue.serverTimestamp(), // Stores the time of registration
      'completedSetup': false, // Indicates if setup is completed
    });
  }


  // Navigate to the correct page after successful registration
  void _navigateAfterRegistration() {
    if (_selectedRole == "investor") {
      Navigator.pushNamedAndRemoveUntil(context, "/investorHome", (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, "/realtorSetup", (route) => false);
    }
  }


  // Maps Firebase authentication error codes to user-friendly messages
  String _getAuthErrorMessage(FirebaseAuthException e) {
    print(e.code); // Debugging
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


  // Builds the UI for the login page
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


          // Semi-transparent white overlay for readability
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
                      _isRegister ? 'Please Sign Up' : 'Please Sign In',
                      style: GoogleFonts.poppins(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
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


  // Function to create text fields
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


  // Builds the login/register button
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


  // Switches between login and register modes
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
