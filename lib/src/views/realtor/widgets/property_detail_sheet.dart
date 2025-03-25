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

class PropertyDetailSheet extends StatelessWidget {
  final Map<String, dynamic> property;

  const PropertyDetailSheet({Key? key, required this.property})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "en_US");

    return PointerInterceptor(
      child: Stack(
        children: [
          // 🏡 Property Details Content
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
                    imageUrls: List<String>.from(property["alt_photos"] ?? []), // Safe casting
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
                  PropertyDescriptionWidget(
                    description: property["text"] ?? "", // Handle missing descriptions
                  ),
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

          // ❌ **Close Button in Top Right**
          Positioned(
            right: 10,
            top: 10,
            child: GestureDetector(
              onTap: () => Navigator.pop(context), // Close Modal
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.6), // Background for contrast
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
