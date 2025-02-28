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

  /// Hardcoded real estate properties in **College Station, TX**
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
    {
      "latitude": 30.6215,
      "longitude": -96.3418,
      "address": "700 Holleman Dr, College Station, TX",
      "price": 295000,
      "status": "Sold",
      "lastUpdated": "2024-02-23",
    },
    {
      "latitude": 30.6184,
      "longitude": -96.3361,
      "address": "1801 Harvey Mitchell Pkwy, College Station, TX",
      "price": 385000,
      "status": "For Sale",
      "lastUpdated": "2024-02-22",
    },
    {
      "latitude": 30.6015,
      "longitude": -96.3140,
      "address": "2500 Earl Rudder Fwy, College Station, TX",
      "price": 515000,
      "status": "Pending",
      "lastUpdated": "2024-02-21",
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
    {
      "message": "Investor Jane Smith rejected 4500 Carter Creek Pkwy",
      "investorEmail": "jane@example.com",
      "status": "rejected",
      "timestamp": "2024-02-24",
    },
    {
      "message": "Investor Alex Brown showed interest in 700 Holleman Dr",
      "investorEmail": "alex@example.com",
      "status": "interested",
      "timestamp": "2024-02-23",
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _moveMapToFirstProperty();
    });
  }

  /// Moves the map to the first property (only if the map is rendered)
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
          initialCenter: LatLng(30.6280, -96.3344), // College Station
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

  /// Builds property cards
  Widget _buildPropertyCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Property Changes",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentProperties.length,
            itemBuilder: (context, index) {
              final property = recentProperties[index];
              return _buildPropertyCard(property);
            },
          ),
        ),
      ],
    );
  }

  /// Builds a single property card
  Widget _buildPropertyCard(Map<String, dynamic> property) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              property['address'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "Price: \$${property['price']}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              "Status: ${property['status']}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "Updated: ${property['lastUpdated']}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds notification overview
  Widget _buildNotifications() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Investor Notifications",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: Icon(
                  notification['status'] == 'approved' ? Icons.check_circle : Icons.cancel,
                  color: notification['status'] == 'approved' ? Colors.green : Colors.red,
                ),
                title: Text(notification['message']),
                subtitle: Text(
                  "Investor: ${notification['investorEmail']}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: Text(
                  notification['timestamp'],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Realtor Dashboard",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Map showing property changes
              _buildMap(),

              const SizedBox(height: 20),

              // Recent Properties Section
              _buildPropertyCards(),

              const SizedBox(height: 20),

              // Notifications Section
              _buildNotifications(),
            ],
          ),
        ),
      ),
    );
  }
}
