import 'package:flutter/material.dart';

import '../../../../../models/property_filter.dart';

class PriceSelector extends StatelessWidget {
  final LayerLink link;
  final PropertyFilter filters;
  final void Function(int minPrice, int maxPrice) onChanged;
  final OverlayEntry? overlayEntry;
  final void Function(OverlayEntry?) onEntryUpdate;

  const PriceSelector({
    Key? key,
    required this.link,
    required this.filters,
    required this.onChanged,
    required this.overlayEntry,
    required this.onEntryUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final label = (filters.minPrice != null && filters.maxPrice != null)
        ? '\$${filters.minPrice} - \$${filters.maxPrice}'
        : 'Any Price';

    return CompositedTransformTarget(
      link: link,
      child: SizedBox(
        width: 160,
        child: ElevatedButton(
          onPressed: () => _showOverlay(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.deepPurple,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.deepPurple),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.attach_money, size: 16, color: Colors.deepPurple),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOverlay(BuildContext context) {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      onEntryUpdate(null);
      return;
    }

    double tempMin = filters.minPrice?.toDouble() ?? 100000;
    double tempMax = filters.maxPrice?.toDouble() ?? 5000000;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                entry.remove();
                onEntryUpdate(null);
              },
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
          ),
          Positioned(
            width: 280,
            child: CompositedTransformFollower(
              link: link,
              offset: const Offset(0, 60),
              showWhenUnlinked: false,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: StatefulBuilder(
                  builder: (context, setState) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Select Price Range", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            "\$${tempMin.toStringAsFixed(0)} - \$${tempMax.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 10),
                        RangeSlider(
                          values: RangeValues(tempMin, tempMax),
                          min: 50000,
                          max: 2000000,
                          divisions: 100,
                          labels: RangeLabels("\$${tempMin.round()}", "\$${tempMax.round()}"),
                          onChanged: (range) {
                            setState(() {
                              tempMin = range.start;
                              tempMax = range.end;
                            });
                          },
                          activeColor: Colors.deepPurple,
                          inactiveColor: Colors.deepPurple.shade100,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                entry.remove();
                                onEntryUpdate(null);
                              },
                              child: const Text("Cancel"),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                onChanged(tempMin.toInt(), tempMax.toInt());
                                entry.remove();
                                onEntryUpdate(null);
                              },
                              child: const Text("Apply"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    onEntryUpdate(entry);
    Overlay.of(context).insert(entry);
  }
}
