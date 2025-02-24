import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/bottom_nav_item.dart';
import 'realtor_home_screen.dart';
import 'realtor_clients_screen.dart';
import 'realtor_settings_screen.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  // Dummy list of saved properties.
  final List<Map<String, String>> savedProperties = const [
    {
      "title": "Modern Apartment",
      "Address": "1501 Northpoint Ln",
      "City": "College Station",
      "State": "TX",
      "price": "544,000",
      "bedrooms": "4",
      "baths": "4",
      "sqft": "3,240 sqft",
      "image": "assets/images/property.jpg"
    },
    {
      "title": "Luxury Villa",
      "Address": "1234 Palm Dr",
      "City": "Los Angeles",
      "State": "CA",
      "price": "2,200,000",
      "bedrooms": "6",
      "baths": "5",
      "sqft": "5,500 sqft",
      "image": "assets/images/property.jpg"
    },
    {
      "title": "Cozy Cottage",
      "Address": "789 Country Rd",
      "City": "Asheville",
      "State": "NC",
      "price": "375,000",
      "bedrooms": "3",
      "baths": "2",
      "sqft": "1,800 sqft",
      "image": "assets/images/property.jpg"
    },
  ];

  Widget _detailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF002244),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Listings',
          style: GoogleFonts.openSans(
            fontSize: 32,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        itemCount: savedProperties.length,
        itemBuilder: (context, index) {
          final property = savedProperties[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property image.
                Image.asset(
                  property['image']!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // Title and address.
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                // Row of detail "chips" for Price, Bedrooms, Baths, and Sqft.
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      _detailChip(
                          Icons.attach_money, property['price'] ?? ''),
                      _detailChip(
                          Icons.king_bed, property['bedrooms'] ?? ''),
                      _detailChip(
                          Icons.bathtub, property['baths'] ?? ''),
                      _detailChip(
                          Icons.square_foot, property['sqft'] ?? ''),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 18.0),
        color: const Color(0xFF212834),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                BottomNavItem(
                  icon: Icons.home,
                  label: 'Home',
                  isSelected: false,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RealtorHomeScreen()),
                    );
                  },
                ),
                BottomNavItem(
                  icon: Icons.group,
                  label: 'Clients',
                  isSelected: false,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ClientsPage()),
                    );
                  },
                ),
                BottomNavItem(
                  icon: Icons.bookmark,
                  label: 'Saved',
                  isSelected: true,
                  onTap: () {
                    // Already on Saved Listings page.
                  },
                ),
                BottomNavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  isSelected: false,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SettingsPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
