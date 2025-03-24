import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../realtor_user_provider.dart';

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
  // Removed the single invitation code controller

  // Create eight controllers for the invitation code boxes
  final List<TextEditingController> _invitationCodeControllers =
  List.generate(8, (_) => TextEditingController());

  bool _isLoading = false;
  String? _errorMessage;
  Uint8List? _profileImageBytes;

  // Store the verified realtor id, name, and profile pic URL.
  String? _verifiedRealtorId;
  String? _verifiedRealtorName;
  String? _verifiedRealtorProfilePicUrl;

  @override
  void initState() {
    super.initState();
    // Autofill contact email from authenticated user
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
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
      });
    }
  }

  /// Concatenates the values from the eight boxes into one string.
  String _getInvitationCode() {
    String code = '';
    for (var controller in _invitationCodeControllers) {
      code += controller.text.trim();
    }
    return code;
  }

  /// Verifies the invitation code by querying the 'realtors' collection.
  Future<void> _verifyInvitationCode() async {
    final code = _getInvitationCode();
    if (code.length != 8) {
      setState(() {
        _errorMessage =
        "Please enter the complete 8-character invitation code.";
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
        setState(() {
          _errorMessage =
          "Invitation code not found. Please check and try again.";
        });
        return;
      }

      // Get the realtor document.
      final realtorDoc = querySnapshot.docs.first;
      final realtorData = realtorDoc.data() as Map<String, dynamic>;
      final realtorFirstName = realtorData['firstName'] ?? '';
      final realtorLastName = realtorData['lastName'] ?? '';
      final realtorProfilePicUrl = realtorData['profilePicUrl'] ?? '';
      final realtorId = realtorDoc.id; // This is the realtor id

      // Show a confirmation dialog with the realtor’s details.
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Confirm Realtor"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (realtorProfilePicUrl != '')
                  CircleAvatar(
                    backgroundImage: NetworkImage(realtorProfilePicUrl),
                    radius: 40,
                  ),
                const SizedBox(height: 20),
                Text(
                  "$realtorFirstName $realtorLastName",
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // On confirmation, store the realtor id, name, and profile pic URL.
                  setState(() {
                    _verifiedRealtorId = realtorId;
                    _verifiedRealtorName = "$realtorFirstName $realtorLastName";
                    _verifiedRealtorProfilePicUrl = realtorProfilePicUrl;
                    _errorMessage = null;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text("Confirm"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss dialog
                },
                child: const Text("Cancel"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage =
        "Error verifying invitation code. Please try again.";
      });
    }
  }

  void _saveInvestorData() async {
    // Ensure that a realtor has been linked before saving.
    if (_verifiedRealtorId == null) {
      setState(() {
        _errorMessage =
        "Please verify your invitation code to link a realtor before saving.";
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

        // Save the investor data with the realtor id, status, and notes.
        await _firestore.collection('investors').doc(uid).set({
          'uid': uid,
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'contactEmail': _contactEmailController.text.trim(),
          'contactPhone': _contactPhoneController.text.trim(),
          'realtorId': _verifiedRealtorId,
          'profilePicUrl': profilePicUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Update', // Add status field set to "Active"
          'notes': 'Account Created', // Add notes field set to "Account Created"
        });

        Navigator.pushReplacementNamed(context, '/investorHome');
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

  /// Builds the row of 8 square input boxes and the Verify button.
  Widget _buildInvitationCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(8, (index) {
            return Container(
              width: 40,
              height: 40,
              child: TextField(
                controller: _invitationCodeControllers[index],
                textAlign: TextAlign.center,
                maxLength: 1,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[200],
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
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
          width: 100,
          height: 45,
          child: ElevatedButton(
            onPressed: _verifyInvitationCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: const Text("Verify"),
          ),
        ),
      ],
    );
  }

  /// Displays the verified realtor's info in a single row.
  Widget _buildVerifiedRealtorInfo() {
    if (_verifiedRealtorId == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          const Text(
            "Realtor: ",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (_verifiedRealtorProfilePicUrl != null &&
              _verifiedRealtorProfilePicUrl != '')
            CircleAvatar(
              backgroundImage: NetworkImage(_verifiedRealtorProfilePicUrl!),
              radius: 20,
            ),
          const SizedBox(width: 8),
          Text(
            _verifiedRealtorName ?? '',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Set Up Your Account',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Complete Your Investor Profile",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _profileImageBytes != null
                    ? MemoryImage(_profileImageBytes!)
                    : null,
                child: _profileImageBytes == null
                    ? const Icon(Icons.camera_alt,
                    size: 40, color: Colors.black54)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(_firstNameController, "First Name")),
                const SizedBox(width: 10),
                Expanded(
                    child: _buildTextField(_lastNameController, "Last Name")),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(_contactEmailController, "Contact Email",
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField(_contactPhoneController, "Contact Phone Number",
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            Text("Enter Your Invitation Code: ",
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            // Invitation code input widget.
            _buildInvitationCodeInput(),
            // Display verified realtor info once confirmed.
            _buildVerifiedRealtorInfo(),
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
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveInvestorData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save & Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}