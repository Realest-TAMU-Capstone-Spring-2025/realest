import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FiltersPage extends StatefulWidget {
  final List<String> initialFilters;

  const FiltersPage({Key? key, required this.initialFilters}) : super(key: key);

  @override
  _FiltersPageState createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  // Dummy filter groups for example.
  final Map<String, List<String>> _filterGroups = {
    "Price & Financial": [
      "Price: Low to High",
      "Price: High to Low",
      "Price per Sq Ft"
    ],
    "Property Type & Status": [
      "Newest Listings",
      "Oldest Listings",
      "For Sale",
      "For Rent"
    ],
    "Size & Layout": [
      "Bedrooms: 1+",
      "Bedrooms: 2+",
      "Bathrooms: 1+",
      "Bathrooms: 2+",
      "Square Footage"
    ],
    "Location & Neighborhood": [
      "City/Region",
      "Neighborhood",
      "Zip Code"
    ],
    "Amenities & Features": [
      "Pool",
      "Gym",
      "Garage",
      "Garden",
      "Air Conditioning",
      "Pet Friendly"
    ],
  };

  late Set<String> _selectedFilters;

  @override
  void initState() {
    super.initState();
    _selectedFilters = widget.initialFilters.toSet();
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar: same as in your main screen.
      appBar: AppBar(
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
                'assets/images/profile.jpg',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page title.
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8), // Spacing between icon and text
                  Text(
                    'Filters',
                    style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Display each filter group.
              ..._filterGroups.entries.map((entry) {
                String groupTitle = entry.key;
                List<String> options = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupTitle,
                      style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: options.map((option) {
                        bool isSelected = _selectedFilters.contains(option);
                        return ChoiceChip(
                          label: Text(option),
                          selected: isSelected,
                          onSelected: (selected) => _toggleFilter(option),
                          selectedColor: const Color(0xFF127B86),
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      // Custom bottom bar with "Apply" and "Clear All" buttons.
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Apply" button fills the width.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _selectedFilters.toList());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF13656e),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Apply Filters",
                  style: GoogleFonts.openSans(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // "Clear All" button.
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFilters.clear();
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF212834),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  "Clear All",
                  style: GoogleFonts.openSans(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
