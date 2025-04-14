import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class InvestorSettings extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const InvestorSettings({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _InvestorSettingsState createState() => _InvestorSettingsState();
}

class _InvestorSettingsState extends State<InvestorSettings> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _investorNotesController = TextEditingController();

  final Map<String, TextEditingController> _cashFlowControllers = {
    'downPayment': TextEditingController(),
    'interestRate': TextEditingController(),
    'loanTerm': TextEditingController(),
  };

  final Map<String, String> _cashFlowFieldTypes = {
    'downPayment': 'percent',
    'interestRate': 'percent',
    'loanTerm': 'years',
  };


  bool _isLoading = false;
  String? _errorMessage;

  // New state variables for profile picture
  Uint8List? _profileImageBytes;
  String _profilePicUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Loads investor data from Firestore (including profilePicUrl)
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc =
        await _firestore.collection('investors').doc(user.uid).get();

        if (doc.exists) {
          setState(() {
            _firstNameController.text = doc['firstName'] ?? '';
            _lastNameController.text = doc['lastName'] ?? '';
            _contactEmailController.text = doc['contactEmail'] ?? '';
            _contactPhoneController.text = doc['contactPhone'] ?? '';
            _investorNotesController.text = doc['investorNotes'] ?? '';
            _profilePicUrl = doc['profilePicUrl'] ?? '';
            final cashFlow = doc['cashFlowDefaults'] ?? {};
            cashFlow.forEach((key, value) {
              if (_cashFlowControllers.containsKey(key)) {
                final type = _cashFlowFieldTypes[key];
                if (type == 'percent' && value is num) {
                  _cashFlowControllers[key]!.text = (value * 100).toString();
                } else {
                  _cashFlowControllers[key]!.text = value.toString();
                }
              }
            });
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

  /// Opens the gallery to pick a new profile picture
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

  /// Updates Firestore with new investor data and uploads a new profile picture if picked
  Future<void> _updateInvestorData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      String updatedProfilePicUrl = _profilePicUrl;
      try {
        // If a new profile image has been picked, upload it.
        if (_profileImageBytes != null) {
          Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('Profile_Pics')
              .child('${user.uid}.jpg');
          UploadTask uploadTask = storageRef.putData(
            _profileImageBytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          TaskSnapshot snapshot = await uploadTask;
          updatedProfilePicUrl = await snapshot.ref.getDownloadURL();
        }

        // Update Firestore with new data (including profilePicUrl)
        await _firestore.collection('investors').doc(user.uid).update({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'contactEmail': _contactEmailController.text.trim(),
          'contactPhone': _contactPhoneController.text.trim(),
          'investorNotes': _investorNotesController.text.trim(),
          'profilePicUrl': updatedProfilePicUrl,
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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      "Update Your Profile",
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Profile Picture Picker Section
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profileImageBytes != null
                            ? MemoryImage(_profileImageBytes!)
                            : (_profilePicUrl.isNotEmpty
                            ? NetworkImage(_profilePicUrl)
                            : const AssetImage('assets/images/profile.png')
                        as ImageProvider),
                        child: _profileImageBytes == null && _profilePicUrl.isEmpty
                            ? const Icon(Icons.camera_alt, size: 40, color: Colors.black54)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Tap the image to change your profile picture",
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  // All the text fields
                  _buildTextField("First Name:", _firstNameController, theme),
                  _buildTextField("Last Name:", _lastNameController, theme),
                  _buildTextField("Contact Email:", _contactEmailController, theme),
                  _buildTextField("Contact Phone:", _contactPhoneController, theme),
                  _buildTextField("Investor Notes:", _investorNotesController, theme),
                  const SizedBox(height: 10),
                  // Save / Cancel Buttons
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateInvestorData,

                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : const Text("Save Changes"),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 200,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _loadUserData,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: Theme.of(context).textTheme.bodyLarge,
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  ExpansionTile(
                    title: const Text("Investment Defaults"),
                    initiallyExpanded: false,
                    children: [
                      ..._cashFlowControllers.entries.map((entry) {
                        final key = entry.key;
                        final controller = entry.value;
                        final type = _cashFlowFieldTypes[key] ?? 'text';

                        Widget suffix;
                        switch (type) {
                          case 'percent':
                            suffix = const Text('%');
                            break;
                          case 'years':
                            suffix = const Text('yrs');
                            break;
                          default:
                            suffix = const SizedBox();
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              constraints: const BoxConstraints(maxWidth: 200),
                              labelText: _formatLabel(key),
                              suffix: suffix,
                              filled: true,
                              fillColor: theme.inputDecorationTheme.fillColor,
                              border: theme.inputDecorationTheme.border,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                          ),
                        );
                      }).toList(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ElevatedButton(
                          onPressed: _saveInvestorDefaults,
                          child: const Text("Save Defaults"),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Creates a modern input field that adapts to the theme
  Widget _buildTextField(String label, TextEditingController controller, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: theme.textTheme.bodyLarge,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.inputDecorationTheme.fillColor,
                border: theme.inputDecorationTheme.border,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              style: theme.textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String key) {
    return key.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
      return '${match.group(1)} ${match.group(2)}';
    }).replaceFirstMapped(RegExp(r'^.'), (m) => m.group(0)!.toUpperCase());
  }

  Future<void> _saveInvestorDefaults() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final Map<String, dynamic> updated = {};
    _cashFlowControllers.forEach((key, controller) {
      final val = controller.text.trim();
      final type = _cashFlowFieldTypes[key];
      if (type == 'percent') {
        updated[key] = (double.tryParse(val) ?? 0) / 100;
      } else if (type == 'years') {
        updated[key] = int.tryParse(val) ?? 0;
      } else {
        updated[key] = double.tryParse(val) ?? val;
      }
    });

    try {
      await _firestore.collection('investors').doc(user.uid).update({
        'cashFlowDefaults': updated,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Defaults saved")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update defaults: $e")),
      );
    }
  }

}
