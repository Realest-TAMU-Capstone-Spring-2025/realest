import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; //timestamp
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
      'profilePicUrl': 'https://github.com/shadcn.png',
      'agencyName': 'Doe Realty',
      'licenseNumber': 'AB123456',
      'address': '123 Main St, Springfield',
    });
    await firestore.collection('users').doc(realtor.user!.uid).set({
      'email': 'realtor@example.com',
      'role': 'realtor',
      'firstName': 'John',
      'lastName': 'Doe',
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

    await firestore.collection('users').doc(investor.user!.uid).set({
      'email': 'investor@example.com',
      'role': 'investor',
      'firstName': 'Jane',
      'lastName': 'Smith',
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

    // Add disliked properties for tests
    for (int i = 1; i <= 3; i++) {
      final propertyId = 'property_$i';
      await firestore
          .collection('investors')
          .doc(auth.currentUser?.uid)
          .collection('property_interactions')
          .doc(propertyId)
          .set({'propertyId': propertyId, 'status': 'disliked'});

      await firestore.collection('listings').doc(propertyId).set({
        'id': propertyId,
        'address': 'Property $i',
        'price': 100000 * i,
        'location': 'Location $i',
      });
    }

    // Create 9 properties for testing

    return {'firestore': firestore, 'auth': auth};
  }

  static Future<Map<String, dynamic>> initializeMockFirebaseRoled(bool isRealtor) async {
    // Initialize Firebase core for testing
    setupFirebaseAuthMocks();
    await Firebase.initializeApp();

    final firestore = FakeFirebaseFirestore();
    final auth = MockFirebaseAuth();

    // Create primary realtor
    if(isRealtor){
      final realtor = await auth.createUserWithEmailAndPassword(
        email: 'realtor@example.com',
        password: 'password123',
      );
      await firestore.collection('realtors').doc(realtor.user!.uid).set({
        'firstName': 'John',
        'lastName': 'Doe',
        'contactPhone': '123-456-7890',
        'profilePicUrl': 'https://github.com/shadcn.png',
        'agencyName': 'Doe Realty',
        'licenseNumber': 'AB123456',
        'address': '123 Main St, Springfield',
      });
      await firestore.collection('users').doc(realtor.user!.uid).set({
        'email': 'realtor@example.com',
        'role': 'realtor',
        'firstName': 'John',
        'lastName': 'Doe',
      });
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
    }else{
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
        'realtorId': "realtor-uid-123",
        'status': 'client',
      });

      await firestore.collection('users').doc(investor.user!.uid).set({
        'email': 'investor@example.com',
        'role': 'investor',
        'firstName': 'Jane',
        'lastName': 'Smith',
      });
      for (int i = 1; i <= 9; i++) {
        final propertyId = 'property_$i';
        await firestore.collection('listings').doc(propertyId).set({
          'id': propertyId,
          'street': 'Street $i',
          'city': 'City $i',
          'state': 'State $i',
          'zip_code': '0000$i',
          'neighborhoods': 'Neighborhood $i',
          'list_price': 100000 + (i * 5000),
          'beds': i % 3 + 1,
          'full_baths': i % 2 + 1,
          'half_baths': i % 2,
          'sqft': 1000 + (i * 100),
          'alt_photos': 'photo$i.jpg, photo${i + 1}.jpg',
          'text': 'Description for property $i',
        });

        if (i <= 3) {
          // Like the first 3 properties
          await firestore
              .collection('investors')
              .doc(auth.currentUser?.uid)
              .collection('property_interactions')
              .doc(propertyId)
              .set({
            'status': 'liked',
            'propertyId': propertyId,
            'sentByRealtor': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
        } else if (i <= 6) {
          // Dislike the next 3 properties
          await firestore
              .collection('investors')
              .doc(auth.currentUser?.uid)
              .collection('property_interactions')
              .doc(propertyId)
              .set({
            'status': 'disliked',
            'propertyId': propertyId,
            'sentByRealtor': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
        // Leave the last 3 properties untouched
      }
    }
    print("Current User ID: ${auth.currentUser?.uid}");
    //signout
    await auth.signOut();
    return {'firestore': firestore, 'auth': auth};
  }

  static Future<List<Map<String, dynamic>>> fetchAll(FakeFirebaseFirestore firestore, String collection) async {
    final snapshot = await firestore.collection(collection).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}