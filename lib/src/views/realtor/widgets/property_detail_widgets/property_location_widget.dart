import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Displays the property location on a small embedded Google Map with a marker.
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
            borderRadius: BorderRadius.circular(12), // Rounded corners for a modern look
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
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              liteModeEnabled: true, // Optional: Lite mode for better performance in a widget
            ),
          ),
        ),
      ],
    );
  }
}
