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
    Provider.of<UserProvider>(context, listen: false).fetchUserData();
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
            Text(
              "Welcome, ${userProvider.firstName ?? 'Loading...'} ${userProvider.lastName}",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),

            // First Row: 4 equal columns
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildModernCard(
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Total Listings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text("24", style: TextStyle(fontSize: 24)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModernCard(
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Pending Sales", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text("5", style: TextStyle(fontSize: 24)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModernCard(
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Active Clients", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text("12", style: TextStyle(fontSize: 24)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildModernCard(
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Revenue", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text("\$1.2M", style: TextStyle(fontSize: 24)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Second Row: 2 columns with flexible heights
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildModernCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Recent Properties",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: recentProperties.length,
                              itemBuilder: (context, index) {
                                final property = recentProperties[index];
                                return ListTile(
                                  title: Text(property['address']),
                                  subtitle: Text("Price: \$${property['price']}"),
                                  trailing: Text(
                                    property['status'],
                                    style: TextStyle(
                                      color: property['status'] == "For Sale"
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: _buildModernCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Notifications",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Flexible(
                            child: ListView.builder(
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                final notification = notifications[index];
                                return ListTile(
                                  leading: Icon(
                                    notification['status'] == 'approved'
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: notification['status'] == 'approved'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  title: Text(notification['message']),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}