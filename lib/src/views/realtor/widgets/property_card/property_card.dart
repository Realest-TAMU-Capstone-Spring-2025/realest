import 'package:flutter/material.dart';
import 'cashflow_badge.dart';  // Widget to display cashflow info
import 'status_badge.dart';    // Widget to display listing status (For Sale, Pending, etc.)
import 'property_image.dart';  // Widget to display the main property image
import 'property_info.dart';   // Widget to display property details (price, address, etc.)

/// A clickable card that shows property image, info, status, and cash flow badges.
class PropertyCard extends StatelessWidget {
  final Map<String, dynamic> property; // Property data
  final VoidCallback onTap;             // Tap handler
  final Color? color;                   // Optional background color

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color ?? theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Displays the main image of the property
                PropertyImage(
                  imageUrl: property['image'],
                  address: property['address'],
                ),
                // Displays property info like price, beds, baths, address
                PropertyInfo(property: property),
              ],
            ),
            // Top-left badge showing property status (For Sale, Sold, etc.)
            Positioned(
              left: 10,
              top: 10,
              child: StatusBadge(listingType: property['status']),
            ),
            // Top-right badge showing cash flow estimates (BE and PE)
            Positioned(
              right: 10,
              top: 10,
              child: CashFlowBadge(propertyId: property["id"]),
            ),
          ],
        ),
      ),
    );
  }
}
