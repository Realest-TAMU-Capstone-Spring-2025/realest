import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CashFlowAnalysisWidget extends StatefulWidget {
  final String listingId;

  const CashFlowAnalysisWidget({Key? key, required this.listingId}) : super(key: key);

  @override
  _CashFlowAnalysisWidgetState createState() => _CashFlowAnalysisWidgetState();
}

class _CashFlowAnalysisWidgetState extends State<CashFlowAnalysisWidget> {
  bool _isExpanded = false;
  bool _isLoading = true;

  double? estimatedRent;
  double? propertyTax;
  double? insurance;
  double? maintenance;
  double? vacancyReserve;
  double? managementFee;
  double? hoaFee;
  double? loanInterest;
  double? loanPrincipal;
  double? otherCosts;


  @override
  void initState() {
    super.initState();
    _fetchCashFlowData();
  }

  Future<void> _fetchCashFlowData() async {
    final doc = await FirebaseFirestore.instance
        .collection('cashflow_analysis')
        .doc(widget.listingId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final expenses = data['monthlyExpenseBreakdown'] ?? {};

      setState(() {
        estimatedRent = (data['price'] ?? 0).toDouble() * 0.0086;
        final grossRent = (data['grossMonthlyRent'] ?? 0).toDouble();
        vacancyReserve = grossRent - estimatedRent!;

        hoaFee = (expenses['hoaFee'] ?? 0).toDouble();
        insurance = (expenses['insurance'] ?? 0).toDouble();
        loanInterest = (expenses['loanInterest'] ?? 0).toDouble();
        loanPrincipal = (expenses['loanPrinciple'] ?? 0).toDouble();
        maintenance = (expenses['maintenance'] ?? 0).toDouble();
        managementFee = (expenses['managementFee'] ?? 0).toDouble();
        otherCosts = (expenses['otherCosts'] ?? 0).toDouble();
        propertyTax = (expenses['propertyTax'] ?? 0).toDouble();
        _isLoading = false;
      });

    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: "\$");

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if ([loanInterest, loanPrincipal, propertyTax, insurance, maintenance, vacancyReserve, managementFee].any((v) => v == null)) {
      return const Text("Unable to load cash flow data.");
    }

    final totalExpenses = loanInterest! + loanPrincipal! + propertyTax! + insurance! + hoaFee! + maintenance! + managementFee! + otherCosts!;
    final cashFlow = estimatedRent! - totalExpenses;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔥 Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 8),
              Text(
                "Cash Flow Analysis",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 📊 Income - Expenses = Cash Flow
          _buildEquationDisplay(currencyFormat, totalExpenses, cashFlow, theme),

          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isExpanded ? "Hide Breakdown" : "View Breakdown",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ],
            ),
          ),

          if (_isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.only(top: 16),
              child: _buildExpenseBreakdown(theme),
            ),
        ],
      ),
    );
  }
  Widget _buildEquationDisplay(NumberFormat currencyFormat, double totalExpenses, double cashFlow, ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 400;

    return Wrap(
      spacing: isMobile ? 0 : 12,
      runSpacing: isMobile ? 6: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.center,
      children: [
        _buildValueBox("Income", estimatedRent!, theme, Colors.green),
        _buildOperator("-", theme),
        _buildValueBox("Expenses", totalExpenses, theme, Colors.red),
        _buildOperator("=", theme),
        _buildValueBox("Cash Flow", cashFlow, theme, cashFlow >= 0 ? Colors.green : Colors.red),
      ],
    );
  }


  Widget _buildValueBox(String label, double amount, ThemeData theme, Color color) {
    final currencyFormat = NumberFormat.currency(symbol: "\$");
    final isMobile = MediaQuery.of(context).size.width < 400;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: isMobile ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(isMobile ? 12 : 20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.black,
              fontSize: isMobile ? 14 : 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 6 : 10,
              vertical: isMobile ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              currencyFormat.format(amount),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: isMobile ? 16 : 22,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOperator(String symbol, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        symbol,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 26,
          color: theme.colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildExpenseBreakdown(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIncomeItem( "Estimated Rent", estimatedRent ?? 0, theme),
        _buildExpenseItem("Loan Interest", loanInterest ?? 0, theme),
        _buildExpenseItem("Loan Principal", loanPrincipal ?? 0, theme),
        _buildExpenseItem("Property Tax", propertyTax ?? 0, theme),
        _buildExpenseItem("Insurance", insurance ?? 0, theme),
        _buildExpenseItem("HOA Fee", hoaFee ?? 0, theme),
        _buildExpenseItem("Maintenance", maintenance ?? 0, theme),
        _buildExpenseItem("Management Fee", managementFee ?? 0, theme),
        _buildExpenseItem("Other Costs", otherCosts ?? 0, theme),
      ],
    );
  }
  Widget _buildExpenseItem(String label, double amount, ThemeData theme) {
    final currencyFormat = NumberFormat.currency(symbol: "\$");
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            currencyFormat.format(amount),
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  Widget _buildIncomeItem(String label, double amount, ThemeData theme) {
    final currencyFormat = NumberFormat.currency(symbol: "\$");
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            currencyFormat.format(amount),
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
