import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PropertyInfo extends StatelessWidget {
  final Map<String, dynamic> property;

  const PropertyInfo({super.key, required this.property});

  Widget _divider() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 8),
    height: 14,
    width: 1,
    color: Colors.grey.shade400,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat("#,##0", "en_US");

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            "\$${currency.format(property["price"])}",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.king_bed_outlined, size: 14),
              const SizedBox(width: 2),
              Text(
                "${property["beds"]}",
                style: theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold),
              ),

              _divider(),

              const Icon(Icons.bathtub_outlined, size: 14),
              const SizedBox(width: 2),
              Text(
                "${property["baths"]}",
                style: theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold),
              ),

              _divider(),

              const Icon(Icons.square_foot, size: 14),
              const SizedBox(width: 2),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: currency.format(property["sqft"]),
                      style: theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: " sqft"),
                  ],
                ),
              ),
            ],


          ),
        ],
      ),
    );
  }
}
