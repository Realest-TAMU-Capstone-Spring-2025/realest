import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../../../util/property_fetch_helpers.dart';
import '../marker/property_marker.dart';
import '../property_detail_sheet.dart';
import '../../../../models/property_filter.dart';

/// Fetch basic property data from Firestore by ID
Future<Map<String, dynamic>> getSelectedPropertyData(String id) async {
  final propertyRef = FirebaseFirestore.instance.collection('listings').doc(id);
  final snapshot = await propertyRef.get();

  if (!snapshot.exists) return {};
  final data = snapshot.data()!;
  return {
    'id': snapshot.id,
    ...data,
  };
}

/// Handles what happens when a user taps a marker or selects a property
Future<void> handlePropertyTap({
  required BuildContext context,
  required String propertyId,
  required LatLng location,
  required GoogleMapController mapController,
  required Function(String) setSelectedId,
}) async {
  setSelectedId(propertyId);
  mapController.animateCamera(CameraUpdate.newLatLng(location));

  final propertyData = await fetchPropertyData(propertyId);
  showModalBottomSheet(
    context: context,
    constraints: const BoxConstraints(maxWidth: 1000),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: false,
    builder: (_) => PropertyDetailSheet(property: propertyData),
  );
}

/// Builds map markers from Firestore-style property data
Future<Set<Marker>> buildPropertyMarkers({
  required List<Map<String, dynamic>> properties,
  required String? selectedId,
  required Function(String propertyId, LatLng location) onTap,
}) async {
  final Set<Marker> markers = {};

  for (final property in properties) {
    final location = LatLng(property['latitude'], property['longitude']);
    final price = property['price'] ?? 0;

    final marker = Marker(
      markerId: MarkerId(property['id']),
      position: location,
      icon: await createPriceMarkerBitmap(
        "\$${(price / 1000).round()}K",
        color: getStatusColor(property['status']),
      ),
      onTap: () => onTap(property['id'], location),
    );

    markers.add(marker);
  }

  return markers;
}

/// Load custom map styling
Future<String?> loadMapStyle() async {
  try {
    return await rootBundle.loadString('assets/dark_map_style.json');
  } catch (_) {
    return null;
  }
}