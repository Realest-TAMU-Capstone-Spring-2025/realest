import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// A settings page for investors to update their profile and investment defaults.
class InvestorSettings extends StatefulWidget {
  /// Callback to toggle the app's theme.
  final VoidCallback toggleTheme;

  /// Indicates if dark mode is currently enabled.
  final bool isDarkMode;

  const InvestorSettings({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _InvestorSettingsState createState() => _InvestorSettingsState();
}

/// Manages the state for [InvestorSettings], including data loading and updates.
class _InvestorSettingsState extends State<InvestorSettings> {
  /// Firebase Authentication instance.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Firestore instance for database operations.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Controllers for text input fields.
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _investorNotesController = TextEditingController();

  /// Controllers for cash flow default fields.
  final Map<String, TextEditingController> _cashFlowControllers = {
    'downPayment': TextEditingController(),
    'interestRate': TextEditingController(),
    'loanTerm': TextEditingController(),
  };

  /// Field types for cash flow inputs (e.g., percent, years).
  final Map<String, String> _cashFlowFieldTypes = {
    'downPayment': 'percent',
    'interestRate': 'percent',
    'loanTerm': 'years',
  };

  /// Indicates if data is currently being loaded or updated.
  bool _isLoading = false;

  /// Error message to display, if any.
  String? _errorMessage;

  /// Bytes of the selected profile image, if any.
  Uint8List? _profileImageBytes;

  /// URL of the current profile picture.
  String _profilePicUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Loads investor data from Firestore, including profile picture URL.
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final User? user = _auth.currentUser;
    if (user != null) {
      try {
        final DocumentSnapshot doc =
        await _firestore.collection('investors').doc(user.uid).get();

        if (doc.exists) {
          setState(() {
            _firstNameController.text = doc['firstName'] ?? '';
            _lastNameController.text = doc['lastName'] ?? '';
            _contactEmailController.text = doc['contactEmail'] ?? '';
            _contactPhoneController.text = doc['contactPhone'] ?? '';
            _investorNotesController.text = doc['investorNotes'] ?? '';
            _profilePicUrl = doc['profilePicUrl'] ?? '';
            final cashFlow = doc['cashFlowDefaults'] as Map<String, dynamic>? ?? {};
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

  /// Opens the gallery to pick a new profile picture.
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final Uint8List bytes = await pickedFile.readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
      });
    }
  }

  /// Updates Firestore with new investor data and uploads a new profile picture if selected.
  Future<void> _updateInvestorData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final User? user = _auth.currentUser;
    if (user != null) {
      String updatedProfilePicUrl = _profilePicUrl;
      try {
        // Upload new profile image if selected
        if (_profileImageBytes != null) {
          final Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('Profile_Pics')
              .child('${user.uid}.jpg');
          final UploadTask uploadTask = storageRef.putData(
            _profileImageBytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          final TaskSnapshot snapshot = await uploadTask;
          updatedProfilePicUrl = await snapshot.ref.getDownloadURL();
        }

        // Update Firestore with new data
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

  /// Saves investment default values to Firestore.
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

  /// Formats a field key into a human-readable label (e.g., 'downPayment' to 'Down Payment').
  String _formatLabel(String key) {
    return key.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
      return '${match.group(1)} ${match.group(2)}';
    }).replaceFirstMapped(RegExp(r'^.'), (m) => m.group(0)!.toUpperCase());
  }

  /// Creates a themed text input field for profile data.
  ///
  /// [label] The label for the text field.
  /// [controller] The controller for the text input.
  /// [theme] The current theme data.
  /// Returns a [Widget] representing the text field.
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
                            : const AssetImage('assets/images/profile.png') as ImageProvider),
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
                  // Text Fields
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
                              textStyle: theme.textTheme.bodyLarge,
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Investment Defaults Section
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
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
}