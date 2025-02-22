import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/bottom_nav_item.dart';

class RealtorHomeScreen extends StatefulWidget {
  const RealtorHomeScreen({Key? key}) : super(key: key);

  @override
  _RealtorHomeScreenState createState() => _RealtorHomeScreenState();
}

class _RealtorHomeScreenState extends State<RealtorHomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  // Dummy data for property listings
  final List<Map<String, String>> _properties = [
    {"title": "Modern Apartment", "location": "New York"},
    {"title": "Luxury Villa", "location": "Los Angeles"},
    {"title": "Cozy Cottage", "location": "Seattle"},
    {"title": "Urban Loft", "location": "Chicago"},
    {"title": "4BHK Apartment", "location": "Austin"},
    {"title": "Apartment in the City", "location": "Dallas"},
    {"title": "Villa with Garden", "location": "Houston"},
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add navigation logic if needed.
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    print('Total properties: ${_properties.length}');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with logo on left and profile image on right.
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/logo.png', // Your logo asset
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: AssetImage(
                'assets/images/profile.jpg', // Realtor's profile photo asset
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar (replacing a traditional navigation bar)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Search field takes 3/4 of the row.
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search properties',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                    onTap: () {
                      Navigator.pushNamed(context, '/filters');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_list, size: 28, color: Colors.black),
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

          // Dashboard: property listings
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _properties.length,
              itemBuilder: (context, index) {
                final property = _properties[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.home),
                    title: Text(property['title'] ?? ''),
                    subtitle: Text(property['location'] ?? ''),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to property details page.
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Footer: a bottom navigation bar with Home, People, and Settings icons.
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: 18.0), // Moves the bar up from the bottom
        color: const Color(0xFF212834), // Background color of the bottom bar.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Extra top space so the nav items are not flush with the top edge.
            const SizedBox(height: 1),
            // The row of navigation items.
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
                  label: 'People',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onItemTapped(1),
                ),
                BottomNavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onItemTapped(2),
                ),
              ],
            )

          ],
        ),
      ),
    );
  }
}
