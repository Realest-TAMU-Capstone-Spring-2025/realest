import 'dart:math';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'cashflow_edit_dialog.dart';

/// Widget for displaying cash flow analysis of a property
/// with baseline and personalized estimates, editing, and suggestions.
class CashFlowAnalysisWidget extends StatefulWidget {
  final String listingId;
  final bool isRealtor;

  const CashFlowAnalysisWidget({Key? key, required this.listingId,required this.isRealtor,
  }) : super(key: key);

  @override
  State<CashFlowAnalysisWidget> createState() => _CashFlowAnalysisWidgetState();
}

class _CashFlowAnalysisWidgetState extends State<CashFlowAnalysisWidget> {
  bool _isLoading = true;
  String? realtorId;
  Map<String, dynamic> cashflowData = {};
  Map<String, dynamic> cashFlowDefaults = {}; // ✅ should be here
  Map<String, dynamic>? previousValuesUsed;
  Map<String, dynamic> baselineData = {};
  Map<String, dynamic> personalData = {};
  bool _showPersonalEstimate = true;
  Map<String, dynamic> fromRealtorValues = {};



  @override
  void initState() {
    super.initState();
    _fetchData(); // realtorId will be resolved inside this method
  }

  /// Fetch investor's default loan parameters
  Future<Map<String, dynamic>> _getInvestorLoanDefaults() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return {};

    final doc = await FirebaseFirestore.instance.collection('investors').doc(userId).get();
    final defaults = doc.data()?['cashFlowDefaults'] ?? {};

