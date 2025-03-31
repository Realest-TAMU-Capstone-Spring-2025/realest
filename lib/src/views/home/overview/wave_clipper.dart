import 'package:flutter/material.dart';

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50); // Start at bottom-left with some offset

    // Define wave points
    final firstControlPoint = Offset(size.width / 4, 0);  // Flipped y
    final firstEndPoint = Offset(size.width / 2, 30);     // Flipped y
    final secondControlPoint = Offset(size.width * 3/4, 80);  // Flipped y
    final secondEndPoint = Offset(size.width, 40);

    // Create quadratic Bezier curves for the wave
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

    path.lineTo(size.width, size.height);  // Close to bottom-right
    path.lineTo(0, size.height);           // Back to bottom-left
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}