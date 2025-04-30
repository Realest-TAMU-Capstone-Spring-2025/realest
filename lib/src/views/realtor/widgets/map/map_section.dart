import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../main.dart'; // Theme mode notifier for dynamic styling

/// A Google Map widget that updates its style based on light/dark theme
/// and shows property markers with tap functionality.
class MapSection extends StatefulWidget {
  final Set<Marker> markers; // Set of map markers (properties)
  final Function(GoogleMapController) onMapCreated; // Callback when the map is created
  final Function(String propertyId, LatLng location) onPropertyTap; // Callback when a property is tapped

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
  ThemeMode? _lastThemeMode; // Last known theme mode for optimization

  // Custom dark mode map styling
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
    themeModeNotifier.addListener(_updateMapStyle); // Listen for theme changes
  }

  @override
  void dispose() {
    themeModeNotifier.removeListener(_updateMapStyle); // Clean up
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMapStyle(); // Update map style if dependencies change
  }

  /// Updates the Google Map style based on the current theme mode
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
        target: LatLng(30.575437, -96.294686), // Default center position
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
