import 'package:cloud_firestore/cloud_firestore.dart';

Future<Map<String, dynamic>> fetchPropertyData(String propertyId) async {
  final propertyRef = FirebaseFirestore.instance.collection('listings').doc(propertyId);
  final snapshot = await propertyRef.get();

  if (!snapshot.exists) {
    throw Exception('Property with ID $propertyId not found.');
  }

  final data = snapshot.data() ?? {};

  List<String> altPhotos = [];
  if (data['alt_photos'] is String) {
    altPhotos = data['alt_photos'].split(', ');
  } else if (data['alt_photos'] is List) {
    altPhotos = List<String>.from(data['alt_photos']);
  }

  return {
    'id': propertyId,
    'alt_photos': altPhotos,
    'primary_photo': data['primary_photo'] ?? 'https://via.placeholder.com/400',
    'address': data['full_street_line'] ?? 'Address unavailable',
    'city': data['city'] ?? 'N/A',
    'state': data['state'] ?? 'N/A',
    'zip_code': data['zip_code'] ?? 'N/A',
    'beds': data['beds'] ?? 0,
    'baths': data['full_baths'] ?? 0,
    'half_baths': data['half_baths'] ?? 0,
    'sqft': data['sqft'] ?? 0,
    'price_per_sqft': data['price_per_sqft'] ?? 0,
    'list_price': data['list_price'] ?? 0,
    'estimated_value': data['estimated_value'] ?? 0,
    'tax': data['tax'] ?? 0,
    'hoa_fee': data['hoa_fee'] ?? 0,
    'list_date': data['list_date'] ?? 'N/A',
    'agent_name': data['agent_name'] ?? 'N/A',
    'office_name': data['office_name'] ?? 'N/A',
    'broker_name': data['broker_name'] ?? 'N/A',
    'county': data['county'] ?? 'N/A',
    'latitude': data['latitude'] ?? 0.0,
    'longitude': data['longitude'] ?? 0.0,
    'nearby_schools': data['nearby_schools'] ?? 'N/A',
    'status': data['status'] ?? 'N/A',
    'stories': data['stories'] ?? 0,
    'style': data['style'] ?? 'N/A',
    'new_construction': data['new_construction'] ?? false,
    'tax_history': data['tax_history'] != null
        ? List<Map<String, dynamic>>.from(data['tax_history'])
        : <Map<String, dynamic>>[],
    'builder_name': data['builder_name'] ?? 'N/A',
    'builder_id': data['builder_id'] ?? 'N/A',
    'neighborhoods': data['neighborhoods'] ?? 'N/A',
    'last_sold_date': data['last_sold_date'] ?? 'N/A',
    'parking': data['parking'] ?? 'N/A',
    'agent_id': data['agent_id'] ?? 'N/A',
    'mls_id': data['mls'] ?? 'N/A',
    'description': data['text_description'] ?? 'No description available',
    'property_type': data['property_type'] ?? 'Unknown',
    'fips_code': data['fips_code'] ?? 'N/A',
    'agent_mls_set': data['agent_mls_set'] ?? 'N/A',
    'text': data['text'] ?? 'No description available',
    'year_built': data['year_built'] ?? 0,
    'lot_sqft': data['lot_sqft'] ?? 0,
  };
}
