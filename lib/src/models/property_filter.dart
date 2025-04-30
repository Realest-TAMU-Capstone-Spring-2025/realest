class PropertyFilter {
  int? minPrice;
  int? maxPrice;
  int? minBeds;
  double? minBaths;
  int? minSqft;
  int? maxSqft;
  int? minLotSize;
  int? maxLotSize;
  int? minYearBuilt;
  int? maxYearBuilt;
  int? maxHoa;
  List<String>? homeTypes;
  List<String>? selectedStatuses;
  bool? isNewConstruction;
  int? maxFloors;
  int? maxDaysOnMarket;
  int? maxHOAFee;

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
