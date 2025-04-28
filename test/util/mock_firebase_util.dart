import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../firebase_core_mocks.dart';

void dumpAllTextInWidgetTree(WidgetTester tester) {
  final allTextWidgets = find.byType(Text);
  for (var widget in allTextWidgets.evaluate()) {
    final textWidget = widget.widget as Text;
    debugPrint(textWidget.data);
  }
}
class MockAuthCredential extends AuthCredential {
  MockAuthCredential() : super(providerId: 'mock', signInMethod: 'mock');
}

class MockFirebaseUtil {
  static Future<Map<String, dynamic>> initializeMockFirebase() async {
    // Initialize Firebase core for testing
    setupFirebaseAuthMocks();
    await Firebase.initializeApp();

    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth();

    // Create primary realtor
    final realtor = await auth.createUserWithEmailAndPassword(
      email: 'realtor@example.com',
      password: 'password123',
    );
    await firestore.collection('realtors').doc(realtor.user!.uid).set({
      'firstName': 'John',
      'lastName': 'Doe',
      'contactPhone': '123-456-7890',
      'profilePicUrl': 'https://example.com/realtor.jpg',
      'agencyName': 'Doe Realty',
      'licenseNumber': 'AB123456',
      'address': '123 Main St, Springfield',
    });

    // Create primary investor
    final investor = await auth.createUserWithEmailAndPassword(
      email: 'investor@example.com',
      password: 'password123',
    );
    await firestore.collection('investors').doc(investor.user!.uid).set({
      'firstName': 'Jane',
      'lastName': 'Smith',
      'contactPhone': '987-654-3210',
      'contactEmail': 'investor@example.com',
      'profilePicUrl': 'https://example.com/investor.jpg',
      'notes': 'Interested in high ROI properties.',
      'realtorId': realtor.user!.uid,
      'status': 'client',
    });

    // Create dummy clients
    for (int i = 1; i <= 3; i++) {
      await firestore.collection('investors').add({
        'firstName': 'Client$i',
        'lastName': 'Test',
        'contactPhone': '555-000-000$i',
        'contactEmail': 'client$i@example.com',
        'profilePicUrl': '',
        'notes': 'Test client $i',
        'realtorId': realtor.user!.uid,
        'status': 'client',
      });
    }

    // Create dummy properties
    for (int i = 1; i <= 5; i++) {
      await firestore.collection('properties').add({
        'address': 'Property $i, Springfield',
        'price': 100000 + (i * 5000),
        'realtorId': realtor.user!.uid,
        'status': 'available',
      });
    }

    return {'firestore': firestore, 'auth': auth};
  }
}