import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/bottom_nav_item.dart';
import 'realtor_clients_screen.dart';
import 'realtor_filters_screen.dart';
import 'realtor_settings_screen.dart';
import 'realtor_dashboard_screen.dart';

class RealtorHomeScreen extends StatefulWidget {
  const RealtorHomeScreen({Key? key}) : super(key: key);

  @override
  _RealtorHomeScreenState createState() => _RealtorHomeScreenState();
}

class _RealtorHomeScreenState extends State<RealtorHomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // Dummy data for property listings.
  final List<Map<String, String>> _properties = [
    {
      "title": "Modern Apartment",
      "Address": "1501 Northpoint Ln",
      "City": "College Station",
      "State": "TX",
      "price": "544,000",
      "bedrooms": "4",
      "baths": "4",
      "sqft": "3,240 sqft"
    },
    {
      "title": "Luxury Villa",
      "Address": "1234 Palm Dr",
      "City": "Los Angeles",
      "State": "CA",
      "price": "2,200,000",
      "bedrooms": "6",
      "baths": "5",
      "sqft": "5,500 sqft"
    },
    {
      "title": "Cozy Cottage",
      "Address": "789 Country Rd",
      "City": "Asheville",
      "State": "NC",
      "price": "375,000",
      "bedrooms": "3",
      "baths": "2",
      "sqft": "1,800 sqft"
    },
    {
      "title": "Urban Loft",
      "Address": "101 Downtown St",
      "City": "Chicago",
      "State": "IL",
      "price": "650,000",
      "bedrooms": "2",
      "baths": "2",
      "sqft": "1,500 sqft"
    },
    {
      "title": "Suburban Home",
      "Address": "456 Maple Ave",
      "City": "Austin",
      "State": "TX",
      "price": "480,000",
      "bedrooms": "4",
      "baths": "3",
      "sqft": "2,700 sqft"
    },
    {
      "title": "Beachside Bungalow",
      "Address": "321 Ocean Blvd",
      "City": "Miami",
      "State": "FL",
      "price": "850,000",
      "bedrooms": "3",
      "baths": "3",
      "sqft": "2,200 sqft"
    },
    {
      "title": "Country Estate",
      "Address": "987 Farm Road",
      "City": "Nashville",
      "State": "TN",
      "price": "1,100,000",
      "bedrooms": "5",
      "baths": "4",
      "sqft": "4,000 sqft"
    },
    {
      "title": "Modern Condo",
      "Address": "654 Skyline Rd",
      "City": "New York",
      "State": "NY",
      "price": "1,200,000",
      "bedrooms": "3",
      "baths": "3",
      "sqft": "2,100 sqft"
    },
  ];

  // List to store applied filters.
  List<String> _appliedFilters = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {

    } else if (index == 1) {
      // Navigate to People screen.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ClientsPage()),
      );
    } else if (index == 2) {
      // Already on Settings, do nothing.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DashboardPage()),
      );
    }else if (index == 3) {
      // Already on Settings, do nothing.
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SettingsPage()),
      );
    }

    // Add navigation logic if needed.
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Helper widget for the detail chips.
  Widget _detailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Color(0xFF002244),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.openSans(fontSize: 14, color: Colors.white,fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with logo on left and profile image on right.
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Home',
          style: GoogleFonts.openSans(
            fontSize: 32,fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: AssetImage(
                'assets/images/profile.png',
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar row.
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search field takes 3/4 of the row.
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search properties',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                // Filter section takes 1/4 of the row.
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () async {
                      final selectedFilters = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FiltersPage(initialFilters: _appliedFilters),
                        ),
                      );

                      if (selectedFilters != null) {
                        setState(() {
                          _appliedFilters =
                          List<String>.from(selectedFilters);
                        });
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_list,
                            size: 28, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          // Container showing applied filters (only visible if there are filters).
          if (_appliedFilters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _appliedFilters.map((filter) {
                        return Chip(
                          backgroundColor: const Color(0xFF212834),
                          label: Text(filter,
                              style: GoogleFonts.openSans(
                                  color: Colors.white)),
                          onDeleted: () {
                            setState(() {
                              _appliedFilters.remove(filter);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          if (_appliedFilters.isNotEmpty) const SizedBox(height: 8),
          // Dashboard: property listings.
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _properties.length,
              itemBuilder: (context, index) {
                final property = _properties[index];
                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Property image.
                      Image.asset(
                        'assets/images/property.jpg',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      // Title and address.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              property['title'] ?? '',
                              style: GoogleFonts.openSans(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${property['Address']}, ${property['City']}, ${property['State']}",
                              style: GoogleFonts.openSans(
                                  fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                      // Row of detail "buttons" for Price, Bedrooms, Baths, and Sqft.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            _detailChip(Icons.attach_money, property['price'] ?? ''),
                            _detailChip(Icons.king_bed, property['bedrooms'] ?? ''),
                            _detailChip(Icons.bathtub, property['baths'] ?? ''),
                            _detailChip(Icons.square_foot, property['sqft'] ?? ''),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Footer: Bottom navigation bar.
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 18.0),
        color: const Color(0xFF212834),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 1),
            Row(
              children: [
                BottomNavItem(
                  icon: Icons.home,
                  label: 'Home',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
                BottomNavItem(
                  icon: Icons.people,
                  label: 'Clients',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onItemTapped(1),
                ),
                BottomNavItem(
                  icon: Icons.bookmark,
                  label: 'Saved',
                  isSelected:  _selectedIndex == 2,
                  onTap: () => _onItemTapped(2),
                ),
                BottomNavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: _selectedIndex == 3,
                  onTap: () => _onItemTapped(3),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
