import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CashFlowAnalysisWidget extends StatefulWidget {
  const CashFlowAnalysisWidget({Key? key}) : super(key: key);

  @override
  _CashFlowAnalysisWidgetState createState() => _CashFlowAnalysisWidgetState();
}

class _CashFlowAnalysisWidgetState extends State<CashFlowAnalysisWidget> {
  bool _isExpanded = false;

  // Hardcoded Data (Replace with real calculations later)
  final double estimatedRent = 2500; // Income
  final double propertyTax = 300;
  final double insurance = 150;
  final double maintenance = 200;
  final double vacancyRate = 100;
  final double managementFee = 200;
  final double mortgage = 1300;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: "\$");

    double totalExpenses =
        propertyTax + insurance + maintenance + vacancyRate + managementFee + mortgage;
    double cashFlow = estimatedRent - totalExpenses;

    return Container(
      width: double.infinity, // Take full width
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔥 **Modern Title with Icon**
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 8),
              Text(
                "Cash Flow Analysis",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 24),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // **📌 Income - Expenses = Cash Flow Display (Boxes)**
          _buildEquationDisplay(currencyFormat, totalExpenses, cashFlow, theme),

          // 📌 **Expand Breakdown Button**
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

          // 📌 **Expanded Breakdown Section**
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

  /// **🔥 Displays [Income - Expenses = Cash Flow] as stylish full-width floating boxes**
  Widget _buildEquationDisplay(NumberFormat currencyFormat, double totalExpenses, double cashFlow, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildValueBox("Income", estimatedRent, theme, Colors.green)),
        _buildOperator("-", theme),
        Expanded(child: _buildValueBox("Expenses", totalExpenses, theme, Colors.red)),
        _buildOperator("=", theme),
        Expanded(child: _buildValueBox("Cash Flow", cashFlow, theme, cashFlow >= 0 ? Colors.green : Colors.red)),
      ],
    );
  }

  /// **🔥 Creates a floating value box for Income, Expenses, Cash Flow**
  Widget _buildValueBox(String label, double amount, ThemeData theme, Color color) {
    final currencyFormat = NumberFormat.currency(symbol: "\$");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration:
                  BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
            child: Text(

                currencyFormat.format(amount),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 22,
                ),
            )
          )
        ],
      ),
    );
  }

  /// **🔥 Creates the - and = symbols between boxes**
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

  /// **📌 Breakdown of all expenses**
  Widget _buildExpenseBreakdown(ThemeData theme) {
    return Column(
      children: [
        _buildExpenseItem("🏡 Mortgage", mortgage, theme),
        _buildExpenseItem("🏦 Property Tax", propertyTax, theme),
        _buildExpenseItem("🔐 Insurance", insurance, theme),
        _buildExpenseItem("🔧 Maintenance", maintenance, theme),
        _buildExpenseItem("📉 Vacancy Reserve", vacancyRate, theme),
        _buildExpenseItem("👨‍💼 Management Fee", managementFee, theme),
      ],
    );
  }

  /// **📌 Expense Item Row**
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
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
