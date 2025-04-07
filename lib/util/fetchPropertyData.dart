import 'package:cloud_firestore/cloud_firestore.dart';

Future<Map<String, dynamic>> fetchPropertyData(String propertyId) async {
    final propertyRef = FirebaseFirestore.instance.collection('listings').doc(propertyId);
    final snapshot = await propertyRef.get();

    final data = snapshot.data() ?? {};

    //convert alt_photos to a list of strings
    List<String> altPhotos = data['alt_photos'].split(', ');
    // add "http://0.0.0.0:8080/" to each alt_photo"
    altPhotos = altPhotos.map((photo) => photo).toList();
    return {
      'id': propertyId,
      'alt_photos': altPhotos,
      'primary_photo': data['primary_photo'] as String? ??
          'https://via.placeholder.com/400',
      'address': data['full_street_line'] as String? ?? 'Address unavailable',
      'city': data['city'] as String? ?? 'N/A',
      'state': data['state'] as String? ?? 'N/A',
      'zip_code': data['zip_code'] as String? ?? 'N/A',
      'beds': data['beds'] as int? ?? 0,
      'baths': data['full_baths'] as int? ?? 0,
      'half_baths': data['half_baths'] as int? ?? 0,
      'sqft': data['sqft'] as int? ?? 0,
      'price_per_sqft': data['price_per_sqft'] as num? ?? 0,
      'list_price': data['list_price'] as int? ?? 0,
      'estimated_value': data['estimated_value'] as int? ?? 0,
      'tax': data['tax'] as int? ?? 0,
      'hoa_fee': data['hoa_fee'] as int? ?? 0,
      'list_date': data['list_date'] as String? ?? 'N/A',
      'agent_name': data['agent_name'] as String? ?? 'N/A',
      'office_name': data['office_name'] as String? ?? 'N/A',
      'broker_name': data['broker_name'] as String? ?? 'N/A',
      'county': data['county'] as String? ?? 'N/A',
      'latitude': data['latitude'] as double? ?? 0.0,
      'longitude': data['longitude'] as double? ?? 0.0,
      'nearby_schools': data['nearby_schools'] as String? ?? 'N/A',
      'status': data['status'] as String? ?? 'N/A',
      'stories': data['stories'] as int? ?? 0,
      'style': data['style'] as String? ?? 'N/A',
      'new_construction': data['new_construction'] as bool? ?? false,
      'tax_history': data['tax_history'] != null
          ? List<Map<String, dynamic>>.from(data['tax_history'])
          : <Map<String, dynamic>>[],
      'builder_name': data['builder_name'] as String? ?? 'N/A',
      'builder_id': data['builder_id'] as String? ?? 'N/A',
      'neighborhoods': data['neighborhoods'] as String? ?? 'N/A',
      'last_sold_date': data['last_sold_date'] as String? ?? 'N/A',
      'parking': data['parking'] as String? ?? 'N/A',
      'agent_id': data['agent_id'] as String? ?? 'N/A',
      'mls_id': data['mls'] as String? ?? 'N/A',
      'description': data['text_description'] as String? ??
          'No description available',
      'property_type': data['property_type'] as String? ?? 'Unknown',
      'fips_code': data['fips_code'] as String? ?? 'N/A',
      'agent_mls_set': data['agent_mls_set'] as String? ?? 'N/A',
      'text': data['text'] as String? ?? 'No description available',
      'year_built': data['year_built'] as int? ?? 0,
      'lot_sqft': data['lot_sqft'] as int? ?? 0,
    };
  }