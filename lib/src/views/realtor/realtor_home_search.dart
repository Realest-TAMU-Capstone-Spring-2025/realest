import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'widgets/property_card.dart';
import 'widgets/property_detail_sheet.dart';

class RealtorHomeSearch extends StatefulWidget {
  const RealtorHomeSearch({Key? key}) : super(key: key);

  @override
  _RealtorHomeSearchState createState() => _RealtorHomeSearchState();
}

class _RealtorHomeSearchState extends State<RealtorHomeSearch> {
  late GoogleMapController _mapController;
  bool _isFilterOpen = false;
  String? _selectedPropertyId;
  bool _showingMap = true; // default to map on small screen


  // **Pagination Settings**
  final int _perPage = 10;
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  // **Filter Settings**
  double _minPrice = 100000;
  double _maxPrice = 1000000;
  int _minBeds = 1;
  num _minBaths = 1.0;

  BitmapDescriptor? _selectedMarkerIcon;
  BitmapDescriptor? _defaultMarkerIcon;
  List<Map<String, dynamic>> properties = [];
  List<Map<String, dynamic>> allFilteredPropertiesForMap = []; // Markers


  @override
  void initState() {
    super.initState();
    _fetchProperties();
    _fetchAllFilteredPropertiesForMap();
    _loadCustomMarkers();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _fetchProperties({bool isLoadMore = false}) async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    Query query = FirebaseFirestore.instance
        .collection('listings')
        .orderBy('list_price')
        .limit(_perPage);

    if (_lastDocument != null && isLoadMore) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      _lastDocument = snapshot.docs.last;
    } else {
      _hasMore = false;
    }

    final List<Map<String, dynamic>> fetchedProperties = snapshot.docs.map((doc) {
      // ✅ Explicitly cast Firestore document data
      final data = doc.data() as Map<String, dynamic>;

      return {
        "id": doc.id,  // Store the Firestore ID
        "latitude": data["latitude"] ?? 0.0,
        "longitude": data["longitude"] ?? 0.0,
        "address": data["full_street_line"] ?? "Unknown Address",
        "price": data["list_price"] ?? 0,
        "beds": data["beds"] ?? 0,
        "baths": data["full_baths"] ?? 0,
        "sqft": data["sqft"] ?? 0,
        "mls_id": data["mls_id"] ?? "N/A",
        "image": (data["primary_photo"] != null && data["primary_photo"] != "")
            ? data["primary_photo"]
            : "https://bearhomes.com/wp-content/uploads/2019/01/default-featured.png",
      };
    }).toList(); // ✅ Now it's a List<Map<String, dynamic>>

    setState(() {
      if (isLoadMore) {
        properties.addAll(fetchedProperties);
      } else {
        properties = fetchedProperties;
      }
    });

