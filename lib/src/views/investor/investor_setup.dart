import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

/// InvestorSetupPage allows an investor to set up their profile, including contact info and password.
class InvestorSetupPage extends StatefulWidget {
  const InvestorSetupPage({Key? key}) : super(key: key);

  @override
  _InvestorSetupPageState createState() => _InvestorSetupPageState();
}

/// State for InvestorSetupPage. Manages form fields, validations, and profile updates.
class _InvestorSetupPageState extends State<InvestorSetupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _profileImageBytes;
  String? _tempPassword;

  // Validation error states
  String? _firstNameError;
  String? _lastNameError;
  String? _contactEmailError;
  String? _contactPhoneError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  // Password visibility states
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Password requirement states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _showPasswordStrength = false;
  double _passwordStrength = 0.0;

  static const Color neonPurple = Color(0xFFa78cde);

  @override
  void initState() {
    super.initState();
    _prefillUserData();

    // Add listeners for real-time validation
    _firstNameController.addListener(_validateFirstName);
    _lastNameController.addListener(_validateLastName);
    _contactEmailController.addListener(_validateContactEmail);
    _contactPhoneController.addListener(_validateContactPhone);
    _newPasswordController.addListener(_validateNewPassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    // Remove listeners
    _firstNameController.removeListener(_validateFirstName);
    _lastNameController.removeListener(_validateLastName);
    _contactEmailController.removeListener(_validateContactEmail);
    _contactPhoneController.removeListener(_validateContactPhone);
    _newPasswordController.removeListener(_validateNewPassword);
    _confirmPasswordController.removeListener(_validateConfirmPassword);

    // Dispose controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Prefills form fields with existing investor data if available.
  Future<void> _prefillUserData() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email != null) {
      _contactEmailController.text = currentUser.email!;
      QuerySnapshot investorQuery = await _firestore
          .collection('investors')
          .where('contactEmail', isEqualTo: currentUser.email!)
          .limit(1)
          .get();

      if (investorQuery.docs.isNotEmpty) {
        DocumentSnapshot investorDoc = investorQuery.docs.first;
        Map<String, dynamic> data = investorDoc.data() as Map<String, dynamic>;
        setState(() {
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _tempPassword = data['tempPassword'];
        });
      }
    }
  }

  /// Validates first name input.
  void _validateFirstName() {
    final value = _firstNameController.text.trim();
    setState(() {
      if (value.isEmpty) {
        _firstNameError = 'First name is required';
      } else {
        _firstNameError = null;
      }
    });
  }

  /// Validates last name input.
  void _validateLastName() {
    final value = _lastNameController.text.trim();
    setState(() {
      if (value.isEmpty) {
        _lastNameError = 'Last name is required';
      } else {
        _lastNameError = null;
      }
    });
  }

  /// Validates email format and presence.
  void _validateContactEmail() {
    final value = _contactEmailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() {
      if (value.isEmpty) {
        _contactEmailError = 'Email is required';
      } else if (!emailRegex.hasMatch(value)) {
        _contactEmailError = 'Enter a valid email';
      } else {
        _contactEmailError = null;
      }
    });
  }

  /// Validates phone number to ensure it's 10 digits.
  void _validateContactPhone() {
    final value = _contactPhoneController.text.trim();
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      if (value.isEmpty) {
        _contactPhoneError = 'Phone number is required';
      } else if (digits.length != 10) {
        _contactPhoneError = 'Phone number must be 10 digits';
      } else {
        _contactPhoneError = null;
      }
    });
  }

  /// Validates password based on strength requirements.
  void _validateNewPassword() {
    final password = _newPasswordController.text;
    setState(() {
      _showPasswordStrength = password.isNotEmpty;
      if (password.isEmpty) {
        _newPasswordError = 'Password is required';
        _hasMinLength = false;
        _hasUppercase = false;
        _hasLowercase = false;
        _hasNumber = false;
        _hasSpecialChar = false;
        _passwordStrength = 0.0;
      } else {
        _hasMinLength = password.length >= 8;
        _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
        _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
        _hasNumber = RegExp(r'[0-9]').hasMatch(password);
        _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

        if (!_hasMinLength) {
          _newPasswordError = 'Password must be at least 8 characters';
        } else if (!_hasUppercase) {
          _newPasswordError = 'Password must contain an uppercase letter';
        } else if (!_hasLowercase) {
          _newPasswordError = 'Password must contain a lowercase letter';
        } else if (!_hasNumber) {
          _newPasswordError = 'Password must contain a number';
        } else if (!_hasSpecialChar) {
          _newPasswordError = 'Password must contain a special character';
        } else {
          _newPasswordError = null;
        }

        _passwordStrength = _calculatePasswordStrength(password);
      }
    });
  }

  /// Calculates and returns password strength as a score.
  double _calculatePasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;
    return strength / 5.0;
  }

  /// Validates that confirm password matches the new password.
  void _validateConfirmPassword() {
    final confirmPassword = _confirmPasswordController.text;
    setState(() {
      if (confirmPassword.isEmpty) {
        _confirmPasswordError = 'Confirm password is required';
      } else if (confirmPassword != _newPasswordController.text) {
        _confirmPasswordError = 'Passwords do not match';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  /// Runs all validators and collects form errors.
  List<String> _validateFields() {
    List<String> errors = [];
    _validateFirstName();
    _validateLastName();
    _validateContactEmail();
    _validateContactPhone();
    _validateNewPassword();
    _validateConfirmPassword();

    if (_firstNameError != null) errors.add(_firstNameError!);
    if (_lastNameError != null) errors.add(_lastNameError!);
    if (_contactEmailError != null) errors.add(_contactEmailError!);
    if (_contactPhoneError != null) errors.add(_contactPhoneError!);
    if (_newPasswordError != null) errors.add(_newPasswordError!);
    if (_confirmPasswordError != null) errors.add(_confirmPasswordError!);

    return errors;
  }

  /// Allows user to pick a profile picture from their device.
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
      });
    }
  }

  /// Reauthenticates user using email and temporary password.
  Future<void> _reAuthenticateUser(String email, String tempPassword) async {
    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: tempPassword,
      );
      await _auth.currentUser!.reauthenticateWithCredential(credential);
    } catch (e) {
      throw Exception("Re-authentication failed: $e");
    }
  }

  /// Validates form and saves investor data to Firestore.
  void _saveInvestorData() async {
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

    User? user = _auth.currentUser;
    if (user != null) {
      String uid = user.uid;

      try {
        if (_tempPassword == null || _tempPassword!.isEmpty) {
          throw Exception("Temporary password not found. Please contact support.");
        }

        await _reAuthenticateUser(_contactEmailController.text.trim(), _tempPassword!);

        await user.updatePassword(_newPasswordController.text.trim());

        await _firestore.collection('investors').doc(uid).update({
          'tempPassword': null,
        });

        String profilePicUrl = '';
        if (_profileImageBytes != null) {
          Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('Profile_Pics')
              .child('$uid.jpg');
          UploadTask uploadTask = storageRef.putData(
            _profileImageBytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          TaskSnapshot snapshot = await uploadTask;
          profilePicUrl = await snapshot.ref.getDownloadURL();
        }

        await _firestore.collection('users').doc(uid).update({
          'completedSetup': true,
        });

        await _firestore.collection('investors').doc(uid).set({
          'uid': uid,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'contactEmail': _contactEmailController.text.trim(),
          'contactPhone': _contactPhoneController.text.trim(),
          'profilePicUrl': profilePicUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'qualified-lead',
          'notes': 'Account Created',
        }, SetOptions(merge: true));

        if (mounted) {
          context.go('/home');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = "Error saving data: $e";
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "No authenticated user found.";
        });
      }
    }
  }

  /// Builds a reusable styled text field.
  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        TextInputType keyboardType = TextInputType.text,
        bool readOnly = false,
        bool obscureText = false,
        required bool isMobile,
        String? error,
        VoidCallback? toggleObscure,
        bool isPassword = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: isMobile ? 400 : 800,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            obscureText: obscureText,
            style: TextStyle(color: Colors.white, fontSize: isMobile ? 14 : 16),
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
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: toggleObscure,
              )
                  : null,
            ),
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

  /// Builds password requirements checklist widget.
  Widget _buildPasswordRequirements(bool isMobile) {
    return Visibility(
      visible: _showPasswordStrength,
      child: Wrap(
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
            _hasSpecialChar ? '✔️ Special Character' : 'x Special Character',
            _hasSpecialChar,
            isMobile,
          ),
        ],
      ),
    );
  }

  /// Builds a single requirement text widget.
  Widget _buildRequirementText(String text, bool isMet, bool isMobile) {
    return Text(
      text,
      style: TextStyle(
        color: isMet ? Colors.green : Colors.red,
        fontSize: isMobile ? 12 : 14,
      ),
    );
  }

  /// Displays a password strength bar with label.
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

    return Visibility(
      visible: _showPasswordStrength,
      child: Column(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: Colors.black,
      body: isMobile
          ? _buildMobileLayout(isMobile)
          : Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildFormColumn(isMobile),
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
    );
  }

  /// Builds layout for mobile screens.
  Widget _buildMobileLayout(bool isMobile) {
    return Container(
      color: const Color(0xFF1f1e25),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: SizedBox(
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                    SizedBox(height: isMobile ? 20 : 40),
                    ..._buildFormChildren(isMobile),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds layout for larger desktop/tablet screens.
  Widget _buildFormColumn(bool isMobile) {
    return Container(
      color: const Color(0xFF1f1e25),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(left: 100, right: 100, top: 20, bottom: 100),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: SizedBox(
                width: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                    SizedBox(height: isMobile ? 20 : 40),
                    ..._buildFormChildren(isMobile),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Returns all form fields as a list of widgets.
  List<Widget> _buildFormChildren(bool isMobile) {
    return [
      Center(
        child: Text(
          textAlign: TextAlign.center,
          'Set Up Your Investor Profile',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 28 : 32,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 10),
      Center(
        child: Text(
          _errorMessage ?? 'Complete your profile',
          style: _errorMessage != null
              ? TextStyle(color: Colors.red, fontSize: isMobile ? 12 : 14)
              : GoogleFonts.poppins(fontSize: isMobile ? 16 : 20, color: Colors.white70),
        ),
      ),
      SizedBox(height: isMobile ? 20 : 40),
      Center(
        child: GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: isMobile ? 50 : 60,
            backgroundColor: Colors.black,
            backgroundImage: _profileImageBytes != null ? MemoryImage(_profileImageBytes!) : null,
            child: _profileImageBytes == null
                ? Icon(Icons.camera_alt, size: isMobile ? 30 : 40, color: Colors.white70)
                : null,
          ),
        ),
      ),
      SizedBox(height: isMobile ? 20 : 30),
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              _firstNameController,
              "First Name",
              isMobile: isMobile,
              error: _firstNameError,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: _buildTextField(
              _lastNameController,
              "Last Name",
              isMobile: isMobile,
              error: _lastNameError,
            ),
          ),
        ],
      ),
      SizedBox(height: isMobile ? 12 : 16),
      _buildTextField(
        _contactEmailController,
        "Contact Email",
        keyboardType: TextInputType.emailAddress,
        readOnly: true,
        isMobile: isMobile,
        error: _contactEmailError,
      ),
      SizedBox(height: isMobile ? 12 : 16),
      _buildTextField(
        _contactPhoneController,
        "Contact Phone",
        keyboardType: TextInputType.phone,
        isMobile: isMobile,
        error: _contactPhoneError,
      ),
      SizedBox(height: isMobile ? 12 : 16),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            _newPasswordController,
            "New Password",
            obscureText: _obscureNewPassword,
            isMobile: isMobile,
            error: _newPasswordError,
            toggleObscure: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
            isPassword: true,
          ),
          _buildPasswordRequirements(isMobile),
          const SizedBox(height: 8),
          _buildPasswordStrengthBar(isMobile),
        ],
      ),
      SizedBox(height: isMobile ? 12 : 16),
      _buildTextField(
        _confirmPasswordController,
        "Confirm Password",
        obscureText: _obscureConfirmPassword,
        isMobile: isMobile,
        error: _confirmPasswordError,
        toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        isPassword: true,
      ),
      SizedBox(height: isMobile ? 20 : 30),
      Center(
        child: SizedBox(
          width: isMobile ? 400 : 800,
          height: isMobile ? 45 : 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveInvestorData,
            style: ElevatedButton.styleFrom(
              backgroundColor: neonPurple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
              textStyle: GoogleFonts.poppins(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('SAVE & CONTINUE'),
          ),
        ),
      ),
    ];
  }
}