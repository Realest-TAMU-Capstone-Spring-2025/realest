import 'package:flutter/material.dart';
import 'package:realest/src/models/property_filter.dart'; // ✅ Make sure this path is correct

class BedBathSelector extends StatelessWidget {
  final LayerLink link;
  final PropertyFilter filters;
  final void Function(int beds, double baths) onChanged;
  final OverlayEntry? overlayEntry;
  final void Function(OverlayEntry?) onEntryUpdate; // ✅ make nullable

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
    final label = '${filters.minBeds ?? 1}+ bd / ${filters.minBaths ?? 1}+ ba';

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

  void _showOverlay(BuildContext context) {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      onEntryUpdate(null);
      return;
    }

    int tempBeds = filters.minBeds ?? 1;
    double tempBaths = filters.minBaths ?? 1.0;

    late final OverlayEntry entry; // ✅ Fix "referenced before declaration"

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
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Bedrooms", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ToggleButtons(
                          isSelected: [1, 2, 3, 4, 5].map((b) => tempBeds == b).toList(),
                          onPressed: (index) => setState(() => tempBeds = [1, 2, 3, 4, 5][index]),
                          borderRadius: BorderRadius.circular(8),
                          selectedColor: Colors.white,
                          fillColor: Colors.deepPurple[300],
                          color: Colors.black87,
                          selectedBorderColor: Colors.deepPurple,
                          borderColor: Colors.grey.shade300,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
                          children: [1, 2, 3, 4, 5].map((b) => Text('$b+')).toList(),
                        ),
                        const SizedBox(height: 20),
                        Text("Bathrooms", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ToggleButtons(
                          isSelected: [1.0, 1.5, 2.0, 3.0, 4.0].map((b) => tempBaths == b).toList(),
                          onPressed: (index) => setState(() => tempBaths = [1.0, 1.5, 2.0, 3.0, 4.0][index]),
                          borderRadius: BorderRadius.circular(8),
                          selectedColor: Colors.white,
                          fillColor: Colors.deepPurple[300],
                          color: Colors.black87,
                          selectedBorderColor: Colors.deepPurple,
                          borderColor: Colors.grey.shade300,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
                          children: [1.0, 1.5, 2.0, 3.0, 4.0]
                              .map((b) => Text('${b.toString().replaceAll('.0', '')}+'))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
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
