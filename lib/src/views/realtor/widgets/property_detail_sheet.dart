import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realest/user_provider.dart'; // Ensure this path matches the actual location of UserProvider
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/agent_info_panel.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/cash_flow_analysis_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/image_gallery_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/important_details_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/property_description_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/property_location_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/property_summary_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/tax_assessment_widget.dart';
import 'package:realest/src/views/realtor/widgets/select_client_dialog.dart';

class PropertyDetailSheet extends StatelessWidget {
  final Map<String, dynamic> property;

  const PropertyDetailSheet({Key? key, required this.property}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "en_US");
    final userProvider = Provider.of<UserProvider>(context);
    final bool isRealtor = userProvider.userRole == "realtor";

    return PointerInterceptor(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ImageGalleryWidget(
                    imageUrls: List<String>.from(property["alt_photos"] ?? []),
                  ),
                  const SizedBox(height: 12),
                  if (isRealtor)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded, size: 20),
                      label: const Text(
                        "Send Property to Client",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () {
                        _sendPropertyToClient(context, property["id"]);
                      },
                    ),
                  if (!isRealtor)
                    ElevatedButton.icon(
                      icon: const Icon(Icons.note_add_rounded, size: 20),
                      label: const Text(
                        "Send Note About Property To Realtor",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.2),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () {
                        _sendNoteToRealtor(context, property["id"], userProvider.uid!);
                      },
                    ),

                  const SizedBox(height: 12),

                  PropertySummaryWidget(
                    property: property,
                  ),
                  const SizedBox(height: 6),
                  CashFlowAnalysisWidget(listingId: property["id"], isRealtor: isRealtor),
                  const SizedBox(height: 10),
                  ImportantDetailsWidget(property: property),
                  const SizedBox(height: 8),
                  PropertyDescriptionWidget(description: property["text"] ?? ""),
                  const SizedBox(height: 8),
                  TaxAssessmentWidget(taxHistory: property["tax_history"] ?? []),
                  const SizedBox(height: 8),
                  PropertyExtraDetailsPanel(property: property),
                  const SizedBox(height: 20),
                  PropertyLocationWidget(
                    latitude: property["latitude"] ?? 0.0,
                    longitude: property["longitude"] ?? 0.0,
                    propertyId: property["id"] ?? "unknown",
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.6),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendPropertyToClient(BuildContext context, String propertyId) async {
    await showDialog(
      context: context,
      builder: (_) => SelectClientDialog(
        onClientsSelected: (List<String> selectedClientIds) async {
          final firestore = FirebaseFirestore.instance;
          final realtorId = FirebaseAuth.instance.currentUser!.uid; // or however you're identifying the realtor

          final batch = firestore.batch();

          for (String clientId in selectedClientIds) {
            final investorRef = firestore
                .collection('investors')
                .doc(clientId)
                .collection('property_interactions')
                .doc(propertyId);

            final realtorRef = firestore
                .collection('realtors')
                .doc(realtorId)
                .collection('interactions')
                .doc('${propertyId}_$clientId');

            // Create the interaction data for realtor
            final interactionDataRealtor = {
              'propertyId': propertyId,
              'investorId': clientId,
              'realtorId': realtorId,
              'status': 'sent',
              'timestamp': FieldValue.serverTimestamp(),
              'sentByRealtor': true,
              'propertyDetails':
              {
                'price': property['price'] ?? 0,
                'address': property['address'] ?? '',
                'status': property['status'] ?? '',
              }
            };

            //create the interaction data for investor
            final interactionDataInvestor = {
              'propertyId': propertyId,
              'investorId': clientId,
              'realtorId': realtorId,
              'status': 'sent',
              'timestamp': FieldValue.serverTimestamp(),
              'sentByRealtor': true,
            };

            batch.set(investorRef, interactionDataInvestor);
            batch.set(realtorRef, interactionDataRealtor);
          }

          await batch.commit();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Property sent to ${selectedClientIds.length} investor(s)!')),
          );
        },
        property: property, // assuming this is defined and passed properly
      ),
    );
  }


  void _sendNoteToRealtor(BuildContext context, String propertyId, String investorId) async {
    TextEditingController noteController = TextEditingController();
    
    // Show dialog to enter note
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Note to Realtor'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            hintText: 'Write your note about this property...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (noteController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a note')),
                );
                return;
              }
              
              // First, get the realtorId from the investor's document
              try {
                final investorDoc = await FirebaseFirestore.instance
                    .collection('investors')
                    .doc(investorId)
                    .get();
                
                if (!investorDoc.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Investor profile not found')),
                  );
                  Navigator.pop(context);
                  return;
                }
                
                final realtorId = investorDoc.data()?['realtorId'];
                
                if (realtorId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You don\'t have a realtor assigned')),
                  );
                  Navigator.pop(context);
                  return;
                }
                
                // Add the note to the realtor's notes collection
                await FirebaseFirestore.instance
                    .collection('realtors')
                    .doc(realtorId)
                    .collection('notes')
                    .add({
                  'propertyId': propertyId,
                  'investorId': investorId,
                  'note': noteController.text.trim(),
                  'timestamp': FieldValue.serverTimestamp(),
                  'read': false,

                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note sent to your realtor successfully!')),
                );
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error sending note: ${e.toString()}')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
