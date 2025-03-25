import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RealtorSettings extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const RealtorSettings({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

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
  final Map<String, TextEditingController> _cashFlowControllers = {
    'closingCost': TextEditingController(),
    'costToSell': TextEditingController(),
    'defaultHOA': TextEditingController(),
    'downPayment': TextEditingController(),
    'holdingLength': TextEditingController(),
    'insurance': TextEditingController(),
    'interestRate': TextEditingController(),
    'loanTerm': TextEditingController(),
    'maintenance': TextEditingController(),
    'managementFee': TextEditingController(),
    'needsRepair': TextEditingController(),
    'otherCosts': TextEditingController(),
    'otherIncome': TextEditingController(),
    'propertyTax': TextEditingController(),
    'repairCost': TextEditingController(),
    'useLoan': TextEditingController(),
    'vacancyRate': TextEditingController(),
    'valueAfterRepair': TextEditingController(),
    'valueAppreciation': TextEditingController(),
  };
  final Map<String, String> _cashFlowFieldTypes = {
    'closingCost': 'cash',
    'costToSell': 'percent',
    'defaultHOA': 'cash',
    'downPayment': 'percent',
    'holdingLength': 'years',
    'insurance': 'percent',
    'interestRate': 'percent',
    'loanTerm': 'years',
    'maintenance': 'percent',
    'managementFee': 'percent',
    'needsRepair': 'bool',
    'otherCosts': 'cash',
    'otherIncome': 'cash',
    'propertyTax': 'percent',
    'repairCost': 'cash',
    'useLoan': 'bool',
    'vacancyRate': 'percent',
    'valueAfterRepair': 'cash',
    'valueAppreciation': 'percent',
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

  /// Loads realtor data from Firestore (including profilePicUrl)
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot doc =
        await _firestore.collection('realtors').doc(user.uid).get();

        if (doc.exists) {
          setState(() {
            _firstNameController.text = doc['firstName'] ?? '';
            _lastNameController.text = doc['lastName'] ?? '';
            _agencyNameController.text = doc['agencyName'] ?? '';
            _licenseNumberController.text = doc['licenseNumber'] ?? '';
            _contactEmailController.text = doc['contactEmail'] ?? '';
            _contactPhoneController.text = doc['contactPhone'] ?? '';
            _addressController.text = doc['address'] ?? '';
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

  /// Updates Firestore with new realtor data and uploads a new profile picture if picked
  Future<void> _updateRealtorData() async {
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
        await _firestore.collection('realtors').doc(user.uid).update({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'agencyName': _agencyNameController.text.trim(),
          'licenseNumber': _licenseNumberController.text.trim(),
          'contactEmail': _contactEmailController.text.trim(),
          'contactPhone': _contactPhoneController.text.trim(),
          'address': _addressController.text.trim(),
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
                  _buildTextField("Agency Name:", _agencyNameController, theme),
                  _buildTextField("License Number:", _licenseNumberController, theme),
                  _buildTextField("Contact Email:", _contactEmailController, theme),
                  _buildTextField("Contact Phone:", _contactPhoneController, theme),
                  _buildTextField("Address:", _addressController, theme),
                  const SizedBox(height: 20),
                  // Theme Toggle Switch
                  SwitchListTile(
                    title: Text(
                      "Dark Mode",
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    value: widget.isDarkMode,
                    onChanged: (value) => widget.toggleTheme(),
                  ),
                  const SizedBox(height: 20),
                  ExpansionTile(
                    title: const Text("Cash Flow Defaults"),
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
                          case 'cash':
                            suffix = const Text('\$');
                            break;
                          case 'years':
                            suffix = const Text('yrs');
                            break;
                          default:
                            suffix = const SizedBox();
                        }

                        if (type == 'bool') {
                          // Render as switch
                          final boolVal = controller.text.toLowerCase() == 'true';
                          return SwitchListTile(
                            title: Text(_formatCashFlowLabel(key)),
                            value: boolVal,
                            onChanged: (val) {
                              setState(() {
                                controller.text = val.toString();
                              });
                            },
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TextField(
                            controller: controller,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: _formatCashFlowLabel(key),
                              suffix: suffix,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        );
                      }).toList(),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ElevatedButton(
                          onPressed: _saveCashFlowDefaults,
                          child: const Text("Save Cash Flow Defaults"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  // Save / Cancel Buttons
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 200,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateRealtorData,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: Theme.of(context).textTheme.bodyLarge,
                            ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  String _formatCashFlowLabel(String key) {
    return key.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
      return '${match.group(1)} ${match.group(2)}';
    }).replaceFirstMapped(RegExp(r'^.'), (m) => m.group(0)!.toUpperCase());
  }
  Future<void> _saveCashFlowDefaults() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final Map<String, dynamic> updated = {};
    _cashFlowControllers.forEach((key, controller) {
      final val = controller.text.trim();
      final type = _cashFlowFieldTypes[key];

      if (type == 'bool') {
        updated[key] = val.toLowerCase() == 'true';
      } else if (type == 'percent') {
        updated[key] = (double.tryParse(val) ?? 0) / 100;
      } else {
        updated[key] = double.tryParse(val) ?? val;
      }
    });


    try {
      await _firestore.collection('realtors').doc(user.uid).update({
        'cashFlowDefaults': updated,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cash Flow Defaults updated")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update: $e")),
      );
    }
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
}
