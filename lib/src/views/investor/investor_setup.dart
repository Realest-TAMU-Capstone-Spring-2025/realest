import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class InvestorSetupPage extends StatefulWidget {
  const InvestorSetupPage({Key? key}) : super(key: key);

  @override
  _InvestorSetupPageState createState() => _InvestorSetupPageState();
}

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
  String? _tempPassword; // To store the temp password for re-authentication

  static const Color neonPurple = Color(0xFFa78cde);

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
          _tempPassword = data['tempPassword']; // Fetch temp password for re-authentication
        });
      }
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

  void _saveInvestorData() async {
    // Validate passwords
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Passwords do not match.";
      });
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Please enter a new password.";
      });
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
        // Re-authenticate the user before updating the password
        if (_tempPassword == null || _tempPassword!.isEmpty) {
          throw Exception("Temporary password not found. Please contact support.");
        }

        await _reAuthenticateUser(_contactEmailController.text.trim(), _tempPassword!);

        // Update the user's password in Firebase Auth
        await user.updatePassword(_newPasswordController.text.trim());

        // Clear the tempPassword in Firestore after successful password update
        await _firestore.collection('investors').doc(uid).update({
          'tempPassword': null, // Invalidate temp password
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

        // Update the completedSetup flag in the users collection
        await _firestore.collection('users').doc(uid).update({
          'completedSetup': true,
        });

        // Update or set investor data (realtorId preserved from invite)
        await _firestore.collection('investors').doc(uid).set({
          'uid': uid,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'contactEmail': _contactEmailController.text.trim(),
          'contactPhone': _contactPhoneController.text.trim(),
          'profilePicUrl': profilePicUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Update',
          'notes': 'Account Created',
        }, SetOptions(merge: true)); // Merge to preserve existing realtorId

        if (mounted) {
          context.go('/investorHome');
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
        bool obscureText = false,
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
            child: _buildTextField(_firstNameController, "First Name", isMobile: isMobile),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: _buildTextField(_lastNameController, "Last Name", isMobile: isMobile),
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
      ),
      SizedBox(height: isMobile ? 12 : 16),
      _buildTextField(
        _contactPhoneController,
        "Contact Phone",
        keyboardType: TextInputType.phone,
        isMobile: isMobile,
      ),
      SizedBox(height: isMobile ? 12 : 16),
      _buildTextField(
        _newPasswordController,
        "New Password",
        obscureText: true,
        isMobile: isMobile,
      ),
      SizedBox(height: isMobile ? 12 : 16),
      _buildTextField(
        _confirmPasswordController,
        "Confirm Password",
        obscureText: true,
        isMobile: isMobile,
      ),
      SizedBox(height: isMobile ? 20 : 30),
      Center(
        child: SizedBox(
          width: isMobile ? 400 : 500,
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