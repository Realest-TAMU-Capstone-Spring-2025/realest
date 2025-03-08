import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'calculators/rental_property_calculator.dart';


class RealtorCalculators extends StatefulWidget {
  const RealtorCalculators({Key? key}) : super(key: key);

  @override
  _RealtorCalculatorsState createState() => _RealtorCalculatorsState();
}

class _RealtorCalculatorsState extends State<RealtorCalculators> {
  int _selectedCalculator = 0; // Default to PITI Calculator

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation for Calculator Selection
          Column(
            children: [
              const SizedBox(height: 30), // White Space Above Sidebar
              Container(
                width: 250,
                // height: MediaQuery.of(context).size.height - 100, // Adjusted for spacing
                decoration: BoxDecoration(
                  color: CupertinoColors.tertiarySystemFill, // White Background
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 40), // Top & Bottom Padding
                child: Column(
                  children: [
                    // Title
                    const Text(
                      "Calculators",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Navigation Items
                    _buildNavItem("PITI Calculator", 0),
                    _buildNavItem("Affordability Calculator", 1),
                    _buildNavItem("Rental Property Calc", 2)

                  ],
                ),
              ),
              const SizedBox(height: 30), // White Space Below Sidebar
            ],
          ),

          // Main Content Area (Calculator)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),

              child: _selectedCalculator == 0
                  ? _buildPITICalculator()
                  : _selectedCalculator == 1
                  ? _buildAffordabilityCalculator()
                  : const RentalPropertyCalculator(),

            ),
          ),
        ],
      ),
    );
  }

  /// Sidebar Navigation Item
  Widget _buildNavItem(String label, int index) {
    bool isSelected = _selectedCalculator == index;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCalculator = index;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        margin: const EdgeInsets.symmetric(vertical: 8), // Spacing between items
        decoration: BoxDecoration(
          color: isSelected ? CupertinoColors.tertiarySystemFill : Colors.transparent, // Light Grey for Selected
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? theme.colorScheme.primary : theme.primaryColor, // Black for Selected
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **PITI (Principal, Interest, Taxes, Insurance) Calculator**
  Widget _buildPITICalculator() {
    final TextEditingController homePriceController = TextEditingController();
    final TextEditingController downPaymentController = TextEditingController();
    final TextEditingController interestRateController = TextEditingController();
    final TextEditingController loanTermController = TextEditingController();
    final TextEditingController propertyTaxController = TextEditingController();
    final TextEditingController insuranceController = TextEditingController();

    double monthlyPayment = 0.0;

    void _calculatePITI() {
      double homePrice = double.tryParse(homePriceController.text) ?? 0;
      double downPayment = double.tryParse(downPaymentController.text) ?? 0;
      double interestRate = (double.tryParse(interestRateController.text) ?? 0) / 100 / 12;
      int loanTerm = (int.tryParse(loanTermController.text) ?? 0) * 12;
      double propertyTax = (double.tryParse(propertyTaxController.text) ?? 0) / 12;
      double insurance = double.tryParse(insuranceController.text) ?? 0;

      double loanAmount = homePrice - downPayment;
      double monthlyPrincipalInterest = (loanAmount * interestRate) /
          (1 - pow((1 + interestRate), -loanTerm));
      double piti = monthlyPrincipalInterest + propertyTax + insurance;

      setState(() {
        monthlyPayment = piti.isNaN ? 0.0 : piti;
      });
    }

    return _buildCalculatorLayout(
      title: "PITI Calculator",
      inputFields: [
        _buildTextField("Home Price (\$)", homePriceController),
        _buildTextField("Down Payment (\$)", downPaymentController),
        _buildTextField("Interest Rate (%)", interestRateController),
        _buildTextField("Loan Term (Years)", loanTermController),
        _buildTextField("Annual Property Tax (\$)", propertyTaxController),
        _buildTextField("Monthly Insurance (\$)", insuranceController),
      ],
      onCalculate: _calculatePITI,
      resultText: "Estimated Monthly Payment: \$${monthlyPayment.toStringAsFixed(2)}",
    );
  }

  /// **Mortgage Affordability Calculator**
  Widget _buildAffordabilityCalculator() {
    final TextEditingController annualIncomeController = TextEditingController();
    final TextEditingController monthlyDebtController = TextEditingController();
    final TextEditingController downPaymentController = TextEditingController();
    final TextEditingController interestRateController = TextEditingController();
    final TextEditingController loanTermController = TextEditingController();

    double affordableHomePrice = 0.0;

    void _calculateAffordability() {
      double annualIncome = double.tryParse(annualIncomeController.text) ?? 0;
      double monthlyDebt = double.tryParse(monthlyDebtController.text) ?? 0;
      double downPayment = double.tryParse(downPaymentController.text) ?? 0;
      double interestRate = (double.tryParse(interestRateController.text) ?? 0) / 100 / 12;
      int loanTerm = (int.tryParse(loanTermController.text) ?? 0) * 12;

      double maxMonthlyPayment = (annualIncome / 12) * 0.28 - monthlyDebt;
      double loanAmount = maxMonthlyPayment * ((1 - pow((1 + interestRate), -loanTerm)) / interestRate);
      double homePrice = loanAmount + downPayment;

      setState(() {
        affordableHomePrice = homePrice.isNaN ? 0.0 : homePrice;
      });
    }

    return _buildCalculatorLayout(
      title: "Affordability Calculator",
      inputFields: [
        _buildTextField("Annual Income (\$)", annualIncomeController),
        _buildTextField("Monthly Debt Payments (\$)", monthlyDebtController),
        _buildTextField("Down Payment (\$)", downPaymentController),
        _buildTextField("Interest Rate (%)", interestRateController),
        _buildTextField("Loan Term (Years)", loanTermController),
      ],
      onCalculate: _calculateAffordability,
      resultText: "You can afford a home up to: \$${affordableHomePrice.toStringAsFixed(2)}",
    );
  }


  /// **Modern Styled Calculate Button**
  Widget _buildModernButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// **Reusable Calculator Layout**
  Widget _buildCalculatorLayout({
    required String title,
    required List<Widget> inputFields,
    required VoidCallback onCalculate,
    required String resultText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ...inputFields,
        const SizedBox(height: 20),

        // Modern Styled Calculate Button
        Center(child: _buildModernButton("Calculate", onCalculate)),

        const SizedBox(height: 20),

        // Display Result
        Center(
          child: Text(
            resultText,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// **Styled Input Fields**
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
