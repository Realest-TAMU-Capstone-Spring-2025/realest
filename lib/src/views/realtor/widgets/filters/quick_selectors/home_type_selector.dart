import 'package:flutter/material.dart';
import '../../../../../models/property_filter.dart';

class HomeTypeSelector extends StatelessWidget {
  final LayerLink link;
  final PropertyFilter filters;
  final void Function(List<String>) onChanged;
  final OverlayEntry? overlayEntry;
  final void Function(OverlayEntry?) onEntryUpdate;

  const HomeTypeSelector({
    super.key,
    required this.link,
    required this.filters,
    required this.onChanged,
    required this.overlayEntry,
    required this.onEntryUpdate,
  });

  @override
  Widget build(BuildContext context) {
    String label;

    if (filters.homeTypes == null || filters.homeTypes!.isEmpty) {
      label = "Home Type";
    } else if (filters.homeTypes!.length == 1) {
      label = filters.homeTypes!.first;
    } else {
      label = "${filters.homeTypes!.length} selected";
    }

    return CompositedTransformTarget(
      link: link,
      child: SizedBox(
        width: 160,
        child: OutlinedButton.icon(
          onPressed: () => _showOverlay(context),
          icon: const Icon(Icons.home_work_outlined, size: 18),
          label: Text(
            label,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.deepPurple,
            side: const BorderSide(color: Colors.deepPurple),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            minimumSize: const Size(160, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

    final List<String> homeTypeOptions = [
      'SINGLE_FAMILY',
      'MULTI_FAMILY',
      'CONDOS',
      'TOWNHOMES',
      'DUPLEX_TRIPLEX',
      'MOBILE',
      'FARM',
      'LAND',
      'CONDO_TOWNHOME'
    ];

    List<String> tempSelectedTypes = List<String>.from(filters.homeTypes ?? []);

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                entry.remove();
                onEntryUpdate(null);
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withAlpha(50)),
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
                      border: Border.all(color: Colors.deepPurple.withAlpha(75)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Home Type", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: homeTypeOptions.map((type) {
                            final isSelected = tempSelectedTypes.contains(type);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  isSelected
                                      ? tempSelectedTypes.remove(type)
                                      : tempSelectedTypes.add(type);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? Colors.deepPurple : Colors.grey.shade400,
                                  ),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
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
                                onChanged(tempSelectedTypes);
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
