import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/investor_bottom_nav_item.dart';
import 'investor_home_screen.dart';
import 'investor_dashboard_screen.dart';
import 'investor_settings_screen.dart';

class InvestorRealtorScreen extends StatefulWidget {
  const InvestorRealtorScreen({Key? key}) : super(key: key);

  @override
  _InvestorRealtorScreenState createState() => _InvestorRealtorScreenState();
}

class _InvestorRealtorScreenState extends State<InvestorRealtorScreen> {
  // Placeholder realtor information.
  final String realtorName = "John Doe";
  final String realtorProfilePicUrl = "assets/images/realtor_profile.png";

  // Dummy recommended listings data.
  final List<Map<String, String>> recommendedListings = [
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
  ];

  int _selectedIndex = 1; // Realtor tab is selected by default.

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InvestorHomeScreen()),
      );
    } else if (index == 1) {
      // Already on Realtor screen.
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InvestorDashboardScreen()),
      );
    } else if (index == 3) {
      // Navigate to Settings if needed.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InvestorSettingsScreen()),
      );
    }
  }

  // Helper widget similar to the one in InvestorHomeScreen.
  Widget _detailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF127B86),
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
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtorInfo() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage('assets/images/profile.png'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              realtorName,
              style: GoogleFonts.openSans(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedListings() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header text.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Recommended Listings",
              style: GoogleFonts.openSans(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          // Listings formatted similarly to InvestorHomeScreen.
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommendedListings.length,
            itemBuilder: (context, index) {
              final property = recommendedListings[index];
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Listing image.
                    Image.asset(
                      "assets/images/property.jpg",
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    // Title and location.
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
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.only(bottom: 18.0),
      color: const Color(0xFF13656e),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InvestorBottomNavItem(
                icon: Icons.home,
                label: 'Home',
                isSelected: _selectedIndex == 0,
                onTap: () => _onItemTapped(0),
              ),
              InvestorBottomNavItem(
                icon: Icons.people,
                label: 'Realtor',
                isSelected: _selectedIndex == 1,
                onTap: () => _onItemTapped(1),
              ),
              InvestorBottomNavItem(
                icon: Icons.bookmark,
                label: 'Saved',
                isSelected: _selectedIndex == 2,
                onTap: () => _onItemTapped(2),
              ),
              InvestorBottomNavItem(
                icon: Icons.settings,
                label: 'Settings',
                isSelected: _selectedIndex == 3,
                onTap: () => _onItemTapped(3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Realtor", style: GoogleFonts.openSans(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
        automaticallyImplyLeading: false, // Removes the back arrow.
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildRealtorInfo(),
          _buildRecommendedListings(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
