import 'package:flutter/material.dart';

import '../../../../../../main.dart';
import '../../../../../models/property_filter.dart';
import 'min_max_selector.dart';
import 'min_max_text_input_selector.dart';

void showFilterDrawer({
  required BuildContext context,
  required PropertyFilter filters,
  required void Function(PropertyFilter) onApply,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Filters",
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (BuildContext dialogContext, _, __) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          child: FilterDrawerContent(
            filters: filters,
            onApply: onApply,
            close: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim1),
        child: child,
      );
    },
  );
}

class FilterDrawerContent extends StatefulWidget {
  final PropertyFilter filters;
  final void Function(PropertyFilter) onApply;
  final VoidCallback close;

  const FilterDrawerContent({
    super.key,
    required this.filters,
    required this.onApply,
    required this.close,
  });

  @override
  State<FilterDrawerContent> createState() => _FilterDrawerContentState();
}

class _FilterDrawerContentState extends State<FilterDrawerContent> {
  late double tempMinPrice;
  late double tempMaxPrice;
  late int tempMinBeds;
  late double tempMinBaths;
  int? tempMinSqft;
  int? tempMaxSqft;
  int? tempMinLotSize;
  int? tempMaxLotSize;
  int? tempMinYearBuilt;
  int? tempMaxYearBuilt;
  final Map<String, String> allStatuses = {
    'FOR_SALE': 'For sale',
    'PENDING': 'Pending',
    'SOLD': 'Sold',
  };
  late List<String> selectedStatuses;
  bool? isNewConstruction;
  int? tempMaxFloors;
  int? tempMaxDaysOnMarket;
  int? tempMaxHOAFee;

  @override
  void initState() {
    super.initState();
    final f = widget.filters;
    tempMinPrice = f.minPrice?.toDouble() ?? 100000;
    tempMaxPrice = f.maxPrice?.toDouble() ?? 5000000;
    tempMinBeds = f.minBeds ?? 1;
    tempMinBaths = f.minBaths ?? 1.0;
    tempMinSqft = f.minSqft;
    tempMaxSqft = f.maxSqft;
    tempMinLotSize = f.minLotSize;
    tempMaxLotSize = f.maxLotSize;
    tempMinYearBuilt = f.minYearBuilt;
    tempMaxYearBuilt = f.maxYearBuilt;
    selectedStatuses = List.from(f.selectedStatuses ?? []);
    isNewConstruction = f.isNewConstruction;
    tempMaxFloors = f.maxFloors;
    tempMaxDaysOnMarket = f.maxDaysOnMarket;
    tempMaxHOAFee = f.maxHOAFee;
  }

