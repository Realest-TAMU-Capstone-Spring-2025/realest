import 'dart:math';
import 'package:flutter/material.dart';

/// A standalone PITI (Principal, Interest, Taxes, Insurance) calculator widget,
/// with no pre-filled values, but hint text for guidance.
class PitiCalculator extends StatefulWidget {
  const PitiCalculator({Key? key}) : super(key: key);

  @override
  State<PitiCalculator> createState() => _PitiCalculatorState();
}

class _PitiCalculatorState extends State<PitiCalculator> {
  // Start with empty controllers. The user sees hintText if no text is typed.
  final homePriceController = TextEditingController();
  final downPaymentController = TextEditingController();
  final interestRateController = TextEditingController();
  final loanTermController = TextEditingController();
  final propertyTaxController = TextEditingController();
  final insuranceController = TextEditingController();

  double _monthlyPayment = 0.0;

  /// Perform the PITI calculation
  void _calculatePITI() {
    final homePrice = _parseDouble(homePriceController.text);
    final downPayment = _parseDouble(downPaymentController.text);
    final annualInterestRate = _parseDouble(interestRateController.text);
    final loanTermYears = _parseInt(loanTermController.text);
    final annualPropertyTax = _parseDouble(propertyTaxController.text);
    final monthlyInsurance = _parseDouble(insuranceController.text);

    // Basic clamps to avoid negative or nonsense values
    final loanAmount = (homePrice - downPayment).clamp(0, double.infinity);
    final monthlyInterestRate = annualInterestRate / 100 / 12;
    final totalMonths = loanTermYears * 12;

    double monthlyPrincipalInterest;
    if (loanAmount <= 0 || monthlyInterestRate <= 0 || totalMonths <= 0) {
      monthlyPrincipalInterest = 0.0;
    } else {
      // Mortgage formula
      monthlyPrincipalInterest = (loanAmount * monthlyInterestRate) /
          (1 - pow(1 + monthlyInterestRate, -totalMonths));
    }

    final monthlyTax = annualPropertyTax / 12;
    final piti = monthlyPrincipalInterest + monthlyTax + monthlyInsurance;

    setState(() {
      _monthlyPayment = piti.isFinite ? piti : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildCalculatorLayout(
      title: "PITI Calculator",
      inputFields: [
        _buildTextField("Home Price (\$)", homePriceController, "e.g. 300000"),
        _buildTextField("Down Payment (\$)", downPaymentController, "e.g. 60000"),
        _buildTextField("Interest Rate (%)", interestRateController, "e.g. 5"),
        _buildTextField("Loan Term (Years)", loanTermController, "e.g. 30"),
        _buildTextField("Annual Property Tax (\$)", propertyTaxController, "e.g. 3600"),
        _buildTextField("Monthly Insurance (\$)", insuranceController, "e.g. 100"),
      ],
      onCalculate: _calculatePITI,
      resultText: "Estimated Monthly Payment: \$${_monthlyPayment.toStringAsFixed(2)}",
    );
  }

  // -------------------------
  //  HELPER WIDGETS & METHODS
  // -------------------------

  /// Reusable layout matching your modern style
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

          Center(child: _buildModernButton("Calculate", onCalculate)),
          const SizedBox(height: 20),

          Center(
            child: Text(
              resultText,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// A modern elevated button with consistent styling
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

  /// A styled text field with optional hint text for examples
  Widget _buildTextField(String label, TextEditingController controller, String hintText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  double _parseDouble(String val) => double.tryParse(val.trim()) ?? 0;
  int _parseInt(String val) => int.tryParse(val.trim()) ?? 0;
}
