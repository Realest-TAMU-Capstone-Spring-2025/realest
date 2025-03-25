import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PropertyLocationWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String propertyId;

  const PropertyLocationWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.propertyId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12), // Rounded corners for modern look
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(latitude, longitude),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId(propertyId),
                  position: LatLng(latitude, longitude),
                ),
              },
            ),
          ),
        ),
      ],
    );
  }
}
