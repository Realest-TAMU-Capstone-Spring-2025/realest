import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  final TextEditingController _investorNotesController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _realtorIdController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _profileImageBytes; // For web image bytes

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

  void _saveInvestorData() async {
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

        // Create a document in the 'investors' collection
        await _firestore.collection('investors').doc(uid).set({
          'uid': uid,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'investorNotes': _investorNotesController.text.trim(),
          'contactEmail': _contactEmailController.text.trim(),
          'contactPhone': _contactPhoneController.text.trim(),
          'realtorId': _realtorIdController.text.trim(),
          'status': _statusController.text.trim(),
          'profilePicUrl': profilePicUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });

        context.go('/investorHome');
      } catch (e) {
        setState(() {
          print(e);
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
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
                          "Complete Your Investor Profile",
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
                        _buildTextField(_contactEmailController, "Contact Email", keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 16),
                        _buildTextField(_contactPhoneController, "Contact Phone Number", keyboardType: TextInputType.phone),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          ),
                        const SizedBox(height: 20),
                        // Save Button with fixed width
                        SizedBox(
                          width: 200, height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveInvestorData,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
