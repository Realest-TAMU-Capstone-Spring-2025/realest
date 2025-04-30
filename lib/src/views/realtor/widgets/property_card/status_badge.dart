import 'package:flutter/material.dart';

/// A small badge widget that displays the property's current listing status.
/// (e.g., For Sale, Pending, Sold, etc.)
class StatusBadge extends StatelessWidget {
  final String? listingType; // Property listing type

  const StatusBadge({super.key, required this.listingType});

  @override
  Widget build(BuildContext context) {
    // If no listing type is provided, return an empty widget
    if (listingType == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65), // Semi-transparent dark background
        borderRadius: BorderRadius.circular(6), // Slightly rounded corners
      ),
      child: Text(
        _getStatusLabel(listingType), // Get human-readable label
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Converts backend listingType codes into user-friendly labels
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
        return 'Unknown'; // Default if the status is not recognized
    }
  }
}
