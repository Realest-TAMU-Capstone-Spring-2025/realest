import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'piti_calculator.dart';           // <--- Import PITI
import 'affordability_calculator.dart';  // <--- Import Affordability
import 'rental_property_calculator.dart';

class RealtorCalculators extends StatefulWidget {
  const RealtorCalculators({Key? key}) : super(key: key);

  @override
  State<RealtorCalculators> createState() => _RealtorCalculatorsState();
}

class _RealtorCalculatorsState extends State<RealtorCalculators> {
  int _selectedCalculator = 0; // 0 = PITI, 1 = Affordability, 2 = Rental

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(context),
          // Main content
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Builder(builder: (_) {
                if (_selectedCalculator == 0) {
                  return const PitiCalculator();        // <--- Show PITI
                } else if (_selectedCalculator == 1) {
                  return const AffordabilityCalculator(); // <--- Show Affordability
                } else {
                  return const RentalPropertyCalculator(); // <--- Show your rental calc
                }
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the vertical sidebar with calculator selectors
  Widget _buildSidebar(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Container(
          width: 250,
          height: MediaQuery.of(context).size.height - 60, // Adjust spacing
          decoration: BoxDecoration(
            color: CupertinoColors.tertiarySystemFill,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Text(
                "Calculators",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildNavItem("PITI Calculator", 0),
              _buildNavItem("Affordability Calculator", 1),
              _buildNavItem("Rental Property Calc", 2),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  /// Sidebar nav item
  Widget _buildNavItem(String label, int index) {
    bool isSelected = _selectedCalculator == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCalculator = index;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.lightBackgroundGray
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.primaryColorDark,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  //  Common Calculator UI
  // --------------------------------------------------------------------------
  Widget _buildCalculatorLayout({
    required String title,
    required List<Widget> inputFields,
    required VoidCallback onCalculate,
    required String resultText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // All input fields
        ...inputFields,
        const SizedBox(height: 20),

        // Button
        Center(child: _buildModernButton("Calculate", onCalculate)),
        const SizedBox(height: 20),

        // Result
        Center(
          child: Text(
            resultText,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// A modern styled calculate button
  Widget _buildModernButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// A styled TextField
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Helper to parse doubles, returning 0 if invalid
  double _parseDouble(String? val) {
    if (val == null || val.trim().isEmpty) return 0;
    return double.tryParse(val.trim()) ?? 0;
  }

  // Helper to parse int, returning 0 if invalid
  int _parseInt(String? val) {
    if (val == null || val.trim().isEmpty) return 0;
    return int.tryParse(val.trim()) ?? 0;
  }
}
