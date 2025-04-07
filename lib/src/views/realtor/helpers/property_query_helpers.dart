import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/property_filter.dart';

/// Build filtered Firestore query from filter model
Query<Map<String, dynamic>> buildFilteredQuery(PropertyFilter filters) {
  Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('listings');

  if (filters.minPrice != null) {
    query = query.where('list_price', isGreaterThanOrEqualTo: filters.minPrice);
  }
  if (filters.maxPrice != null) {
    query = query.where('list_price', isLessThanOrEqualTo: filters.maxPrice);
  }
  if (filters.minBeds != null) {
    query = query.where('beds', isGreaterThanOrEqualTo: filters.minBeds);
  }
  if (filters.minBaths != null) {
    query = query.where('full_baths', isGreaterThanOrEqualTo: filters.minBaths);
  }
  if (filters.homeTypes != null && filters.homeTypes!.isNotEmpty) {
    query = query.where('style', whereIn: filters.homeTypes);
  }
  if (filters.maxHoa != null) {
    query = query.where('hoa_fee', isLessThanOrEqualTo: filters.maxHoa);
  }
  if (filters.minSqft != null) {
    query = query.where('sqft', isGreaterThanOrEqualTo: filters.minSqft);
  }
  if (filters.maxSqft != null) {
    query = query.where('sqft', isLessThanOrEqualTo: filters.maxSqft);
  }
  if (filters.minLotSize != null) {
    query = query.where('lot_sqft', isGreaterThanOrEqualTo: filters.minLotSize);
  }
  if (filters.maxLotSize != null) {
    query = query.where('lot_sqft', isLessThanOrEqualTo: filters.maxLotSize);
  }
  if (filters.minYearBuilt != null) {
    query = query.where('year_built', isGreaterThanOrEqualTo: filters.minYearBuilt);
  }
  if (filters.maxYearBuilt != null) {
    query = query.where('year_built', isLessThanOrEqualTo: filters.maxYearBuilt);
  }
  if (filters.selectedStatuses != null && filters.selectedStatuses!.isNotEmpty) {
    query = query.where('status', whereIn: filters.selectedStatuses);
  }
  print('Selected statuses: ${filters.selectedStatuses}');
  if (filters.isNewConstruction != null) {
    query = query.where('new_construction', isEqualTo: filters.isNewConstruction);
  }
  if (filters.maxFloors != null) {
    query = query.where('stories', isLessThanOrEqualTo: filters.maxFloors);
  }
  if (filters.maxDaysOnMarket != null) {
    query = query.where('days_on_mls', isLessThanOrEqualTo: filters.maxDaysOnMarket);
  }

  return query.orderBy('days_on_mls');
}

/// Fetch all filtered properties (used for both list and map)
Future<List<Map<String, dynamic>>> fetchPropertiesForMap(PropertyFilter filters) async {
  final snapshot = await buildFilteredQuery(filters).get();

  return snapshot.docs.map((doc) {
    final data = doc.data();
    return {
      "id": doc.id,
      "latitude": data["latitude"] ?? 0.0,
      "longitude": data["longitude"] ?? 0.0,
      "price": data["list_price"] ?? 0,
      "beds": data["beds"] ?? 0,
      "baths": data["full_baths"] ?? 0,
      "address": data["full_street_line"] ?? "Unknown Address",
      "status": data["status"] ?? "N/A",
    };
  }).toList();
}
