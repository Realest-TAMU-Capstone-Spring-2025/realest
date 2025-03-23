import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:realest/services/realtor_settings_service.dart';

class RealtorSettings extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const RealtorSettings({Key? key, required this.toggleTheme, required this.isDarkMode}) : super(key: key);

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
        DocumentSnapshot doc = await _firestore.collection('realtors').doc(user.uid).get();

        if (doc.exists) {
          setState(() {
            _firstNameController.text = doc['firstName'] ?? '';
            _lastNameController.text = doc['lastName'] ?? '';
            _agencyNameController.text = doc['agencyName'] ?? '';
            _licenseNumberController.text = doc['licenseNumber'] ?? '';
            _contactEmailController.text = doc['contactEmail'] ?? '';
            _contactPhoneController.text = doc['contactPhone'] ?? '';
            _addressController.text = doc['address'] ?? '';
          });
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Update Your Profile",
              style: theme.textTheme.titleLarge, // ✅ Fixed from `headline6`
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

            // All the fields
            _buildTextField("First Name", _firstNameController, theme),
            _buildTextField("Last Name", _lastNameController, theme),
            _buildTextField("Agency Name", _agencyNameController, theme),
            _buildTextField("License Number", _licenseNumberController, theme),
            _buildTextField("Contact Email", _contactEmailController, theme),
            _buildTextField("Contact Phone", _contactPhoneController, theme),
            _buildTextField("Address", _addressController, theme),

            const SizedBox(height: 20),

            // Theme Toggle Switch
            SwitchListTile(
              title: Text(
                "Dark Mode",
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold), // ✅ Fixed from `bodyText1`
              ),
              value: widget.isDarkMode,
              onChanged: (value) => widget.toggleTheme(),
            ),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateRealtorData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: Theme.of(context).textTheme.bodyLarge, // Uses theme text style
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Save Changes"),
              ),
            ),

          ],
        ),
      ),
    );
  }

  /// Creates a modern input field that adapts to the theme
  Widget _buildTextField(String label, TextEditingController controller, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: theme.inputDecorationTheme.fillColor,
          border: theme.inputDecorationTheme.border,
        ),
        style: theme.textTheme.bodyLarge, // ✅ Fixed from `bodyText1`
      ),
    );
  }
}
