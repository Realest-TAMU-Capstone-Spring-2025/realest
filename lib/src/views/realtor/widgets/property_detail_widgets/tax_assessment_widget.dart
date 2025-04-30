import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A widget that displays the property's tax assessment history
/// using a line chart inside an expandable panel.
class TaxAssessmentWidget extends StatefulWidget {
  final List<dynamic> taxHistory;

  const TaxAssessmentWidget({Key? key, required this.taxHistory}) : super(key: key);

  @override
  _TaxAssessmentWidgetState createState() => _TaxAssessmentWidgetState();
}

class _TaxAssessmentWidgetState extends State<TaxAssessmentWidget> {
  bool _isExpanded = false;

  // Gradient colors used for line and area under the curve
  List<Color> gradientColors = [
    Colors.cyan,
    Colors.blue,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpansionPanelList(
          elevation: 1,
          expansionCallback: (_, __) {
            setState(() {
              _isExpanded = !_isExpanded; // Toggle visibility
            });
          },
          children: [
            ExpansionPanel(
              canTapOnHeader: true,
              headerBuilder: (context, _) => ListTile(
                title: Text("Tax History", style: Theme.of(context).textTheme.titleMedium),
              ),
              body: _isExpanded ? _buildChart() : Container(),
              isExpanded: _isExpanded,
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the line chart showing tax assessment data
  Widget _buildChart() {
    if (widget.taxHistory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "No tax history available.",
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            // Define axis label styles and title generation
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 80,
                  getTitlesWidget: (value, _) => getLeftTitleWidget(value, widget.taxHistory),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, _) => getBottomTitleWidget(value, widget.taxHistory),
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (spots) => spots.map((spot) {
                  final year = spot.x.toInt();
                  final value = NumberFormat("#,##0").format(spot.y);
                  return LineTooltipItem(
                    "$year\nValue: \$$value",
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: _buildTaxSpots(widget.taxHistory),
                isCurved: true,
                barWidth: 5,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: gradientColors.map((c) => c.withOpacity(0.3)).toList(),
                  ),
                ),
                dotData: FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Converts tax history into FlSpot data points
  List<FlSpot> _buildTaxSpots(List<dynamic> taxHistory) {
    if (taxHistory.isEmpty) return [];

    // Sort data chronologically by year
    taxHistory.sort((a, b) => (a["year"] as int).compareTo(b["year"] as int));

    return taxHistory.map((entry) {
      final year = (entry["year"] as int).toDouble();
      final value = (entry["assessment"]?["total"] as num?)?.toDouble() ?? 0;
      return FlSpot(year, value);
    }).toList();
  }

  /// Generates left Y-axis labels for property value
  Widget getLeftTitleWidget(double value, List<dynamic> taxHistory) {
    // Determine range of values to decide label interval
    final values = taxHistory
        .map((e) => (e["assessment"]?["total"] ?? 0) as num)
        .toList();

    final min = values.isNotEmpty ? values.reduce((a, b) => a < b ? a : b) : 100000;
    final max = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 1000000;
    final range = max - min;

    double interval;
    if (range <= 200000) {
      interval = 25000;
    } else if (range <= 500000) {
      interval = 50000;
    } else if (range <= 1000000) {
      interval = 100000;
    } else {
      interval = 250000;
    }

    return value % interval == 0
        ? Text("\$${NumberFormat("#,##0").format(value)}")
        : Container();
  }

  /// Generates bottom X-axis labels (years)
  Widget getBottomTitleWidget(double value, List<dynamic> taxHistory) {
    final years = taxHistory.map((e) => e["year"] as int).toList();
    final minYear = years.isNotEmpty ? years.first : DateTime.now().year;
    final maxYear = years.isNotEmpty ? years.last : DateTime.now().year;
    final yearRange = maxYear - minYear;

    double interval = yearRange <= 5 ? 1 : yearRange <= 10 ? 2 : 5;

    return value % interval == 0 ? Text(value.toInt().toString()) : Container();
  }
}
