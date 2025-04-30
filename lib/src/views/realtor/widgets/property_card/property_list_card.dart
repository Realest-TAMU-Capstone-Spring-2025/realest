import 'package:flutter/material.dart';
import 'status_badge.dart';

/// Displays a compact list card view for a property.
/// Shows address, price, and status badge.
class PropertyListCard extends StatelessWidget {
  final Map<String, dynamic> property; // Property details
  final VoidCallback onTap;             // Callback when card is tapped
  final Color? color;                   // Optional background color

  const PropertyListCard({
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 80, // Compact height for list view
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color ?? theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Property address and price info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Address text
                    Text(
                      property['address'] ?? 'No address',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Price text
                    Text(
                      '\$${property['price']?.toStringAsFixed(0) ?? 'N/A'}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Property listing status badge (For Sale, Pending, Sold)
              StatusBadge(listingType: property['status']),
            ],
          ),
        ),
      ),
    );
  }
}
