import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../main.dart';

class MapSection extends StatefulWidget {
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
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
  GoogleMapController? _controller;
  ThemeMode? _lastThemeMode;

  final String _darkMapStyle = '''[
    {
      "elementType": "geometry",
      "stylers": [{"color": "#212121"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#212121"}]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "poi",
      "elementType": "geometry",
      "stylers": [{"color": "#2e2e2e"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#383838"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#000000"}]
    }
  ]''';

  @override
  void initState() {
    super.initState();
    themeModeNotifier.addListener(_updateMapStyle);
  }

  @override
  void dispose() {
    themeModeNotifier.removeListener(_updateMapStyle);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMapStyle(); // ensure it's checked anytime dependencies change
  }

  void _updateMapStyle() {
    if (_controller == null) return;

    final isDark = themeModeNotifier.value == ThemeMode.dark;
    if (_lastThemeMode != themeModeNotifier.value) {
      _lastThemeMode = themeModeNotifier.value;
      _controller!.setMapStyle(isDark ? _darkMapStyle : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(30.575437, -96.294686),
        zoom: 13,
      ),
      onMapCreated: (controller) {
        _controller = controller;
        widget.onMapCreated(controller);
        _updateMapStyle();
      },
      markers: widget.markers,
      mapType: MapType.normal,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
    );
  }
}
