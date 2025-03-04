import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  String? _firstName;
  String? get firstName => _firstName;

  Future<void> fetchRealtorData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot realtorDoc = await FirebaseFirestore.instance.collection('realtors').doc(user.uid).get();
      if (realtorDoc.exists) {
        _firstName = realtorDoc['firstName'];
        notifyListeners(); // Notify UI to update
      }
    }
  }
}
