import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A Buyer Net Sheet Calculator that calculates the total amount
/// the buyer must bring to closing. Some fields (like Tax Proration,
/// HOA Dues Proration, and Escrow Taxes) are auto‑calculated and shown as read‑only values.
class BuyerNetSheetCalculator extends StatefulWidget {
  const BuyerNetSheetCalculator({Key? key}) : super(key: key);

  @override
  State<BuyerNetSheetCalculator> createState() =>
      _BuyerNetSheetCalculatorState();
}

class _BuyerNetSheetCalculatorState extends State<BuyerNetSheetCalculator> {
  // ---------- Section A: Basic Info ----------
  final TextEditingController _closingDateController = TextEditingController();
  final TextEditingController _salesPriceController = TextEditingController();
  final TextEditingController _previousYearTaxesController = TextEditingController();
  // Tax Proration will be auto-calculated (from Jan 1 to closing date)
  double _calculatedTaxProration = 0.0;
  // Escrow Taxes are now calculated as the prorated portion of annual taxes from the closing date until Dec 31
  double _calculatedEscrowTaxes = 0.0;

  // ---------- Section B: HOA Dues ----------
  final TextEditingController _hoaDuesController = TextEditingController();
  // Frequency: "annual", "semiannual", "quarterly", or "monthly"
  String _hoaFrequency = 'annual';
  // Auto‑calculated HOA Dues Proration (e.g., 3 months worth)
  double _calculatedHoaProration = 0.0;

  // ---------- Section C: Credits (expanded sub-fields) ----------
  final TextEditingController _earnestMoneyController = TextEditingController();
  final TextEditingController _sellerPaidCostsController = TextEditingController();
  final TextEditingController _optionFeeController = TextEditingController();
  final TextEditingController _newLoanAmountController = TextEditingController();
  double _calculatedCredits = 0.0;

  // ---------- Section D: Charges (Non-Editable Heading) ----------
  // Charges remain a fixed 0.0 in the final calculation.
  final double _charges = 0.0;

  // ---------- Section E: Lender Fees (Expanded Sub-Fields) ----------
  final TextEditingController _originationFeeController = TextEditingController();
  final TextEditingController _discountPointsController = TextEditingController();
  final TextEditingController _appraisalFeeController = TextEditingController();
  final TextEditingController _creditReportController = TextEditingController();
  final TextEditingController _taxServiceController = TextEditingController();
  final TextEditingController _floodCertificationController = TextEditingController();
  final TextEditingController _additionalLenderFeeController = TextEditingController();
  final TextEditingController _prepaidInterestController = TextEditingController();
  final TextEditingController _firstYearHOIController = TextEditingController();
  // Escrow HOI is auto‑calculated as 25% of the 1st Year HOI
  double _calculatedEscrowHOI = 0.0;
  // Total Lender Fees (sum of sub-fields and auto‑calculated escrow values)
  double _calculatedLenderFees = 0.0;

  // ---------- Section F: Title Company Fees ----------
  final TextEditingController _titleCompanyFeesController = TextEditingController();

  // ---------- Section G: Contractual/Misc Fees ----------
  final TextEditingController _contractualFeesController = TextEditingController();

  // ---------- Final Calculation ----------
  double _totalBringToClose = 0.0;
  final _currencyFormat = NumberFormat.currency(symbol: "\$");

  // For date picking
  final DateFormat _dateFormat = DateFormat('MM/dd/yyyy');

  /// Opens a date picker, sets the selected date in _closingDateController, then recalculates.
  Future<void> _pickClosingDate() async {
    final now = DateTime.now();
    final initialDate = now.add(const Duration(days: 30));
    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (newDate != null) {
      _closingDateController.text = _dateFormat.format(newDate);
      _calculateNetSheet();
    }
  }

