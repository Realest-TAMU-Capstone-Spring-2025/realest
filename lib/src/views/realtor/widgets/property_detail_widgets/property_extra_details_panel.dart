import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// An expandable panel to show additional property metadata like
/// baths, last sold date, builder, location, garage, and other details.
class PropertyExtraDetailsPanel extends StatefulWidget {
  final Map<String, dynamic> property;

  const PropertyExtraDetailsPanel({super.key, required this.property});

  @override
  State<PropertyExtraDetailsPanel> createState() => _PropertyExtraDetailsPanelState();
}

class _PropertyExtraDetailsPanelState extends State<PropertyExtraDetailsPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat("#,##0", "en_US");

    final items = <String, String>{
      "Full Baths": "${widget.property["full_baths"] ?? "-"}",
      "Half Baths": "${widget.property["half_baths"] ?? "-"}",
      "Last Sold": widget.property["last_sold_date"] ?? "-",
      "Nearby Schools": widget.property["nearby_schools"]?.toString() ?? "-",
      "New Construction": widget.property["new_construction"] == true ? "Yes" : "No",
      "Garage": widget.property["parking_garage"] ?? "-",
      "Price/Sqft": widget.property["price_per_sqft"] != null
          ? "\$${widget.property["price_per_sqft"]}"
          : "-",
      "Stories": "${widget.property["stories"] ?? "-"}",
      "ZIP Code": "${widget.property["zip_code"] ?? "-"}",
      "Builder": widget.property["builder_name"] ?? "-",
      "Latitude": "${widget.property["latitude"] ?? "-"}",
      "Longitude": "${widget.property["longitude"] ?? "-"}",
    };

    return ExpansionPanelList(
      elevation: 1,
      expansionCallback: (int index, bool _) {
        setState(() => _isExpanded = !_isExpanded);
      },
      children: [
        ExpansionPanel(
          canTapOnHeader: true,
          isExpanded: _isExpanded,
          headerBuilder: (context, isExpanded) => ListTile(
            title: Text("Additional Property Details", style: theme.textTheme.titleMedium),
          ),
          body: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final label = items.keys.elementAt(index);
              final value = items.values.elementAt(index);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        value,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
