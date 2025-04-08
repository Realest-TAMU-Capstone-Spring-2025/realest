import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status Badge
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

          // Price
          Text(
            price != null ? "\$${currencyFormat.format(price)}" : "Price Unavailable",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

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

  String _formatStatus(String status) {
    return status
        .replaceAll("_", " ")
        .toLowerCase()
        .split(' ')
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' ');
  }
}
