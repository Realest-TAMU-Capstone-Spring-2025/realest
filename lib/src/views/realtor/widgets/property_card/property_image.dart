import 'dart:ui'; // Needed for ImageFilter.blur
import 'package:flutter/material.dart';

/// A widget that displays a property's main image with an address label over a blurred background.
class PropertyImage extends StatelessWidget {
  final String? imageUrl; // Property image URL (can be null)
  final String address;   // Property address to display at the bottom

  const PropertyImage({
    super.key,
    required this.imageUrl,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), // Rounded top corners
      child: AspectRatio(
        aspectRatio: 16 / 10, // Enforce consistent image aspect ratio
        child: Stack(
          children: [
            // Main property image
            Positioned.fill(
              child: Image.network(
                imageUrl ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: theme.colorScheme.surface,
                  child: Icon(Icons.image_not_supported,
                      size: 40, color: theme.colorScheme.error),
                ),
              ),
            ),
            // Blurred background bar at the bottom for address text
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
