import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A panel widget that shows agent, office, and broker information.
/// Expands/collapses on tap to show contact details, MLS IDs, and emails.
class AgentInfoPanel extends StatefulWidget {
  final Map<String, dynamic> property; // Property map containing agent info

  const AgentInfoPanel({super.key, required this.property});

  @override
  State<AgentInfoPanel> createState() => _AgentInfoPanelState();
}

class _AgentInfoPanelState extends State<AgentInfoPanel> {
  bool _isExpanded = false; // Expansion state for the panel

  @override
  Widget build(BuildContext context) {
    // Extract agent, office, and broker information
    final agent = widget.property;
    final agentName = agent["agent_name"] ?? "N/A";
    final agentEmail = agent["agent_email"];
    final agentPhones = List<Map<String, dynamic>>.from(agent["agent_phones"] ?? []);
    final agentMLS = agent["agent_mls_set"] ?? "-";
    final agentNRDS = agent["agent_nrds_id"] ?? "-";

    final officeName = agent["office_name"] ?? "-";
    final officeEmail = agent["office_email"];
    final officePhones = List<Map<String, dynamic>>.from(agent["office_phones"] ?? []);
    final officeMLS = agent["office_mls_set"] ?? "-";
    final officeId = agent["office_id"] ?? "-";

    final brokerName = agent["broker_name"] ?? "-";

    return ExpansionPanelList(
      expansionCallback: (_, __) => setState(() => _isExpanded = !_isExpanded),
      elevation: 1,
      children: [
        ExpansionPanel(
          canTapOnHeader: true,
          isExpanded: _isExpanded,
          headerBuilder: (_, __) => const ListTile(
            title: Text("Agent & Office Information"),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("Agent"),
                _infoTile("Name", agentName),
                if (agentEmail != null) _linkTile("Email", agentEmail, "mailto:$agentEmail"),
                _infoTile("MLS ID", agentMLS),
                _infoTile("NRDS ID", agentNRDS),
                ..._phoneList(agentPhones), // Add agent phone numbers

                const SizedBox(height: 16),
                _sectionTitle("Office"),
                _infoTile("Name", officeName),
                if (officeEmail != null) _linkTile("Email", officeEmail, "mailto:$officeEmail"),
                _infoTile("MLS ID", officeMLS),
                _infoTile("Office ID", officeId),
                ..._phoneList(officePhones), // Add office phone numbers

                const SizedBox(height: 16),
                _sectionTitle("Broker"),
                _infoTile("Name", brokerName),
              ],
            ),
          ),
        )
      ],
    );
  }

  /// Helper to render section titles ("Agent", "Office", "Broker")
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  /// Helper to render a label-value pair without links
  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text("$label:", style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  /// Helper to render a clickable email or phone number
  Widget _linkTile(String label, String value, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text("$label:", style: const TextStyle(color: Colors.grey))),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri); // Launch email or phone app
                }
              },
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper to generate a list of phone number tiles
  List<Widget> _phoneList(List<Map<String, dynamic>> phones) {
    return phones.map((p) {
      final number = p["number"];
      final type = p["type"] ?? "Phone";
      return number != null
          ? _linkTile(type, number, "tel:$number")
          : const SizedBox.shrink();
    }).toList();
  }
}
