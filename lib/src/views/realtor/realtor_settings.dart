import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:realest/services/realtor_settings_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// A settings page where realtors can update their profile, cash flow defaults, and toggle dark mode.
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

/// State class for RealtorSettings. Handles profile updates, image upload, and validation.
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
  Uint8List? _profileImageBytes;
  String _profilePicUrl = '';

  // Validation error states
  String? _firstNameError;
  String? _lastNameError;
  String? _agencyNameError;
  String? _licenseNumberError;
  String? _contactEmailError;
  String? _contactPhoneError;
  String? _addressError;
  final Map<String, String?> _cashFlowErrors = {
    'closingCost': null,
    'costToSell': null,
    'defaultHOA': null,
    'downPayment': null,
    'holdingLength': null,
    'insurance': null,
    'interestRate': null,
    'loanTerm': null,
    'maintenance': null,
    'managementFee': null,
    'needsRepair': null,
    'otherCosts': null,
    'otherIncome': null,
    'propertyTax': null,
    'repairCost': null,
    'useLoan': null,
    'vacancyRate': null,
    'valueAfterRepair': null,
    'valueAppreciation': null,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Add listeners for real-time validation
    _firstNameController.addListener(_validateFirstName);
    _lastNameController.addListener(_validateLastName);
    _agencyNameController.addListener(_validateAgencyName);
    _licenseNumberController.addListener(_validateLicenseNumber);
    _contactEmailController.addListener(_validateContactEmail);
    _contactPhoneController.addListener(_validateContactPhone);
    _addressController.addListener(_validateAddress);
    _cashFlowControllers.forEach((key, controller) {
      controller.addListener(() => _validateCashFlowField(key));
    });
  }

  @override
  void dispose() {
    // Remove listeners
    _firstNameController.removeListener(_validateFirstName);
    _lastNameController.removeListener(_validateLastName);
    _agencyNameController.removeListener(_validateAgencyName);
    _licenseNumberController.removeListener(_validateLicenseNumber);
    _contactEmailController.removeListener(_validateContactEmail);
    _contactPhoneController.removeListener(_validateContactPhone);
    _addressController.removeListener(_validateAddress);
    _cashFlowControllers.forEach((key, controller) {
      controller.removeListener(() => _validateCashFlowField(key));
      controller.dispose();
    });

    // Dispose controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _agencyNameController.dispose();
    _licenseNumberController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Loads the user's current profile data and cash flow defaults from Firestore.
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

  /// Validates the first name field.
  void _validateFirstName() {
    final value = _firstNameController.text.trim();
    setState(() {
      if (value.isEmpty) {
        _firstNameError = 'First name is required';
      } else {
        _firstNameError = null;
      }
    });
  }

  /// Validates the last name field.
  void _validateLastName() {
    final value = _lastNameController.text.trim();
    setState(() {
      if (value.isEmpty) {
        _lastNameError = 'Last name is required';
      } else {
        _lastNameError = null;
      }
    });
  }

  /// Validates the agency name field.
  void _validateAgencyName() {
    final value = _agencyNameController.text.trim();
    setState(() {
      if (value.isEmpty) {
        _agencyNameError = 'Agency name is required';
      } else if (value.length < 2) {
        _agencyNameError = 'Agency name must be at least 2 characters';
      } else if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(value)) {
        _agencyNameError = 'Agency name must contain only letters, numbers, or spaces';
      } else {
        _agencyNameError = null;
      }
    });
  }

  /// Validates the license number field.
  void _validateLicenseNumber() {
    final value = _licenseNumberController.text.trim();
    setState(() {
      if (value.isEmpty) {
        _licenseNumberError = 'License number is required';
      } else if (value.length < 5) {
        _licenseNumberError = 'License number must be at least 5 characters';
      } else if (!RegExp(r'^[a-zA-Z0-9- ]+$').hasMatch(value)) {
        _licenseNumberError = 'License number must contain only letters, numbers, dashes, or spaces';
      } else {
        _licenseNumberError = null;
      }
    });
  }

  /// Validates the contact email field.
  void _validateContactEmail() {
    final value = _contactEmailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() {
      if (value.isEmpty) {
        _contactEmailError = 'Email is required';
      } else if (!emailRegex.hasMatch(value)) {
        _contactEmailError = 'Enter a valid email';
      } else {
        _contactEmailError = null;
      }
    });
  }

  /// Validates the contact phone field.
  void _validateContactPhone() {
    final value = _contactPhoneController.text.trim();
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    setState(() {
      if (value.isEmpty) {
        _contactPhoneError = 'Phone number is required';
      } else if (digits.length != 10) {
        _contactPhoneError = 'Phone number must be 10 digits';
      } else {
        _contactPhoneError = null;
      }
    });
  }

  /// Validates the address field.
  void _validateAddress() {
    final value = _addressController.text.trim();
    setState(() {
      if (value.isEmpty) {
        _addressError = 'Address is required';
      } else if (value.length < 5) {
        _addressError = 'Address must be at least 5 characters';
      } else if (!RegExp(r'^[a-zA-Z0-9,. -]+$').hasMatch(value)) {
        _addressError = 'Address must contain only letters, numbers, commas, periods, dashes, or spaces';
      } else {
        _addressError = null;
      }
    });
  }

  /// Validates a specific cash flow field by key.
  void _validateCashFlowField(String key) {
    final controller = _cashFlowControllers[key];
    final value = controller!.text.trim();
    final type = _cashFlowFieldTypes[key];

    setState(() {
      if (value.isEmpty) {
        _cashFlowErrors[key] = '${_formatCashFlowLabel(key)} is required';
        return;
      }

      if (type == 'bool') {
        final lowerVal = value.toLowerCase();
        if (lowerVal != 'true' && lowerVal != 'false') {
          _cashFlowErrors[key] = '${_formatCashFlowLabel(key)} must be true or false';
        } else {
          _cashFlowErrors[key] = null;
        }
        return;
      }

      final number = double.tryParse(value);
      if (number == null) {
        _cashFlowErrors[key] = '${_formatCashFlowLabel(key)} must be a valid number';
        return;
      }

      if (type == 'percent') {
        if (number < 0 || number > 100) {
          _cashFlowErrors[key] = '${_formatCashFlowLabel(key)} must be between 0 and 100';
        } else {
          _cashFlowErrors[key] = null;
        }
      } else if (type == 'cash') {
        if (number < 0) {
          _cashFlowErrors[key] = '${_formatCashFlowLabel(key)} cannot be negative';
        } else {
          _cashFlowErrors[key] = null;
        }
      } else if (type == 'years') {
        if (number < 1) {
          _cashFlowErrors[key] = '${_formatCashFlowLabel(key)} must be at least 1';
        } else {
          _cashFlowErrors[key] = null;
        }
      }
    });
  }

  /// Runs all field validations and collects error messages.
  List<String> _validateFields() {
    List<String> errors = [];
    _validateFirstName();
    _validateLastName();
    _validateAgencyName();
    _validateLicenseNumber();
    _validateContactEmail();
    _validateContactPhone();
    _validateAddress();
    _cashFlowControllers.keys.forEach(_validateCashFlowField);

    if (_firstNameError != null) errors.add(_firstNameError!);
    if (_lastNameError != null) errors.add(_lastNameError!);
    if (_agencyNameError != null) errors.add(_agencyNameError!);
    if (_licenseNumberError != null) errors.add(_licenseNumberError!);
    if (_contactEmailError != null) errors.add(_contactEmailError!);
    if (_contactPhoneError != null) errors.add(_contactPhoneError!);
    if (_addressError != null) errors.add(_addressError!);
    _cashFlowErrors.forEach((key, error) {
      if (error != null) errors.add(error);
    });

    return errors;
  }

  /// Opens the image picker to select a new profile picture.
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Uint8List bytes = await pickedFile.readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
      });
    }
  }

  /// Updates the realtor's profile data in Firestore, including uploading a new profile picture if selected.
  Future<void> _updateRealtorData() async {
    List<String> errors = _validateFields();
    if (errors.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Validation Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors.map((error) => Text('• $error')).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    User? user = _auth.currentUser;
    if (user != null) {
      String updatedProfilePicUrl = _profilePicUrl;
      try {
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

  /// Saves the cash flow default values to Firestore after validation.
  Future<void> _saveCashFlowDefaults() async {
    List<String> errors = [];
    _cashFlowControllers.keys.forEach(_validateCashFlowField);
    _cashFlowErrors.forEach((key, error) {
      if (error != null) errors.add(error);
    });

    if (errors.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Validation Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors.map((error) => Text('• $error')).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

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
                  _buildTextField("First Name:", _firstNameController, theme, error: _firstNameError),
                  _buildTextField("Last Name:", _lastNameController, theme, error: _lastNameError),
                  _buildTextField("Agency Name:", _agencyNameController, theme, error: _agencyNameError),
                  _buildTextField(
                      "License Number:", _licenseNumberController, theme, error: _licenseNumberError),
                  _buildTextField("Contact Email:", _contactEmailController, theme,
                      error: _contactEmailError),
                  _buildTextField("Contact Phone:", _contactPhoneController, theme,
                      error: _contactPhoneError),
                  _buildTextField("Address:", _addressController, theme, error: _addressError),
                  const SizedBox(height: 20),
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
                        final error = _cashFlowErrors[key];

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
                          final boolVal = controller.text.toLowerCase() == 'true';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                title: Text(_formatCashFlowLabel(key)),
                                value: boolVal,
                                onChanged: (val) {
                                  setState(() {
                                    controller.text = val.toString();
                                  });
                                },
                              ),
                              if (error != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                                  child: Text(
                                    error,
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                  ),
                                ),
                            ],
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: controller,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: _formatCashFlowLabel(key),
                                  suffix: suffix,
                                  border: const OutlineInputBorder(),
                                  errorText: error,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveCashFlowDefaults,
                          child: const Text("Save Cash Flow Defaults"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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

  /// Formats a cash flow field key into a human-readable label.
  String _formatCashFlowLabel(String key) {
    return key.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
      return '${match.group(1)} ${match.group(2)}';
    }).replaceFirstMapped(RegExp(r'^.'), (m) => m.group(0)!.toUpperCase());
  }

  /// Builds a reusable labeled text field widget with error handling.
  Widget _buildTextField(
      String label,
      TextEditingController controller,
      ThemeData theme, {
        String? error,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    errorText: error,
                  ),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}