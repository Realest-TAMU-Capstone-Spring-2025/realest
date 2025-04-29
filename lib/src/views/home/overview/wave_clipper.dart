import 'package:flutter/material.dart';

/// A custom clipper that creates a wave-shaped path for clipping widgets.
class WaveClipper extends CustomClipper<Path> {
  @override
  /// Defines the wave-shaped clipping path based on the widget's size.
  ///
  /// [size] The size of the widget to be clipped.
  /// Returns a [Path] representing the wave shape.
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height); // Start at the bottom-left corner

    // Define control points for Bezier curves to create wave effect
    final firstControlPoint = Offset(size.width / 4, 0); // Top of first wave
    final firstEndPoint = Offset(size.width / 2, 30);
    final secondControlPoint = Offset(size.width * 3 / 4, 80);
    final secondEndPoint = Offset(size.width, 40);

    // Create quadratic Bezier curves for smooth wave shape
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, size.height); // Extend to bottom-right corner
    path.lineTo(0, size.height); // Return to bottom-left corner
    path.close(); // Close the path to form a complete shape

    return path;
  }

  @override
  /// Determines if the clipper should recalculate the path.
  ///
  /// [oldClipper] The previous clipper instance for comparison.
  /// Returns `false` as the wave shape is static.
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}