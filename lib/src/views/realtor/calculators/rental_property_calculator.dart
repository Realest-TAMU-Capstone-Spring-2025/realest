import 'dart:math';
import 'package:flutter/material.dart';

/// A rental property calculator widget that matches the theming
/// of your PITI and Affordability calculators.
class RentalPropertyCalculator extends StatefulWidget {
  const RentalPropertyCalculator({Key? key}) : super(key: key);

  @override
  State<RentalPropertyCalculator> createState() =>
      _RentalPropertyCalculatorState();
}

class _RentalPropertyCalculatorState extends State<RentalPropertyCalculator> {
  // Purchase-related fields
  final purchasePriceController = TextEditingController();
  final downPaymentController = TextEditingController();
  final interestRateController = TextEditingController();
  final loanTermController = TextEditingController();
  final closingCostController = TextEditingController();
  final repairCostController = TextEditingController();

  // Recurring expenses
  final propertyTaxController = TextEditingController();
  final insuranceController = TextEditingController();
  final hoaFeeController = TextEditingController();
  final maintenanceController = TextEditingController();
  final otherCostsController = TextEditingController();

  // Income
  final rentController = TextEditingController();
  final vacancyRateController = TextEditingController();
  final managementFeeController = TextEditingController();

  double _annualCashFlow = 0.0; // net annual income
  double _roi = 0.0;            // return on investment (%)

  /// Main calculation
  void _calculateRentalProperty() {
    // 1. Parse inputs
    final purchasePrice = _parseDouble(purchasePriceController.text);
    final downPaymentPct = _parseDouble(downPaymentController.text) / 100;
    final annualInterestRate = _parseDouble(interestRateController.text) / 100;
    final years = _parseInt(loanTermController.text);
    final closingCost = _parseDouble(closingCostController.text);
    final repairCost = _parseDouble(repairCostController.text);

    final propertyTax = _parseDouble(propertyTaxController.text);
    final insurance = _parseDouble(insuranceController.text);
    final hoaFee = _parseDouble(hoaFeeController.text);
    final maintenance = _parseDouble(maintenanceController.text);
    final otherCosts = _parseDouble(otherCostsController.text);

    final monthlyRent = _parseDouble(rentController.text);
    final vacancyPct = _parseDouble(vacancyRateController.text) / 100;
    final mgmtFeePct = _parseDouble(managementFeeController.text) / 100;

    // 2. Loan
    final loanAmount = purchasePrice * (1 - downPaymentPct);
    final monthlyInterestRate = (annualInterestRate / 12).clamp(0.0, double.infinity);
    final totalMonths = (years * 12).clamp(0, 1000);

    double monthlyMortgage;
    if (loanAmount <= 0 || monthlyInterestRate <= 0 || totalMonths <= 0) {
      monthlyMortgage = 0.0;
    } else {
      monthlyMortgage = (loanAmount * monthlyInterestRate) /
          (1 - pow(1 + monthlyInterestRate, -totalMonths));
    }

    // 3. Monthly expenses (annual to monthly)
    final monthlyPropertyTax = propertyTax / 12;
    final monthlyInsurance = insurance / 12;
    final monthlyHoaFee = hoaFee / 12;
    final monthlyMaintenance = maintenance / 12;
    final monthlyOther = otherCosts / 12;

    final monthlyExpenses = monthlyMortgage +
        monthlyPropertyTax +
        monthlyInsurance +
        monthlyHoaFee +
        monthlyMaintenance +
        monthlyOther;

    // 4. Net monthly income
    final monthlyVacancyLoss = monthlyRent * vacancyPct;
    final monthlyMgmtFee = monthlyRent * mgmtFeePct;
    final netMonthlyIncome = monthlyRent - monthlyExpenses - monthlyVacancyLoss - monthlyMgmtFee;
    final netAnnualIncome = netMonthlyIncome * 12;

    // 5. Total investment (down payment + closing + repairs)
    final totalInvestment = (purchasePrice * downPaymentPct) + closingCost + repairCost;

    double yearlyROI = 0.0;
    if (totalInvestment > 0) {
      yearlyROI = (netAnnualIncome / totalInvestment) * 100;
    }

    setState(() {
      _annualCashFlow = netAnnualIncome;
      _roi = yearlyROI.isFinite ? yearlyROI : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Using the same style approach as your other calculators
    return _buildCalculatorLayout(
      title: "Rental Property Calculator",
      inputFields: [
        // Purchase
        _buildTextField("Purchase Price (\$)", purchasePriceController, "e.g. 200000"),
        _buildTextField("Down Payment (%)", downPaymentController, "e.g. 20"),
        _buildTextField("Interest Rate (%)", interestRateController, "e.g. 6"),
        _buildTextField("Loan Term (Years)", loanTermController, "e.g. 30"),
        _buildTextField("Closing Costs (\$)", closingCostController, "e.g. 6000"),
        _buildTextField("Repairs (\$)", repairCostController, "e.g. 0"),

        const SizedBox(height: 15),
        const Text(
          "Recurring Expenses (Annual)",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        _buildTextField("Property Tax (\$)", propertyTaxController, "e.g. 3000"),
        _buildTextField("Insurance (\$)", insuranceController, "e.g. 1200"),
        _buildTextField("HOA Fees (\$)", hoaFeeController, "e.g. 0"),
        _buildTextField("Maintenance (\$)", maintenanceController, "e.g. 2000"),
        _buildTextField("Other Costs (\$)", otherCostsController, "e.g. 500"),

        const SizedBox(height: 15),
        const Text(
          "Income",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        _buildTextField("Monthly Rent (\$)", rentController, "e.g. 2000"),
        _buildTextField("Vacancy Rate (%)", vacancyRateController, "e.g. 5"),
        _buildTextField("Management Fee (%)", managementFeeController, "e.g. 0"),
      ],
      onCalculate: _calculateRentalProperty,
      resultText: "Annual Cash Flow: \$${_annualCashFlow.toStringAsFixed(2)}\n"
          "ROI: ${_roi.toStringAsFixed(2)}%",
    );
  }

  // --------------
  // Layout Helpers
  // --------------

  Widget _buildCalculatorLayout({
    required String title,
    required List<Widget> inputFields,
    required VoidCallback onCalculate,
    required String resultText,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          ...inputFields,
          const SizedBox(height: 20),

          // "Calculate" button in same style as PITI/Affordability
          Center(child: _buildModernButton("Calculate", onCalculate)),
          const SizedBox(height: 20),

          // Show results
          Center(
            child: Text(
              resultText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hintText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  double _parseDouble(String? val) => double.tryParse(val?.trim() ?? '') ?? 0;
  int _parseInt(String? val) => int.tryParse(val?.trim() ?? '') ?? 0;
}
