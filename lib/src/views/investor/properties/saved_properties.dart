import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'properties_view.dart'; // Import PropertiesView
import '../swiping/property_swiping.dart';

class SavedProperties extends StatelessWidget {
  SavedProperties({super.key});

  final NumberFormat currencyFormat = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? uid = user?.uid;

    if (uid == null) {
      return Scaffold(
        body: Center(child: const Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Properties')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('decisions')
            .where('liked', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final decisionDocs = snapshot.data!.docs;

          if (decisionDocs.isEmpty) {
            return const Center(child: Text('No saved properties.'));
          }

          return FutureBuilder<List<Property>>(
            future: _fetchProperties(decisionDocs),
            builder: (context, propertySnapshot) {
              if (!propertySnapshot.hasData) return const Center(child: CircularProgressIndicator());

              final properties = propertySnapshot.data!;

              return ListView.builder(
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  final property = properties[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to PropertiesView when a card is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PropertiesView(propertyId: property.id),
                        ),
                      );
                    },
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: _buildPropertyCard(property),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Property>> _fetchProperties(List<QueryDocumentSnapshot> decisionDocs) async {
    final List<Property> properties = [];

    for (var decisionDoc in decisionDocs) {
      final propertyId = decisionDoc['propertyId'] as String?;
      if (propertyId == null) continue;

      final listingDoc = await FirebaseFirestore.instance.collection('listings').doc(propertyId).get();

      if (listingDoc.exists && listingDoc.data() != null) {
        properties.add(Property.fromFirestore(listingDoc));
      }
    }

    return properties;
  }

  Widget _buildPropertyCard(Property property) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          property.primaryPhoto != null && property.primaryPhoto!.isNotEmpty
              ? Image.network(property.primaryPhoto!, width: 120, fit: BoxFit.cover)
              : Container(width: 120, color: Colors.grey),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(property.street ?? 'Unknown Address', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(property.listPrice != null ? '\$${currencyFormat.format(property.listPrice)}' : 'N/A'),
                  const SizedBox(height: 4),
                  Text('${property.beds ?? 0} Beds | ${property.fullBaths ?? 0} Baths | ${property.sqft ?? 'N/A'} sqft'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}