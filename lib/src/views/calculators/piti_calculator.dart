import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PitiCalculator extends StatefulWidget {
  const PitiCalculator({Key? key}) : super(key: key);

  @override
  State<PitiCalculator> createState() => _PitiCalculatorState();
}

class _PitiCalculatorState extends State<PitiCalculator> {
  final downPaymentController = TextEditingController();
  final interestRateController = TextEditingController();
  final loanTermController = TextEditingController();
  final propertyTaxController = TextEditingController();
  final insuranceController = TextEditingController();
  final homePriceController = TextEditingController();

  double _monthlyPayment = 0.0;

  final currencyFormat = NumberFormat.currency(symbol: "\$");

  void _calculatePITI() {
    final homePrice = _parseDouble(homePriceController.text);
    final downPayment = _parseDouble(downPaymentController.text);
    final annualInterestRate = _parseDouble(interestRateController.text);
    final loanTermYears = _parseInt(loanTermController.text);
    final annualPropertyTax = _parseDouble(propertyTaxController.text);
    final monthlyInsurance = _parseDouble(insuranceController.text);

    final loanAmount = (homePrice - downPayment).clamp(0, double.infinity);
    final monthlyInterestRate = annualInterestRate / 100 / 12;
    final totalMonths = loanTermYears * 12;

    double monthlyPrincipalInterest = 0.0;
    if (loanAmount > 0 && monthlyInterestRate > 0 && totalMonths > 0) {
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
                "PITI Calculator",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              _buildTextField("Home Price (\$)", homePriceController, "e.g. 300000"),
              _buildTextField("Down Payment (\$)", downPaymentController, "e.g. 60000"),
              _buildTextField("Interest Rate (%)", interestRateController, "e.g. 5.5"),
              _buildTextField("Loan Term (Years)", loanTermController, "e.g. 30"),
              _buildTextField("Annual Property Tax (\$)", propertyTaxController, "e.g. 3600"),
              _buildTextField("Monthly Insurance (\$)", insuranceController, "e.g. 100"),

              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.calculate, color: Colors.white),
                  label: const Text("Calculate"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  onPressed: _calculatePITI,
                ),
              ),

              const SizedBox(height: 32),

              if (_monthlyPayment > 0)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.primary),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        "Monthly Payment Breakdown",
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieSections(),
                            centerSpaceRadius: 40,
                            sectionsSpace: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        "Estimated Monthly Payment: \$${_monthlyPayment.toStringAsFixed(2)}",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_monthlyPayment == 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Center(
                    child: Text(
                      "Please enter valid values to calculate your payment.",
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final homePrice = _parseDouble(homePriceController.text);
    final downPayment = _parseDouble(downPaymentController.text);
    final loanAmount = (homePrice - downPayment).clamp(0, double.infinity);
    final monthlyInterestRate = _parseDouble(interestRateController.text) / 100 / 12;
    final totalMonths = _parseInt(loanTermController.text) * 12;

    double principalInterest = 0;
    if (loanAmount > 0 && monthlyInterestRate > 0 && totalMonths > 0) {
      principalInterest = (loanAmount * monthlyInterestRate) /
          (1 - pow(1 + monthlyInterestRate, -totalMonths));
    }

    final propertyTax = _parseDouble(propertyTaxController.text) / 12;
    final insurance = _parseDouble(insuranceController.text);

    final total = principalInterest + propertyTax + insurance;

    return [
      PieChartSectionData(
        value: principalInterest,
        color: Colors.deepPurple,
        title: "${(principalInterest / total * 100).toStringAsFixed(1)}%",
      ),
      PieChartSectionData(
        value: propertyTax,
        color: Colors.teal,
        title: "${(propertyTax / total * 100).toStringAsFixed(1)}%",
      ),
      PieChartSectionData(
        value: insurance,
        color: Colors.orange,
        title: "${(insurance / total * 100).toStringAsFixed(1)}%",
      ),
    ];
  }

  Widget _buildTextField(String label, TextEditingController controller, String hintText) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
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
