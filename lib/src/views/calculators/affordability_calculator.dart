import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  double _targetPrice = 0.0;
  double _lowPrice = 0.0;
  double _highPrice = 0.0;
  double _monthlyLimit = 0.0;
  double _loanAmount = 0.0;
  double _downPayment = 0.0;

  final currencyFormat = NumberFormat.currency(symbol: "\$");

  void _calculateAffordability() {
    final annualIncome = _parseDouble(annualIncomeController.text);
    final monthlyDebt = _parseDouble(monthlyDebtController.text);
    final downInput = downPaymentController.text.trim();
    final annualInterestRate = _parseDouble(interestRateController.text);
    final loanTermYears = _parseInt(loanTermController.text);

    final monthlyIncome = annualIncome / 12;
    final maxMonthlyPayment = (monthlyIncome * 0.28) - monthlyDebt;

    if (maxMonthlyPayment <= 0 || loanTermYears <= 0) {
      setState(() {
        _targetPrice = _lowPrice = _highPrice = _monthlyLimit = _loanAmount = _downPayment = 0;
      });
      return;
    }

    final monthlyInterestRate = annualInterestRate / 100 / 12;
    final totalMonths = loanTermYears * 12;

    double loanAmount;
    if (monthlyInterestRate <= 0) {
      loanAmount = maxMonthlyPayment * totalMonths;
    } else {
      loanAmount = maxMonthlyPayment *
          ((1 - pow(1 + monthlyInterestRate, -totalMonths)) / monthlyInterestRate);
    }

    double downPayment;
    if (downInput.endsWith("%")) {
      final percent = double.tryParse(downInput.replaceAll("%", "")) ?? 0;
      downPayment = loanAmount * (percent / 100) / (1 - (percent / 100));
    } else {
      downPayment = _parseDouble(downInput);
    }

    final homePrice = loanAmount + downPayment;

    setState(() {
      _targetPrice = homePrice;
      _lowPrice = homePrice * 0.9;
      _highPrice = homePrice * 1.1;
      _monthlyLimit = maxMonthlyPayment;
      _loanAmount = loanAmount;
      _downPayment = downPayment;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Affordability Calculator",
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              _buildTextField("Annual Income (\$)", annualIncomeController, "e.g. 100000"),
              _buildTextField("Monthly Debt (\$)", monthlyDebtController, "e.g. 500"),
              _buildTextField("Down Payment (\$ or %)", downPaymentController, "e.g. 20000 or 20%"),
              _buildTextField("Interest Rate (%)", interestRateController, "e.g. 6"),
              _buildTextField("Loan Term (Years)", loanTermController, "e.g. 30"),

              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calculate),
                  label: const Text("Calculate"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  onPressed: _calculateAffordability,
                ),
              ),
              const SizedBox(height: 32),

              if (_targetPrice > 0) _buildResultLayout(theme),
              if (_targetPrice == 0)
                Center(
                  child: Text(
                    "Please enter valid values to calculate affordability.",
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultLayout(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Estimated Price Range",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _priceCard("Low", _lowPrice, Colors.orange),
            _priceCard("Target", _targetPrice, theme.colorScheme.primary),
            _priceCard("High", _highPrice, Colors.green),
          ],
        ),
        const SizedBox(height: 24),
        Divider(thickness: 1.2),
        const SizedBox(height: 16),
        Text("Monthly Budget", style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text("Max Monthly Payment: ${currencyFormat.format(_monthlyLimit)}",
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Text("Mortgage Breakdown", style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _labeledStat("Loan Amount", _loanAmount),
        _labeledStat("Down Payment", _downPayment),
      ],
    );
  }

  Widget _priceCard(String label, double value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            currencyFormat.format(value),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _labeledStat(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(currencyFormat.format(value), style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hintText) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          fillColor: theme.inputDecorationTheme.fillColor ?? Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  double _parseDouble(String val) => double.tryParse(val.trim()) ?? 0;
  int _parseInt(String val) => int.tryParse(val.trim()) ?? 0;
}
