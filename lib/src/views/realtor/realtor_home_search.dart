import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class RealtorHomeSearch extends StatefulWidget {
  const RealtorHomeSearch({Key? key}) : super(key: key);

  @override
  _RealtorHomeSearchState createState() => _RealtorHomeSearchState();
}

class _RealtorHomeSearchState extends State<RealtorHomeSearch> {
  late GoogleMapController _mapController;
  bool _isFilterOpen = false;

  // **Filter Settings**
  double _minPrice = 100000;
  double _maxPrice = 1000000;
  int _minBeds = 1;
  num _minBaths = 1.0;

  final List<Map<String, dynamic>> properties = [
    {
      "latitude": 30.6280,
      "longitude": -96.3344,
      "address": "1101 University Dr, College Station, TX",
      "price": 350000,
      "beds": 3,
      "baths": 2,
      "sqft": 1800,
      "mls_id": "CS123456",
      "image": "https://photos.zillowstatic.com/fp/12d9eed69c968eccbbb271736443c874-cc_ft_1536.webp",
    },
    {
      "latitude": 30.6090,
      "longitude": -96.3490,
      "address": "4500 Carter Creek Pkwy, College Station, TX",
      "price": 420000,
      "beds": 4,
      "baths": 3,
      "sqft": 2500,
      "mls_id": "CS654321",
      "image": "https://photos.zillowstatic.com/fp/f92e12421954f63424e6788ca770bdc4-cc_ft_1536.webp",
    },
  ];

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              // **Left Side: Google Map**
              Expanded(
                flex: 1,
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(30.6280, -96.3344),
                    zoom: 12,
                  ),
                  mapType: MapType.normal,
                  onMapCreated: _onMapCreated,
                  markers: _filteredProperties().map((property) {
                    return Marker(
                      markerId: MarkerId(property["address"]),
                      position: LatLng(
                          property["latitude"], property["longitude"]),
                      infoWindow: InfoWindow(
                        title: property["address"],
                        snippet: "\$${NumberFormat("#,##0").format(
                            property["price"])}",
                      ),
                    );
                  }).toSet(),
                ),
              ),

              // **Right Side: Listings**
              Expanded(
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
                                _isFilterOpen ? Icons.filter_alt_off : Icons
                                    .filter_alt, size: 28),
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
                      child: ListView.builder(
                        itemCount: _filteredProperties().length,
                        itemBuilder: (context, index) {
                          return _buildPropertyCard(
                              _filteredProperties()[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // **Floating Filter Menu**
          _isFilterOpen ? _buildFilters() : Container(),
        ],
      ),
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
                },
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


  /// **Restored Beautiful Property Cards**
  Widget _buildPropertyCard(Map<String, dynamic> property) {
    final NumberFormat currencyFormat = NumberFormat("#,##0", "en_US");

    return Card(
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _mapController.animateCamera(
            CameraUpdate.newLatLng(LatLng(property["latitude"], property["longitude"])),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
              child: Image.network(property["image"], width: 120, height: 120, fit: BoxFit.cover),
            ),
            Expanded(
              child: ListTile(
                title: Text(property["address"], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("\$${currencyFormat.format(property["price"])}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    Text("${property["beds"]} Beds • ${property["baths"]} Baths • ${currencyFormat.format(property["sqft"])} sqft"),
                    Text("MLS ID: ${property["mls_id"]}", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
