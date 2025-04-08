import 'package:flutter/material.dart';
import 'piti_calculator.dart';
import 'affordability_calculator.dart';
import 'rental_property_calculator.dart';
import 'buyer_netsheet_calculator.dart';

class Calculators extends StatefulWidget {
  const Calculators({Key? key}) : super(key: key);

  @override
  State<Calculators> createState() => _CalculatorsState();
}

class _CalculatorsState extends State<Calculators> {
  int _selectedCalculator = 0;

  final List<String> calculatorNames = [
    "PITI Calculator",
    "Affordability Calculator",
    "Rental Property Calculator",
    "Buyer Net Sheet Calculator",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;

          return KeyedSubtree(
            key: ValueKey(isWide),
            child: isWide ? _buildWideLayout() : _buildMobileLayout(),
          );
        },
      ),
    );
  }

  /// Mobile layout with dropdown
  Widget _buildMobileLayout() {
    return Column(
      children: [
        Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: DropdownButtonFormField<int>(
            value: _selectedCalculator,
            onChanged: (index) {
              if (index != null) {
                setState(() => _selectedCalculator = index);
              }
            },
            items: List.generate(
              calculatorNames.length,
                  (index) => DropdownMenuItem(
                value: index,
                child: Text(calculatorNames[index]),
              ),
            ),
            decoration: const InputDecoration(
              labelText: "Select Calculator",
              border: OutlineInputBorder(),
              filled: true,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSelectedCalculator(),
          ),
        ),
      ],
    );
  }

  /// Wide layout with styled sidebar
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 250,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                offset: Offset(1, 0),
                blurRadius: 6,
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
          child: Column(
            children: [
              const Text(
                "Calculators",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              ...List.generate(
                calculatorNames.length,
                    (index) => _buildSidebarItem(calculatorNames[index], index),
              )
            ],
          ),
        ),

        // Main Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: _buildSelectedCalculator(),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(String label, int index) {
    final isSelected = _selectedCalculator == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => setState(() => _selectedCalculator = index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color:
          isSelected ? theme.colorScheme.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCalculator() {
    switch (_selectedCalculator) {
      case 0:
        return const PitiCalculator();
      case 1:
        return const AffordabilityCalculator();
      case 2:
        return const RentalPropertyCalculator();
      case 3:
        return const BuyerNetSheetCalculator();
      default:
        return const SizedBox.shrink();
    }
  }
}
