import 'package:flutter/material.dart';

/// A placeholder page for viewing realtor reports.
/// Displays a simple centered message.
class RealtorReports extends StatelessWidget {
  const RealtorReports({Key? key}) : super(key: key);

  /// Builds the RealtorReports UI with a centered message.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "View Reports Here",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
