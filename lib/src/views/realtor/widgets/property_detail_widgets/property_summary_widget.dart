import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertySummaryWidget extends StatelessWidget {
  final Map<String, dynamic> property;

  const PropertySummaryWidget({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat("#,##0", "en_US");

    final rawPrice = property["list_price"];
    final priceText = rawPrice != null ? "\$${currency.format(rawPrice)}" : "Price Unavailable";

    final address = property["address"] ?? "Address Unavailable";
    final beds = property["beds"] ?? "-";
    final baths = property["baths"] ?? "-";
    final sqft = property["sqft"];
    final sqftText = sqft != null ? "${currency.format(sqft)}" : "N/A";

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Price and address
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  priceText,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 0,
                  children: [
                    Text(
                      address,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4,),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                      tooltip: 'Copy address',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: address));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Address copied")),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.map_outlined, size: 20, color: Colors.grey),
                      tooltip: 'Open in Google Maps',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: () => _launchGoogleMaps(address),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "MLS: ${property["mls"] ?? "N/A"} • Days on MLS: ${property["days_on_mls"] ?? "N/A"} • ID: ${property["mls_id"] ?? "N/A"}",
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),

              ],
            ),
          ),

          // Right: Beds, Baths, Sqft
          Container(
            margin: const EdgeInsets.only(left: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                _stat("$beds", "Beds", theme),
                const SizedBox(width: 12),
                _stat("$baths", "Baths", theme),
                const SizedBox(width: 12),
                _stat(sqftText, "Sqft", theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
      ],
    );
  }

  void _launchGoogleMaps(String address) async {
    final encoded = Uri.encodeComponent(address);
    final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$encoded");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

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
      "Price/Sqft": widget.property["price_per_sqft"] != null ? "\$${widget.property["price_per_sqft"]}" : "-",
      "Stories": "${widget.property["stories"] ?? "-"}",
      "ZIP Code": "${widget.property["zip_code"] ?? "-"}",
      "Builder": widget.property["builder_name"] ?? "-",
      "Latitude": "${widget.property["latitude"] ?? "-"}",
      "Longitude": "${widget.property["longitude"] ?? "-"}"
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
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              runSpacing: 12,
              spacing: 24,
              children: items.entries.map((e) => _detailItem(e.key, e.value, theme)).toList(),
            ),
          ),
        )
      ],
    );
  }

  Widget _detailItem(String label, String value, ThemeData theme) {
    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}