import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';

class RealtorSetupPage extends StatefulWidget {
  const RealtorSetupPage({Key? key}) : super(key: key);

  @override
  _RealtorSetupPageState createState() => _RealtorSetupPageState();
}

class _RealtorSetupPageState extends State<RealtorSetupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _agencyNameController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _profileImageBytes;

  // Validation error states
  String? _firstNameError;
  String? _lastNameError;
  String? _agencyNameError;
  String? _licenseNumberError;
  String? _contactEmailError;
  String? _contactPhoneError;
  String? _addressError;

  static const Color neonPurple = Color(0xFFa78cde);

  @override
  void initState() {
    super.initState();
    User? currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email != null) {
      _contactEmailController.text = currentUser.email!;
    }

    // Add listeners for real-time validation
    _firstNameController.addListener(_validateFirstName);
    _lastNameController.addListener(_validateLastName);
    _agencyNameController.addListener(_validateAgencyName);
    _licenseNumberController.addListener(_validateLicenseNumber);
    _contactEmailController.addListener(_validateContactEmail);
    _contactPhoneController.addListener(_validateContactPhone);
    _addressController.addListener(_validateAddress);
  }

  @override
  void dispose() {
    // Remove listeners
    _firstNameController.removeListener(_validateFirstName);
    _lastNameController.removeListener(_validateLastName);
    _agencyNameController.removeListener(_validateAgencyName);
    _licenseNumberController.removeListener(_validateLicenseNumber);
    _contactEmailController.removeListener(_validateContactEmail);
    _contactPhoneController.removeListener(_validateContactPhone);
    _addressController.removeListener(_validateAddress);

    // Dispose controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _agencyNameController.dispose();
    _licenseNumberController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

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

  void _validateAgencyName() {
    final value = _agencyNameController.text.trim();
    setState(() {
      if (value.isEmpty) {
        _agencyNameError = 'Agency name is required';
      } else if (value.length < 3) {
        _agencyNameError = 'Agency name must be at least 3 characters';
      } else {
        _agencyNameError = null;
      }
    });
  }

  void _validateLicenseNumber() {
    final value = _licenseNumberController.text.trim();
    setState(() {
      if (value.isEmpty) {
        _licenseNumberError = 'License number is required';
      } else if (value.length < 5) {
        _licenseNumberError = 'License number must be at least 5 characters';
      } else if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
        _licenseNumberError = 'License number must be alphanumeric';
      } else {
        _licenseNumberError = null;
      }
    });
  }

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

  void _validateContactPhone() {
    final value = _contactPhoneController.text.trim();
    // Normalize phone number by removing non-digits
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

  void _validateAddress() {
    final value = _addressController.text.trim();
    setState(() {
      if (value.isEmpty) {
        _addressError = 'Address is required';
      } else if (value.length < 5) {
        _addressError = 'Address must be at least 5 characters';
      } else {
        _addressError = null;
      }
    });
  }

  List<String> _validateFields() {
    List<String> errors = [];
    _validateFirstName();
    _validateLastName();
    _validateAgencyName();
    _validateLicenseNumber();
    _validateContactEmail();
    _validateContactPhone();
    _validateAddress();

    if (_firstNameError != null) errors.add(_firstNameError!);
    if (_lastNameError != null) errors.add(_lastNameError!);
    if (_agencyNameError != null) errors.add(_agencyNameError!);
    if (_licenseNumberError != null) errors.add(_licenseNumberError!);
    if (_contactEmailError != null) errors.add(_contactEmailError!);
    if (_contactPhoneError != null) errors.add(_contactPhoneError!);
    if (_addressError != null) errors.add(_addressError!);

    return errors;
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
      });
    }
  }

  void _saveRealtorData() async {
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

        await _firestore.collection('realtors').doc(uid).set({
          'uid': uid,
          'firstName': _firstNameController.text.trim(),
          'lastName': _firstNameController.text.trim(),
          'agencyName': _agencyNameController.text.trim(),
          'licenseNumber': _licenseNumberController.text.trim(),
          'contactEmail': _contactEmailController.text.trim(),
          'contactPhone': _contactPhoneController.text.trim(),
          'address': _addressController.text.trim(),
          'profilePicUrl': profilePicUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'cashFlowDefaults': {
            'useLoan': true,
            'downPayment': 0.20,
            'interestRate': 0.06,
            'loanTerm': 30,
            'closingCost': 6000,
            'needsRepair': false,
            'repairCost': 0,
            'valueAfterRepair': 0,
            'propertyTax': 0.015,
            'insurance': 0.01,
            'defaultHOA': 50,
            'maintenance': 0.03,
            'otherCosts': 500,
            'vacancyRate': 0.05,
            'otherIncome': 0,
            'managementFee': 0.00,
            'valueAppreciation': 0.03,
            'holdingLength': 20,
            'costToSell': 0.08
          }
        });

        if (mounted) {
          context.go("/home");
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = "Error saving data: $e";
          });
          print("Save error: $e");
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

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        TextInputType keyboardType = TextInputType.text,
        bool readOnly = false,
        required bool isMobile,
        String? error,
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
          width: isMobile ? 400 : 1000,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
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

  // Mobile layout with left-aligned logo in scrolling content
  Widget _buildMobileLayout(bool isMobile) {
    return Container(
      color: const Color(0xFF1f1e25),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: SizedBox(
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo aligned to the left
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

  // Desktop layout with left-aligned logo in scrolling content
  Widget _buildFormColumn(bool isMobile) {
    return Container(
      color: const Color(0xFF1f1e25),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(left: 100, right: 100, top: 20, bottom: 100),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: SizedBox(
                width: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo aligned to the left
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

  // Form children (without logo)
  List<Widget> _buildFormChildren(bool isMobile) {
    return [
      Center(
        child: Text(
          textAlign: TextAlign.center,
          'Complete Your Realtor Profile',
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
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              _agencyNameController,
              "Agency Name",
              isMobile: isMobile,
              error: _agencyNameError,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: _buildTextField(
              _licenseNumberController,
              "License Number",
              isMobile: isMobile,
              error: _licenseNumberError,
            ),
          ),
        ],
      ),
      SizedBox(height: isMobile ? 12 : 16),
      _buildTextField(
        _contactEmailController,
        "Contact Email",
        keyboardType: TextInputType.emailAddress,
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
      _buildTextField(
        _addressController,
        "Address",
        isMobile: isMobile,
        error: _addressError,
      ),
      SizedBox(height: isMobile ? 20 : 30),
      Center(
        child: SizedBox(
          width: isMobile ? 400 : 1000,
          height: isMobile ? 45 : 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveRealtorData,
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
                : const Text('COMPLETE SETUP'),
          ),
        ),
      ),
    ];
  }
}