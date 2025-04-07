import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class CashFlowEditDialog extends StatefulWidget {
  final Map<String, dynamic> initialDefaults;
  final double purchasePrice;
  final double grossMonthlyRent;
  final String listingId;
  final String realtorId;
  final void Function(Map<String, dynamic>) onSave;

  const CashFlowEditDialog({
    super.key,
    required this.initialDefaults,
    required this.purchasePrice,
    required this.grossMonthlyRent,
    required this.listingId,
    required this.realtorId,
    required this.onSave,
  });

  @override
  State<CashFlowEditDialog> createState() => _CashFlowEditDialogState();
}

class _CashFlowEditDialogState extends State<CashFlowEditDialog> {
  final Map<String, TextEditingController> controllers = {};
  Map<String, double> estimate = {};

  final fieldGroups = {
    'Loan & Purchase': ['downPayment', 'interestRate', 'loanTerm'],
    'Taxes & Insurance': ['propertyTax', 'insurance'],
    'Operating Expenses': ['maintenance', 'managementFee', 'vacancyRate', 'hoaFee', 'otherCosts'],
    'Income': ['customIncome'],
  };

  final percentFields = [
    'downPayment', 'interestRate', 'propertyTax', 'insurance', 'maintenance', 'managementFee', 'vacancyRate'
  ];

  @override
  void initState() {
    super.initState();
    final allFields = fieldGroups.values.expand((list) => list);
    for (final field in allFields) {
      final rawValue = widget.initialDefaults[field]?.toDouble() ?? 0;
      final isPercent = percentFields.contains(field);
      controllers[field] = TextEditingController(
        text: isPercent ? (rawValue * 100).toStringAsFixed(2) : rawValue.toString(),
      );
    }
    controllers['customIncome']?.text = widget.grossMonthlyRent.toString();
  }


  String _labelForField(String field) {
    final labels = {
      'downPayment': 'Down Payment (%)',
      'interestRate': 'Interest Rate (%)',
      'loanTerm': 'Loan Term (Years)',
      'propertyTax': 'Property Tax (%)',
      'insurance': 'Insurance (%)',
      'maintenance': 'Maintenance (%)',
      'managementFee': 'Management Fee (%)',
      'vacancyRate': 'Vacancy Rate (%)',
      'hoaFee': 'Monthly HOA Fee',
      'otherCosts': 'Other Monthly Costs',
      'customIncome': 'Monthly Rent',
    };
    return labels[field] ?? field;
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '\$');

    return Dialog(
      backgroundColor: theme.dialogBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: SizedBox(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Edit Cash Flow Inputs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final entry in fieldGroups.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Text(entry.key, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: entry.value.map((field) => SizedBox(
                            width: MediaQuery.of(context).size.width * 0.35,
                            child: TextField(
                              controller: controllers[field],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: _labelForField(field),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Changes"),
                onPressed: () {
                  final updated = {
                    for (var key in controllers.keys)
                      key: percentFields.contains(key)
                          ? (double.tryParse(controllers[key]!.text) ?? 0) / 100
                          : double.tryParse(controllers[key]!.text) ?? 0
                  };
                  widget.onSave(updated);
                  Navigator.of(context).pop();
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

extension on double {
  double pow(num exponent) => math.pow(this, exponent).toDouble();
}