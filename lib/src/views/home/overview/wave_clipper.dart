import 'package:flutter/material.dart';

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height); // Start at the very bottom-left

    // Define wave points
    final firstControlPoint = Offset(size.width / 4, 0); // Top of the wave
    final firstEndPoint = Offset(size.width / 2, 30);
    final secondControlPoint = Offset(size.width * 3 / 4, 80);
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

    path.lineTo(size.width, size.height); // Extend to bottom-right
    path.lineTo(0, size.height); // Back to bottom-left
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}