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
  final List<TextEditingController> _invitationCodeControllers =
  List.generate(8, (_) => TextEditingController());

  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _profileImageBytes;

  String? _verifiedRealtorId;
  String? _verifiedRealtorName;
  String? _verifiedRealtorProfilePicUrl;

  static const Color neonPurple = Color(0xFFa78cde);

  @override
  void initState() {
    super.initState();
    User? currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email != null) {
      _contactEmailController.text = currentUser.email!;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    for (var controller in _invitationCodeControllers) {
      controller.dispose();
    }
    super.dispose();
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

  String _getInvitationCode() {
    String code = '';
    for (var controller in _invitationCodeControllers) {
      code += controller.text.trim();
    }
    return code;
  }

  Future<void> _verifyInvitationCode() async {
    final code = _getInvitationCode();
    if (code.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Invitation code is invalid. Please enter an 8-character code.",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {
        _errorMessage = null;
      });
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('realtors')
          .where('invitationCode', isEqualTo: code)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Realtor not found. Please check your invitation code.",
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {
          _errorMessage = null;
        });
        return;
      }

      final realtorDoc = querySnapshot.docs.first;
      final realtorData = realtorDoc.data() as Map<String, dynamic>;
      final realtorFirstName = realtorData['firstName'] ?? '';
      final realtorLastName = realtorData['lastName'] ?? '';
      final realtorProfilePicUrl = realtorData['profilePicUrl'] ?? '';
      final realtorId = realtorDoc.id;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text("Confirm Realtor", style: GoogleFonts.poppins(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (realtorProfilePicUrl != '')
                  CircleAvatar(
                    backgroundImage: NetworkImage(realtorProfilePicUrl),
                    radius: 80,
                  ),
                const SizedBox(height: 20),
                Text(
                  "$realtorFirstName $realtorLastName",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _verifiedRealtorId = realtorId;
                    _verifiedRealtorName = "$realtorFirstName $realtorLastName";
                    _verifiedRealtorProfilePicUrl = realtorProfilePicUrl;
                    _errorMessage = null;
                  });
                  Navigator.of(context).pop();
                },
                child: Text("Confirm", style: GoogleFonts.poppins(color: neonPurple)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Cancel", style: GoogleFonts.poppins(color: neonPurple)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = "Error verifying invitation code: $e";
      });
      print("Verification error: $e");
    }
  }

  void _saveInvestorData() async {
    if (_verifiedRealtorId == null) {
      setState(() {
        _errorMessage = "Please verify your invitation code to link a realtor before saving.";
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
          'realtorId': _verifiedRealtorId,
          'profilePicUrl': profilePicUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Update',
          'notes': 'Account Created',
        });

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
        required bool isMobile,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18, // Reduced from 18 to 16
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: isMobile ? 400 : 800, // Reduced width for mobile
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            style: TextStyle(color: Colors.white, fontSize: isMobile ? 14 : 16), // Reduced font size
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

  Widget _buildInvitationCodeInput(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(8, (index) {
            return Container(
              width: isMobile ? 40 : 50, // Reduced from 50 to 40
              height: isMobile ? 35 : 40, // Reduced from 40 to 35
              child: TextField(
                controller: _invitationCodeControllers[index],
                textAlign: TextAlign.center,
                maxLength: 1,
                style: TextStyle(color: Colors.white, fontSize: isMobile ? 14 : 16), // Reduced font size
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  counterText: "",
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(color: neonPurple, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    borderSide: const BorderSide(color: neonPurple, width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.length == 1 && index < 7) {
                    FocusScope.of(context).nextFocus();
                  } else if (value.isEmpty && index > 0) {
                    FocusScope.of(context).previousFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: isMobile ? 100 : 100, // Reduced from 100 to 80
          height: isMobile ? 50 : 45, // Reduced from 45 to 40
          child: ElevatedButton(
            onPressed: _verifyInvitationCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: neonPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
              textStyle: GoogleFonts.poppins(
                fontSize: isMobile ? 14 : 16, // Reduced from 16 to 14
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text("Verify"),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedRealtorInfo(bool isMobile) {
    if (_verifiedRealtorId == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Realtor:   ",
            style: GoogleFonts.poppins(fontSize: isMobile ? 20 : 24, color: Colors.white), // Reduced from 24 to 20
          ),
          if (_verifiedRealtorProfilePicUrl != null && _verifiedRealtorProfilePicUrl != '')
            CircleAvatar(
              backgroundImage: NetworkImage(_verifiedRealtorProfilePicUrl!),
              radius: isMobile ? 30 : 35, // Reduced from 35 to 30
            ),
          const SizedBox(width: 8),
          Text(
            _verifiedRealtorName ?? '',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 18 : 22, // Reduced from 22 to 18
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

  // Mobile layout with left-aligned logo in scrolling content
  Widget _buildMobileLayout(bool isMobile) {
    return Container(
      color: const Color(0xFF1f1e25),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0), // Reduced padding
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: SizedBox(
                width: 400, // Reduced max width for mobile
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Left-align logo and content
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
                            fontSize: isMobile ? 20 : 24, // Reduced from 24 to 20
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isMobile ? 20 : 40), // Reduced spacing
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
            // padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
            padding: const EdgeInsets.only(left: 100, right: 100, top: 20, bottom: 100),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: SizedBox(
                width: 500,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Left-align logo and content
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
          'Set Up Your Investor Profile',
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 28 : 32, // Reduced from 32 to 28
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
              ? TextStyle(color: Colors.red, fontSize: isMobile ? 12 : 14) // Reduced from 14 to 12
              : GoogleFonts.poppins(fontSize: isMobile ? 16 : 20, color: Colors.white70), // Reduced from 20 to 16
        ),
      ),
      SizedBox(height: isMobile ? 20 : 40), // Reduced spacing
      Center(
        child: GestureDetector(
          onTap: _pickImage,
          child: CircleAvatar(
            radius: isMobile ? 50 : 60, // Reduced from 60 to 50
            backgroundColor: Colors.black,
            backgroundImage: _profileImageBytes != null ? MemoryImage(_profileImageBytes!) : null,
            child: _profileImageBytes == null
                ? Icon(Icons.camera_alt, size: isMobile ? 30 : 40, color: Colors.white70) // Reduced from 40 to 30
                : null,
          ),
        ),
      ),
      SizedBox(height: isMobile ? 20 : 30), // Reduced spacing
      Row(
        children: [
          Expanded(
            child: _buildTextField(_firstNameController, "First Name", isMobile: isMobile),
          ),
          SizedBox(width: isMobile ? 12 : 16), // Reduced spacing
          Expanded(
            child: _buildTextField(_lastNameController, "Last Name", isMobile: isMobile),
          ),
        ],
      ),
      SizedBox(height: isMobile ? 12 : 16), // Reduced spacing
      _buildTextField(
        _contactEmailController,
        "Contact Email",
        keyboardType: TextInputType.emailAddress,
        isMobile: isMobile,
      ),
      SizedBox(height: isMobile ? 12 : 16), // Reduced spacing
      _buildTextField(
        _contactPhoneController,
        "Contact Phone",
        keyboardType: TextInputType.phone,
        isMobile: isMobile,
      ),
      SizedBox(height: isMobile ? 12 : 16), // Reduced spacing
      Center(
        child: Text(
          "Enter Your Invitation Code",
          style: GoogleFonts.poppins(
            fontSize: isMobile ? 16 : 18, // Reduced from 18 to 16
            color: Colors.white,
          ),
        ),
      ),
      SizedBox(height: isMobile ? 12 : 16), // Reduced spacing
      _buildInvitationCodeInput(isMobile),
      _buildVerifiedRealtorInfo(isMobile),
      SizedBox(height: isMobile ? 20 : 30), // Reduced spacing
      Center(
        child: SizedBox(
          width: isMobile ? 400 : 500, // Reduced width for mobile
          height: isMobile ? 45 : 50, // Reduced height for mobile
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveInvestorData,
            style: ElevatedButton.styleFrom(
              backgroundColor: neonPurple,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15), // Adjusted padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Colors.black, width: 2),
              ),
              textStyle: GoogleFonts.poppins(
                fontSize: isMobile ? 18 : 22, // Reduced from 22 to 18
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