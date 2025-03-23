import 'dart:math';
import 'package:flutter/material.dart';

/// A standalone Mortgage Affordability calculator widget,
/// with no pre-filled values and showing hint text on highlight/focus.
class AffordabilityCalculator extends StatefulWidget {
  const AffordabilityCalculator({Key? key}) : super(key: key);

  @override
  State<AffordabilityCalculator> createState() => _AffordabilityCalculatorState();
}

class _AffordabilityCalculatorState extends State<AffordabilityCalculator> {
  final annualIncomeController = TextEditingController();
  final monthlyDebtController = TextEditingController();
  final downPaymentController = TextEditingController();
  final interestRateController = TextEditingController();
  final loanTermController = TextEditingController();

  double _affordableHomePrice = 0.0;

  void _calculateAffordability() {
    final annualIncome = _parseDouble(annualIncomeController.text);
    final monthlyDebt = _parseDouble(monthlyDebtController.text);
    final downPayment = _parseDouble(downPaymentController.text);
    final annualInterestRate = _parseDouble(interestRateController.text);
    final loanTermYears = _parseInt(loanTermController.text);

    // 28% rule - monthly limit
    final monthlyIncome = annualIncome / 12;
    final maxMonthlyPayment = (monthlyIncome * 0.28) - monthlyDebt;
    if (maxMonthlyPayment <= 0) {
      setState(() => _affordableHomePrice = 0);
      return;
    }

    final monthlyInterestRate = annualInterestRate / 100 / 12;
    final totalMonths = loanTermYears * 12;

    double loanAmount;
    if (monthlyInterestRate <= 0 || totalMonths <= 0) {
      loanAmount = maxMonthlyPayment * totalMonths;
    } else {
      // Reverse mortgage formula
      loanAmount = maxMonthlyPayment *
          ((1 - pow(1 + monthlyInterestRate, -totalMonths)) / monthlyInterestRate);
    }

    final homePrice = loanAmount + downPayment;
    setState(() {
      _affordableHomePrice = homePrice.isFinite ? homePrice : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildCalculatorLayout(
      title: "Affordability Calculator",
      inputFields: [
        _buildTextField("Annual Income (\$)", annualIncomeController, "e.g. 100000"),
        _buildTextField("Monthly Debt (\$)", monthlyDebtController, "e.g. 500"),
        _buildTextField("Down Payment (\$)", downPaymentController, "e.g. 20000"),
        _buildTextField("Interest Rate (%)", interestRateController, "e.g. 4.5"),
        _buildTextField("Loan Term (Years)", loanTermController, "e.g. 30"),
      ],
      onCalculate: _calculateAffordability,
      resultText: "You can afford a home up to: \$${_affordableHomePrice.toStringAsFixed(2)}",
    );
  }

  // -------------------------
  //  HELPER WIDGETS & METHODS
  // -------------------------

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
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText, // Show example while empty/focused
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
