import 'dart:math';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'cashflow_edit_dialog.dart';

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


  @override
  void initState() {
    super.initState();
    _fetchData(); // realtorId will be resolved inside this method
  }


  Future<void> _fetchData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (widget.isRealtor) {
      // Realtor accesses their own document
      realtorId = userId;
    } else {
      // Investor – get their document to find assigned realtor
      final investorDoc = await FirebaseFirestore.instance
          .collection('investors')
          .doc(userId)
          .get();

      final investorData = investorDoc.data();
      realtorId = investorData?['realtorId'];

      if (realtorId == null) {
        debugPrint('❌ Could not find assigned realtor for investor $userId');
        return;
      }
    }

    // Now fetch the correct cashflow_analysis doc
    final doc = await FirebaseFirestore.instance
        .collection('realtors')
        .doc(realtorId)
        .collection('cashflow_analysis')
        .doc(widget.listingId)
        .get();

    if (doc.exists) {
      setState(() {
        cashflowData = doc.data()!;
        _isLoading = false;
      });
    } else {
      debugPrint('❌ Cash flow document not found for listing ${widget.listingId}');
    }
  }

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

    final breakdown = {
      'Principal': cashflowData['principal'] ?? 0,
      'Interest': cashflowData['interest'] ?? 0,
      'Property Tax': cashflowData['tax'] ?? 0,
      'Insurance': cashflowData['insurance'] ?? 0,
      'Maintenance': cashflowData['maintenance'] ?? 0,
      'HOA Fee': cashflowData['hoaFee'] ?? 0,
      'Vacancy Loss': cashflowData['vacancy'] ?? 0,
      'Management Fee': 0.0, // optional
      'Other Costs': cashflowData['otherCosts'] ?? 0,
    };


    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isPositive ? Colors.green : Colors.red, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              // Adjust as needed
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _valueCard(
                      "Income", cashflowData['rent']!, Colors.green, currency),
                  _valueCard("Expenses",
                      cashflowData['rent'] - cashflowData['netOperatingIncome'],
                      Colors.red, currency),
                  _valueCard("Cash Flow", cashflowData['netOperatingIncome']!,
                      isPositive ? Colors.green : Colors.red, currency),
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

// Pie chart
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


        ],
      ),
    );
  }

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
      'defaultHOA': usedValues['hoaFee'] ?? 0.0,
      'otherCosts': usedValues['otherCosts'] ?? 0.0,
      'customIncome': (cashflowData['rent'] ?? 0).toDouble(),
    };

    showDialog(
      context: context,
      builder: (context) => CashFlowEditDialog(
        initialDefaults: initialDefaults,
        purchasePrice: (cashflowData['purchasePrice'] ?? 0).toDouble(),
        grossMonthlyRent: (cashflowData['rent'] ?? 0).toDouble(),
        listingId: widget.listingId,
        realtorId: realtorId!,
          onSave: (newDefaults) async {
            setState(() {
              cashFlowDefaults = newDefaults;
            });

            final double purchasePrice = cashflowData['purchasePrice'];
            final rent = (newDefaults['customIncome'] ?? 0).toDouble();
            final double downPayment = newDefaults['downPayment'] * purchasePrice;
            final double loanAmount = purchasePrice - downPayment;
            final double interestRate = newDefaults['interestRate'];
            final int loanTerm = newDefaults['loanTerm'];
            final double monthlyInterest = interestRate / 12;
            final int months = loanTerm * 12;

            final double principal = loanAmount / months;
            final double monthlyPayment = loanAmount * monthlyInterest / (1 - (1 / pow(1 + monthlyInterest, months)));
            final double interest = monthlyPayment - principal;

            final double hoaFee = newDefaults['hoaFee'];
            final double propertyTax = newDefaults['propertyTax'] * purchasePrice / 12;
            final double vacancy = newDefaults['vacancyRate'] * rent;
            final double insurance = newDefaults['insurance'] * purchasePrice / 12;
            final double maintenance = newDefaults['maintenance'] * purchasePrice / 12;
            final double otherCosts = newDefaults['otherCosts'] / 12;
            final double managementFee = newDefaults['managementFee'] * rent;

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
              // Only save to Firestore if they’re a realtor
              print ("Saving data to Firestore: $data");
              await FirebaseFirestore.instance
                  .collection('realtors')
                  .doc(realtorId)
                  .collection('cashflow_analysis')
                  .doc(widget.listingId)
                  .set(data);
            } else {
              // Just update locally for preview
              print("Updating local state only: $data");
              setState(() {
                cashflowData = data;
              });
            }

            await _fetchData();
          }
      ),
    );
  }}
