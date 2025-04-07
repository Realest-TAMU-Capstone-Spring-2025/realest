import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<BitmapDescriptor> createPriceMarkerBitmap(
    String priceText, {
      Color color = Colors.red,
    }) async {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(
      text: priceText,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
  );
  textPainter.layout();

  const double padding = 15;
  final double width = textPainter.width + padding;
  const double height = 20;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final Paint paint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  final RRect rrect = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, width, height),
    const Radius.circular(12),
  );

  canvas.drawRRect(rrect, paint);
  textPainter.paint(canvas, Offset(padding / 2, (height - textPainter.height) / 2));

  final picture = recorder.endRecording();
  final img = await picture.toImage(width.toInt(), height.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}

Color getStatusColor(String? listingType) {
  switch (listingType) {
    case 'FOR_SALE':
      return Colors.red.shade700;
    case 'PENDING':
      return Colors.amber.shade700;
    case 'FOR_RENT':
      return Colors.deepPurple.shade600;
    case 'SOLD':
      return Colors.blue.shade600;
    default:
      return Colors.grey;
  }
}