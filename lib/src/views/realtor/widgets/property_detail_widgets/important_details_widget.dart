import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A widget displaying important property details like style, year built, lot size, HOA, and more.
class ImportantDetailsWidget extends StatelessWidget {
  final Map<String, dynamic> property;

  const ImportantDetailsWidget({super.key, required this.property});

  /// Converts raw property type keys into pretty readable format
  String formatPropertyType(String? rawType) {
    if (rawType == null) return "N/A";

    const Map<String, String> prettyLabels = {
      "APARTMENT": "Apartment",
      "BUILDING": "Building",
      "COMMERCIAL": "Commercial",
      "GOVERNMENT": "Government",
      "INDUSTRIAL": "Industrial",
      "CONDO_TOWNHOME": "Condo/Townhome",
      "CONDO_TOWNHOME_ROWHOME_COOP": "Condo/Rowhome/Co-op",
      "CONDO": "Condo",
      "CONDOP": "Condop",
      "CONDOS": "Condos",
      "COOP": "Co-op",
      "DUPLEX_TRIPLEX": "Duplex/Triplex",
      "FARM": "Farm",
      "INVESTMENT": "Investment",
      "LAND": "Land",
      "MOBILE": "Mobile Home",
      "MULTI_FAMILY": "Multi-Family",
      "RENTAL": "Rental",
      "SINGLE_FAMILY": "Single Family",
      "TOWNHOMES": "Townhomes",
      "OTHER": "Other",
    };

    return prettyLabels[rawType] ??
        rawType
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat("#,##0", "en_US");

    final details = [
      {"icon": Icons.architecture, "label": "Style", "value": formatPropertyType(property["style"])},
      {"icon": Icons.calendar_today, "label": "Year Built", "value": "${property["year_built"] ?? "N/A"}"},
      {"icon": Icons.landscape, "label": "Lot Size", "value": "${currencyFormat.format(property["lot_sqft"] ?? 0)} sqft"},
      {"icon": Icons.attach_money, "label": "Price/sqft", "value": "\$${property["price_per_sqft"] ?? "N/A"}"},
      {"icon": Icons.home_work, "label": "HOA", "value": "\$${property["hoa_fee"] ?? "N/A"}/mo"},
      {"icon": Icons.map, "label": "County", "value": property["county"] ?? "N/A"},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✨ Top quick stats
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(icon: Icons.king_bed, label: "${property["beds"]} Beds", theme: theme),
              _verticalDivider(),
              _buildStat(
                icon: Icons.bathtub,
                label: "${(property["baths"] + (property["half_baths"] ?? 0) / 2)} Baths",
                theme: theme,
              ),
              _verticalDivider(),
              _buildStat(
                icon: Icons.square_foot,
                label: "${currencyFormat.format(property["sqft"])} sqft",
                theme: theme,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 🛠️ Additional Details
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: details.map((detail) => _buildDetailCard(detail, theme)).toList(),
        ),
      ],
    );
  }

  /// Build quick stat like "Beds", "Baths", "Sqft"
  Widget _buildStat({required IconData icon, required String label, required ThemeData theme}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  /// Vertical divider between stats
  Widget _verticalDivider() => Container(
    width: 1,
    height: 20,
    color: Colors.grey[400],
    margin: const EdgeInsets.symmetric(horizontal: 12),
  );

  /// Build detailed cards like "HOA", "Lot Size", etc.
  Widget _buildDetailCard(Map<String, dynamic> detail, ThemeData theme) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(detail["icon"], size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail["label"],
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail["value"],
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
