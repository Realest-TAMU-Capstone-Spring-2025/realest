import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PropertyPriceWidget extends StatelessWidget {
  final num? price;
  final String status;

  const PropertyPriceWidget({Key? key, required this.price, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat("#,##0", "en_US");

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property Status
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              color: _getStatusColor(theme),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.toUpperCase().replaceAll("_", " "),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Property Price
          Text(
            price != null ? "\$${currencyFormat.format(price)}" : "Price Unavailable",
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// **🔵 Dynamic Status Color Based on Listing State**
  Color _getStatusColor(ThemeData theme) {
    switch (status) {
      case "FOR_SALE":
        return Colors.green;
      case "PENDING":
        return Colors.orange;
      case "SOLD":
        return Colors.red;
      default:
        return theme.colorScheme.secondary;
    }
  }
}
