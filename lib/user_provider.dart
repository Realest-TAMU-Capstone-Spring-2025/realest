import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';


class UserProvider extends ChangeNotifier {
  bool isLoading = false;
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

  set uid(String? value) {
    _uid = value;
    notifyListeners();
  }

  set userRole(String? value) {
    _userRole = value;
    notifyListeners();
  }


  // Clients list
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> get clients => _clients;

  // Tags list
  List<Map<String, dynamic>> _tags = [];
  List<Map<String, dynamic>> get tags => _tags;

  Future<void> initializeUser() async {
  // Load local data first
    await loadUserData();

    // Then fetch fresh data from Firebase if needed
    if (_uid != null) {
      await fetchUserData();
    } else {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', _userRole ?? '');
    await prefs.setString('uid', _uid ?? '');
    await prefs.setString('firstName', _firstName ?? '');
    await prefs.setString('lastName', _lastName ?? '');
    await prefs.setString('contactEmail', _contactEmail ?? '');
    await prefs.setString('contactPhone', _contactPhone ?? '');
    await prefs.setString('profilePicUrl', _profilePicUrl ?? '');
    await prefs.setString('invitationCode', _invitationCode ?? '');
    await prefs.setString('agencyName', _agencyName ?? '');
    await prefs.setString('licenseNumber', _licenseNumber ?? '');
    await prefs.setString('address', _address ?? '');
    await prefs.setString('investorNotes', _investorNotes ?? '');
    await prefs.setString('realtorId', _realtorId ?? '');
    await prefs.setString('status', _status ?? '');
    await prefs.setString('createdAt', _createdAt ?? '');
    await prefs.setString('tempPassword', _tempPassword ?? '');
    if(_userRole == 'realtor') {
      await prefs.setStringList('clients', _clients.map((client) => client['id'] as String).toList());
      await prefs.setStringList('tags', _tags.map((tag) => tag['id'] as String).toList());
    }
    notifyListeners();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('userRole');
    _uid = prefs.getString('uid');
    _firstName = prefs.getString('firstName');
    _lastName = prefs.getString('lastName');
    _contactEmail = prefs.getString('contactEmail');
    _contactPhone = prefs.getString('contactPhone');
    _profilePicUrl = prefs.getString('profilePicUrl');
    _invitationCode = prefs.getString('invitationCode');
    _agencyName = prefs.getString('agencyName');
    _licenseNumber = prefs.getString('licenseNumber');
    _address = prefs.getString('address');
    _investorNotes = prefs.getString('investorNotes');
    _realtorId = prefs.getString('realtorId');
    _status = prefs.getString('status');
    _createdAt = prefs.getString('createdAt');
    _tempPassword = prefs.getString('tempPassword');

    // Load clients and tags from SharedPreferences
    List<String>? clientIds = prefs.getStringList('clients');
    if (clientIds != null) {
      _clients = clientIds.map((id) {
        return {
          'id': id,
          'name': prefs.getString('clientName_$id') ?? 'Unnamed Client',
          'email': prefs.getString('clientEmail_$id') ?? '',
          'contactPhone': prefs.getString('clientPhone_$id') ?? '',
          'createdAt': prefs.getString('clientCreatedAt_$id') ?? '',
          'notes': prefs.getString('clientNotes_$id') ?? '',
          'realtorId': prefs.getString('clientRealtorId_$id') ?? '',
          'status': prefs.getString('clientStatus_$id') ?? '',
          'tempPassword': prefs.getString('clientTempPassword_$id') ?? '',
        };
      }).toList();
    }

    List<String>? tagIds = prefs.getStringList('tags');
    if (tagIds != null) {
      _tags = tagIds.map((id) {
        return {
          'id': id,
          'name': prefs.getString('tagName_$id') ?? id,
          'color': prefs.getString('tagColor_$id') ?? '#FFFFFF',
          'investors': prefs.getStringList('tagInvestors_$id') ?? [],
        };
      }).toList();
    }
    notifyListeners();
  }

  Future<void> fetchUserData() async {
    isLoading = true;
    notifyListeners();
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

        await saveUserData();

        isLoading = false;
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
      _createdAt = data['createdAt'];
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
  
  void clearUserData() {
    // Clear SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.clear(); // Clears all preferences
    });

    // Reset local variables
    _userRole = null;
    _uid = null;
    _firstName = null;
    _lastName = null;
    _contactEmail = null;
    _contactPhone = null;
    _profilePicUrl = null;
    _invitationCode = null;
    _agencyName = null;
    _licenseNumber = null;
    _address = null;
    _investorNotes = null;
    _realtorId = null;
    _status = null;
    _createdAt = null;
    _tempPassword = null;

    _clients.clear();
    _tags.clear();

    notifyListeners();
  }
}