  /// Main calculation method for the net sheet.
  void _calculateNetSheet() {
    // SECTION A: Basic Info
    final salesPrice = _parseDouble(_salesPriceController.text);
    final annualTaxes = _parseDouble(_previousYearTaxesController.text);

    // Calculate Tax Proration: prorate from January 1 to the closing date.
    final closingDateStr = _closingDateController.text.trim();
    DateTime? closingDate;
    try {
      if (closingDateStr.isNotEmpty) {
        closingDate = _dateFormat.parse(closingDateStr);
      }
    } catch (_) {
      closingDate = null;
    }
    if (closingDate != null && annualTaxes > 0) {
      final dayOfYear = _dayOfYear(closingDate);
      // Modified Escrow Taxes Calculation:
      // Seller pays taxes for days 1 to (dayOfYear - 1)
      _calculatedTaxProration = ((dayOfYear - 1) / 365.0) * annualTaxes;
      // Buyer (via escrow) pays taxes from the closing date to December 31
      final remainingDays = 366 - dayOfYear;
      _calculatedEscrowTaxes = (remainingDays / 365.0) * annualTaxes;
    } else {
      _calculatedTaxProration = 0.0;
      _calculatedEscrowTaxes = 0.0;
    }

    // SECTION B: HOA Dues
    final rawHoa = _parseDouble(_hoaDuesController.text);
    double annualHoa;
    switch (_hoaFrequency) {
      case 'semiannual':
        annualHoa = rawHoa * 2;
        break;
      case 'quarterly':
        annualHoa = rawHoa * 4;
        break;
      case 'monthly':
        annualHoa = rawHoa * 12;
        break;
      case 'annual':
      default:
        annualHoa = rawHoa;
        break;
    }
    // Assume 3 months of HOA dues at closing.
    _calculatedHoaProration = (annualHoa / 12) * 3;

    // SECTION C: Credits
    final earnest = _parseDouble(_earnestMoneyController.text);
    final sellerPaid = _parseDouble(_sellerPaidCostsController.text);
    final optionFee = _parseDouble(_optionFeeController.text);
    final newLoan = _parseDouble(_newLoanAmountController.text);
    _calculatedCredits = earnest + sellerPaid + optionFee + newLoan;

    // SECTION D: Charges remains fixed at 0.0.
    final charges = _charges;

    // SECTION E: Lender Fees
    final originationFee = _parseDouble(_originationFeeController.text);
    final discountPoints = _parseDouble(_discountPointsController.text);
    final appraisalFee = _parseDouble(_appraisalFeeController.text);
    final creditReport = _parseDouble(_creditReportController.text);
    final taxService = _parseDouble(_taxServiceController.text);
    final floodCert = _parseDouble(_floodCertificationController.text);
    final additionalFee = _parseDouble(_additionalLenderFeeController.text);
    final prepaidInterest = _parseDouble(_prepaidInterestController.text);
    final firstYearHOI = _parseDouble(_firstYearHOIController.text);
    // Auto-calculate Escrow HOI as 25% of 1st Year HOI.
    _calculatedEscrowHOI = firstYearHOI * 0.25;
    // Sum Lender Fees: include all sub-fields plus auto-calculated Escrow Taxes.
    _calculatedLenderFees =
        originationFee +
            discountPoints +
            appraisalFee +
            creditReport +
            taxService +
            floodCert +
            additionalFee +
            prepaidInterest +
            firstYearHOI +
            _calculatedEscrowHOI +
            _calculatedEscrowTaxes;

    // SECTION F: Title Company Fees
    final titleFees = _parseDouble(_titleCompanyFeesController.text);

    // SECTION G: Contractual/Misc Fees
    final miscFees = _parseDouble(_contractualFeesController.text);

    // Final calculation (simplified):
    final total = salesPrice +
        annualTaxes +
        annualHoa +
        _calculatedTaxProration +
        _calculatedHoaProration +
        charges +
        _calculatedLenderFees +
        titleFees +
        miscFees -
        _calculatedCredits;

    setState(() {
      _totalBringToClose = total.isFinite ? total : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionA(theme),
              const SizedBox(height: 10),
              _buildSectionB(theme),
              const SizedBox(height: 10),
              _buildSectionC(theme),
              const SizedBox(height: 10),
              _buildSectionD(theme),
              const SizedBox(height: 10),
              _buildSectionE(theme),
              const SizedBox(height: 10),
              _buildSectionF(theme),
              const SizedBox(height: 10),
              _buildSectionG(theme),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _calculateNetSheet,
                  child: const Text("Calculate Net Sheet"),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  border: Border.all(color: theme.primaryColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Total Bring to Close: ${_currencyFormat.format(_totalBringToClose)}",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- SECTION A: Basic Info ----------------
  Widget _buildSectionA(ThemeData theme) {
    return ExpansionTile(
      title: const Text("Basic Info"),
      initiallyExpanded: true,
      children: [
        _buildDateField("Anticipated Closing Date", _closingDateController, _pickClosingDate),
        _buildTextField("Sales Price (\$)", _salesPriceController, "e.g. 1,000,000"),
        _buildTextField("Annual Taxes - Previous Year (\$)", _previousYearTaxesController, "e.g. 7,110"),
        _buildReadOnlyRow("Tax Proration (\$)", _calculatedTaxProration),
      ],
    );
  }

  // ---------------- SECTION B: HOA Dues ----------------
  Widget _buildSectionB(ThemeData theme) {
    return ExpansionTile(
      title: const Text("Annual HOA Dues"),
      children: [
        _buildTextField("HOA Dues (\$)", _hoaDuesController, "e.g. 500"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("HOA Dues Frequency:"),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Annual"),
                      value: 'annual',
                      groupValue: _hoaFrequency,
                      onChanged: (val) {
                        setState(() {
                          _hoaFrequency = val!;
                          _calculateNetSheet();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Semiannual"),
                      value: 'semiannual',
                      groupValue: _hoaFrequency,
                      onChanged: (val) {
                        setState(() {
                          _hoaFrequency = val!;
                          _calculateNetSheet();
                        });
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Quarterly"),
                      value: 'quarterly',
                      groupValue: _hoaFrequency,
                      onChanged: (val) {
                        setState(() {
                          _hoaFrequency = val!;
                          _calculateNetSheet();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text("Monthly"),
                      value: 'monthly',
                      groupValue: _hoaFrequency,
                      onChanged: (val) {
                        setState(() {
                          _hoaFrequency = val!;
                          _calculateNetSheet();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _buildReadOnlyRow("HOA Dues Proration (\$)", _calculatedHoaProration),
      ],
    );
  }

  // ---------------- SECTION C: Credits ----------------
  Widget _buildSectionC(ThemeData theme) {
    return ExpansionTile(
      title: const Text("Credits"),
      children: [
        _buildTextField("Earnest Money (\$)", _earnestMoneyController, "e.g. 1000"),
        _buildTextField("Seller Paid Closing Costs (\$)", _sellerPaidCostsController, "e.g. 2000"),
        _buildTextField("Option Fee (\$)", _optionFeeController, "e.g. 100"),
        _buildTextField("New Loan Amount (\$)", _newLoanAmountController, "e.g. 250000"),
        _buildReadOnlyRow("Total Credits (\$)", _calculatedCredits),
      ],
    );
  }

  // ---------------- SECTION D: Charges (Non-Editable Heading) ----------------
  Widget _buildSectionD(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        "Charges",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------- SECTION E: Lender Fees (Expanded Sub-Fields) ----------------
  Widget _buildSectionE(ThemeData theme) {
    return ExpansionTile(
      title: const Text("Lender Fees"),
      children: [
        _buildTextField("Origination Fee (\$)", _originationFeeController, "e.g. 0"),
        _buildTextField("Discount Points (\$)", _discountPointsController, "e.g. 0"),
        _buildTextField("Appraisal Fee (\$)", _appraisalFeeController, "e.g. 0"),
        _buildTextField("Credit Report (\$)", _creditReportController, "e.g. 0"),
        _buildTextField("Tax Service (\$)", _taxServiceController, "e.g. 0"),
        _buildTextField("Flood Certification (\$)", _floodCertificationController, "e.g. 0"),
        _buildTextField("Additional Lender Fee (\$)", _additionalLenderFeeController, "e.g. 0"),
        _buildTextField("Prepaid Interest (\$)", _prepaidInterestController, "e.g. 0"),
        _buildTextField("1st Year HOI (\$)", _firstYearHOIController, "e.g. 0"),
        _buildReadOnlyRow("Escrow HOI (\$)", _calculatedEscrowHOI),
        _buildReadOnlyRow("Escrow Taxes (\$)", _calculatedEscrowTaxes),
        _buildReadOnlyRow("Total Lender Fees (\$)", _calculatedLenderFees),
      ],
    );
  }

  // ---------------- SECTION F: Title Company Fees ----------------
  Widget _buildSectionF(ThemeData theme) {
    return ExpansionTile(
      title: const Text("Title Company Fees"),
      children: [
        _buildTextField("Total Title Company Fees (\$)", _titleCompanyFeesController, "e.g. 1200"),
      ],
    );
  }

  // ---------------- SECTION G: Contractual/Misc Fees ----------------
  Widget _buildSectionG(ThemeData theme) {
    return ExpansionTile(
      title: const Text("Contractual / Misc. Fees"),
      children: [
        _buildTextField("Total Contractual/Misc Fees (\$)", _contractualFeesController, "e.g. 300"),
      ],
    );
  }

  // ---------------- Helper Widgets & Utility Methods ----------------
  Widget _buildDateField(String label, TextEditingController controller, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: IgnorePointer(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              hintText: "Select date",
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hintText) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => _calculateNetSheet(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// Helper widget to display a read-only row.
  Widget _buildReadOnlyRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(_currencyFormat.format(value)),
        ],
      ),
    );
  }

  double _parseDouble(String val) => double.tryParse(val.trim()) ?? 0.0;
  int _parseInt(String val) => int.tryParse(val.trim()) ?? 0;

  /// Returns the day-of-year (1..365) for a given date.
  int _dayOfYear(DateTime date) {
    final start = DateTime(date.year, 1, 1);
    return date.difference(start).inDays + 1;
  }
}