  final Set<String> hoveredStatus = {};


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 400,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          //align the title to the left
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Filters",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text("Price Range", style: TextStyle(fontWeight: FontWeight.bold)),
                  RangeSlider(
                    values: RangeValues(tempMinPrice, tempMaxPrice),
                    min: 50000,
                    max: 2000000,
                    divisions: 100,
                    labels: RangeLabels("\$${tempMinPrice.round()}", "\$${tempMaxPrice.round()}"),
                    onChanged: (values) => setState(() {
                      tempMinPrice = values.start;
                      tempMaxPrice = values.end;
                    }),
                  ),
                  const SizedBox(height: 16),
                  const Text("Bedrooms", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ToggleButtons(
                    isSelected: List.generate(5, (i) => tempMinBeds == i + 1),
                    onPressed: (i) => setState(() => tempMinBeds = i + 1),
                    borderRadius: BorderRadius.circular(8),
                    children: List.generate(5, (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${i + 1}+'),
                    )),
                  ),
                  const SizedBox(height: 16),
                  const Text("Bathrooms", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  ToggleButtons(
                    isSelected: [1.0, 1.5, 2.0, 3.0, 4.0].map((b) => tempMinBaths == b).toList(),
                    onPressed: (i) => setState(() => tempMinBaths = [1.0, 1.5, 2.0, 3.0, 4.0][i]),
                    borderRadius: BorderRadius.circular(8),
                    children: [1.0, 1.5, 2.0, 3.0, 4.0].map((b) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${b.toString().replaceAll('.0', '')}+'),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  MinMaxSelector(
                    label: "Square Footage",
                    minValue: tempMinSqft,
                    maxValue: tempMaxSqft,
                    min: 500,
                    max: 10000,
                    step: 500,
                    onChanged: (min, max) {
                      setState(() {
                        tempMinSqft = min;
                        tempMaxSqft = max;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  MinMaxSelector(
                    label: "Lot Size",
                    minValue: tempMinLotSize,
                    maxValue: tempMaxLotSize,
                    min: 1000,
                    max: 20000,
                    step: 1000,
                    onChanged: (min, max) {
                      setState(() {
                        tempMinLotSize = min;
                        tempMaxLotSize = max;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  MinMaxYearInput(
                    minYear: tempMinYearBuilt,
                    maxYear: tempMaxYearBuilt,
                    onChanged: (min, max) {
                      setState(() {
                        tempMinYearBuilt = min;
                        tempMaxYearBuilt = max;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allStatuses.entries.map((entry) {
                      final statusKey = entry.key;
                      final isSelected = selectedStatuses.contains(statusKey);
                      final isHovered = hoveredStatus.contains(statusKey);

                      return MouseRegion(
                        onEnter: (_) {
                          setState(() {
                            hoveredStatus.add(statusKey);
                          });
                        },
                        onExit: (_) {
                          setState(() {
                            hoveredStatus.remove(statusKey);
                          });
                        },
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedStatuses.remove(statusKey);
                              } else {
                                selectedStatuses.add(statusKey);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.deepPurple.shade100
                                  : isHovered
                                  ? theme.colorScheme.onTertiary
                                  : theme.colorScheme.onTertiaryFixedVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                color: isSelected ? Colors.deepPurple : themeModeNotifier.value == ThemeMode.dark ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text("New Construction", style: TextStyle(fontWeight: FontWeight.w500)),
                    value: isNewConstruction ?? false,
                    onChanged: (value) {
                      setState(() {
                        isNewConstruction = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text("Max Floors", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ToggleButtons(
                    isSelected: List.generate(4, (i) => tempMaxFloors == (i + 1)),
                    onPressed: (i) => setState(() => tempMaxFloors = i + 1),
                    borderRadius: BorderRadius.circular(8),
                    children: List.generate(4, (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${i + 1}'),
                    )),
                  ),
                  const SizedBox(height: 16),
                  const Text("Max HOA Fee", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<int>(
                    value: tempMaxHOAFee,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    hint: const Text("Any"),
                    items: const [
                      DropdownMenuItem(value: null, child: Text("Any")),
                      DropdownMenuItem(value: 20, child: Text("\$20")),
                      DropdownMenuItem(value: 50, child: Text("\$50")),
                      DropdownMenuItem(value: 100, child: Text("\$100")),
                      DropdownMenuItem(value: 200, child: Text("\$200")),
                    ],
                    onChanged: (val) {
                      setState(() {
                        tempMaxHOAFee = val;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text("Days on MLS", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: tempMaxDaysOnMarket,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    hint: const Text("Any"),
                    items: const [
                      DropdownMenuItem(value: null, child: Text("Any")),
                      DropdownMenuItem(value: 1, child: Text("1 Day")),
                      DropdownMenuItem(value: 3, child: Text("3 Days")),
                      DropdownMenuItem(value: 7, child: Text("1 Week")),
                      DropdownMenuItem(value: 30, child: Text("1 Month")),
                      DropdownMenuItem(value: 60, child: Text("2+ Months")),
                    ],
                    onChanged: (val) {
                      setState(() {
                        tempMaxDaysOnMarket = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Bottom fixed Apply/Cancel button row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.close,
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  widget.close();
                  widget.onApply(
                    PropertyFilter(
                      minPrice: tempMinPrice.toInt(),
                      maxPrice: tempMaxPrice.toInt(),
                      minBeds: tempMinBeds,
                      minBaths: tempMinBaths,
                      minSqft: tempMinSqft,
                      maxSqft: tempMaxSqft,
                      minLotSize: tempMinLotSize,
                      maxLotSize: tempMaxLotSize,
                      minYearBuilt: tempMinYearBuilt,
                      maxYearBuilt: tempMaxYearBuilt,
                      selectedStatuses: selectedStatuses,
                      isNewConstruction: isNewConstruction,
                      maxFloors: tempMaxFloors,
                      maxDaysOnMarket: tempMaxDaysOnMarket,
                      maxHOAFee: tempMaxHOAFee,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Apply"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


