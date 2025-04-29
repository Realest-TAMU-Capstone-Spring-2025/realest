import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../util/property_fetch_helpers.dart';
import '../../realtor/widgets/property_card/property_card.dart';
import '../../realtor/widgets/property_detail_sheet.dart';
import 'properties_view.dart'; // Import PropertiesView
import '../swiping/property_swiping.dart';

/// Displays a list of properties liked (saved) by the logged-in investor.
class SavedProperties extends StatefulWidget {
  const SavedProperties({super.key});

  @override
  State<SavedProperties> createState() => _SavedPropertiesState();
}

/// Manages property fetching and interactions for [SavedProperties].
class _SavedPropertiesState extends State<SavedProperties> {
  /// Formats numbers with commas for display (e.g., 1000 → 1,000).
  final NumberFormat currencyFormat = NumberFormat('#,##0', 'en_US');

  /// User ID of the logged-in investor.
  late final String? uid = FirebaseAuth.instance.currentUser?.uid;

  /// Stream of liked property interactions from Firestore.
  late final Stream<QuerySnapshot> _interactionsStream;

  /// Cached future for fetched properties to avoid redundant queries.
  Future<List<Property>>? _cachedPropertiesFuture;

  @override
  void initState() {
    super.initState();
    // Initialize the stream for liked property interactions if user is logged in
    if (uid != null) {
      _interactionsStream = FirebaseFirestore.instance
          .collection('investors')
          .doc(uid)
          .collection('property_interactions')
          .where('status', isEqualTo: 'liked')
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Builds the UI, handling authentication and data states
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Properties')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _interactionsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final decisionDocs = snapshot.data!.docs;
          if (decisionDocs.isEmpty) {
            return const Center(child: Text('No saved properties.'));
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

  /// Fetches property details for liked properties from Firestore.
  ///
  /// [decisionDocs] List of documents containing property interaction data.
  /// Returns a [Future] containing a list of [Property] objects.
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

  /// Builds a property card with options to move to disliked or view details.
  ///
  /// [property] The property data to display.
  /// Returns a [Widget] representing the property card.
  Widget _buildPropertyCard(Property property) {
    debugPrint('🔍 $property');
    return PropertyCard(
      property: property.toMap(),
      onTap: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('What would you like to do?'),
            content: const Text('Choose an action for this saved property.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'dislike'),
                child: const Text('Move to Disliked'),
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
          // Update investor's interaction to 'disliked' in Firestore
          await FirebaseFirestore.instance
              .collection('investors')
              .doc(uid)
              .collection('property_interactions')
              .doc(property.id)
              .update({'status': 'disliked'});

          // Update realtor's interaction if applicable
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
                .update({'status': 'disliked'});
          }

          setState(() {
            _cachedPropertiesFuture = null; // Trigger refresh
          });
        } else if (result == 'details') {
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