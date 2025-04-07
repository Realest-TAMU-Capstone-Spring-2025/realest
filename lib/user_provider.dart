import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  String? _userRole;
  String? get userRole => _userRole;
  String? _firstName;
  String? get firstName => _firstName;
  String? _uid;
  String? get uid => _uid;
  String? _lastName;
  String? get lastName => _lastName;
  String? _contactEmail;
  String? get contactEmail => _contactEmail;
  String? _contactPhone;
  String? get contactPhone => _contactPhone;
  String? _profilePicUrl;
  String? get profilePicUrl => _profilePicUrl;
  String? _invitationCode;
  String? get invitationCode => _invitationCode;
  String? _agencyName;
  String? get agencyName => _agencyName;
  String? _licenseNumber;
  String? get licenseNumber => _licenseNumber;
  String? _address;
  String? get address => _address;
  String? _investorNotes;
  String? get investorNotes => _investorNotes;
  String? _realtorId;
  String? get realtorId => _realtorId;
  String? _status;
  String? get status => _status;
  String? _createdAt;
  String? get createdAt => _createdAt;
  String? _tempPassword;
  String? get tempPassword => _tempPassword;

  // Clients list
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> get clients => _clients;

  // Tags list
  List<Map<String, dynamic>> _tags = [];
  List<Map<String, dynamic>> get tags => _tags;

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        _contactEmail = data['email'];
        _userRole = data['role'];
        _uid = user.uid;

        String userRole = data['role'];
        if (userRole == 'realtor') {
          await _fetchRealtorData(user.uid);
          await _fetchClients(user.uid);
          await _fetchTags(user.uid); // Fetch tags for realtor
        } else if (userRole == 'investor') {
          await _fetchInvestorData(user.uid);
        }

        notifyListeners();
      }
    }
  }

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
      _contactEmail = data['contactEmail'];
      _profilePicUrl = data['profilePicUrl'];
      _investorNotes = data['notes'];
      _realtorId = data['realtorId'];
      _status = data['status'];
      _tempPassword = data['tempPassword'];
    }
  }

  Future<void> _fetchClients(String realtorId) async {
    QuerySnapshot investorSnapshot = await FirebaseFirestore.instance
        .collection('investors')
        .where('realtorId', isEqualTo: realtorId)
        .where('status', isEqualTo: 'client')
        .get();

    _clients = investorSnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['firstName'] != null && doc['lastName'] != null
            ? '${doc['firstName']} ${doc['lastName']}'
            : 'Unnamed Client',
        'email': doc['contactEmail'] ?? '',
        'contactPhone': doc['contactPhone'] ?? '',
        'createdAt': doc['createdAt'] ?? '',
        'notes': doc['notes'] ?? '',
        'realtorId': doc['realtorId'] ?? '',
        'status': doc['status'] ?? '',
        'tempPassword': doc['tempPassword'] ?? '',
      };
    }).toList();

    notifyListeners();
  }

  Future<void> _fetchTags(String realtorId) async {
    QuerySnapshot tagSnapshot = await FirebaseFirestore.instance
        .collection('realtors')
        .doc(realtorId)
        .collection('tags')
        .get();

    _tags = tagSnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['name'] ?? doc.id,
        'color': doc['color'] ?? '#FFFFFF',
        'investors': List<String>.from(doc['investors'] ?? []),
      };
    }).toList();

    notifyListeners();
  }
}