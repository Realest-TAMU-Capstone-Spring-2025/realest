import 'package:flutter/material.dart';
import 'package:realest/main.dart'; // Theme mode notifier
import '../../../../../models/property_filter.dart'; // Property filter model

/// Widget to select Home Types (e.g., Condo, Single Family) using a popup overlay.
class HomeTypeSelector extends StatelessWidget {
  final LayerLink link; // For overlay positioning
  final PropertyFilter filters; // Current selected filters
  final void Function(List<String>) onChanged; // Callback when user applies
  final OverlayEntry? overlayEntry; // Current overlay entry (nullable)
  final void Function(OverlayEntry?) onEntryUpdate; // Updates overlay state

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

    // Determine button label based on selection
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            minimumSize: const Size(160, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide.none, // No visible border
          ),
        ),
      ),
    );
  }

  /// Opens or closes the home type selection overlay
  void _showOverlay(BuildContext context) {
    if (overlayEntry != null) {
      overlayEntry!.remove();
      onEntryUpdate(null);
      return;
    }

    final Map<String, String> prettyHomeTypeNames = {
      'SINGLE_FAMILY': 'Single Family',
      'MULTI_FAMILY': 'Multi Family',
      'CONDOS': 'Condo',
      'TOWNHOMES': 'Townhome',
      'DUPLEX_TRIPLEX': 'Duplex/Triplex',
      'MOBILE': 'Mobile Home',
      'FARM': 'Farm',
      'LAND': 'Land',
      'CONDO_TOWNHOME': 'Condo/Townhome',
    };

    List<String> tempSelectedTypes = List<String>.from(filters.homeTypes ?? []);

    late final OverlayEntry entry;
    final theme = Theme.of(context);

    // Building the overlay UI
    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Dimmed background that closes on tap
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
          // Popup card
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
                      border: Border.all(color: Colors.deepPurple.withAlpha(75)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text("Home Type", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        // Type options
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: prettyHomeTypeNames.entries.map((entry) {
                            final type = entry.key;
                            final prettyName = entry.value;
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
                                  color: isSelected
                                      ? Colors.deepPurple
                                      : theme.colorScheme.onTertiaryFixedVariant,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.deepPurple
                                        : theme.colorScheme.onTertiaryFixedVariant,
                                  ),
                                ),
                                child: Text(
                                  prettyName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : themeModeNotifier.value == ThemeMode.dark
                                        ? Colors.white
                                        : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
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
