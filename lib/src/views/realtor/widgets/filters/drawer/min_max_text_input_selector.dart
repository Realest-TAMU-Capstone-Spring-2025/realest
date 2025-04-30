import 'package:flutter/material.dart';

/// A widget for inputting minimum and maximum year values.
/// Used for filtering properties by "Year Built" or similar fields.
class MinMaxYearInput extends StatefulWidget {
  final int? minYear; // Currently selected minimum year
  final int? maxYear; // Currently selected maximum year
  final void Function(int?, int?) onChanged; // Callback when values change

  const MinMaxYearInput({
    super.key,
    required this.minYear,
    required this.maxYear,
    required this.onChanged,
  });

  @override
  State<MinMaxYearInput> createState() => _MinMaxYearInputState();
}

class _MinMaxYearInputState extends State<MinMaxYearInput> {
  late TextEditingController _minController;
  late TextEditingController _maxController;
  bool _minValid = true;
  bool _maxValid = true;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with prefilled min and max year if available
    _minController = TextEditingController(text: widget.minYear?.toString() ?? '');
    _maxController = TextEditingController(text: widget.maxYear?.toString() ?? '');
  }

  /// Validates the inputs and updates parent widget via callback
  void _validate() {
    final minText = _minController.text;
    final maxText = _maxController.text;

    final minYear = int.tryParse(minText);
    final maxYear = int.tryParse(maxText);

    setState(() {
      _minValid = minText.isEmpty || (minYear != null && minYear >= 1000 && minYear <= DateTime.now().year);
      _maxValid = maxText.isEmpty || (maxYear != null && maxYear >= 1000 && maxYear <= DateTime.now().year);
    });

    widget.onChanged(
      _minValid && minYear != null ? minYear : null,
      _maxValid && maxYear != null ? maxYear : null,
    );
  }

  /// Builds input decoration with dynamic color based on validation state
  InputDecoration _inputDecoration(String hint, bool isValid) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isValid ? Colors.grey : Colors.red),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isValid ? Colors.grey : Colors.red),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: isValid ? Colors.deepPurple : Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text("Year Built", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // Min and Max input fields
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _minController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Min", _minValid),
                onChanged: (_) => _validate(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _maxController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Max", _maxValid),
                onChanged: (_) => _validate(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
