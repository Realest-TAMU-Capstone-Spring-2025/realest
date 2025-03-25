import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ImportantDetailsWidget extends StatelessWidget {
  final Map<String, dynamic> property;

  const ImportantDetailsWidget({Key? key, required this.property}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat("#,##0", "en_US");

    final List<Map<String, dynamic>> details = [
      {"icon": Icons.architecture, "label": "Style", "value": property["style"] ?? "N/A"},
      {"icon": Icons.calendar_today, "label": "Year Built", "value": "${property["year_built"] ?? "N/A"}"},
      {"icon": Icons.landscape, "label": "Lot Size", "value": "${currencyFormat.format(property["lot_sqft"] ?? 0)} sqft"},
      {"icon": Icons.attach_money, "label": "Price/sqft", "value": "\$${property["price_per_sqft"] ?? "N/A"}"},
      {"icon": Icons.home_work, "label": "HOA", "value": "\$${property["hoa_fee"] ?? "N/A"}/mo"},
      {"icon": Icons.location_city, "label": "Neighborhood", "value": property["neighborhoods"] ?? "N/A"},
      {"icon": Icons.map, "label": "County", "value": property["county"] ?? "N/A"},
    ];

    return Column(
      children: [
        // 📌 **Top Row - Quick Overview (Beds, Baths, Size)**
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDetail(Icons.king_bed, "${property["beds"]} Beds", theme),
            _buildDivider(),
            _buildDetail(Icons.bathtub, "${(property["baths"] + (property["half_baths"] ?? 0) / 2)} Baths", theme),
            _buildDivider(),
            _buildDetail(Icons.square_foot, "${currencyFormat.format(property["sqft"])} sqft", theme),
          ],
        ),
        const SizedBox(height: 12),

        const SizedBox(height: 10),

        // 📌 **Wrapped List of Details**
        _buildWrappedDetails(details, theme),
      ],
    );
  }

  /// ✅ **Wrap Instead of Grid - No Overflow, Perfect Fit**
  Widget _buildWrappedDetails(List<Map<String, dynamic>> details, ThemeData theme) {
    return Wrap(
        spacing: 12, // Horizontal spacing
        runSpacing: 12, // Vertical spacing
        children: details.map((detail) => _buildCompactItem(detail, theme)).toList(),
      );
  }

  /// ✅ **Compact Card for Each Detail (Prevents Overflow)**
  Widget _buildCompactItem(Map<String, dynamic> detail, ThemeData theme) {
    return IntrinsicWidth(
      child: Container(
        constraints: const BoxConstraints(minWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(detail["icon"], color: theme.colorScheme.primary, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    detail["label"],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2), // Space between label and value
                  Text(
                    detail["value"],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ **Divider Between Icons**
  Widget _buildDivider() => Container(
    width: 2,
    height: 30,
    color: Colors.grey[400],
  );

  /// ✅ **Quick Stats Row (Beds, Baths, Size)**
  Widget _buildDetail(IconData icon, String text, ThemeData theme) => Row(
    children: [
      Icon(icon, color: theme.colorScheme.primary, size: 24),
      const SizedBox(width: 4),
      Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    ],
  );
}
