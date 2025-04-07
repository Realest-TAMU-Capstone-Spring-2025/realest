import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:realest/user_provider.dart'; // Ensure this path matches the actual location of UserProvider
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/agent_info_panel.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/cash_flow_analysis_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/image_gallery_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/important_details_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/intelligent_overview_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/property_description_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/property_location_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/property_price_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/property_summary_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/tax_assessment_widget.dart';
import 'package:realest/src/views/realtor/widgets/select_client_dialog.dart';

class PropertyDetailSheet extends StatelessWidget {
  final Map<String, dynamic> property;

  const PropertyDetailSheet({Key? key, required this.property}) : super(key: key);

  //check if the user is a realtor
  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "en_US");
    final bool isRealtor = Provider.of<UserProvider>(context).userRole == "realtor";

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
                  const SizedBox(height: 8),
                  AgentInfoPanel(property: property),
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
          for (String clientId in selectedClientIds) {
            // For each selected investor, add the property to the recommended_properties subcollection.
            await FirebaseFirestore.instance
                .collection('investors')
                .doc(clientId)
                .collection('recommended_properties')
                .doc(propertyId)
                .set({
              'property_id': propertyId,
              'sent_at': FieldValue.serverTimestamp(),
              'status': 'pending',
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Property sent to ${selectedClientIds.length} investor(s)!')),
          );
        },
        property: property, // Pass the property data
      ),
    );
  }

}