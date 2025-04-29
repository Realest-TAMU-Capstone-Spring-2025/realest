import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages user data, including role, profile details, clients, and tags.
class UserProvider extends ChangeNotifier {
  /// Indicates if user data is being loaded.
  bool isLoading = false;

  /// User's role (e.g., 'realtor', 'investor').
  String? _userRole;
  String? get userRole => _userRole;

  /// User's first name.
  String? _firstName;
  String? get firstName => _firstName;

  /// User's unique ID.
  String? _uid;
  String? get uid => _uid;

  /// User's last name.
  String? _lastName;
  String? get lastName => _lastName;

  /// User's contact email.
  String? _contactEmail;
  String? get contactEmail => _contactEmail;

  /// User's contact phone number.
  String? _contactPhone;
  String? get contactPhone => _contactPhone;

  /// URL of the user's profile picture.
  String? _profilePicUrl;
  String? get profilePicUrl => _profilePicUrl;

  /// Invitation code for the user.
  String? _invitationCode;
  String? get invitationCode => _invitationCode;

  /// Name of the realtor's agency.
  String? _agencyName;
  String? get agencyName => _agencyName;

  /// Realtor's license number.
  String? _licenseNumber;
  String? get licenseNumber => _licenseNumber;

  /// User's address.
  String? _address;
  String? get address => _address;

  /// Notes for the investor.
  String? _investorNotes;
  String? get investorNotes => _investorNotes;

  /// ID of the realtor associated with the investor.
  String? _realtorId;
  String? get realtorId => _realtorId;

  /// Status of the investor (e.g., 'client', 'qualified-lead').
  String? _status;
  String? get status => _status;

  /// Timestamp of when the user was created.
  String? _createdAt;
  String? get createdAt => _createdAt;

  /// List of clients for a realtor.
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> get clients => _clients;

  /// List of tags for a realtor.
  List<Map<String, dynamic>> _tags = [];
  List<Map<String, dynamic>> get tags => _tags;

  set uid(String? value) {
    _uid = value;
    notifyListeners();
  }

  set userRole(String? value) {
    _userRole = value;
    notifyListeners();
  }

  /// Initializes user data by loading from local storage and fetching from Firestore.
  Future<void> initializeUser() async {
    isLoading = true;
    notifyListeners();
    await loadUserData();
    if (_uid != null) {
      await fetchUserData();
    }
    isLoading = false;
    notifyListeners();
  }

  /// Saves user data to SharedPreferences.
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
    if (_userRole == 'realtor') {
      await prefs.setStringList('clients', _clients.map((client) => client['id'] as String).toList());
      await prefs.setStringList('tags', _tags.map((tag) => tag['id'] as String).toList());
    }
    notifyListeners();
  }

  /// Loads user data from SharedPreferences.
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('userRole');
    _uid = prefs.getString('uid');
    _firstName = prefs.getString('firstName');
    List<String>? clientIds = prefs.getStringList('clients');
    if (clientIds != null) {
      _clients = clientIds.map((id) => {'id': id}).toList();
    }
    List<String>? tagIds = prefs.getStringList('tags');
    if (tagIds != null) {
      _tags = tagIds.map((id) => {'id': id, 'name': '', 'color': '#FFFFFF', 'investors': []}).toList();
    }
    notifyListeners();
  }

  /// Fetches user data from Firestore based on the authenticated user.
  Future<void> fetchUserData() async {
    try {
      isLoading = true;
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
            await _fetchTags(user.uid);
          } else if (userRole == 'investor') {
            await _fetchInvestorData(user.uid);
          }
          await saveUserData();
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    } finally {
      isLoading = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isLoading = false;
      notifyListeners();
    });
  }

  /// Fetches realtor-specific data from Firestore.
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
    }
  }

  /// Fetches investor-specific data from Firestore.
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
    }
  }

  /// Fetches clients associated with a realtor from Firestore.
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
      };
    }).toList();
    notifyListeners();
  }

  /// Fetches tags associated with a realtor from Firestore.
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

  /// Clears all user data from SharedPreferences and local state.
  void clearUserData() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.clear();
    });
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
    _clients.clear();
    _tags.clear();
    notifyListeners();
  }
}