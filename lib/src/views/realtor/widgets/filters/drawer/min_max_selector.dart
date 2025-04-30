import 'package:flutter/material.dart';

/// A widget that displays two dropdowns for selecting minimum and maximum values.
/// Useful for filtering properties by ranges like price, square footage, etc.
class MinMaxSelector extends StatelessWidget {
  final String label; // Label for the selector
  final int? minValue; // Currently selected minimum value
  final int? maxValue; // Currently selected maximum value
  final int min; // Minimum allowed value in the dropdown
  final int max; // Maximum allowed value in the dropdown
  final int step; // Step size between dropdown options
  final void Function(int?, int?) onChanged; // Callback when selection changes

  const MinMaxSelector({
    super.key,
    required this.label,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
    this.min = 0,
    this.max = 10000,
    this.step = 500,
  });

  @override
  Widget build(BuildContext context) {
    // Generate dropdown options from min to max with given step
    final List<int> options = [
      for (int i = min; i <= max; i += step) i
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label at the top
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // Row containing Min and Max dropdowns
        Row(
          children: [
            // Min dropdown
            Expanded(
              child: DropdownButtonFormField<int>(
                value: minValue,
                isExpanded: true,
                hint: const Text("Min"),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: options.map((val) {
                  return DropdownMenuItem<int>(
                    value: val == min ? null : val,
                    child: Text(val == min ? "Any" : val.toString()),
                  );
                }).toList(),
                onChanged: (val) => onChanged(val, maxValue),
              ),
            ),
            const SizedBox(width: 12),
            // Max dropdown
            Expanded(
              child: DropdownButtonFormField<int>(
                value: maxValue,
                isExpanded: true,
                hint: const Text("Max"),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: options.map((val) {
                  return DropdownMenuItem<int>(
                    value: val == min ? null : val,
                    child: Text(val == min ? "Any" : val.toString()),
                  );
                }).toList(),
                onChanged: (val) => onChanged(minValue, val),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
