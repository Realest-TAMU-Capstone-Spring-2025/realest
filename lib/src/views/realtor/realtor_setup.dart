import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';

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
    // Generate invitation code
    _invitationCodeController.text = _generateInvitationCode();
    // Autofill contact email from authenticated user
    User? currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email != null) {
      _contactEmailController.text = currentUser.email!;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Read image bytes directly (web only)
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
        // Upload profile image if available
        String profilePicUrl = '';
        if (_profileImageBytes != null) {
          Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('Profile_Pics') // Folder name in Storage
              .child('$uid.jpg');
          UploadTask uploadTask = storageRef.putData(
            _profileImageBytes!,
            SettableMetadata(contentType: 'image/jpeg'), // or 'image/png'
          );
          TaskSnapshot snapshot = await uploadTask;
          profilePicUrl = await snapshot.ref.getDownloadURL();
        }

        // Update the user document in 'users' collection
        await _firestore.collection('users').doc(uid).update({
          'completedSetup': true,
        });

        // Create a document in the 'realtors' collection
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
          'cashFlowDefaults' :{
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

        context.go("/realtorDashboard");
      } catch (e) {
        setState(() {
          _errorMessage = "Error saving data. Please try again.";
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Reusable text field widget
  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, bool readOnly = false}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Matches login screen theme
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes back arrow
        title: const Text(
          'Set Up Your Account',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            // Constrain overall width for three columns
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Row(
              // Center children vertically in the row
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Left Column: Logo and Company Name (centered)
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Complete Your Realtor Profile",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const SizedBox(height: 20),
                        // Profile Image Picker
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _profileImageBytes != null ? MemoryImage(_profileImageBytes!) : null,
                            child: _profileImageBytes == null
                                ? const Icon(Icons.camera_alt, size: 40, color: Colors.black54)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // First Name & Last Name Fields
                        Row(
                          children: [
                            Expanded(child: _buildTextField(_firstNameController, "First Name")),
                            const SizedBox(width: 10),
                            Expanded(child: _buildTextField(_lastNameController, "Last Name")),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(_agencyNameController, "Agency Name"),
                        const SizedBox(height: 16),
                        _buildTextField(_licenseNumberController, "License Number"),
                        const SizedBox(height: 16),
                        _buildTextField(_contactEmailController, "Contact Email", keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        _buildTextField(_contactPhoneController, "Contact Phone Number", keyboardType: TextInputType.phone),
                        const SizedBox(height: 16),
                        _buildTextField(_addressController, "Address"),
                        const SizedBox(height: 16),
                        _buildTextField(_invitationCodeController, "Invitation Code", readOnly: true),
                        const SizedBox(height: 24),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          ),
                        SizedBox(
                          width: 200,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveRealtorData,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("Save & Continue"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}