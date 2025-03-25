import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaxAssessmentWidget extends StatefulWidget {
  final List<dynamic> taxHistory;

  const TaxAssessmentWidget({Key? key, required this.taxHistory}) : super(key: key);

  @override
  _TaxAssessmentWidgetState createState() => _TaxAssessmentWidgetState();
}

class _TaxAssessmentWidgetState extends State<TaxAssessmentWidget> {
  bool _isExpanded = false;
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
          expansionCallback: (int index, bool _) { // Ignore `isExpanded`
            setState(() {
              _isExpanded = !_isExpanded; // Toggle state manually
              print("Panel expanded: $_isExpanded");
            });
          },
          children: [
            ExpansionPanel(
              canTapOnHeader: true,
              headerBuilder: (BuildContext context, bool isExpanded) {
                return ListTile(
                  title: Text(
                    "Tax History",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              },
              body: _isExpanded ? _buildChart() : Container(),
              isExpanded: _isExpanded, // Use state directly
            ),
          ],
        ),
      ],
    );
  }

  /// ✅ **Refactored Chart Widget**
  Widget _buildChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            titlesData:
            FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 80, // Adjust spacing dynamically
                  getTitlesWidget: (value, meta) => getLeftTitleWidget(value, widget.taxHistory),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30, // Adjust spacing dynamically
                  getTitlesWidget: (value, meta) => getBottomTitleWidget(value, widget.taxHistory),
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide right
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide top
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((spot) {
                    final year = spot.x.toInt(); // Get Year
                    final price = NumberFormat("#,##0").format(spot.y); // Format Price

                    return LineTooltipItem(
                      "$year\nValue: \$$price",
                      //use theme color to match app
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  }).toList();
                },
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
                    colors: gradientColors
                        .map((color) => color.withValues(alpha: 0.3))
                        .toList(),
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

  /// ✅ **Fix: Ensure Tax Data is Not Null**
  List<FlSpot> _buildTaxSpots(List<dynamic> taxHistory) {
    if (taxHistory.isEmpty) return [];

    taxHistory.sort((a, b) => (a["year"] as int).compareTo(b["year"] as int));

    return taxHistory.map((e) {
      final year = (e["year"] as int).toDouble();
      final totalAssessment = (e["assessment"]?["total"] as num?)?.toDouble() ?? 0;
      return FlSpot(year, totalAssessment);
    }).toList();
  }

  Widget getLeftTitleWidget(double value, List<dynamic> taxHistory) {
    // Determine min and max price from tax history (or use defaults)
    final minValue = taxHistory.isNotEmpty
        ? taxHistory.map((e) => e["assessment"]["total"] as num).reduce((a, b) => a < b ? a : b)
        : 100000; // Default to $100K if no data

    final maxValue = taxHistory.isNotEmpty
        ? taxHistory.map((e) => e["assessment"]["total"] as num).reduce((a, b) => a > b ? a : b)
        : 1000000; // Default to $1M if no data

    final valueRange = maxValue - minValue;

    // Dynamically adjust interval based on the price range
    double interval;
    if (valueRange <= 200000) {
      interval = 25000;
    } else if (valueRange <= 500000) {
      interval = 50000;
    } else if (valueRange <= 1000000) {
      interval = 100000;
    } else {
      interval = 250000;
    }

    if (value % interval == 0) {
      return Text("\$${NumberFormat("#,##0").format(value)}");
    }

    return Container(); // Hide other titles
  }

  Widget getBottomTitleWidget(double value, List<dynamic> taxHistory) {
    // Determine min and max years from tax history (or use current year)
    final minYear = taxHistory.isNotEmpty
        ? taxHistory.first["year"] as int
        : DateTime.now().year;

    final maxYear = taxHistory.isNotEmpty
        ? taxHistory.last["year"] as int
        : DateTime.now().year;

    final yearRange = maxYear - minYear;

    // Dynamically adjust interval based on how old the house is
    double interval;
    if (yearRange <= 5) {
      interval = 1; // Show every year if house is very new
    } else if (yearRange <= 10) {
      interval = 2; // Show every 2 years for newer houses
    } else {
      interval = 5; // Default to every 5 years
    }

    if (value % interval == 0) {
      return Text(value.toInt().toString());
    }

    return Container(); // Hide other titles
  }


}
