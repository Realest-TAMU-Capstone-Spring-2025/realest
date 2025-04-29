import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:realest/util/property_fetch_helpers.dart';
import 'package:realest/src/views/realtor/widgets/property_card/property_card.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_sheet.dart';
import 'package:realest/src/views/investor/properties/properties_view.dart';
import 'package:realest/src/views/investor/swiping/property_swiping.dart';
import 'package:provider/provider.dart';
import 'package:realest/user_provider.dart';

class DislikedProperties extends StatefulWidget {
  const DislikedProperties({super.key});

  @override
  State<DislikedProperties> createState() => _DislikedPropertiesState();
}

class _DislikedPropertiesState extends State<DislikedProperties> {
  final NumberFormat currencyFormat = NumberFormat('#,##0', 'en_US');
  late final String? uid;
  late final Stream<QuerySnapshot> _interactionsStream;
  Future<List<Property>>? _cachedPropertiesFuture;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    uid = userProvider.auth.currentUser?.uid;

    if (uid != null) {
      _interactionsStream = FirebaseFirestore.instance
          .collection('investors')
          .doc(uid)
          .collection('property_interactions')
          .where('status', isEqualTo: 'disliked')
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Disliked Properties')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _interactionsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final decisionDocs = snapshot.data!.docs;
          if (decisionDocs.isEmpty) {
            return const Center(child: Text('No disliked properties.'));
          }

          _cachedPropertiesFuture ??= _fetchProperties(decisionDocs);

          return FutureBuilder<List<Property>>(
            future: _cachedPropertiesFuture,
            builder: (context, propertySnapshot) {
              if (!propertySnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final properties = propertySnapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: properties.map((property) {
                      return ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PropertiesView(propertyId: property.id),
                              ),
                            );
                          },
                          child: _buildPropertyCard(property),
                        ),
                      );

                    }).toList(),
                  ),
                ),
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

      final listingDoc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(propertyId)
          .get();

      if (listingDoc.exists && listingDoc.data() != null) {
        properties.add(Property.fromFirestore(listingDoc));
      }
    }

    return properties;
  }

  Widget _buildPropertyCard(Property property) {
    debugPrint('🔍 $property');
    return PropertyCard(
      property: property.toMap(),
      onTap: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('What would you like to do?'),
            content: const Text('Choose an action for this disliked property.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'dislike'),
                child: const Text('Move to Liked'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'details'),
                child: const Text('See Details'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );

        if (result == 'dislike') {
          // Update investor's interaction
          await FirebaseFirestore.instance
              .collection('investors')
              .doc(uid)
              .collection('property_interactions')
              .doc(property.id)
              .update({'status': 'liked'});

          // Get investor document to retrieve realtorId
          final investorDoc = await FirebaseFirestore.instance
              .collection('investors')
              .doc(uid)
              .get();

          final realtorId = investorDoc.data()?['realtorId'];
          final interactionDocId = '${property.id}_$uid';

          if (realtorId != null) {
            await FirebaseFirestore.instance
                .collection('realtors')
                .doc(realtorId)
                .collection('interactions')
                .doc(interactionDocId)
                .update({'status': 'liked'});
          }

          setState(() {
            _cachedPropertiesFuture = null; // Trigger refresh
          });
        }
        else if (result == 'details') {
          final propertyData = await fetchPropertyData(property.id);
          showModalBottomSheet(
            context: context,
            constraints: const BoxConstraints(maxWidth: 1000),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            enableDrag: false,
            builder: (_) => PropertyDetailSheet(property: propertyData),
          );
        }
      },

    );
  }

}
