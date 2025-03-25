import 'package:flutter_test/flutter_test.dart';
import 'package:realest/services/calculator_service.dart';

void main() {
  group('CalculatorService Tests', () {
    late CalculatorService service;

    setUp(() {
      service = CalculatorService();
    });

    test('calculatePITI returns 0 when interest is 0', () {
      final result = service.calculatePITI(
        homePrice: 300000,
        downPayment: 60000,
        annualInterestRatePercent: 0.0,
        loanTermYears: 30,
        annualPropertyTax: 3600,
        monthlyInsurance: 100,
      );
      // Zero interest would cause a divide-by-zero in real formula.
      // We handle errors by returning 0 in that scenario.
      expect(result, equals(0.0));
    });

    test('calculatePITI with typical values', () {
      final result = service.calculatePITI(
        homePrice: 300000,
        downPayment: 60000,
        annualInterestRatePercent: 5.0, // 5%
        loanTermYears: 30,
        annualPropertyTax: 3600, // $300/month
        monthlyInsurance: 100,
      );

      expect(result, greaterThan(1600));
      expect(result, lessThan(1800));
    });

    test('calculateAffordability returns 0 if annualIncome is zero', () {
      final result = service.calculateAffordability(
        annualIncome: 0,
        monthlyDebt: 500,
        downPayment: 20000,
        annualInterestRatePercent: 4.5,
        loanTermYears: 30,
      );
      expect(result, 0.0);
    });

    test('calculateAffordability with realistic numbers', () {
      final result = service.calculateAffordability(
        annualIncome: 100000, // ~8,333 monthly
        monthlyDebt: 500,
        downPayment: 30000,
        annualInterestRatePercent: 4.5,
        loanTermYears: 30,
      );
      // We might expect somewhere in the mid 300k-400k range
      expect(result, greaterThan(300000));
      expect(result, lessThan(500000));
    });
  });
}
