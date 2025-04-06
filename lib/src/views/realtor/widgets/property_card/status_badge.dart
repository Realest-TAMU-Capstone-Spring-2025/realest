import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String? listingType;

  const StatusBadge({super.key, required this.listingType});

  @override
  Widget build(BuildContext context) {
    if (listingType == null) return const SizedBox();

    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          _getStatusLabel(listingType),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(String? listingType) {
    switch (listingType) {
      case 'FOR_SALE':
        return 'For Sale';
      case 'PENDING':
        return 'Pending';
      case 'FOR_RENT':
        return 'For Rent';
      case 'SOLD':
        return 'Sold';
      default:
        return 'Unknown';
    }
  }
}
