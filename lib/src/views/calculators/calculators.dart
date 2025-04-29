import 'package:flutter/material.dart';
import 'piti_calculator.dart';
import 'affordability_calculator.dart';
import 'rental_property_calculator.dart';

/// Displays a collection of financial calculators for real estate.
class Calculators extends StatefulWidget {
  const Calculators({Key? key}) : super(key: key);

  @override
  State<Calculators> createState() => _CalculatorsState();
}

/// State for [Calculators], managing the selected calculator and layout.
class _CalculatorsState extends State<Calculators> {
  /// Index of the currently selected calculator.
  int _selectedCalculator = 0;

  /// List of calculator names for display.
  final List<String> calculatorNames = [
    "PITI Calculator",
    "Affordability Calculator",
    "Rental Property Calculator",
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

  /// Builds a mobile layout with a dropdown to select calculators.
  Widget _buildMobileLayout() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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

  /// Builds a wide layout with a sidebar for calculator selection.
  Widget _buildWideLayout() {
    return Row(
      children: [
        Container(
          width: 250,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: _buildSelectedCalculator(),
          ),
        ),
      ],
    );
  }

  /// Creates a sidebar item for a calculator with selection styling.
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
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : null,
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

  /// Returns the selected calculator widget based on [_selectedCalculator].
  Widget _buildSelectedCalculator() {
    switch (_selectedCalculator) {
      case 0:
        return const PitiCalculator();
      case 1:
        return const AffordabilityCalculator();
      case 2:
        return const RentalPropertyCalculator();
      default:
        return const SizedBox.shrink();
    }
  }
}