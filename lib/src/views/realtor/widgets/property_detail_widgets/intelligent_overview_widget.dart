import 'package:flutter/material.dart';
import 'dart:ui';

/// A futuristic glassmorphic panel displaying AI-generated property overview.
class IntelligentOverviewWidget extends StatefulWidget {
  final String overview;

  const IntelligentOverviewWidget({Key? key, required this.overview}) : super(key: key);

  @override
  _IntelligentOverviewWidgetState createState() => _IntelligentOverviewWidgetState();
}

class _IntelligentOverviewWidgetState extends State<IntelligentOverviewWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glass-like effect
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: ExpansionPanelList(
            elevation: 0, // Flat futuristic design
            expandedHeaderPadding: EdgeInsets.zero,
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            children: [
              ExpansionPanel(
                canTapOnHeader: true,
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return ListTile(
                    leading: const Icon(Icons.insights, color: Colors.cyanAccent), // Futuristic icon
                    title: const Text(
                      "AI-Generated Overview",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  );
                },
                body: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    widget.overview.isNotEmpty
                        ? widget.overview
                        : "No AI-generated insights available yet.",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                isExpanded: _isExpanded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
