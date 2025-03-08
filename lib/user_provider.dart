import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  String? _firstName;
  String? get firstName => _firstName;

  String? _lastName;
  String? get lastName => _lastName;

  String? _agencyName;
  String? get agencyName => _agencyName;

  String? _licenseNumber;
  String? get licenseNumber => _licenseNumber;

  String? _contactEmail;
  String? get contactEmail => _contactEmail;

  String? _contactPhone;
  String? get contactPhone => _contactPhone;

  String? _address;
  String? get address => _address;

  String? _profilePicUrl;
  String? get profilePicUrl => _profilePicUrl;

  Future<void> fetchRealtorData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot realtorDoc = await FirebaseFirestore.instance
          .collection('realtors')
          .doc(user.uid)
          .get();

      if (realtorDoc.exists) {
        final data = realtorDoc.data() as Map<String, dynamic>;

        _firstName = data['firstName'];
        _lastName = data['lastName'];
        _agencyName = data['agencyName'];
        _licenseNumber = data['licenseNumber'];
        _contactEmail = data['contactEmail'];
        _contactPhone = data['contactPhone'];
        _address = data['address'];
        _profilePicUrl = data['profilePicUrl'];

        notifyListeners(); // Notify UI to update
      }
    }
  }
}
