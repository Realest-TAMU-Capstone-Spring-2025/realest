import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RealtorDashboard extends StatefulWidget {
  const RealtorDashboard({Key? key}) : super(key: key);

  @override
  _RealtorDashboardState createState() => _RealtorDashboardState();
}

class _RealtorDashboardState extends State<RealtorDashboard> {
  final MapController _mapController = MapController();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _moveMapToFirstProperty();
    });
  }

  void _moveMapToFirstProperty() {
    if (recentProperties.isNotEmpty) {
      _mapController.move(
        LatLng(recentProperties[0]['latitude'], recentProperties[0]['longitude']),
        13.0,
      );
    }
  }

  /// Builds the map with property markers
  Widget _buildMap() {
    return SizedBox(
      height: 300,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(30.6280, -96.3344),
          initialZoom: 12,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: recentProperties.map((property) {
              return Marker(
                point: LatLng(property['latitude'], property['longitude']),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 30,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Realtor Dashboard", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            _buildMap(),
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
