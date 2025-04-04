import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // Import for rootBundle
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:realest/src/views/realtor/widgets/property-search-bar.dart';
import 'package:realest/src/views/realtor/widgets/property_filter.dart';
import 'package:realest/src/views/realtor/widgets/property_list.dart';
import 'package:realest/src/views/realtor/widgets/property_card.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_sheet.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';

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
  String? _darkMapStyle;

  final LayerLink _priceLink = LayerLink();
  OverlayEntry? _priceOverlayEntry;

  List<Map<String, dynamic>> allFilteredPropertiesForMap = []; // Markers
  PropertyFilter _filters = PropertyFilter();

  final LayerLink _bedBathLink = LayerLink();
  OverlayEntry? _bedBathOverlayEntry;

  final LayerLink _homeTypeLink = LayerLink();
  OverlayEntry? _homeTypeOverlayEntry;

  late Query<Map<String, dynamic>> _filteredQuery;

  final HitsSearcher _searcher = HitsSearcher(
    applicationID: 'BFVXJ9G642',
    apiKey: 'af22176f0bb769ad93bf9d2666a4bc31',
    indexName: 'listingSearch',
  );

  final TextEditingController _controller = TextEditingController();

  Future<Set<Marker>> _cachedMarkersFuture = Future.value({});

  void _refreshMarkers() {
    _cachedMarkersFuture = _createMarkers();
  }

  bool _isLoading = true;

  @override
  void dispose() {
    _searcher.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _loadMapStyle();
    // 👇 Enable hybrid composition for Android (fixes rendering issues)
    final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }
    _controller.addListener(() {
      _searcher.query(_controller.text);
    });


    _updateFilteredQuery();

    _fetchAllFilteredPropertiesForMap().then((_) {
      _refreshMarkers();
      setState(() {
        _isLoading = false; // ✅ Done loading
      });
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_darkMapStyle != null) {
      _mapController.setMapStyle(_darkMapStyle);
    }
  }

  Future<void> _loadMapStyle() async {
    _darkMapStyle = await rootBundle.loadString('assets/dark_map_style.json');
    setState(() {}); // Update the UI once the style is loaded
  }

  Future<void> _selectProperty(String propertyId, LatLng location) async {

    // get the property with this id from firestore
    final propertyRef = FirebaseFirestore.instance.collection('listings').doc(propertyId);
    final snapshot = await propertyRef.get();

    if (!snapshot.exists) {
      print("Property not found");
      return;
    }

    // Set the selected property ID

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

  Future<Set<Marker>> _createMarkers() async {
    final Set<Marker> markers = {};

    for (final property in allFilteredPropertiesForMap) {
      final LatLng location = LatLng(property["latitude"], property["longitude"]);
      final bool isSelected = _selectedPropertyId == property["id"];
      final price = property["price"] ?? 0;

      final marker = Marker(
        markerId: MarkerId(property["id"]),
        position: location,
        icon: await createPriceMarkerBitmap(
          "\$${(price / 1000).round()}K",
          selected: isSelected,
        ),
        onTap: () => _selectProperty(property["id"], location),
      );

      markers.add(marker);
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 1000;
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isSmallScreen = constraints.maxWidth < 1000;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row for search and filter actions
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search Bar
                            Expanded(
                              child: Material(
                                elevation: 2,
                                borderRadius: BorderRadius.circular(10),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 500),
                                  child: PropertySearchBar(controller: _controller, searcher: _searcher, onPropertySelected: _selectProperty),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Buttons
                            if (isSmallScreen)
                              IconButton(
                                icon: Icon(Icons.tune, size: 28),
                                tooltip: "More Filters",
                                onPressed: () {
                                  setState(() => _isFilterOpen = !_isFilterOpen);
                                },
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildPriceSelector(),
                                  _buildBedBathSelector(),
                                  _buildHomeTypeSelector(),ElevatedButton.icon(
                                    icon: Icon(Icons.tune, size: 20),
                                    label: Text("More", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                                      minimumSize: Size(160, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: showFilterDrawer,
                                  ),

                                ],
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              )
              ,

              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;

                    final listingsWidth = _getListingsPanelWidth(screenWidth);
                    final showMap = (_showingMap && isSmallScreen) || !isSmallScreen;
                    final showList = (!_showingMap && isSmallScreen) || !isSmallScreen;

                    return Row(
                      children: [
                        if (showMap)
                          Expanded( // let map take remaining space
                            child: FutureBuilder<Set<Marker>>(
                              future: _cachedMarkersFuture,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();
                                return RepaintBoundary(
                                    child: GoogleMap(
                                      initialCameraPosition: const CameraPosition(
                                        target: LatLng(30.6280, -96.3344),
                                        zoom: 12,
                                      ),
                                      onMapCreated: _onMapCreated,
                                      markers: snapshot.data!,
                                      mapType: MapType.normal,
                                    ));
                              },
                            ),
                          ),

                        if (showList)
                          SizedBox(
                            width: listingsWidth,
                            child: Column(
                              children: [
                                Expanded(

                                  child: RepaintBoundary(
                                    child: PropertyList(
                                      query: _filteredQuery,
                                      buildPropertyCard: _buildPropertyCard,
                                    ),
                                  ),)
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              )

              // **Search Bar**
            ],
          ),

          isSmallScreen? Positioned(
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
          ): Container(),
        ],
      ),
    );
  }

  double _getListingsPanelWidth(double screenWidth) {
    if (screenWidth >= 1700) return 1100; // 3 cards (360 * 3 + spacing)
    if (screenWidth >= 1200) return 740;  // 2 cards (350 * 2 + spacing)
    if (screenWidth >= 920) return 370;  // 1 card (350 + padding)
    return screenWidth;                  // full width on mobile
  }

  Widget _buildPriceSelector() {
    return CompositedTransformTarget(
      link: _priceLink,
      child: SizedBox(
        width: 160,
        child: ElevatedButton(
          onPressed: _togglePriceOverlay,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.deepPurple,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.deepPurple),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.attach_money, size: 16, color: Colors.deepPurple),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  (_filters.minPrice != null && _filters.maxPrice != null)
                      ? '\$${_filters.minPrice} - \$${_filters.maxPrice}'
                      : 'Any Price',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _togglePriceOverlay() {
    if (_priceOverlayEntry != null) {
      _removeAllOverlays();
      return;
    }

    double tempMin = _filters.minPrice?.toDouble() ?? 100000;
    double tempMax = _filters.maxPrice?.toDouble() ?? 1000000;

    _priceOverlayEntry = _buildDismissibleOverlay(
      child: Positioned(
        width: 280,
        child: CompositedTransformFollower(
          link: _priceLink,
          offset: const Offset(0, 60),
          showWhenUnlinked: false,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: StatefulBuilder(
                builder: (context, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select Price Range",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        "\$${tempMin.toStringAsFixed(0)} - \$${tempMax.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    RangeSlider(
                      values: RangeValues(tempMin, tempMax),
                      min: 50000,
                      max: 2000000,
                      divisions: 100,
                      labels: RangeLabels(
                        "\$${tempMin.round()}",
                        "\$${tempMax.round()}",
                      ),
                      onChanged: (range) {
                        setState(() {
                          tempMin = range.start;
                          tempMax = range.end;
                        });
                      },
                      activeColor: Colors.deepPurple,
                      inactiveColor: Colors.deepPurple.shade100,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _removeAllOverlays();
                          },
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            if (!mounted) return;

                            setState(() {
                              _filters.minPrice = tempMin.toInt();
                              _filters.maxPrice = tempMax.toInt();
                            });

                            _removeAllOverlays();

                            // These can trigger setState() internally, so we check again
                            if (mounted) {
                              _fetchAllFilteredPropertiesForMap();
                              _updateFilteredQuery();
                            }
                          },
                          child: const Text("Apply"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_priceOverlayEntry!);
  }

  Widget _buildBedBathSelector() {
    String label = '${_filters.minBeds ?? 1}+ bd / ${_filters.minBaths ?? 1}+ ba';

    return CompositedTransformTarget(
      link: _bedBathLink,
      child: SizedBox(
        width: 160,
        child: ElevatedButton(
          onPressed: _toggleBedBathOverlay,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.deepPurple,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.deepPurple),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.bed, size: 16, color: Colors.deepPurple),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleBedBathOverlay() {
    if (_bedBathOverlayEntry != null) {
      _bedBathOverlayEntry!.remove();
      _bedBathOverlayEntry = null;
      return;
    }

    int tempBeds = _filters.minBeds ?? 1;
    double tempBaths = _filters.minBaths?.toDouble() ?? 1.0;

    List<int> bedOptions = [1, 2, 3, 4, 5];
    List<double> bathOptions = [1.0, 1.5, 2.0, 3.0, 4.0];

    _bedBathOverlayEntry = _buildDismissibleOverlay(
      child: Positioned(
        width: 280,
        child: CompositedTransformFollower(
          link: _bedBathLink,
          offset: const Offset(0, 60),
          showWhenUnlinked: false,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
              ),
              child: StatefulBuilder(
                builder: (context, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Bedrooms", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ToggleButtons(
                      isSelected: bedOptions.map((val) => tempBeds == val).toList(),
                      onPressed: (index) => setState(() => tempBeds = bedOptions[index]),
                      borderRadius: BorderRadius.circular(8),
                      selectedColor: Colors.white,
                      fillColor: Colors.deepPurple[300],
                      color: Colors.black87,
                      selectedBorderColor: Colors.deepPurple,
                      borderColor: Colors.grey.shade300,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
                      children: bedOptions.map((val) => Text('$val+')).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text("Bathrooms", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ToggleButtons(
                      isSelected: bathOptions.map((val) => tempBaths == val).toList(),
                      onPressed: (index) => setState(() => tempBaths = bathOptions[index]),
                      borderRadius: BorderRadius.circular(8),
                      selectedColor: Colors.white,
                      fillColor: Colors.deepPurple[300],
                      color: Colors.black87,
                      selectedBorderColor: Colors.deepPurple,
                      borderColor: Colors.grey.shade300,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
                      children: bathOptions.map(
                            (val) => Text('${val.toString().replaceAll('.0', '')}+'),
                      ).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _bedBathOverlayEntry?.remove();
                            _bedBathOverlayEntry = null;
                          },
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _filters.minBeds = tempBeds;
                              _filters.minBaths = tempBaths;
                            });
                            _bedBathOverlayEntry?.remove();
                            _bedBathOverlayEntry = null;
                            _fetchAllFilteredPropertiesForMap();
                            _updateFilteredQuery();
                          },
                          child: const Text("Apply"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_bedBathOverlayEntry!);
  }

  Widget _buildHomeTypeSelector() {
    String label;

    if (_filters.homeTypes == null || _filters.homeTypes!.isEmpty) {
      label = "Home Type";
    } else if (_filters.homeTypes!.length == 1) {
      label = _filters.homeTypes!.first;
    } else {
      label = "${_filters.homeTypes!.length} selected";
    }

    return CompositedTransformTarget(
      link: _homeTypeLink,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: OutlinedButton.icon(
          onPressed: _toggleHomeTypeOverlay,
          icon: const Icon(Icons.home_work_outlined, size: 18),
          label: Text(
            label,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.deepPurple,
            side: const BorderSide(color: Colors.deepPurple),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            minimumSize: const Size(160, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );

  }

  OverlayEntry _buildDismissibleOverlay({required Widget child}) {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Blocks touch events behind the overlay
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeAllOverlays,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.black.withOpacity(0.2), // Optional: slight dim color if desired
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  void _removeAllOverlays() {
    _priceOverlayEntry?.remove();
    _priceOverlayEntry = null;

    _bedBathOverlayEntry?.remove();
    _bedBathOverlayEntry = null;

    _homeTypeOverlayEntry?.remove();
    _homeTypeOverlayEntry = null;
  }

  void _toggleHomeTypeOverlay() {

    final List<String> homeTypeOptions = [
      'SINGLE_FAMILY',
      'MULTI_FAMILY',
      'CONDOS',
      'TOWNHOMES',
      'DUPLEX_TRIPLEX',
      'MOBILE',
      'FARM',
      'LAND',
      'CONDO_TOWNHOME'
    ];

    if (_homeTypeOverlayEntry != null) {
      _homeTypeOverlayEntry!.remove();
      _homeTypeOverlayEntry = null;
      return;
    }

    List<String> tempSelectedTypes = List<String>.from(_filters.homeTypes ?? []);

    _homeTypeOverlayEntry = _buildDismissibleOverlay(
      child: Positioned(
        width: 280,
        child: CompositedTransformFollower(
          link: _homeTypeLink,
          offset: const Offset(0, 60),
          showWhenUnlinked: false,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
              ),
              child: StatefulBuilder(
                builder: (context, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Home Type", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: homeTypeOptions.map((type) {
                        final isSelected = tempSelectedTypes.contains(type);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              isSelected
                                  ? tempSelectedTypes.remove(type)
                                  : tempSelectedTypes.add(type);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
                              ),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _homeTypeOverlayEntry?.remove();
                            _homeTypeOverlayEntry = null;
                          },
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _filters.homeTypes = tempSelectedTypes;
                            });
                            _homeTypeOverlayEntry?.remove();
                            _homeTypeOverlayEntry = null;
                            _fetchAllFilteredPropertiesForMap();
                            _updateFilteredQuery();
                          },
                          child: const Text("Apply"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_homeTypeOverlayEntry!);
  }

  /// **Property Card**
  Widget _buildPropertyCard(Map<String, dynamic> property) {
    return PropertyCard(
      property: property,
      onTap: () {
        print("Tapped on property: ${property["id"]}");
        _selectProperty(
          property["id"],
          LatLng(property["latitude"], property["longitude"]),
        );
      },
    );
  }

  void showFilterDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Filters",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            color: Colors.white,
            child: Container(
              width: 400,
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: StatefulBuilder(
                builder: (context, setModalState) =>
                    _buildFilterContent(setModalState, dialogContext), // pass outer context
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim1),
          child: child,
        );
      },
    );
  }

  Widget _buildFilterContent(void Function(void Function()) setModalState, BuildContext dialogContext) {
    // Temp values for local updates inside the drawer
    double tempMinPrice = _filters.minPrice?.toDouble() ?? 100000;
    double tempMaxPrice = _filters.maxPrice?.toDouble() ?? 1000000;
    int tempMinBeds = _filters.minBeds ?? 1;
    double tempMinBaths = _filters.minBaths ?? 1.0;
    int? tempMinSqft = _filters.minSqft;
    int? tempMaxSqft = _filters.maxSqft;
    int? tempMinLotSize = _filters.minLotSize;
    int? tempMaxLotSize = _filters.maxLotSize;
    int? tempMinYearBuilt = _filters.minYearBuilt;
    int? tempMaxYearBuilt = _filters.maxYearBuilt;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Filters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),

              const SizedBox(height: 16),
              const Text("Price Range", style: TextStyle(fontWeight: FontWeight.bold)),
              RangeSlider(
                values: RangeValues(tempMinPrice, tempMaxPrice),
                min: 50000,
                max: 2000000,
                divisions: 100,
                labels: RangeLabels("\$${tempMinPrice.round()}", "\$${tempMaxPrice.round()}"),
                onChanged: (values) => setModalState(() {
                  tempMinPrice = values.start;
                  tempMaxPrice = values.end;
                }),
              ),

              const SizedBox(height: 16),
              const Text("Bedrooms", style: TextStyle(fontWeight: FontWeight.bold)),
              ToggleButtons(
                isSelected: List.generate(5, (i) => tempMinBeds == i + 1),
                onPressed: (i) => setModalState(() => tempMinBeds = i + 1),
                borderRadius: BorderRadius.circular(8),
                children: List.generate(5, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${i + 1}+'),
                )),
              ),

              const SizedBox(height: 16),
              const Text("Bathrooms", style: TextStyle(fontWeight: FontWeight.bold)),
              ToggleButtons(
                isSelected: [1.0, 1.5, 2.0, 3.0, 4.0].map((b) => tempMinBaths == b).toList(),
                onPressed: (i) => setModalState(() => tempMinBaths = [1.0, 1.5, 2.0, 3.0, 4.0][i]),
                borderRadius: BorderRadius.circular(8),
                children: [1.0, 1.5, 2.0, 3.0, 4.0].map((b) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('${b.toString().replaceAll('.0', '')}+'),
                )).toList(),
              ),

              const SizedBox(height: 16),
              _buildMinMax("SQFT", tempMinSqft, tempMaxSqft, (min, max) {
                setModalState(() {
                  tempMinSqft = min;
                  tempMaxSqft = max;
                });
              }),

              const SizedBox(height: 16),
              _buildMinMax("Lot Size", tempMinLotSize, tempMaxLotSize, (min, max) {
                setModalState(() {
                  tempMinLotSize = min;
                  tempMaxLotSize = max;
                });
              }),

              const SizedBox(height: 16),
              _buildMinMax("Year Built", tempMinYearBuilt, tempMaxYearBuilt, (min, max) {
                setModalState(() {
                  tempMinYearBuilt = min;
                  tempMaxYearBuilt = max;
                });
              }),

              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      setState(() {
                        _filters.minPrice = tempMinPrice.toInt();
                        _filters.maxPrice = tempMaxPrice.toInt();
                        _filters.minBeds = tempMinBeds;
                        _filters.minBaths = tempMinBaths;
                        _filters.minSqft = tempMinSqft;
                        _filters.maxSqft = tempMaxSqft;
                        _filters.minLotSize = tempMinLotSize;
                        _filters.maxLotSize = tempMaxLotSize;
                        _filters.minYearBuilt = tempMinYearBuilt;
                        _filters.maxYearBuilt = tempMaxYearBuilt;
                      });
                      _fetchAllFilteredPropertiesForMap();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Apply"),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildMinMax(
      String label,
      int? minValue,
      int? maxValue,
      void Function(int?, int?) onChanged,
      )
  {
    final List<int> options = [
      for (int i = 0; i <= 10; i++) i * 500,
      6000, 7000, 8000, 9000, 10000
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: minValue,
                isExpanded: true,
                hint: const Text("Min"),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: options.map((val) {
                  return DropdownMenuItem<int>(
                    value: val == 0 ? null : val,
                    child: Text(val == 0 ? "Any" : val.toString()),
                  );
                }).toList(),
                onChanged: (val) => onChanged(val, maxValue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: maxValue,
                isExpanded: true,
                hint: const Text("Max"),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: options.map((val) {
                  return DropdownMenuItem<int>(
                    value: val == 0 ? null : val,
                    child: Text(val == 0 ? "Any" : val.toString()),
                  );
                }).toList(),
                onChanged: (val) => onChanged(minValue, val),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _fetchAllFilteredPropertiesForMap() async {
    final snapshot = await _buildFilteredQuery().get();


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
      allFilteredPropertiesForMap = fetchedProperties.where((property) {
        final price = property["price"] ?? 0;
        final beds = property["beds"] ?? 0;
        final baths = property["baths"] ?? 0;

        final minPrice = _filters.minPrice ?? 0;
        final maxPrice = _filters.maxPrice ?? double.infinity;
        final minBeds = _filters.minBeds ?? 0;
        final minBaths = _filters.minBaths ?? 0.0;

        return price >= minPrice &&
            price <= maxPrice &&
            beds >= minBeds &&
            baths >= minBaths;
      }).toList();
    });

    _refreshMarkers(); // ✅ move this here
  }

  Future<BitmapDescriptor> createPriceMarkerBitmap(String priceText, {bool selected = false}) async {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: priceText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();

    final double padding = 15;
    final double width = textPainter.width + padding;
    final double height = 20;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final Paint paint = Paint()
      ..color = selected ? Colors.deepPurple : Colors.red.shade900
      ..style = PaintingStyle.fill;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      Radius.circular(12),
    );

    canvas.drawRRect(rrect, paint);

    textPainter.paint(canvas, Offset(padding / 2, (height - textPainter.height) / 2));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Query<Map<String, dynamic>> _buildFilteredQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('listings');

    if (_filters.minPrice != null) {
      query = query.where('list_price', isGreaterThanOrEqualTo: _filters.minPrice);
    }
    if (_filters.maxPrice != null) {
      query = query.where('list_price', isLessThanOrEqualTo: _filters.maxPrice);
    }
    if (_filters.minBeds != null) {
      query = query.where('beds', isGreaterThanOrEqualTo: _filters.minBeds);
    }
    if (_filters.minBaths != null) {
      query = query.where('full_baths', isGreaterThanOrEqualTo: _filters.minBaths);
    }
    if (_filters.homeTypes != null && _filters.homeTypes!.isNotEmpty) {
      query = query.where('style', whereIn: _filters.homeTypes);
    }
    if (_filters.maxHoa != null) {
      query = query.where('hoa_fee', isLessThanOrEqualTo: _filters.maxHoa);
    }
    if (_filters.minSqft != null) {
      query = query.where('sqft', isGreaterThanOrEqualTo: _filters.minSqft);
    }
    if (_filters.maxSqft != null) {
      query = query.where('sqft', isLessThanOrEqualTo: _filters.maxSqft);
    }
    if (_filters.minLotSize != null) {
      query = query.where('lot_sqft', isGreaterThanOrEqualTo: _filters.minLotSize);
    }
    if (_filters.maxLotSize != null) {
      query = query.where('lot_sqft', isLessThanOrEqualTo: _filters.maxLotSize);
    }
    if (_filters.minYearBuilt != null) {
      query = query.where('year_built', isGreaterThanOrEqualTo: _filters.minYearBuilt);
    }
    if (_filters.maxYearBuilt != null) {
      query = query.where('year_built', isLessThanOrEqualTo: _filters.maxYearBuilt);
    }

    return query.orderBy('days_on_mls');
  }

  void _updateFilteredQuery() {
    print('[FirestoreQuery] Updating filtered query...');
    final query = _buildFilteredQuery();
    setState(() => _filteredQuery = query);
    _fetchAllFilteredPropertiesForMap();
  }


}
