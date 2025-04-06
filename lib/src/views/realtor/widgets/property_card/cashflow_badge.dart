import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CashFlowBadge extends StatefulWidget {
  final String propertyId;
  final num price;

  const CashFlowBadge({
    super.key,
    required this.propertyId,
    required this.price,
  });

  @override
  State<CashFlowBadge> createState() => _CashFlowBadgeState();
}

class _CashFlowBadgeState extends State<CashFlowBadge> {
  double? _cashFlow;

  @override
  void initState() {
    super.initState();
    _loadCashFlow();
  }

  Future<void> _loadCashFlow() async {
    final doc = await FirebaseFirestore.instance
        .collection('cashflow_analysis')
        .doc(widget.propertyId)
        .get();

    if (!doc.exists || !mounted) return;

    final data = doc.data()!;
    final expenses = data['monthlyExpenseBreakdown'] ?? {};

    final estimatedRent = (widget.price).toDouble() * 0.0086;

    final totalExpenses = [
      expenses['loanInterest'],
      expenses['loanPrinciple'],
      expenses['propertyTax'],
      expenses['insurance'],
      expenses['hoaFee'],
      expenses['maintenance'],
      expenses['managementFee'],
      expenses['otherCosts'],
    ].map((v) => (v ?? 0).toDouble()).reduce((a, b) => a + b);

    final cashFlow = estimatedRent - totalExpenses;

    setState(() {
      _cashFlow = cashFlow;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cashFlow == null) return const SizedBox();

    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade900.withOpacity(0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _cashFlow! >= 0
                ? Colors.green
                : Colors.red,
            width: 4,
          ),
        ),
        child: Text(
          "${_cashFlow! >= 0 ? '+ ' : '- '}\$${_cashFlow!.abs().toStringAsFixed(0)}",
          style: TextStyle(
            color: _cashFlow! >= 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
