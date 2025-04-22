// File: test/services/calculator_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:realest/services/calculator_service.dart';

void main() {
  final calculator = CalculatorService();

  group('calculatePITI', () {
    test('☀️ sunny‑day: typical mortgage returns expected PITI', () {
      // Given
      const homePrice = 200000.0;
      const downPayment = 40000.0;
      const annualInterestRate = 4.5;
      const loanTermYears = 30;
      const annualPropertyTax = 2400.0;
      const monthlyInsurance = 100.0;

      // When
      final result = calculator.calculatePITI(
        homePrice: homePrice,
        downPayment: downPayment,
        annualInterestRatePercent: annualInterestRate,
        loanTermYears: loanTermYears,
        annualPropertyTax: annualPropertyTax,
        monthlyInsurance: monthlyInsurance,
      );

      // Then ≈ $1,110.70
      expect(result, closeTo(1110.70, 0.2));
    });

    test('🌧 rainy‑day: zero loan term yields 0.0', () {
      final result = calculator.calculatePITI(
        homePrice: 200000,
        downPayment: 40000,
        annualInterestRatePercent: 4.5,
        loanTermYears: 0,
        annualPropertyTax: 2400,
        monthlyInsurance: 100,
      );
      expect(result, equals(0.0));
    });
  });

  group('calculateAffordability', () {
    test('☀️ sunny‑day: typical inputs returns expected home price', () {
      // Given
      const annualIncome = 120000.0;
      const monthlyDebt = 500.0;
      const downPayment = 20000.0;
      const interestRate = 4.5;
      const loanTermYears = 30;

      // When
      final result = calculator.calculateAffordability(
        annualIncome: annualIncome,
        monthlyDebt: monthlyDebt,
        downPayment: downPayment,
        annualInterestRatePercent: interestRate,
        loanTermYears: loanTermYears,
      );

      // Then ≈ $473,930.67
      expect(result, closeTo(473930.67, 1.0));
    });

    test('🌧 rainy‑day: debt exceeds 28% of income → 0.0', () {
      final result = calculator.calculateAffordability(
        annualIncome: 120000,
        monthlyDebt: 3000,
        downPayment: 20000,
        annualInterestRatePercent: 4.5,
        loanTermYears: 30,
      );
      expect(result, equals(0.0));
    });
  });
}
