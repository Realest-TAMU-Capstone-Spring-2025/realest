import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Rental Property Calculator screen widget.
class RentalPropertyCalculator extends StatefulWidget {
  const RentalPropertyCalculator({Key? key}) : super(key: key);

  @override
  State<RentalPropertyCalculator> createState() =>
      _RentalPropertyCalculatorState();
}

/// State for RentalPropertyCalculator. Handles input, calculation, and display.
class _RentalPropertyCalculatorState extends State<RentalPropertyCalculator> {
  final currency = NumberFormat.currency(symbol: "\$");

  // Input controllers for form fields
  final purchasePriceController = TextEditingController();
  final downPaymentController = TextEditingController();
  final interestRateController = TextEditingController();
  final loanTermController = TextEditingController();
  final closingCostController = TextEditingController();
  final repairCostController = TextEditingController();
  final propertyTaxController = TextEditingController();
  final insuranceController = TextEditingController();
  final hoaFeeController = TextEditingController();
  final maintenanceController = TextEditingController();
  final otherCostsController = TextEditingController();
  final rentController = TextEditingController();
  final vacancyRateController = TextEditingController();
  final managementFeeController = TextEditingController();

  double _annualCashFlow = 0.0;
  double _roi = 0.0;

  /// Calculates the annual cash flow and ROI based on user inputs.
  void _calculateRental() {
    final price = _parse(purchasePriceController);
    final downPct = _parse(downPaymentController) / 100;
    final rate = _parse(interestRateController) / 100 / 12;
    final years = _parseInt(loanTermController);
    final closing = _parse(closingCostController);
    final repair = _parse(repairCostController);

    final tax = _parse(propertyTaxController) / 12;
    final ins = _parse(insuranceController) / 12;
    final hoa = _parse(hoaFeeController) / 12;
    final maint = _parse(maintenanceController) / 12;
    final other = _parse(otherCostsController) / 12;

    final rent = _parse(rentController);
    final vac = _parse(vacancyRateController) / 100;
    final mgmt = _parse(managementFeeController) / 100;

    final loanAmount = price * (1 - downPct);
    final months = years * 12;

    double mortgage = 0;
    if (loanAmount > 0 && rate > 0 && months > 0) {
      mortgage = (loanAmount * rate) / (1 - pow(1 + rate, -months));
    }

    final expenses = mortgage + tax + ins + hoa + maint + other;
    final loss = rent * vac;
    final fee = rent * mgmt;
    final netIncome = (rent - expenses - loss - fee) * 12;

    final invested = price * downPct + closing + repair;
    final roi = invested > 0 ? (netIncome / invested) * 100 : 0.0;

    setState(() {
      _annualCashFlow = netIncome;
      _roi = roi.isFinite ? roi : 0.0;
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
                "Rental Property Calculator",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Purchase section
              _sectionTitle("Purchase Details"),
              _field("Purchase Price", purchasePriceController, "e.g. 250000"),
              _field("Down Payment (%)", downPaymentController, "e.g. 20"),
              _field("Interest Rate (%)", interestRateController, "e.g. 6.5"),
              _field("Loan Term (Years)", loanTermController, "e.g. 30"),
              _field("Closing Costs", closingCostController, "e.g. 6000"),
              _field("Repair Costs", repairCostController, "e.g. 5000"),

              // Expenses section
              const SizedBox(height: 24),
              _sectionTitle("Annual Expenses"),
              _field("Property Tax", propertyTaxController, "e.g. 3500"),
              _field("Insurance", insuranceController, "e.g. 1200"),
              _field("HOA Fees", hoaFeeController, "e.g. 0"),
              _field("Maintenance", maintenanceController, "e.g. 1500"),
              _field("Other Costs", otherCostsController, "e.g. 500"),

              // Rental income section
              const SizedBox(height: 24),
              _sectionTitle("Rental Income"),
              _field("Monthly Rent", rentController, "e.g. 2000"),
              _field("Vacancy Rate (%)", vacancyRateController, "e.g. 5"),
              _field("Management Fee (%)", managementFeeController, "e.g. 8"),

              const SizedBox(height: 32),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _calculateRental,
                  icon: const Icon(Icons.calculate, color: Colors.white),
                  label: const Text("Calculate"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Display results if available
              if (_annualCashFlow > 0)
                _resultBox(theme),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the results box showing cash flow and ROI.
  Widget _resultBox(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary),
      ),
      child: Column(
        children: [
          Text(
            "Results",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Annual Cash Flow: ${currency.format(_annualCashFlow)}",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "ROI: ${_roi.toStringAsFixed(2)}%",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Section header widget for grouping form fields.
  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  /// Creates a text field with label, hint, and controller.
  Widget _field(String label, TextEditingController controller, String hint) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
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

  /// Safely parses a double from text.
  double _parse(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  /// Safely parses an integer from text.
  int _parseInt(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;
}
