import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../user_provider.dart';

class RealtorDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const RealtorDashboard({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _RealtorDashboardState createState() => _RealtorDashboardState();
}

class _RealtorDashboardState extends State<RealtorDashboard> {

  /// Hardcoded real estate properties in College Station, TX
  final List<Map<String, dynamic>> recentProperties = [
    {
      "latitude": 30.6280,
      "longitude": -96.3344,
      "address": "1101 University Dr, College Station, TX",
      "price": 350000,
      "status": "For Sale",
      "lastUpdated": "2024-02-25",
    },
    {
      "latitude": 30.6090,
      "longitude": -96.3490,
      "address": "4500 Carter Creek Pkwy, College Station, TX",
      "price": 420000,
      "status": "Pending",
      "lastUpdated": "2024-02-24",
    },
  ];

  /// Hardcoded investor notifications
  final List<Map<String, dynamic>> notifications = [
    {
      "message": "Investor John Doe approved 1101 University Dr",
      "investorEmail": "john@example.com",
      "status": "approved",
      "timestamp": "2024-02-25",
    },
  ];

  @override
  void initState() {
    super.initState();
    Provider.of<UserProvider>(context, listen: false).fetchRealtorData();
  }

  Widget _buildModernCard(Widget child) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }

  Widget _buildPropertyCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Property Changes",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildModernCard(
          Column(
            children: recentProperties.map((property) {
              return ListTile(
                title: Text(property['address']),
                subtitle: Text("Price: \$${property['price']}"),
                trailing: Text(
                  property['status'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: property['status'] == "For Sale"
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Investor Notifications",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildModernCard(
          Column(
            children: notifications.map((notification) {
              return ListTile(
                leading: Icon(
                  notification['status'] == 'approved' ? Icons.check_circle : Icons.cancel,
                  color: notification['status'] == 'approved' ? Colors.green : Colors.red,
                ),
                title: Text(notification['message']),
                subtitle: Text(notification['investorEmail']),
                trailing: Text(notification['timestamp']),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Welcome, ${userProvider.firstName ?? 'Loading...'} ${userProvider.lastName}",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),


            const SizedBox(height: 20),
            _buildPropertyCards(),
            const SizedBox(height: 20),
            _buildNotifications(),
          ],
        ),
      ),
    );
  }
}

