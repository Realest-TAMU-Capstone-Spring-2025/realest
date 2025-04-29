import 'package:flutter/material.dart';

/// Represents a filter for property searches with various criteria.
class PropertyFilter {
  /// Minimum price of the property.
  int? minPrice;

  /// Maximum price of the property.
  int? maxPrice;

  /// Minimum number of bedrooms.
  int? minBeds;

  /// Minimum number of bathrooms.
  double? minBaths;

  /// Minimum square footage.
  int? minSqft;

  /// Maximum square footage.
  int? maxSqft;

  /// Minimum lot size.
  int? minLotSize;

  /// Maximum lot size.
  int? maxLotSize;

  /// Minimum year the property was built.
  int? minYearBuilt;

  /// Maximum year the property was built.
  int? maxYearBuilt;

  /// Maximum HOA fee.
  int? maxHoa;

  /// List of selected home types (e.g., 'single_family', 'condo').
  List<String>? homeTypes;

  /// List of selected property statuses (e.g., 'for_sale', 'pending').
  List<String>? selectedStatuses;

  /// Indicates if only new construction properties are included.
  bool? isNewConstruction;

  /// Maximum number of floors.
  int? maxFloors;

  /// Maximum days the property has been on the market.
  int? maxDaysOnMarket;

  /// Maximum HOA fee (alternative naming).
  int? maxHOAFee;

  /// Creates a [PropertyFilter] with optional properties.
  PropertyFilter({
    this.minPrice,
    this.maxPrice,
    this.minBeds,
    this.minBaths,
    this.minSqft,
    this.maxSqft,
    this.minLotSize,
    this.maxLotSize,
    this.minYearBuilt,
    this.maxYearBuilt,
    this.maxHoa,
    this.homeTypes,
    this.selectedStatuses,
    this.isNewConstruction,
    this.maxFloors,
    this.maxDaysOnMarket,
    this.maxHOAFee,
  });

  /// Converts the filter to a map for serialization or Firestore queries.
  Map<String, dynamic> toMap() {
    return {
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minBeds': minBeds,
      'minBaths': minBaths,
      'minSqft': minSqft,
      'maxSqft': maxSqft,
      'minLotSize': minLotSize,
      'maxLotSize': maxLotSize,
      'minYearBuilt': minYearBuilt,
      'maxYearBuilt': maxYearBuilt,
      'maxHoa': maxHoa,
      'homeTypes': homeTypes,
      'selectedStatuses': selectedStatuses,
      'isNewConstruction': isNewConstruction,
      'maxFloors': maxFloors,
      'maxDaysOnMarket': maxDaysOnMarket,
      'maxHOAFee': maxHOAFee,
    };
  }

  /// Creates a copy of the filter with updated properties.
  PropertyFilter copyWith({
    int? minPrice,
    int? maxPrice,
    int? minBeds,
    double? minBaths,
    int? minSqft,
    int? maxSqft,
    int? minLotSize,
    int? maxLotSize,
    int? minYearBuilt,
    int? maxYearBuilt,
    int? maxHoa,
    List<String>? homeTypes,
    List<String>? selectedStatuses,
    bool? isNewConstruction,
    int? maxFloors,
    int? maxDaysOnMarket,
    int? maxHOAFee,
  }) {
    return PropertyFilter(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minBeds: minBeds ?? this.minBeds,
      minBaths: minBaths ?? this.minBaths,
      minSqft: minSqft ?? this.minSqft,
      maxSqft: maxSqft ?? this.maxSqft,
      minLotSize: minLotSize ?? this.minLotSize,
      maxLotSize: maxLotSize ?? this.maxLotSize,
      minYearBuilt: minYearBuilt ?? this.minYearBuilt,
      maxYearBuilt: maxYearBuilt ?? this.maxYearBuilt,
      maxHoa: maxHoa ?? this.maxHoa,
      homeTypes: homeTypes ?? this.homeTypes,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      isNewConstruction: isNewConstruction ?? this.isNewConstruction,
      maxFloors: maxFloors ?? this.maxFloors,
      maxDaysOnMarket: maxDaysOnMarket ?? this.maxDaysOnMarket,
      maxHOAFee: maxHOAFee ?? this.maxHOAFee,
    );
  }
}