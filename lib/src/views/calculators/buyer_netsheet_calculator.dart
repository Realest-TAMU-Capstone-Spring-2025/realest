import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A Buyer Net Sheet Calculator that estimates the total cash needed at closing.
/// It follows the same modern theme as your other calculators.
class BuyerNetSheetCalculator extends StatefulWidget {
  const BuyerNetSheetCalculator({Key? key}) : super(key: key);

  @override
  State<BuyerNetSheetCalculator> createState() => _BuyerNetSheetCalculatorState();
}

class _BuyerNetSheetCalculatorState extends State<BuyerNetSheetCalculator> {
  // Section A: Purchase & Loan Info
  final TextEditingController purchasePriceController = TextEditingController();
  final TextEditingController downPaymentPctController = TextEditingController();
  final TextEditingController interestRateController = TextEditingController();
  final TextEditingController loanTermController = TextEditingController();

  // Section B: Prepaids (Annual costs to be escrowed)
  final TextEditingController propertyTaxAnnualController = TextEditingController();
  final TextEditingController hazardInsuranceAnnualController = TextEditingController();
  final TextEditingController hoaDuesAnnualController = TextEditingController();

  // Section C: Closing Costs (Fees)
  final TextEditingController originationFeeController = TextEditingController();
  final TextEditingController appraisalFeeController = TextEditingController();
  final TextEditingController inspectionFeeController = TextEditingController();
  final TextEditingController titleFeeController = TextEditingController();
  final TextEditingController escrowFeeController = TextEditingController();
  final TextEditingController recordingFeeController = TextEditingController();
  final TextEditingController otherCostsController = TextEditingController();

  // Section D: Credits/Prorations
  final TextEditingController sellerCreditController = TextEditingController();
  final TextEditingController taxProrationController = TextEditingController();
  final TextEditingController earnestMoneyController = TextEditingController();

  double _totalCashToClose = 0.0;
  final currencyFormat = NumberFormat.currency(symbol: "\$");

  void _calculateNetSheet() {
    // --- Section A: Purchase & Loan ---
    final purchasePrice = _parseDouble(purchasePriceController.text);
    final downPaymentPct = _parseDouble(downPaymentPctController.text) / 100;
    final interestRate = _parseDouble(interestRateController.text);
    final loanTermYears = _parseInt(loanTermController.text);

    final downPayment = purchasePrice * downPaymentPct;
    // Loan amount is not directly used for net sheet but could be calculated if needed:
    // final loanAmount = (purchasePrice - downPayment).clamp(0, double.infinity);

    // --- Section B: Prepaids ---
    final propertyTaxAnnual = _parseDouble(propertyTaxAnnualController.text);
    final hazardInsuranceAnnual = _parseDouble(hazardInsuranceAnnualController.text);
    final hoaDuesAnnual = _parseDouble(hoaDuesAnnualController.text);
    // For simplicity, assume 3 months of prepaids for property tax, insurance, and HOA
    final propertyTaxPrepaid = (propertyTaxAnnual / 12) * 3;
    final hazardInsurancePrepaid = (hazardInsuranceAnnual / 12) * 3;
    final hoaPrepaid = (hoaDuesAnnual / 12) * 3;
    final totalPrepaids = propertyTaxPrepaid + hazardInsurancePrepaid + hoaPrepaid;

    // --- Section C: Closing Costs ---
    final originationFee = _parseDouble(originationFeeController.text);
    final appraisalFee = _parseDouble(appraisalFeeController.text);
    final inspectionFee = _parseDouble(inspectionFeeController.text);
    final titleFee = _parseDouble(titleFeeController.text);
    final escrowFee = _parseDouble(escrowFeeController.text);
    final recordingFee = _parseDouble(recordingFeeController.text);
    final otherClosingCosts = _parseDouble(otherCostsController.text);
    final totalClosingCosts = originationFee +
        appraisalFee +
        inspectionFee +
        titleFee +
        escrowFee +
        recordingFee +
        otherClosingCosts;

    // --- Section D: Credits/Prorations ---
    final sellerCredit = _parseDouble(sellerCreditController.text);
    final taxProration = _parseDouble(taxProrationController.text);
    final earnestMoney = _parseDouble(earnestMoneyController.text);
    final totalCredits = sellerCredit + taxProration + earnestMoney;

    // --- Final Calculation ---
    // Total out-of-pocket = Down Payment + Closing Costs + Prepaids
    final totalOutOfPocket = downPayment + totalClosingCosts + totalPrepaids;
    final netCashToClose = totalOutOfPocket - totalCredits;

    setState(() {
      _totalCashToClose = netCashToClose.isFinite ? netCashToClose : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _buildCalculatorLayout(
      title: "Buyer Net Sheet Calculator",
      onCalculate: _calculateNetSheet,
      resultText: _totalCashToClose >= 0
          ? "Estimated Cash to Close: ${currencyFormat.format(_totalCashToClose)}"
          : "Estimated Cash Back: ${currencyFormat.format(_totalCashToClose.abs())}",
    );
  }

  Widget _buildCalculatorLayout({
    required String title,
    required VoidCallback onCalculate,
    required String resultText,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Section A: Purchase & Loan Info
              _sectionTitle("Purchase & Loan Info"),
              _buildTextField("Purchase Price (\$)", purchasePriceController, "e.g. 300000"),
              _buildTextField("Down Payment (%)", downPaymentPctController, "e.g. 20"),
              _buildTextField("Interest Rate (%)", interestRateController, "e.g. 5"),
              _buildTextField("Loan Term (Years)", loanTermController, "e.g. 30"),
              const SizedBox(height: 20),

              // Section B: Prepaids
              _sectionTitle("Prepaids (Estimate 3 months)"),
              _buildTextField("Property Tax (\$ / year)", propertyTaxAnnualController, "e.g. 3600"),
              _buildTextField("Hazard Insurance (\$ / year)", hazardInsuranceAnnualController, "e.g. 1200"),
              _buildTextField("HOA Dues (\$ / year)", hoaDuesAnnualController, "e.g. 0"),
              const SizedBox(height: 20),

              // Section C: Closing Costs
              _sectionTitle("Closing Costs"),
              _buildTextField("Origination Fee (\$)", originationFeeController, "e.g. 1000"),
              _buildTextField("Appraisal Fee (\$)", appraisalFeeController, "e.g. 500"),
              _buildTextField("Inspection Fee (\$)", inspectionFeeController, "e.g. 400"),
              _buildTextField("Title Fee (\$)", titleFeeController, "e.g. 1200"),
              _buildTextField("Escrow Fee (\$)", escrowFeeController, "e.g. 600"),
              _buildTextField("Recording Fee (\$)", recordingFeeController, "e.g. 250"),
              _buildTextField("Other Costs (\$)", otherCostsController, "e.g. 300"),
              const SizedBox(height: 20),

              // Section D: Credits / Prorations
              _sectionTitle("Credits & Prorations"),
              _buildTextField("Seller Credit (\$)", sellerCreditController, "e.g. 1000"),
              _buildTextField("Tax Proration (\$)", taxProrationController, "e.g. 600"),
              _buildTextField("Earnest Money (\$)", earnestMoneyController, "e.g. 2000"),
              const SizedBox(height: 30),

              // Calculate Button
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
                  onPressed: _calculateNetSheet,
                ),
              ),

              // Result Display
              Center(
                child: Text(
                  resultText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
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
