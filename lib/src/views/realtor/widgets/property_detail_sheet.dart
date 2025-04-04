import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/cash_flow_analysis_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/image_gallery_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/important_details_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/intelligent_overview_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/property_description_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/property_location_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/property_price_widget.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_widgets/tax_assessment_widget.dart';
import 'package:realest/src/views/realtor/widgets/select_client_dialog.dart';

class PropertyDetailSheet extends StatelessWidget {
  final Map<String, dynamic> property;

  const PropertyDetailSheet({Key? key, required this.property}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "en_US");

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
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text("Send Property to Client"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      _sendPropertyToClient(context, property["id"]);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    property["address"] as String? ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  PropertyPriceWidget(price: property["list_price"], status: property["status"]),
                  const SizedBox(height: 6),
                  CashFlowAnalysisWidget(listingId: property["id"]),
                  const SizedBox(height: 10),
                  ImportantDetailsWidget(property: property),
                  const SizedBox(height: 20),
                  IntelligentOverviewWidget(overview: property["text"] ?? ""),
                  const SizedBox(height: 8),
                  PropertyDescriptionWidget(description: property["text"] ?? ""),
                  const SizedBox(height: 8),
                  TaxAssessmentWidget(taxHistory: property["tax_history"] ?? []),
                  const SizedBox(height: 20),
                  PropertyLocationWidget(
                    latitude: property["latitude"] ?? 0.0,
                    longitude: property["longitude"] ?? 0.0,
                    propertyId: property["id"] ?? "unknown",
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.message),
                    label: const Text("Contact Realtor"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Implement contact realtor logic
                    },
                  ),
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
          final realtorId = FirebaseAuth.instance.currentUser?.uid;
          for (String clientId in selectedClientIds) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(clientId)
                .collection('recommended_properties')
                .doc(propertyId)
                .set({
              'sent_by': realtorId,
              'sent_at': FieldValue.serverTimestamp(),
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Property sent to ${selectedClientIds.length} client(s)!')),
          );
        },
        property: property, // Pass the property data
      ),
    );
  }
}