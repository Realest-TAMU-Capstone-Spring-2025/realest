import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A separate service to handle Realtor data load/update
class RealtorSettingsService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  RealtorSettingsService({required this.auth, required this.firestore});

  /// Loads realtor data from Firestore.
  /// Returns a Map with the data, or throws an exception on error.
  Future<Map<String, dynamic>> loadRealtorData() async {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }

    final doc = await firestore.collection('realtors').doc(user.uid).get();
    if (!doc.exists) {
      // Return an empty map if no doc
      return {};
    }
    return doc.data() as Map<String, dynamic>;
  }

  /// Updates the realtor data in Firestore.
  /// Throws an exception if anything goes wrong.
  Future<void> updateRealtorData(Map<String, String> data) async {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }

    await firestore.collection('realtors').doc(user.uid).update({
      'firstName': data['firstName'] ?? '',
      'lastName': data['lastName'] ?? '',
      'agencyName': data['agencyName'] ?? '',
      'licenseNumber': data['licenseNumber'] ?? '',
      'contactEmail': data['contactEmail'] ?? '',
      'contactPhone': data['contactPhone'] ?? '',
      'address': data['address'] ?? '',
    });
  }
}
