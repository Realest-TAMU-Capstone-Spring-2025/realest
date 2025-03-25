import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final VoidCallback onTap;
  final Color? color; // Make nullable, default to theme's cardColor

  const PropertyCard({
    Key? key,
    required this.property,
    required this.onTap,
    this.color, // Optional override
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "en_US");
    final theme = Theme.of(context); // Access the current theme

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: color ?? theme.cardColor, // Use provided color or theme's cardColor
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.surface, // Dynamic shadow color
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  property["image"] ?? '',
                  width: 130,
                  height: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 130,
                      height: 130,
                      color: theme.colorScheme.surface,
                      child: Icon(Icons.error, color: theme.colorScheme.error),
                    );
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        property["address"] ?? 'Unknown Address',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                      Text(
                        "\$${NumberFormat("#,##0", "en_US").format(property["price"])}",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary, // Use primary color
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.king_bed,
                              size: 16, color: theme.textTheme.bodyMedium?.color),
                          const SizedBox(width: 4),
                          Text("${property["beds"]}",
                              style: theme.textTheme.bodyMedium),
                          const SizedBox(width: 10),
                          Icon(Icons.bathtub_outlined,
                              size: 16, color: theme.textTheme.bodyMedium?.color),
                          const SizedBox(width: 4),
                          Text("${property["baths"]}",
                              style: theme.textTheme.bodyMedium),
                          const SizedBox(width: 10),
                          Icon(Icons.square_foot,
                              size: 16, color: theme.textTheme.bodyMedium?.color),
                          const SizedBox(width: 4),
                          Text("${NumberFormat("#,##0").format(property["sqft"])} sqft",
                              style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        "MLS ID: ${property["mls_id"]}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}