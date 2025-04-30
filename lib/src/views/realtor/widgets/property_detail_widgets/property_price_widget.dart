import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Displays the property's current price and listing status badge.
class PropertyPriceWidget extends StatelessWidget {
  final num? price;
  final String status;

  const PropertyPriceWidget({
    Key? key,
    required this.price,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat("#,##0", "en_US");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status badge (e.g., For Sale, Pending)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(theme),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _formatStatus(status),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Price display
          Text(
            price != null ? "\$${currencyFormat.format(price)}" : "Price Unavailable",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Get a color based on the property status
  Color _getStatusColor(ThemeData theme) {
    switch (status) {
      case "FOR_SALE":
        return Colors.green.shade600;
      case "PENDING":
        return Colors.orange.shade700;
      case "SOLD":
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  /// Format the status text (e.g., FOR_SALE -> For Sale)
  String _formatStatus(String status) {
    return status
        .replaceAll("_", " ")
        .toLowerCase()
        .split(' ')
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' ');
  }
}
