import 'dart:math';

class CalculatorService {
  /// Calculates the monthly payment for Principal, Interest, Taxes, Insurance (PITI).
  ///
  /// [homePrice] total home price.
  /// [downPayment] initial down payment.
  /// [annualInterestRatePercent] the annual interest rate in percent, e.g. 4.5 for 4.5%.
  /// [loanTermYears] length of the loan in years.
  /// [annualPropertyTax] total property tax per year.
  /// [monthlyInsurance] the monthly insurance cost.
  ///
  /// Returns the monthly PITI, or 0 if calculation is impossible.
  double calculatePITI({
    required double homePrice,
    required double downPayment,
    required double annualInterestRatePercent,
    required int loanTermYears,
    required double annualPropertyTax,
    required double monthlyInsurance,
  }) {
    try {
      final loanAmount = homePrice - downPayment;
      // Convert annual percent to a monthly rate (e.g. 4.5% -> 0.045/year -> 0.00375/month)
      final monthlyInterestRate = (annualInterestRatePercent / 100) / 12;
      final totalMonths = loanTermYears * 12;

      // Monthly Principal+Interest using standard mortgage formula
      final monthlyPrincipalInterest = (loanAmount * monthlyInterestRate) /
          (1 - pow((1 + monthlyInterestRate), -totalMonths));

      // Tax is annual, so add monthly portion
      final monthlyPropertyTax = annualPropertyTax / 12.0;

      // Sum to get total monthly
      final piti = monthlyPrincipalInterest + monthlyPropertyTax + monthlyInsurance;

      // Guard against NaN or Infinity
      if (piti.isNaN || piti.isInfinite) return 0.0;
      return piti;
    } catch (_) {
      return 0.0; // Fallback if something went awry
    }
  }

  /// Calculates an approximate affordable home price based on income, debt, etc.
  ///
  /// [annualIncome] total household income per year.
  /// [monthlyDebt] monthly debt obligations (car, student loans, etc.).
  /// [downPayment] initial down payment user plans to put down.
  /// [annualInterestRatePercent] the annual interest rate in percent.
  /// [loanTermYears] length of the loan in years.
  ///
  /// Returns the maximum home price user could afford, or 0 if calculation fails.
  double calculateAffordability({
    required double annualIncome,
    required double monthlyDebt,
    required double downPayment,
    required double annualInterestRatePercent,
    required int loanTermYears,
  }) {
    try {
      // Approx: 28% of monthly income minus existing debts
      final maxMonthlyPayment = (annualIncome / 12) * 0.28 - monthlyDebt;

      // If the net payment is negative, clamp to 0
      if (maxMonthlyPayment <= 0) {
        return 0.0;
      }

      // Convert annual interest to monthly
      final monthlyInterestRate = (annualInterestRatePercent / 100) / 12;
      final totalMonths = loanTermYears * 12;

      // Reverse mortgage formula to figure out how large a loan that monthly payment can service
      final loanAmount = maxMonthlyPayment *
          ((1 - pow((1 + monthlyInterestRate), -totalMonths)) / monthlyInterestRate);

      // Total home price is loan + downPayment
      final homePrice = loanAmount + downPayment;

      if (homePrice.isNaN || homePrice.isInfinite) return 0.0;
      return homePrice;
    } catch (_) {
      return 0.0;
    }
  }
}
