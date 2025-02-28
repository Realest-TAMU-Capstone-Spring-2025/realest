import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RealtorSettings extends StatefulWidget {
  const RealtorSettings({Key? key}) : super(key: key);

  @override
  _RealtorSettingsState createState() => _RealtorSettingsState();
}

class _RealtorSettingsState extends State<RealtorSettings> {
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Loads realtor data from Firestore
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc =
        await _firestore.collection('realtors').doc(user.uid).get();

        if (doc.exists) {
          _firstNameController.text = doc['firstName'] ?? '';
          _lastNameController.text = doc['lastName'] ?? '';
          _agencyNameController.text = doc['agencyName'] ?? '';
          _licenseNumberController.text = doc['licenseNumber'] ?? '';
          _contactEmailController.text = doc['contactEmail'] ?? '';
          _contactPhoneController.text = doc['contactPhone'] ?? '';
          _addressController.text = doc['address'] ?? '';
        }
      } catch (e) {
        setState(() {
          _errorMessage = "Error loading data: $e";
        });
      }
    }
    setState(() => _isLoading = false);
  }

  /// Updates Firestore with new realtor data
  Future<void> _updateRealtorData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('realtors').doc(user.uid).update({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'agencyName': _agencyNameController.text.trim(),
          'licenseNumber': _licenseNumberController.text.trim(),
          'contactEmail': _contactEmailController.text.trim(),
          'contactPhone': _contactPhoneController.text.trim(),
          'address': _addressController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _errorMessage = "Error updating data. Please try again.";
        });
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Update Your Profile",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),

            _buildTextField("First Name", _firstNameController),
            _buildTextField("Last Name", _lastNameController),
            _buildTextField("Agency Name", _agencyNameController),
            _buildTextField("License Number", _licenseNumberController),
            _buildTextField("Contact Email", _contactEmailController),
            _buildTextField("Contact Phone", _contactPhoneController),
            _buildTextField("Address", _addressController),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateRealtorData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a modern input field
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
