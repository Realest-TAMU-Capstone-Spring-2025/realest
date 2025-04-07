import 'package:flutter/material.dart';

class PropertyFilter {
  int? minPrice;
  int? maxPrice;
  int? minBeds;
  double? minBaths;
  List<String>? homeTypes;
  int? maxHoa;
  int? minSqft;
  int? maxSqft;
  int? minLotSize;
  int? maxLotSize;
  int? minYearBuilt;
  int? maxYearBuilt;

  PropertyFilter({
    this.minPrice,
    this.maxPrice,
    this.minBeds,
    this.minBaths,
    this.homeTypes,
    this.maxHoa,
    this.minSqft,
    this.maxSqft,
    this.minLotSize,
    this.maxLotSize,
    this.minYearBuilt,
    this.maxYearBuilt,
  });

  PropertyFilter copyWith({
    int? minPrice,
    int? maxPrice,
    int? minBeds,
    double? minBaths,
    List<String>? homeTypes,
    int? maxHoa,
    int? minSqft,
    int? maxSqft,
    int? minLotSize,
    int? maxLotSize,
    int? minYearBuilt,
    int? maxYearBuilt,
  }) {
    return PropertyFilter(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minBeds: minBeds ?? this.minBeds,
      minBaths: minBaths ?? this.minBaths,
      homeTypes: homeTypes ?? this.homeTypes,
      maxHoa: maxHoa ?? this.maxHoa,
      minSqft: minSqft ?? this.minSqft,
      maxSqft: maxSqft ?? this.maxSqft,
      minLotSize: minLotSize ?? this.minLotSize,
      maxLotSize: maxLotSize ?? this.maxLotSize,
      minYearBuilt: minYearBuilt ?? this.minYearBuilt,
      maxYearBuilt: maxYearBuilt ?? this.maxYearBuilt,
    );
  }
}
