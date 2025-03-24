import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  // Common Data for both Realtor and Investor

  String? _userRole;
  String? get userRole => _userRole;

  String? _firstName;
  String? get firstName => _firstName;

  String? _uid;
  String? get uid => _uid;

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

  // Specific to Realtor
  String? _invitationCode;
  String? get invitationCode => _invitationCode;

  String? _agencyName;
  String? get agencyName => _agencyName;

  String? _licenseNumber;
  String? get licenseNumber => _licenseNumber;

  String? _address;
  String? get address => _address;

  // Specific to Investor
  String? _investorNotes;
  String? get investorNotes => _investorNotes;

  String? _realtorId;
  String? get realtorId => _realtorId;

  String? _status;
  String? get status => _status;

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get user role and basic info from 'users' collection
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        // Common user data

        _contactEmail = data['email']; // Assuming email is stored here
        _userRole = data['role'];
        _uid = user.uid;

        String userRole = data['role']; // "realtor" or "investor"

        // Fetch additional data based on role
        if (userRole == 'realtor') {
          await _fetchRealtorData(user.uid);
        } else if (userRole == 'investor') {
          await _fetchInvestorData(user.uid);
        }

        notifyListeners(); // Notify UI to update
      }
    }
  }

  // Fetch Realtor-specific data
  Future<void> _fetchRealtorData(String uid) async {
    DocumentSnapshot realtorDoc = await FirebaseFirestore.instance
        .collection('realtors')
        .doc(uid)
        .get();

    if (realtorDoc.exists) {
      final data = realtorDoc.data() as Map<String, dynamic>;
      _firstName = data['firstName'];
      _lastName = data['lastName'];
      _contactPhone = data['contactPhone'];
      _profilePicUrl = data['profilePicUrl'];
      _agencyName = data['agencyName'];
      _licenseNumber = data['licenseNumber'];
      _address = data['address'];
      _invitationCode = data['invitationCode'];

    }
  }

  // Fetch Investor-specific data
  Future<void> _fetchInvestorData(String uid) async {
    DocumentSnapshot investorDoc = await FirebaseFirestore.instance
        .collection('investors')
        .doc(uid)
        .get();

    if (investorDoc.exists) {
      final data = investorDoc.data() as Map<String, dynamic>;
      _firstName = data['firstName'];
      _lastName = data['lastName'];
      _contactPhone = data['contactPhone'];
      _profilePicUrl = data['profilePicUrl'];
      _investorNotes = data['notes'];
      _realtorId = data['realtorId'];
      _status = data['status'];
    }
  }
}
