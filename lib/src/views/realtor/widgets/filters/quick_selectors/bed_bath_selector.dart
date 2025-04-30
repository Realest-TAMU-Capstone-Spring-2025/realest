import 'package:flutter/material.dart';
import 'package:realest/src/models/property_filter.dart'; // Model for managing property filters

/// Widget for selecting minimum bedrooms and bathrooms with a popup overlay.
class BedBathSelector extends StatelessWidget {
  final LayerLink link; // For positioning the overlay
  final PropertyFilter filters; // Current selected filters
  final void Function(int beds, double baths) onChanged; // Callback when user applies
  final OverlayEntry? overlayEntry; // Current overlay entry (nullable)
  final void Function(OverlayEntry?) onEntryUpdate; // Updates overlay state

  const BedBathSelector({
    Key? key,
    required this.link,
    required this.filters,
    required this.onChanged,
    required this.overlayEntry,
    required this.onEntryUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final label = '${filters.minBeds ?? 1}+ bd / ${filters.minBaths ?? 1}+ ba'; // Button label text

    return CompositedTransformTarget(
      link: link,
      child: SizedBox(
        width: 160,
        child: OutlinedButton(
          onPressed: () => _showOverlay(context),
          style: ElevatedButton.styleFrom(
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
            side: BorderSide.none,
          ),
          child: Row(
            children: [
              const Icon(Icons.bed, size: 16, color: Colors.deepPurple),
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

  /// Opens or closes the overlay for selecting bed/bath values
  void _showOverlay(BuildContext context) {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      onEntryUpdate(null);
      return;
    }

    int tempBeds = filters.minBeds ?? 1;
    double tempBaths = filters.minBaths ?? 1.0;

    late final OverlayEntry entry;

    // Creating the overlay content
    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Background overlay that closes on tap
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
          // Popup card with bed/bath selectors
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
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bedroom selection
                        Text("Bedrooms", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ToggleButtons(
                          isSelected: [1, 2, 3, 4, 5].map((b) => tempBeds == b).toList(),
                          onPressed: (index) => setState(() => tempBeds = [1, 2, 3, 4, 5][index]),
                          borderRadius: BorderRadius.circular(8),
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
                          children: [1, 2, 3, 4, 5].map((b) => Text('$b+')).toList(),
                        ),
                        const SizedBox(height: 20),
                        // Bathroom selection
                        Text("Bathrooms", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ToggleButtons(
                          isSelected: [1.0, 1.5, 2.0, 3.0, 4.0].map((b) => tempBaths == b).toList(),
                          onPressed: (index) => setState(() => tempBaths = [1.0, 1.5, 2.0, 3.0, 4.0][index]),
                          borderRadius: BorderRadius.circular(8),
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
                          children: [1.0, 1.5, 2.0, 3.0, 4.0]
                              .map((b) => Text('${b.toString().replaceAll('.0', '')}+'))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        // Action buttons
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
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                onChanged(tempBeds, tempBaths);
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
