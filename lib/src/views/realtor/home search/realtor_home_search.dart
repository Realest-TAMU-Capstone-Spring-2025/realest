import 'dart:math';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:realest/src/views/realtor/widgets/property-search-bar.dart';
import 'package:realest/src/views/realtor/widgets/property_list.dart';
import 'package:realest/src/views/realtor/widgets/property_card/property_card.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_sheet.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldPath;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../util/property_fetch_helpers.dart';
import '../../../models/property_filter.dart';
import '../helpers/property_query_helpers.dart';
import '../widgets/filters/drawer/filter_drawer.dart';
import '../widgets/filters/quick_selectors/bed_bath_selector.dart';
import '../widgets/filters/quick_selectors/home_type_selector.dart';
import '../widgets/filters/quick_selectors/price_selector.dart';
import '../widgets/map/map_controller.dart';
import '../widgets/map/map_section.dart';
import '../widgets/marker/property_marker.dart';

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

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();

    const int defaultMinPrice = 100000;
    const int defaultMaxPrice = 1000000;
    const int minLimit = 100000;
    const int maxLimit = 5000000;

    final double minPriceRaw = prefs.getDouble('minPrice') ?? defaultMinPrice.toDouble();
    final double maxPriceRaw = prefs.getDouble('maxPrice') ?? defaultMaxPrice.toDouble();

    final int minPrice = min(maxPriceRaw.toInt(), max(minPriceRaw.toInt(), minLimit));
    final int maxPrice = max(minPriceRaw.toInt(), min(maxPriceRaw.toInt(), maxLimit));

    setState(() {
      _filters = PropertyFilter(
        minPrice: minPrice,
        maxPrice: maxPrice,
        minBeds: prefs.getInt('minBeds') ?? 2,
        minBaths: prefs.getDouble('minBaths') ?? 2.0,
        homeTypes: prefs.getStringList('homeTypes') ?? ['SINGLE_FAMILY', 'CONDOS'],
        selectedStatuses: prefs.getStringList('selectedStatuses') ?? ['FOR_SALE'],
      );
    });
  }




  @override
  void dispose() {
    _searcher.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final GoogleMapsFlutterPlatform mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
    }

    _controller.addListener(() {
      _searcher.query(_controller.text);
    });

    _loadFilters().then((_) async {
      _updateFilteredQuery();
      await _fetchAllFilteredPropertiesForMap();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final realtorId = currentUser.uid;
        final realtorDoc = await FirebaseFirestore.instance
            .collection('realtors')
            .doc(realtorId)
            .get();

        final cashFlowDefaults = realtorDoc.data()?['cashFlowDefaults'] ?? {};

        await generateCashFlowIfMissing(
          realtorId: realtorId,
          listings: allFilteredPropertiesForMap,
          cashFlowDefaults: cashFlowDefaults,
        );
      }

      _refreshMarkers();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }


  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // if (_darkMapStyle != null) {
    //   _mapController.setMapStyle(_darkMapStyle);
    // }
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
    final propertyData = await fetchPropertyData(propertyId);

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
          color: getStatusColor(property['status']), // You can pass color based on listingType/status
        ),
        onTap: () => _selectProperty(property["id"], location),
      );

      markers.add(marker);
    }

    return markers;
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();

    // Clamp min/max values
    final int minPrice = (_filters.minPrice ?? 0).clamp(0, 2000000);
    final int maxPrice = (_filters.maxPrice ?? 2000000).clamp(0, 2000000);

    await prefs.setDouble('minPrice', minPrice.toDouble());
    await prefs.setDouble('maxPrice', maxPrice.toDouble());
    await prefs.setInt('minBeds', _filters.minBeds ?? 0);
    await prefs.setDouble('minBaths', _filters.minBaths ?? 0.0);
    await prefs.setStringList('homeTypes', _filters.homeTypes ?? []);
  }



  @override
  Widget build(BuildContext context) {
    bool isSmallScreen = MediaQuery.of(context).size.width < 1000;
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Hold on, generating cashflows...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
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
                                    showFilterDrawer(
                                      context: context,
                                      filters: _filters,
                                      onApply: (updatedFilters) async {
                                        setState(() => _filters = updatedFilters);
                                        await _saveFilters();
                                        _fetchAllFilteredPropertiesForMap();
                                        _updateFilteredQuery();
                                      },
                                    );
                                  }
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  PriceSelector(
                                    link: _priceLink,
                                    filters: _filters,
                                    overlayEntry: _priceOverlayEntry,
                                    onEntryUpdate: (entry) {
                                      setState(() => _priceOverlayEntry = entry);
                                    },
                                    onChanged: (minPrice, maxPrice) async {
                                      setState(() {
                                        _filters.minPrice = minPrice;
                                        _filters.maxPrice = maxPrice;
                                      });
                                      await _saveFilters();
                                      _fetchAllFilteredPropertiesForMap();
                                      _updateFilteredQuery();
                                    },
                                  ),
                                  BedBathSelector(
                                    link: _bedBathLink,
                                    overlayEntry: _bedBathOverlayEntry,
                                    filters: _filters,
                                    onChanged: (beds, baths) async {
                                      setState(() {
                                        _filters.minBeds = beds;
                                        _filters.minBaths = baths;
                                      });
                                      await _saveFilters();
                                      _fetchAllFilteredPropertiesForMap();
                                      _updateFilteredQuery();
                                    },
                                    onEntryUpdate: (entry) => _bedBathOverlayEntry = entry,
                                  ),
                                  HomeTypeSelector(
                                    link: _homeTypeLink,
                                    filters: _filters,
                                    overlayEntry: _homeTypeOverlayEntry,
                                    onEntryUpdate: (entry) => setState(() => _homeTypeOverlayEntry = entry),
                                    onChanged: (types) async {
                                      setState(() {
                                        _filters.homeTypes = types;
                                      });
                                      await _saveFilters();
                                      _fetchAllFilteredPropertiesForMap();
                                      _updateFilteredQuery();
                                    },
                                  ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.tune, size: 20),
                                    label: const Text(
                                      "More",
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                                      minimumSize: const Size(160, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      showFilterDrawer(
                                        context: context,
                                        filters: _filters,
                                        onApply: (updatedFilters) async {
                                          setState(() => _filters = updatedFilters);
                                          await _saveFilters();
                                          _fetchAllFilteredPropertiesForMap();
                                          _updateFilteredQuery();
                                        },
                                      );
                                    }
                                  ),
                                ],
                        ),
                      ],
                    )]);
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
                                  child: MapSection(
                                    markers: snapshot.data!,
                                    onMapCreated: _onMapCreated,
                                    onPropertyTap: (id, location) => handlePropertyTap(
                                      context: context,
                                      propertyId: id,
                                      location: location,
                                      mapController: _mapController,
                                      setSelectedId: (val) => setState(() => _selectedPropertyId = val),
                                    ),
                                  ),
                                );
                              },
                            )
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

  Future<void> _fetchAllFilteredPropertiesForMap() async {
    final snapshot = await buildFilteredQuery(_filters).get();


    final List<Map<String, dynamic>> fetchedProperties = snapshot.docs.map((
        doc) {
      final data = doc.data() as Map<String, dynamic>;

      return {
        "id": doc.id,
        "latitude": data["latitude"] ?? 0.0,
        "longitude": data["longitude"] ?? 0.0,
        "price": data["list_price"] ?? 0,
        "beds": data["beds"] ?? 0,
        "baths": data["full_baths"] ?? 0,
        "address": data["full_street_line"] ?? "Unknown Address",
        "status": data["status"] ?? "N/A",
        "rent_estimate": data["rent_estimate"] ?? 0,
      };
    }).toList();

    if (mounted) {
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
  }

  void _updateFilteredQuery() {
    // print('[FirestoreQuery] Updating filtered query...');
    final query = buildFilteredQuery(_filters);
    if (mounted) {
      setState(() => _filteredQuery = query);
    }
    _fetchAllFilteredPropertiesForMap();
  }

  Future<void> generateCashFlowIfMissing({
    required String realtorId,
    required List<Map<String, dynamic>> listings,
    required Map<String, dynamic> cashFlowDefaults,
  }) async {
    final firestore = FirebaseFirestore.instance;

    Future<void> processChunk(List<Map<String, dynamic>> chunk) async {
      final ids = chunk.map((l) => l['id'] as String).toList();

      final snapshot = await firestore
          .collection('realtors')
          .doc(realtorId)
          .collection('cashflow_analysis')
          .where(FieldPath.documentId, whereIn: ids)
          .get();

      final existingIds = snapshot.docs.map((doc) => doc.id).toSet();
      final List<Future<void>> tasks = [];

      for (final property in chunk) {
        final listingId = property['id'] as String;
        final status = property['status']?.toString().toUpperCase();
        final rent = property['rent_estimate'];

        if (existingIds.contains(listingId)) {
          // print("⏩ Skipping $listingId: Already exists");
          continue;
        }
        if (status != 'FOR_SALE') {
          // print("⏩ Skipping $listingId: Not for sale (status: $status)");
          continue;
        }
        if (rent == null) {
          // print("⏩ Skipping $listingId: No rent_estimate");
          continue;
        }

        // print("✅ Creating cashflow for $listingId...");

        tasks.add(() async {
          final double purchasePrice = (property['price'] ?? 0).toDouble();
          final double rentValue = (rent).toDouble();

          final double downPayment = (cashFlowDefaults['downPayment'] ?? 0.2) * purchasePrice;
          final double loanAmount = purchasePrice - downPayment;
          final double interestRate = cashFlowDefaults['interestRate'] ?? 0.06;
          final int loanTerm = cashFlowDefaults['loanTerm'] ?? 30;
          final double monthlyInterest = interestRate / 12;
          final int months = loanTerm * 12;

          final double principal = loanAmount / months;
          final double monthlyPayment = loanAmount * monthlyInterest / (1 - (1 / pow(1 + monthlyInterest, months)));
          final double interest = monthlyPayment - principal;

          final double hoaFee = (property['hoa_fee'] ?? (cashFlowDefaults['hoaFee'] ?? 0)) / 12;
          final double propertyTax = (cashFlowDefaults['propertyTax'] ?? 0.015) * purchasePrice / 12;
          final double vacancy = (cashFlowDefaults['vacancyRate'] ?? 0.05) * rentValue;
          final double insurance = (cashFlowDefaults['insurance'] ?? 0.005) * purchasePrice / 12;
          final double maintenance = (cashFlowDefaults['maintenance'] ?? 0.001) * purchasePrice / 12;
          final double otherCosts = (cashFlowDefaults['otherCosts'] ?? 500).toDouble() / 12;
          final double managementFee = (cashFlowDefaults['managementFee'] ?? 0.1) * rentValue;

          final double netOperatingIncome = rentValue - (
              monthlyPayment + vacancy + propertyTax + insurance + maintenance + otherCosts + hoaFee
          );

          await firestore
              .collection('realtors')
              .doc(realtorId)
              .collection('cashflow_analysis')
              .doc(listingId)
              .set({
            'rent': rentValue,
            'loanAmount': loanAmount,
            'monthlyPayment': monthlyPayment,
            'hoaFee': hoaFee,
            'propertyHoa': property['hoa_fee'] ?? 0,
            'vacancy': vacancy,
            'downPayment': downPayment,
            'monthlyInterest': monthlyInterest,
            'months': months,
            'purchasePrice': purchasePrice,
            'principal': principal,
            'interest': interest,
            'tax': propertyTax,
            'insurance': insurance,
            'maintenance': maintenance,
            'otherCosts': otherCosts,
            'managementFee': managementFee,
            'netOperatingIncome': netOperatingIncome,
            'updatedAt': FieldValue.serverTimestamp(),
            'valuesUsed': {
              'downPayment': (cashFlowDefaults['downPayment'] ?? 0.2),
              'loanTerm': cashFlowDefaults['loanTerm'] ?? 30,
              'interestRate': cashFlowDefaults['interestRate'] ?? 0.06,
              'hoaFee': (property['hoa_fee'] ?? (cashFlowDefaults['hoaFee'] ?? 0)),
              'propertyTax': cashFlowDefaults['propertyTax'] ?? 0.015,
              'vacancyRate': cashFlowDefaults['vacancyRate'] ?? 0.05,
              'insurance': cashFlowDefaults['insurance'] ?? 0.005,
              'maintenance': cashFlowDefaults['maintenance'] ?? 0.001,
              'otherCosts': cashFlowDefaults['otherCosts'] ?? 500,
              'managementFee': cashFlowDefaults['managementFee'] ?? 0.1,
            },
          });
        }());
      }

      await Future.wait(tasks);
    }

    // Process first 2 chunks (up to 20 listings) eagerly
    final initialChunks = listings.take(20).toList();
    for (int i = 0; i < initialChunks.length; i += 10) {
      final chunk = initialChunks.skip(i).take(10).toList();
      await processChunk(chunk);
    }

    // Defer the rest in background
    final remaining = listings.skip(20).toList();
    if (remaining.isNotEmpty) {
      Future(() async {
        for (int i = 0; i < remaining.length; i += 10) {
          final chunk = remaining.skip(i).take(10).toList();
          await processChunk(chunk);
        }
      });
    }
  }




}
