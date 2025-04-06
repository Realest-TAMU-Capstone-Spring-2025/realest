import 'package:flutter/material.dart';
import 'cashflow_badge.dart';
import 'status_badge.dart';
import 'property_image.dart';
import 'property_info.dart';

class PropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final VoidCallback onTap;
  final Color? color;

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
                PropertyImage(
                  imageUrl: property['image'],
                  address: property['address'],
                ),
                PropertyInfo(property: property),
              ],
            ),
            StatusBadge(listingType: property['status']),
            CashFlowBadge(propertyId: property["id"], price: property["price"]),
          ],
        ),
      ),
    );
  }
}
