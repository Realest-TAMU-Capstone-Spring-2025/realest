import 'package:flutter/material.dart';

/// A simple expandable panel to show property description.
class PropertyDescriptionWidget extends StatefulWidget {
  final String description;

  const PropertyDescriptionWidget({Key? key, required this.description}) : super(key: key);

  @override
  _PropertyDescriptionWidgetState createState() => _PropertyDescriptionWidgetState();
}

class _PropertyDescriptionWidgetState extends State<PropertyDescriptionWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpansionPanelList(
          elevation: 1,
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
                  title: Text(
                    "Property Description",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              },
              body: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  widget.description.isNotEmpty
                      ? widget.description
                      : "No description available for this property.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              isExpanded: _isExpanded,
            ),
          ],
        ),
      ],
    );
  }
}
