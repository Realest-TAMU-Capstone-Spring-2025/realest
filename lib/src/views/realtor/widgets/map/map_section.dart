import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSection extends StatelessWidget {
  final Set<Marker> markers;
  final Function(GoogleMapController) onMapCreated;
  final Function(String propertyId, LatLng location) onPropertyTap;

  const MapSection({
    Key? key,
    required this.markers,
    required this.onMapCreated,
    required this.onPropertyTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(30.6280, -96.3344),
        zoom: 12,
      ),
      onMapCreated: onMapCreated,
      markers: markers,
      mapType: MapType.normal,
    );
  }
}
