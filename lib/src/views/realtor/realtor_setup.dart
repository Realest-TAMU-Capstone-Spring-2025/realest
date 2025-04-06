import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';
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
  final TextEditingController _invitationCodeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _profileImageBytes;

  static const Color neonPurple = Color(0xFFa78cde);

  String _generateInvitationCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        8,
            (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _invitationCodeController.text = _generateInvitationCode();
    User? currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email != null) {
      _contactEmailController.text = currentUser.email!;
    }
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
          'lastName': _lastNameController.text.trim(),
          'agencyName': _agencyNameController.text.trim(),
          'licenseNumber': _licenseNumberController.text.trim(),
          'contactEmail': _contactEmailController.text.trim(),
          'contactPhone': _contactPhoneController.text.trim(),
          'address': _addressController.text.trim(),
          'profilePicUrl': profilePicUrl,
          'invitationCode': _invitationCodeController.text,
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
          context.go("/realtorDashboard");
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
          width: isMobile ? 400 : 700,
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
                borderSide: const BorderSide(color: neonPurple, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.0),
                borderSide: const BorderSide(color: neonPurple, width: 2),
              ),
            ),
          ),
        ),
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
                  crossAxisAlignment: CrossAxisAlignment.start, // Aligns logo and content to the left
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
                    SizedBox(height: isMobile ? 20 : 40), // Space after logo
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
                  crossAxisAlignment: CrossAxisAlignment.start, // Aligns logo and content to the left
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
                    SizedBox(height: isMobile ? 20 : 40), // Space after logo
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
            child: _buildTextField(_firstNameController, "First Name", isMobile: isMobile),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: _buildTextField(_lastNameController, "Last Name", isMobile: isMobile),
          ),
        ],
      ),
      SizedBox(height: isMobile ? 12 : 16),
      Row(
        children: [
          Expanded(
            child: _buildTextField(_agencyNameController, "Agency Name", isMobile: isMobile),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: _buildTextField(_licenseNumberController, "License Number", isMobile: isMobile),
          ),
        ],
      ),
      SizedBox(height: isMobile ? 12 : 16),
      _buildTextField(
        _contactEmailController,
        "Contact Email",
        keyboardType: TextInputType.emailAddress,
        isMobile: isMobile,
      ),
      SizedBox(height: isMobile ? 12 : 16),
      _buildTextField(
        _contactPhoneController,
        "Contact Phone",
        keyboardType: TextInputType.phone,
        isMobile: isMobile,
      ),
      SizedBox(height: isMobile ? 12 : 16),
      _buildTextField(_addressController, "Address", isMobile: isMobile),
      SizedBox(height: isMobile ? 12 : 16),
      _buildTextField(
        _invitationCodeController,
        "Invitation Code (Pre filled)",
        readOnly: true,
        isMobile: isMobile,
      ),
      SizedBox(height: isMobile ? 20 : 30),
      Center(
        child: SizedBox(
          width: isMobile ? 400 : 700,
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