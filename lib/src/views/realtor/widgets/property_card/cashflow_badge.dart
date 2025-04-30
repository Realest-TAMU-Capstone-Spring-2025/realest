import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realest/user_provider.dart';

/// Widget that displays baseline (BE) and personalized (PE) cash flow estimates (NOI)
/// for a property based on realtor settings and investor assumptions.
class CashFlowBadge extends StatefulWidget {
  final String propertyId; // ID of the property to fetch data for

  const CashFlowBadge({
    super.key,
    required this.propertyId,
  });

  @override
  State<CashFlowBadge> createState() => _CashFlowBadgeState();
}

class _CashFlowBadgeState extends State<CashFlowBadge> {
  double? _realtorNOI;   // Baseline NOI from realtor
  double? _investorNOI;  // Personalized NOI based on investor assumptions
  late String userRole;  // Role of the current user: realtor or investor

  @override
  void initState() {
    super.initState();
    _loadNOI(); // Load NOI values on widget initialization
  }

  @override
  void didUpdateWidget(covariant CashFlowBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.propertyId != oldWidget.propertyId) {
      _loadNOI(); // Reload if propertyId changes
    }
  }

  /// Fetches baseline and personalized NOI values from Firestore
  Future<void> _loadNOI() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    userRole = Provider.of<UserProvider>(context, listen: false).userRole!;
    String? targetRealtorId;

    // Determine target realtor (for investor, get their assigned realtor)
    if (userRole == "realtor") {
      targetRealtorId = currentUser.uid;
    } else {
      final investorDoc = await FirebaseFirestore.instance
          .collection('investors')
          .doc(currentUser.uid)
          .get();
      if (!investorDoc.exists) return;
      targetRealtorId = investorDoc.data()?['realtorId'];
    }

    if (targetRealtorId == null) return;

    // Fetch cash flow analysis document
    final doc = await FirebaseFirestore.instance
        .collection('realtors')
        .doc(targetRealtorId)
        .collection('cashflow_analysis')
        .doc(widget.propertyId)
        .get();

    if (!doc.exists || !mounted) return;

    final data = doc.data()!;
    final storedNOI = (data['netOperatingIncome'] ?? 0).toDouble();

    double? personalizedNOI;

    // Calculate personalized NOI for investors
    if (userRole == "investor") {
      final investorDoc = await FirebaseFirestore.instance
          .collection('investors')
          .doc(currentUser.uid)
          .get();
      final investorDefaults = investorDoc.data()?['cashFlowDefaults'] ?? {};

      final purchasePrice = (data['purchasePrice'] ?? 0).toDouble();
      final rent = (data['rent'] ?? 0).toDouble();
      final downPayment = (investorDefaults['downPayment'] ?? 0.2) * purchasePrice;
      final loanAmount = purchasePrice - downPayment;
      final interestRate = investorDefaults['interestRate'] ?? 0.06;
      final loanTerm = investorDefaults['loanTerm'] ?? 30;
      final monthlyInterest = interestRate / 12;
      final months = loanTerm * 12;
      final monthlyPayment = loanAmount * monthlyInterest / (1 - (1 / pow(1 + monthlyInterest, months)));

      final hoaFee = (data['hoaFee'] ?? 0).toDouble();
      final tax = (data['tax'] ?? 0).toDouble();
      final insurance = (data['insurance'] ?? 0).toDouble();
      final maintenance = (data['maintenance'] ?? 0).toDouble();
      final otherCosts = (data['otherCosts'] ?? 0).toDouble();
      final vacancy = (data['vacancy'] ?? 0).toDouble();
      final managementFee = (data['managementFee'] ?? 0).toDouble();

      final expenses = monthlyPayment + tax + insurance + maintenance + otherCosts + hoaFee + vacancy + managementFee;
      personalizedNOI = rent - expenses;
    }

    if (!mounted) return;

    // Update state with NOI values
    setState(() {
      _realtorNOI = storedNOI;
      _investorNOI = personalizedNOI;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_realtorNOI == null) return const SizedBox(); // Don't render if not ready

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _realtorNOI! >= 0 ? Colors.green : Colors.red,
          width: 4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baseline Estimate (BE)
          Tooltip(
            message: 'Baseline Estimate — based on default assumptions set by your realtor.',
            child: Text(
              "BE: ${_realtorNOI! >= 0 ? '+ ' : '- '}\$${_realtorNOI!.abs().toStringAsFixed(0)}",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _realtorNOI! >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ),
          if (_investorNOI != null)
          // Personalized Estimate (PE)
            Tooltip(
              message: 'Personalized Estimate — adjusted based on your loan assumptions.',
              child: Text(
                "PE: ${_investorNOI! >= 0 ? '+ ' : '- '}\$${_investorNOI!.abs().toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _investorNOI! >= 0 ? Colors.green.shade300 : Colors.red.shade300,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
