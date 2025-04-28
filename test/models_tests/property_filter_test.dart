// File: test/services/property_filter_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:realest/src/models/property_filter.dart';

void main() {
  group('PropertyFilter.toMap()', () {
    test('☀️ sunny-day: all fields populated yields correct map', () {
      final filter = PropertyFilter(
        minPrice: 100000,
        maxPrice: 500000,
        minBeds: 2,
        minBaths: 1.5,
        minSqft: 800,
        maxSqft: 2000,
        minLotSize: 1000,
        maxLotSize: 5000,
        minYearBuilt: 1990,
        maxYearBuilt: 2020,
        maxHoa: 300,
        homeTypes: ['Condo', 'SingleFamily'],
        selectedStatuses: ['Active', 'Pending'],
        isNewConstruction: true,
        maxFloors: 3,
        maxDaysOnMarket: 60,
        maxHOAFee: 100,
      );

      final map = filter.toMap();

      expect(map, {
        'minPrice': 100000,
        'maxPrice': 500000,
        'minBeds': 2,
        'minBaths': 1.5,
        'minSqft': 800,
        'maxSqft': 2000,
        'minLotSize': 1000,
        'maxLotSize': 5000,
        'minYearBuilt': 1990,
        'maxYearBuilt': 2020,
        'maxHoa': 300,
        'homeTypes': ['Condo', 'SingleFamily'],
        'selectedStatuses': ['Active', 'Pending'],
        'isNewConstruction': true,
        'maxFloors': 3,
        'maxDaysOnMarket': 60,
        'maxHOAFee': 100,
      });
    });

    test('🌧 rainy-day: default constructor yields all nulls', () {
      final filter = PropertyFilter();
      final map = filter.toMap();

      expect(map.keys.length, 17);
      for (final value in map.values) {
        expect(value, isNull);
      }
    });
  });

  group('PropertyFilter.copyWith()', () {
    final original = PropertyFilter(
      minPrice: 100000,
      maxPrice: 500000,
      minBeds: 3,
      minBaths: 2.0,
      minSqft: 1000,
      maxSqft: 2500,
      minLotSize: 1500,
      maxLotSize: 6000,
      minYearBuilt: 2000,
      maxYearBuilt: 2021,
      maxHoa: 200,
      homeTypes: ['Townhouse'],
      selectedStatuses: ['Sold'],
      isNewConstruction: false,
      maxFloors: 2,
      maxDaysOnMarket: 45,
      maxHOAFee: 150,
    );

    test('☀️ sunny-day: overriding some fields', () {
      final copy = original.copyWith(
        minPrice: 120000,
        isNewConstruction: true,
        homeTypes: ['Loft'],
      );

      expect(copy.minPrice, equals(120000));
      expect(copy.maxPrice, equals(original.maxPrice));
      expect(copy.isNewConstruction, isTrue);
      expect(copy.homeTypes, ['Loft']);
      // other fields unchanged
      expect(copy.minBeds, equals(original.minBeds));
      expect(copy.maxDaysOnMarket, equals(original.maxDaysOnMarket));
    });

    test('🌧 rainy-day: no args returns identical filter', () {
      final copy = original.copyWith();

      // All fields should match the original
      expect(copy.minPrice, equals(original.minPrice));
      expect(copy.maxPrice, equals(original.maxPrice));
      expect(copy.minBeds, equals(original.minBeds));
      expect(copy.minBaths, equals(original.minBaths));
      expect(copy.minSqft, equals(original.minSqft));
      expect(copy.maxSqft, equals(original.maxSqft));
      expect(copy.minLotSize, equals(original.minLotSize));
      expect(copy.maxLotSize, equals(original.maxLotSize));
      expect(copy.minYearBuilt, equals(original.minYearBuilt));
      expect(copy.maxYearBuilt, equals(original.maxYearBuilt));
      expect(copy.maxHoa, equals(original.maxHoa));
      expect(copy.homeTypes, equals(original.homeTypes));
      expect(copy.selectedStatuses, equals(original.selectedStatuses));
      expect(copy.isNewConstruction, equals(original.isNewConstruction));
      expect(copy.maxFloors, equals(original.maxFloors));
      expect(copy.maxDaysOnMarket, equals(original.maxDaysOnMarket));
      expect(copy.maxHOAFee, equals(original.maxHOAFee));
    });
  });
}