    return {
      'downPayment': defaults['downPayment'] ?? 0.2,
      'interestRate': defaults['interestRate'] ?? 0.06,
      'loanTerm': defaults['loanTerm'] ?? 30,
    };
  }

  /// Get breakdown of expense categories
  Map<String, double> _getExpenseBreakdown(Map<String, dynamic> data) {
    return {
      'Principal': (data['principal'] ?? 0).toDouble(),
      'Interest': (data['interest'] ?? 0).toDouble(),
      'Property Tax': (data['tax'] ?? 0).toDouble(),
      'Insurance': (data['insurance'] ?? 0).toDouble(),
      'Maintenance': (data['maintenance'] ?? 0).toDouble(),
      'HOA Fee': (data['hoaFee'] ?? 0).toDouble(),
      'Vacancy Loss': (data['vacancy'] ?? 0).toDouble(),
      'Management Fee': (data['managementFee'] ?? 0).toDouble(),
      'Other Costs': (data['otherCosts'] ?? 0).toDouble(),
    };
  }

  /// Fetch baseline data and personalize if investor
  Future<void> _fetchData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (widget.isRealtor) {
      realtorId = userId;
    } else {
      final investorDoc = await FirebaseFirestore.instance.collection('investors').doc(userId).get();
      final investorData = investorDoc.data();
      realtorId = investorData?['realtorId'];
      if (realtorId == null) {
        debugPrint('❌ Could not find assigned realtor for investor $userId');
        return;
      }
    }

    final doc = await FirebaseFirestore.instance
        .collection('realtors')
        .doc(realtorId)
        .collection('cashflow_analysis')
        .doc(widget.listingId)
        .get();

    if (!doc.exists) {
      debugPrint('❌ Cash flow document not found for listing ${widget.listingId}');
      return;
    }

    final raw = doc.data()!;
    baselineData = Map<String, dynamic>.from(raw);
    cashflowData = Map<String, dynamic>.from(raw); // default to baseline

    if (!widget.isRealtor) {
      final investorDefaults = await _getInvestorLoanDefaults();
      final purchasePrice = (raw['purchasePrice'] ?? 0).toDouble();
      final rent = (raw['rent'] ?? 0).toDouble();
      final dp = investorDefaults['downPayment'];
      final ir = investorDefaults['interestRate'];
      final term = investorDefaults['loanTerm'];

      final downPayment = dp * purchasePrice;
      final loanAmount = purchasePrice - downPayment;
      final monthlyInterest = ir / 12;
      final months = term * 12;
      final principal = loanAmount / months;
      final monthlyPayment = loanAmount * monthlyInterest / (1 - (1 / pow(1 + monthlyInterest, months)));
      final interest = monthlyPayment - principal;

      final hoaFee = (raw['hoaFee'] ?? 0).toDouble();
      final tax = (raw['tax'] ?? 0).toDouble();
      final insurance = (raw['insurance'] ?? 0).toDouble();
      final maintenance = (raw['maintenance'] ?? 0).toDouble();
      final otherCosts = (raw['otherCosts'] ?? 0).toDouble();
      final vacancy = (raw['vacancy'] ?? 0).toDouble();
      final managementFee = (raw['managementFee'] ?? 0).toDouble();

      final expenses = monthlyPayment + tax + insurance + maintenance + otherCosts + hoaFee + vacancy + managementFee;
      final noi = rent - expenses;

      personalData = {
        ...raw,
        'downPayment': downPayment,
        'loanAmount': loanAmount,
        'monthlyInterest': monthlyInterest,
        'monthlyPayment': monthlyPayment,
        'principal': principal,
        'interest': interest,
        'months': months,
        'netOperatingIncome': noi,
        'valuesUsed': {
          ...?raw['valuesUsed'],
          'downPayment': dp,
          'interestRate': ir,
          'loanTerm': term,
        },
      };

      final originalValues = Map<String, dynamic>.from(raw['valuesUsed'] ?? {});
      originalValues.removeWhere((key, _) =>
      key == 'downPayment' || key == 'interestRate' || key == 'loanTerm');

      originalValues['customIncome'] = rent;

      fromRealtorValues= originalValues;

      // Apply toggle
      if (_showPersonalEstimate) {
        cashflowData = Map<String, dynamic>.from(personalData);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Build the full UI
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: "\$");

    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final income = (cashflowData['rent'] ?? 0) - (cashflowData['vacancy'] ?? 0);
    final expenses = (cashflowData['monthlyPayment'] ?? 0) +
        (cashflowData['tax'] ?? 0) +
        (cashflowData['insurance'] ?? 0) +
        (cashflowData['maintenance'] ?? 0) +
        (cashflowData['hoaFee'] ?? 0) +
        (cashflowData['otherCosts'] ?? 0);
    final cashFlow = income - expenses;

    final isPositive = cashFlow >= 0;

    final breakdown = _getExpenseBreakdown(cashflowData);



    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isPositive ? Colors.green : Colors.red, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isRealtor)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Baseline"),
                Switch(
                  value: _showPersonalEstimate,
                  onChanged: (value) {
                    setState(() {
                      _showPersonalEstimate = value;
                      cashflowData = value ? personalData : baselineData;
                    });
                  },
                ),
                const Text("Personalized"),
              ],
            ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: theme.colorScheme.primary,
                      size: 20),
                  const SizedBox(width: 8),
                  Text("Cash Flow Summary",
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                tooltip: "Edit Calculation",
                onPressed: _showEditDialog,
              )
            ],
          ),
          const SizedBox(height: 12),
          // Summary cards
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _valueCard(
                    "Income",
                    (cashflowData['rent'] as num).toDouble(),
                    Colors.green,
                    currency,
                  ),
                  _valueCard(
                    "Expenses",
                    ((cashflowData['rent'] as num) - (cashflowData['netOperatingIncome'] as num)).toDouble(),
                    Colors.red,
                    currency,
                  ),
                  _valueCard(
                    "Cash Flow",
                    (cashflowData['netOperatingIncome'] as num).toDouble(),
                    isPositive ? Colors.green : Colors.red,
                    currency,
                  ),
                ],
              ),
            ),
          ),


          const SizedBox(height: 10),
          // Breakdown section
          Divider(height: 24),
          Text("Monthly Expense Breakdown",
              style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildExpenseBar(breakdown),
          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildBreakdownList(breakdown, theme, currency),
              ),
            ),
          ),
          const SizedBox(height: 10),

          if (!widget.isRealtor)
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send, color: Colors.white), // explicitly white icon
                label: const Text("Suggest Change to Realtor"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _showSuggestionReviewDialog,
              ),
            )
        ],
      ),
    );
  }

  /// Show dialog for the user to review and submit changes to the realtor
  void _showSuggestionReviewDialog() {
    final usedValues = fromRealtorValues;
    final newValues = cashFlowDefaults;
    final differences = <String, dynamic>{};

    print("From realtor: $usedValues");
    print("Updated: $newValues");

    for (final key in newValues.keys) {
      final newVal = newValues[key];

      // Special case: customIncome comparison
      if (key == 'customIncome') {
        final oldVal = usedValues.containsKey('customIncome')
            ? usedValues['customIncome']
            : cashflowData['rent'];

        if (oldVal is num && newVal is num && (oldVal - newVal).abs() < 0.1) {
          continue; // skip if values are same
        }
        if (oldVal != newVal) {
          differences[key] = newVal;
        }
        continue;
      }

      final oldVal = usedValues[key];
      if (oldVal == null && newVal == null) continue;

      if (oldVal is num && newVal is num) {
        if ((oldVal - newVal).abs() > 0.1) {
          differences[key] = newVal;
        }
      } else if (oldVal != newVal) {
        differences[key] = newVal;
      }
    }


    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // ✅ Proper max width
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Confirm Suggestion",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Changes You Made",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: differences.isNotEmpty
                      ? Column(
                    children: differences.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              entry.value.toString(),
                              style: const TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                      : const Text("You made no changes"),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Add a note for your realtor (optional)",
                    hintText: "e.g. I think this HOA is too high",
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        final investorId = FirebaseAuth.instance.currentUser?.uid;
                        if (investorId != null && realtorId != null) {
                          await FirebaseFirestore.instance
                              .collection('realtors')
                              .doc(realtorId)
                              .collection('cashflow_suggestions')
                              .add({
                            'investorId': investorId,
                            'listingId': widget.listingId,
                            'suggestedValues': differences,
                            'note': noteController.text.trim(),
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Suggestion sent to your realtor.")),
                            );
                          }
                        }
                      },
                      child: const Text("Send Suggestion"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );

  }

  /// Title for Monthly Breakdown section
  List<Widget> _buildBreakdownList(Map<String, dynamic> rawBreakdown,
      ThemeData theme,
      NumberFormat currency,) {
    final breakdown = rawBreakdown.map((k, v) =>
        MapEntry(k.toString(), (v as num).toDouble()));

    final colors = {
      'Principal': Colors.blue,
      'Interest': Colors.indigo,
      'Property Tax': Colors.teal,
      'Insurance': Colors.orange,
      'Maintenance': Colors.deepPurple,
      'HOA Fee': Colors.pink,
      'Vacancy Loss': Colors.grey,
      'Management Fee': Colors.brown,
      'Other Costs': Colors.cyan,
    };

    return breakdown.entries.map((entry) {
      final color = colors[entry.key] ?? Colors.grey;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                entry.key,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              currency.format(entry.value),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Summary Income/Expense/Net Cards
  Widget _buildExpenseBar(Map<String, dynamic> breakdown) {
    final total = breakdown.values.fold(
        0.0, (sum, v) => sum + (v as num).toDouble());

    final colors = {
      'Principal': Colors.blue,
      'Interest': Colors.indigo,
      'Property Tax': Colors.teal,
      'Insurance': Colors.orange,
      'Maintenance': Colors.deepPurple,
      'HOA Fee': Colors.pink,
      'Vacancy Loss': Colors.grey,
      'Management Fee': Colors.brown,
      'Other Costs': Colors.cyan,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 24,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade200,
          ),
          child: Row(
            children: breakdown.entries.map((entry) {
              final value = (entry.value as num).toDouble();
              final widthFraction = total == 0 ? 0 : value / total;
              final color = colors[entry.key] ?? Colors.grey.shade400;

              return Flexible(
                flex: (widthFraction * 1000).round(), // Weighted width
                child: Tooltip(
                  message: '${entry.key}: ${NumberFormat
                      .currency(symbol: '\$')
                      .format(value)}',
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.only(
                        topLeft: entry.key == breakdown.keys.first ? Radius
                            .circular(12) : Radius.zero,
                        bottomLeft: entry.key == breakdown.keys.first ? Radius
                            .circular(12) : Radius.zero,
                        topRight: entry.key == breakdown.keys.last ? Radius
                            .circular(12) : Radius.zero,
                        bottomRight: entry.key == breakdown.keys.last ? Radius
                            .circular(12) : Radius.zero,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Widget for a single financial summary card (Income / Expense / Net)
  Widget _valueCard(String label, double amount, Color color,
      NumberFormat currency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(currency.format(amount), style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }


  // Place this inside _CashFlowAnalysisWidgetState
  /// Show dialog to edit cash flow assumptions (loan % down payment, property tax, insurance, etc.)
  void _showEditDialog() {
    final usedValues = cashflowData['valuesUsed'] ?? {};

    final initialDefaults = {
      'downPayment': usedValues['downPayment'] ?? 0.2,
      'interestRate': usedValues['interestRate'] ?? 0.06,
      'loanTerm': usedValues['loanTerm'] ?? 30,
      'propertyTax': usedValues['propertyTax'] ?? 0.015,
      'insurance': usedValues['insurance'] ?? 0.005,
      'maintenance': usedValues['maintenance'] ?? 0.01,
      'managementFee': usedValues['managementFee'] ?? 0.0,
      'vacancyRate': usedValues['vacancyRate'] ?? 0.05,
      'hoaFee': usedValues['hoaFee'] ?? 0.0,
      'otherCosts': usedValues['otherCosts'] ?? 0.0,
      'customIncome': (cashFlowDefaults['customIncome'] ??
          usedValues['customIncome'] ??
          cashflowData['rent'] ?? 0).toDouble(),

    };
    showDialog(
      context: context,
      builder: (context) => CashFlowEditDialog(
        isRealtor: widget.isRealtor,
        initialDefaults: initialDefaults,
        purchasePrice: (cashflowData['purchasePrice'] ?? 0).toDouble(),
        grossMonthlyRent: (cashflowData['rent'] ?? 0).toDouble(),
        listingId: widget.listingId,
        realtorId: realtorId!,
          onSave: (newDefaults) async {
            setState(() {
              cashFlowDefaults = newDefaults;
            });


            final double purchasePrice = (cashflowData['purchasePrice'] ?? 0).toDouble();
            final used = cashflowData['valuesUsed'] ?? {};

            final double rent = (newDefaults['customIncome'] ?? 0).toDouble();
            final double downPayment = ((used['downPayment'] ?? 0) as num).toDouble() * purchasePrice;
            final double loanAmount = purchasePrice - downPayment;
            final double interestRate = ((used['interestRate'] ?? 0) as num).toDouble();
            final int loanTerm = ((used['loanTerm'] ?? 0) as num).toInt();
            final double monthlyInterest = interestRate / 12;
            final int months = loanTerm * 12;

            final double principal = loanAmount / months;
            final double monthlyPayment = loanAmount * monthlyInterest / (1 - (1 / pow(1 + monthlyInterest, months)));
            final double interest = monthlyPayment - principal;

            final double hoaFee = ((newDefaults['hoaFee'] ?? 0) as num).toDouble();
            final double propertyTax = ((newDefaults['propertyTax'] ?? 0) as num).toDouble() * purchasePrice / 12;
            final double vacancy = ((newDefaults['vacancyRate'] ?? 0) as num).toDouble() * rent;
            final double insurance = ((newDefaults['insurance'] ?? 0) as num).toDouble() * purchasePrice / 12;
            final double maintenance = ((newDefaults['maintenance'] ?? 0) as num).toDouble() * purchasePrice / 12;
            final double otherCosts = ((newDefaults['otherCosts'] ?? 0) as num).toDouble() / 12;
            final double managementFee = ((newDefaults['managementFee'] ?? 0) as num).toDouble() * rent;


            final expenses = monthlyPayment + vacancy + propertyTax + insurance + maintenance + otherCosts + hoaFee + managementFee;
            final double netOperatingIncome = rent - expenses;

            final data = {
              'downPayment': downPayment,
              'hoaFee': hoaFee,
              'insurance': insurance,
              'interest': interest,
              'loanAmount': loanAmount,
              'maintenance': maintenance,
              'managementFee': managementFee,
              'monthlyInterest': monthlyInterest,
              'monthlyPayment': monthlyPayment,
              'months': months,
              'netOperatingIncome': netOperatingIncome,
              'otherCosts': otherCosts,
              'principal': principal,
              'propertyHoa': cashflowData['propertyHoa'] ?? 0,
              'purchasePrice': purchasePrice,
              'rent': rent,
              'tax': propertyTax,
              'vacancy': vacancy,
              'updatedAt': FieldValue.serverTimestamp(),
              'valuesUsed': newDefaults,
            };


            if (widget.isRealtor) {
              // Save to Firestore if realtor
              await FirebaseFirestore.instance
                  .collection('realtors')
                  .doc(realtorId)
                  .collection('cashflow_analysis')
                  .doc(widget.listingId)
                  .set(data);

              await _fetchData(); // refresh
            } else {
              print("We should not be here");
              // Save edits locally for investors
              previousValuesUsed = Map<String, dynamic>.from(cashflowData['valuesUsed'] ?? {});
              setState(() {
                personalData = data;
                if (_showPersonalEstimate) {
                  cashflowData = Map<String, dynamic>.from(personalData);
                }
                // ✅ persist new valuesUsed locally
                cashflowData['valuesUsed'] = {
                  ...used,
                  ...newDefaults,
                };
              });
            }
          }
      ),
    );



  }}
