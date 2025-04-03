import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PropertyCard extends StatefulWidget {
  final Map<String, dynamic> property;
  final VoidCallback onTap;
  final Color? color;

  const PropertyCard({
    Key? key,
    required this.property,
    required this.onTap,
    this.color,
  }) : super(key: key);

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  double? _cashFlow;

  @override
  void initState() {
    super.initState();
    _fetchCashFlow();
  }

  Future<void> _fetchCashFlow() async {
    final doc = await FirebaseFirestore.instance
        .collection('cashflow_analysis')
        .doc(widget.property["id"])
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final expenses = data['monthlyExpenseBreakdown'] ?? {};

      final double estimatedRent =
          (data['price'] ?? 0).toDouble() * 0.0086;

      final double totalExpenses = [
        expenses['loanInterest'],
        expenses['loanPrinciple'],
        expenses['propertyTax'],
        expenses['insurance'],
        expenses['hoaFee'],
        expenses['maintenance'],
        expenses['managementFee'],
        expenses['otherCosts'],
      ]
          .map((v) => (v ?? 0).toDouble())
          .reduce((a, b) => a + b);

      final double cashFlow = estimatedRent - totalExpenses;

      if (!mounted) return;
      setState(() {
        _cashFlow = cashFlow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "en_US");
    final theme = Theme.of(context);

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: widget.color ?? theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      widget.property["image"] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.colorScheme.surface,
                        child: Icon(Icons.image_not_supported,
                            size: 40, color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                ),

                // Info
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.property["address"] ?? 'Unknown Address',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$${currencyFormat.format(widget.property["price"])}",
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.king_bed_outlined, size: 14),
                          const SizedBox(width: 2),
                          Text("${widget.property["beds"]}",
                              style: theme.textTheme.bodySmall),
                          const SizedBox(width: 8),
                          const Icon(Icons.bathtub_outlined, size: 14),
                          const SizedBox(width: 2),
                          Text("${widget.property["baths"]}",
                              style: theme.textTheme.bodySmall),
                          const SizedBox(width: 8),
                          const Icon(Icons.square_foot, size: 14),
                          const SizedBox(width: 2),
                          Text(
                              "${currencyFormat.format(widget.property["sqft"])} sqft",
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 🔥 Cash Flow Badge
            if (_cashFlow != null)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                    border:
                    Border.all(
                      color: _cashFlow! >= 0
                          ? Colors.green.withOpacity(0.5)
                          : Colors.red.withOpacity(0.5),
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
              ),
          ],
        ),
      ),
    );
  }
}
