import 'package:flutter/material.dart';

class MinMaxSelector extends StatelessWidget {
  final String label;
  final int? minValue;
  final int? maxValue;
  final int min;
  final int max;
  final int step;
  final void Function(int?, int?) onChanged;

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
    final List<int> options = [
      for (int i = min; i <= max; i += step) i
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
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
