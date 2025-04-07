import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realest/user_provider.dart';

class CashFlowBadge extends StatefulWidget {
  final String propertyId;

  const CashFlowBadge({
    super.key,
    required this.propertyId,
  });

  @override
  State<CashFlowBadge> createState() => _CashFlowBadgeState();
}

class _CashFlowBadgeState extends State<CashFlowBadge> {
  double? _netOperatingIncome;

  @override
  void initState() {
    super.initState();
    _loadNOI();
  }

  @override
  void didUpdateWidget(covariant CashFlowBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.propertyId != oldWidget.propertyId) {
      _loadNOI(); // reload if the propertyId changes
    }
  }

  Future<void> _loadNOI() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userRole = Provider.of<UserProvider>(context, listen: false).userRole;
    String? targetRealtorId;

    if (userRole == "realtor") {
      targetRealtorId = currentUser.uid;
    } else {
      final investorDoc = await FirebaseFirestore.instance
          .collection('investors')
          .doc(currentUser.uid)
          .get();
      if (investorDoc.exists) {
        targetRealtorId = investorDoc.data()?['realtorId'];
      }
    }

    if (targetRealtorId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('realtors')
        .doc(targetRealtorId)
        .collection('cashflow_analysis')
        .doc(widget.propertyId)
        .get();

    if (!doc.exists || !mounted) return;

    final data = doc.data()!;
    final noi = (data['netOperatingIncome'] ?? 0).toDouble();

    setState(() {
      _netOperatingIncome = noi;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_netOperatingIncome == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _netOperatingIncome! >= 0 ? Colors.green : Colors.red,
          width: 4,
        ),
      ),
      child: Text(
        "${_netOperatingIncome! >= 0 ? '+ ' : '- '}\$${_netOperatingIncome!.abs().toStringAsFixed(0)}",
        style: TextStyle(
          color: _netOperatingIncome! >= 0 ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