    _isLoadingMore = false;
  }


  List<Map<String, dynamic>> _filteredProperties() {
    return properties
        .where((property) =>
    property["price"] >= _minPrice &&
        property["price"] <= _maxPrice &&
        property["beds"] >= _minBeds &&
        property["baths"] >= _minBaths)
        .toList();
  }




  Future<void> _selectProperty(String propertyId, LatLng location) async {
    final selectedProperty = properties.firstWhere((p) => p["id"] == propertyId);

    setState(() => _selectedPropertyId = propertyId);

    _mapController.animateCamera(CameraUpdate.newLatLng(location));

    //gather all the data for the selected property from firebase
    final propertyData = await _fetchPropertyData(propertyId);


    showModalBottomSheet(
      context: context,
      constraints: BoxConstraints(
        maxWidth:  1000,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PropertyDetailSheet(property: propertyData),
      //disable swipe to close
      enableDrag: false,

    );
  }



  Future<Map<String, dynamic>> _fetchPropertyData(String propertyId) async {
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



  Set<Marker> _createMarkers() {
    if (_defaultMarkerIcon == null || _selectedMarkerIcon == null) {
      return {};
    }

    return allFilteredPropertiesForMap.map((property) {
      final LatLng location = LatLng(property["latitude"], property["longitude"]);
      final bool isSelected = _selectedPropertyId == property["id"];

      return Marker(
        markerId: MarkerId(property["id"]),
        position: location,
        icon: isSelected ? _selectedMarkerIcon! : _defaultMarkerIcon!,
        infoWindow: InfoWindow(
          title: property["address"],
          snippet: "\$${NumberFormat("#,##0").format(property["price"])}",
        ),
        onTap: () => _selectProperty(property["id"], location),
      );
    }).toSet();
  }



  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 800;


    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // **Left Side: Google Map**
              ((_showingMap && isSmallScreen) || !isSmallScreen)? Expanded(
                flex: 1,
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(30.6280, -96.3344),
                    zoom: 12,
                  ),
                  mapType: MapType.normal,
                  onMapCreated: _onMapCreated,
                  markers: _createMarkers(),  // Call a function to rebuild markers
                ),

              ) : Container(),

              // **Right Side: Listings**
              ((!_showingMap && isSmallScreen) || !isSmallScreen)? Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // **Search Bar**
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Search properties...",
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // **Filter Button**
                          IconButton(
                            icon: Icon(
                                _isFilterOpen ? Icons.filter_alt_outlined: Icons.filter_alt, size: 28),
                            onPressed: () {
                              setState(() {
                                _isFilterOpen = !_isFilterOpen;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // **Property Listings**
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (_hasMore &&
                              scrollInfo.metrics.pixels ==
                                  scrollInfo.metrics.maxScrollExtent) {
                            _fetchProperties(isLoadMore: true);
                          }
                          return false;
                        },
                        child: ListView.builder(
                          itemCount: _filteredProperties().length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _filteredProperties().length) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            return _buildPropertyCard(_filteredProperties()[index]);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ) : Container(),
            ],
          ),
          // **Floating Filter Menu**
          _isFilterOpen ? _buildFilters() : Container(),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _showingMap = !_showingMap);
              },
              icon: Icon(_showingMap ? Icons.list : Icons.map),
              label: Text(_showingMap ? "Show List" : "Show Map"),
            ),
          ),
        ],
      ),
    );
  }

  /// **Property Card**
  Widget _buildPropertyCard(Map<String, dynamic> property) {
    return PropertyCard(
      property: property,
      onTap: () {
        _selectProperty(
          property["id"],
          LatLng(property["latitude"], property["longitude"]),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Positioned(
      right: 20,
      top: 80,
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Filters",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // **Price Range**
              Text("Price Range: \$${NumberFormat("#,##0").format(
                  _minPrice)} - \$${NumberFormat("#,##0").format(_maxPrice)}"),
              RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: 50000,
                max: 1500000,
                divisions: 100,
                  onChanged: (values) {
                    setState(() {
                      _minPrice = values.start;
                      _maxPrice = values.end;
                    });
                    _fetchAllFilteredPropertiesForMap();
                  }

              ),

              const SizedBox(height: 10),

              // **Beds Toggle Buttons**
              const Text(
                  "Min Beds", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              ToggleButtons(
                isSelected: [1, 2, 3, 4, 5].map((e) => _minBeds == e).toList(),
                onPressed: (index) {
                  setState(() {
                    _minBeds = index + 1;
                  });
                  _fetchAllFilteredPropertiesForMap();
                },
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white,
                fillColor: Colors.deepPurple,
                // Highlight color when selected
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("1+")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("2+")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("3+")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("4+")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("5+")),
                ],
              ),

              const SizedBox(height: 10),

              // **Baths Toggle Buttons**
              const Text(
                  "Min Baths", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              ToggleButtons(
                isSelected: [1, 1.5, 2, 3, 4]
                    .map((e) => _minBaths == e)
                    .toList(),
                onPressed: (index) {
                  setState(() {
                    _minBaths = [1, 1.5, 2, 3, 4][index];
                  });
                  _fetchAllFilteredPropertiesForMap();
                },
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white,
                fillColor: Colors.deepPurple,
                // Highlight color when selected
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("1+")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("1.5+")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("2+")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("3+")),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("4+")),
                ],
              ),

              const SizedBox(height: 15),

            ],
          ),
        ),
      ),
    );
  }

  void _loadCustomMarkers() async {
    _defaultMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(15, 15)),
      'assets/markers/marker_default.png',
    );

    _selectedMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(30, 30)),
      'assets/markers/marker_selected.png',
    );

    setState(() {}); // Refresh map once markers are loaded
  }

  Future<void> _fetchAllFilteredPropertiesForMap() async {
    final snapshot = await FirebaseFirestore.instance.collection('listings').get();

    final List<Map<String, dynamic>> fetchedProperties = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return {
        "id": doc.id,
        "latitude": data["latitude"] ?? 0.0,
        "longitude": data["longitude"] ?? 0.0,
        "price": data["list_price"] ?? 0,
        "beds": data["beds"] ?? 0,
        "baths": data["full_baths"] ?? 0,
        "address": data["full_street_line"] ?? "Unknown Address",
      };
    }).toList();

    setState(() {
      allFilteredPropertiesForMap = fetchedProperties
          .where((property) =>
      property["price"] >= _minPrice &&
          property["price"] <= _maxPrice &&
          property["beds"] >= _minBeds &&
          property["baths"] >= _minBaths)
          .toList();
    });
  }

}


