import 'package:flutter/material.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A reusable search bar widget that integrates with Algolia to provide
/// property address autocomplete with real-time suggestions.
/// Calls [onPropertySelected] when a property is chosen.
class PropertySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final HitsSearcher searcher;
  final void Function(String id, LatLng location) onPropertySelected;

  const PropertySearchBar({
    super.key,
    required this.controller,
    required this.searcher,
    required this.onPropertySelected,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<Map<String, dynamic>>(
      textEditingController: controller,
      focusNode: FocusNode(),

      /// Query Algolia and return list of property options
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) return const [];

        searcher.query(textEditingValue.text); // Trigger Algolia search
        final snapshot = await searcher.responses.first;

        return snapshot.hits
            .map<Map<String, dynamic>>((hit) => Map<String, dynamic>.from(hit))
            .toList();
      },

      /// Display string in field for selected option
      displayStringForOption: (option) => option['full_street_line'] ?? 'Unknown',

      /// UI builder for autocomplete dropdown
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options.elementAt(index);
                final address = option['full_street_line'] ?? 'Unknown';

                return ListTile(
                  title: Text(address),
                  onTap: () => onSelected(option), // Select this address
                );
              },
            ),
          ),
        );
      },

      /// Handle when user selects an address
      onSelected: (selectedOption) {
        final id = selectedOption['objectID'];
        final lat = selectedOption['latitude'];
        final lng = selectedOption['longitude'];

        controller.clear(); // Clear input field

        onPropertySelected(
          id,
          LatLng(lat?.toDouble() ?? 0.0, lng?.toDouble() ?? 0.0),
        );
      },

      /// Build the text field for user input
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: 'Search by address, MLS ID, or Neighborhood...',
            prefixIcon: Icon(Icons.search),
          ),
        );
      },
    );
  }
}
