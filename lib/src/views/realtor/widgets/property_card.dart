import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final VoidCallback onTap;

  const PropertyCard({
    Key? key,
    required this.property,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "en_US");

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                        Text(
                          "\$${NumberFormat("#,##0", "en_US").format(property["price"])}",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.king_bed, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text("${property["beds"]}", style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(width: 10),
                            Icon(Icons.bathtub_outlined, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text("${property["baths"]}", style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(width: 10),
                            Icon(Icons.square_foot, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text("${NumberFormat("#,##0").format(property["sqft"])} sqft", style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          "MLS ID: ${property["mls_id"]}",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}
