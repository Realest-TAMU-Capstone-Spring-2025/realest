import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../../../realtor_user_provider.dart'; // Ensure this path is correct
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'average_graphs.dart';

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

class _RealtorDashboardState extends State<RealtorDashboard> with SingleTickerProviderStateMixin {
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
      "message": "John Doe approved 1101 University Dr",
      "investorEmail": "john@example.com",
      "status": "approved",
      "timestamp": "2024-02-25",
    },
    {
      "message": "Eshwar Reddy liked 1510 Northside Dr",
      "investorEmail": "john@example.com",
      "status": "liked",
      "timestamp": "2024-02-25",
    },
    {
      "message": "Dinesh Balakrishnan disliked 1203 Wellborn Dr",
      "investorEmail": "john@example.com",
      "status": "disliked",
      "timestamp": "2024-02-25",
    },
    {
      "message": "Thesis Doe disapproved 821 Texas Dr",
      "investorEmail": "john@example.com",
      "status": "disapproved",
      "timestamp": "2024-02-25",
    },
    {
      "message": "Dinesh Reddy liked 1510 Northside Dr",
      "investorEmail": "john@example.com",
      "status": "liked",
      "timestamp": "2024-02-25",
    },
    {
      "message": "Arjun Som liked 1510 Northside Dr",
      "investorEmail": "john@example.com",
      "status": "liked",
      "timestamp": "2024-02-25",
    },
    {
      "message": "Dev Patel disliked 1203 Wellborn Dr",
      "investorEmail": "john@example.com",
      "status": "disliked",
      "timestamp": "2024-02-25",
    },
    {
      "message": "John Doe disapproved 821 Texas Dr",
      "investorEmail": "john@example.com",
      "status": "disapproved",
      "timestamp": "2024-02-25",
    },
  ];

  Map<String, int> clientStatusCounts = {
    "Update": 0,
    "Active": 0,
    "Inactive": 0,
  };
  bool _isLoadingClients = true;
  String? _errorMessage;

  // Houses Sold Meter Variables
  double housesSold = 5; // Current value (placeholder)
  double monthlyTarget = 10; // Monthly target (configurable)
  late AnimationController _animationController;
  late Animation<double> _needleAnimation;
  late TextEditingController _targetController;

  // Opacity values for each section
  double _notificationsOpacity = 0.0;
  double _housesClientsOpacity = 0.0;
  double _propertiesOpacity = 0.0;
  double _rentPriceOpacity = 0.0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _needleAnimation = Tween<double>(begin: 0, end: housesSold).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _targetController = TextEditingController(text: monthlyTarget.toString());

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.fetchRealtorData().then((_) {
      if (mounted) { // Check mounted before proceeding
        _fetchClientStatusCounts();
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _isLoadingClients = false;
          _errorMessage = "Failed to initialize user data: $e";
        });
      }
    });

    // Staggered animations with mounted checks
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _notificationsOpacity = 1.0);
      }
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _housesClientsOpacity = 1.0;
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) _animationController.forward();
          });
        });
      }
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _propertiesOpacity = 1.0);
      }
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() => _rentPriceOpacity = 1.0);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _fetchClientStatusCounts() async {
    if (!mounted) return; // Early exit if not mounted

    setState(() {
      _isLoadingClients = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final String? realtorId = userProvider.uid;

      if (realtorId == null) {
        if (mounted) {
          setState(() {
            _isLoadingClients = false;
            _errorMessage = "Realtor ID is null. Please log in again.";
          });
        }
        return;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('investors')
          .where('realtorId', isEqualTo: realtorId)
          .get();

      final counts = {"Update": 0, "Active": 0, "Inactive": 0};
      for (var doc in querySnapshot.docs) {
        final status = doc['status'] ?? 'Inactive';
        counts[status] = (counts[status] ?? 0) + 1;
      }

      if (mounted) {
        setState(() {
          clientStatusCounts = counts;
          _isLoadingClients = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingClients = false;
          _errorMessage = "Failed to load client status: $e";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load client status: $e')),
        );
      }
    }
  }

  Widget _buildModernCard(Widget child) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 3,
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: child,
      ),
    );
  }

  Widget _buildStatusBar() {
    final theme = Theme.of(context);
    final totalClients = clientStatusCounts.values.reduce((a, b) => a + b);
    if (totalClients == 0) {
      return Text(
        "No clients found",
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: clientStatusCounts["Update"]!,
          child: Container(
            height: 20,
            color: Color(0xFF1F51FF),
          ),
        ),
        Expanded(
          flex: clientStatusCounts["Active"]!,
          child: Container(
            height: 20,
            color: Color(0xFFBC13FE),
          ),
        ),
        Expanded(
          flex: clientStatusCounts["Inactive"]!,
          child: Container(
            height: 20,
            color: Color(0xFF39FF14),
          ),
        ),
      ],
    );
  }

  Widget _buildHousesSoldMeter() {
    final int interval = (monthlyTarget / 10).ceil();
    return AnimatedBuilder(
      animation: _needleAnimation,
      builder: (context, child) {
        return SfRadialGauge(
          axes: <RadialAxis>[
            RadialAxis(
              minimum: 0,
              maximum: monthlyTarget,
              startAngle: 140,
              endAngle: 40,
              showLabels: true,
              labelOffset: 15,
              labelFormat: '{value}',
              interval: interval.toDouble(),
              axisLabelStyle: const GaugeTextStyle(fontSize: 12),
              showTicks: true,
              majorTickStyle: const MajorTickStyle(length: 4, thickness: 2),
              minorTicksPerInterval: 0,
              radiusFactor: 1.0,
              axisLineStyle: const AxisLineStyle(
                thickness: 0.2,
                thicknessUnit: GaugeSizeUnit.factor,
                color: Colors.grey,
              ),
              pointers: <GaugePointer>[
                RangePointer(
                  value: _needleAnimation.value,
                  width: 0.2,
                  sizeUnit: GaugeSizeUnit.factor,
                  gradient: const SweepGradient(
                    colors: [Color(0xFFFF9500), Color(0xFFFF1744)],
                    stops: [0.0, 1.0],
                  ),
                  enableAnimation: true,
                  animationType: AnimationType.ease,
                ),
                NeedlePointer(
                  value: _needleAnimation.value,
                  needleLength: 0.5,
                  needleStartWidth: 1,
                  needleEndWidth: 4,
                  knobStyle: const KnobStyle(
                    knobRadius: 0.05,
                    sizeUnit: GaugeSizeUnit.factor,
                    color: Colors.blue,
                  ),
                  needleColor: Colors.red,
                  enableAnimation: true,
                  animationType: AnimationType.ease,
                ),
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                  widget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _needleAnimation.value.toInt().toString(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "of ${monthlyTarget.toInt()}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  angle: 90,
                  positionFactor: 0.5,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget _buildWebLayout(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                "Dashboard",
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Divider(
                color: theme.primaryColor,
                thickness: 2,
              ),
              const SizedBox(height: 10),

              // Second Row: Three Columns (unchanged)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: AnimatedOpacity(
                      opacity: _notificationsOpacity,
                      duration: const Duration(milliseconds: 500),
                      child: _buildModernCard(
                        SizedBox(
                          height: 275 + 150,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Notifications",
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: (275 + 150) - 45,
                                child: ListView.builder(
                                  itemCount: notifications.length,
                                  itemBuilder: (context, index) {
                                    final notification = notifications[index];
                                    final String initial = notification['message']
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase();

                                    // Determine color based on status
                                    Color statusColor;
                                    switch (notification['status']) {
                                      case 'liked':
                                        statusColor = Colors.blue;
                                        break;
                                      case 'disliked':
                                        statusColor = Colors.orange;
                                        break;
                                      case 'approved':
                                        statusColor = Colors.green;
                                        break;
                                      case 'disapproved':
                                        statusColor = Colors.red;
                                        break;
                                      default:
                                        statusColor = Colors.grey; // Fallback for undefined status
                                    }

                                    return ListTile(
                                      leading: CircleAvatar(
                                        radius: 20,
                                        backgroundColor: statusColor.withOpacity(0.2),
                                        child: Text(
                                          initial,
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        notification['message'],
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: AnimatedOpacity(
                      opacity: _housesClientsOpacity,
                      duration: const Duration(milliseconds: 500),
                      child: Column(
                        children: [
                          _buildModernCard(
                            SizedBox(
                              height: 275,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Houses Sold",
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Flexible(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              "Target:",
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 60,
                                              child: TextField(
                                                controller: _targetController,
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(),
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                                ),
                                                style: theme.textTheme.bodyMedium,
                                                onSubmitted: (value) {
                                                  final newTarget = double.tryParse(value);
                                                  if (newTarget != null && newTarget >= 0) {
                                                    setState(() {
                                                      monthlyTarget = newTarget;
                                                      _targetController.text = newTarget.toString();
                                                      _animationController.reset();
                                                      _needleAnimation = Tween<double>(begin: 0, end: housesSold).animate(
                                                        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
                                                      );
                                                      _animationController.forward();
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(child: _buildHousesSoldMeter()),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildModernCard(
                            SizedBox(
                              height: 100,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Clients",
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _isLoadingClients
                                      ? const Center(child: CircularProgressIndicator())
                                      : _errorMessage != null
                                      ? Text(
                                    _errorMessage!,
                                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                                  )
                                      : Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Total: ${clientStatusCounts.values.reduce((a, b) => a + b)}",
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Flexible(
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 2,
                                                        height: 16,
                                                        color: Color(0xFF1F51FF),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "Update: ${clientStatusCounts["Update"]}",
                                                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 2,
                                                        height: 16,
                                                        color: Color(0xFFBC13FE),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "Active: ${clientStatusCounts["Active"]}",
                                                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        width: 2,
                                                        height: 16,
                                                        color: Color(0xFF39FF14),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "Inactive: ${clientStatusCounts["Inactive"]}",
                                                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        _buildStatusBar(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: AnimatedOpacity(
                      opacity: _propertiesOpacity,
                      duration: const Duration(milliseconds: 500),
                      child: _buildModernCard(
                        SizedBox(
                          height: 275 + 150,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Property Updates",
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: recentProperties.length,
                                  itemBuilder: (context, index) {
                                    final property = recentProperties[index];
                                    return ListTile(
                                      title: Text(
                                        property['address'],
                                        style: theme.textTheme.bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        "Price: \$${property['price']}",
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.secondary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Text(
                                        property['status'],
                                        style: TextStyle(
                                          color: property['status'] == "For Sale" ? Colors.green : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Third Row: Split into Two Columns with Line Charts
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // First Column: Average Rent Price
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _rentPriceOpacity,
                      duration: const Duration(milliseconds: 500),
                      child: _buildModernCard(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Average Rent Price",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AspectRatio(
                              aspectRatio: 1.70,
                              child: AverageGraphs(title: "Average House Price", graphType: "rent"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Second Column: Average House Price
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _rentPriceOpacity,
                      duration: const Duration(milliseconds: 500),
                      child: _buildModernCard(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Average House Price",
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            AspectRatio(
                              aspectRatio: 1.70,
                              child: AverageGraphs(title: "Average House Price", graphType: "house"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Notifications
            AnimatedOpacity(
              opacity: _notificationsOpacity,
              duration: const Duration(milliseconds: 500),
              child: _buildModernCard(
                SizedBox(
                  height: 275,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Notifications",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: (275) - 45,
                        child: ListView.builder(
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            final String initial = notification['message'].toString().substring(0, 1).toUpperCase();
                            Color statusColor;
                            switch (notification['status']) {
                              case 'liked':
                                statusColor = Colors.blue;
                                break;
                              case 'disliked':
                                statusColor = Colors.orange;
                                break;
                              case 'approved':
                                statusColor = Colors.green;
                                break;
                              case 'disapproved':
                                statusColor = Colors.red;
                                break;
                              default:
                                statusColor = Colors.grey;
                            }
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: statusColor.withOpacity(0.2),
                                child: Text(
                                  initial,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                              title: Text(
                                notification['message'],
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Row 2: Clients
            AnimatedOpacity(
              opacity: _housesClientsOpacity,
              duration: const Duration(milliseconds: 1000),
              child: _buildModernCard(
                SizedBox(
                  height: 100,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Clients",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _isLoadingClients
                          ? const Center(child: CircularProgressIndicator())
                          : _errorMessage != null
                          ? Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                      )
                          : Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total: ${clientStatusCounts.values.reduce((a, b) => a + b)}",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 2,
                                            height: 16,
                                            color: Color(0xFF1F51FF),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Update: ${clientStatusCounts["Update"]}",
                                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        children: [
                                          Container(
                                            width: 2,
                                            height: 16,
                                            color: Color(0xFFBC13FE),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Active: ${clientStatusCounts["Active"]}",
                                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        children: [
                                          Container(
                                            width: 2,
                                            height: 16,
                                            color: Color(0xFF39FF14),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Inactive: ${clientStatusCounts["Inactive"]}",
                                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildStatusBar(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Row 3: Property Updates
            AnimatedOpacity(
              opacity: _propertiesOpacity,
              duration: const Duration(milliseconds: 1500),
              child: _buildModernCard(
                SizedBox(
                  height: 275,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Property Updates",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: recentProperties.length,
                          itemBuilder: (context, index) {
                            final property = recentProperties[index];
                            return ListTile(
                              title: Text(
                                property['address'],
                                style: theme.textTheme.bodyMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                "Price: \$${property['price']}",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(
                                property['status'],
                                style: TextStyle(
                                  color: property['status'] == "For Sale" ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Row 4: Houses Sold
            AnimatedOpacity(
              opacity: _housesClientsOpacity,
              duration: const Duration(milliseconds: 2000),
              child: _buildModernCard(
                SizedBox(
                  height: 275,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Houses Sold",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Target:",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 60,
                                  child: TextField(
                                    controller: _targetController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                    ),
                                    style: theme.textTheme.bodyMedium,
                                    onSubmitted: (value) {
                                      final newTarget = double.tryParse(value);
                                      if (newTarget != null && newTarget >= 0) {
                                        setState(() {
                                          monthlyTarget = newTarget;
                                          _targetController.text = newTarget.toString();
                                          _animationController.reset();
                                          _needleAnimation = Tween<double>(begin: 0, end: housesSold).animate(
                                            CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
                                          );
                                          _animationController.forward();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(child: _buildHousesSoldMeter()),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Row 5: Average Rent Price
            AnimatedOpacity(
              opacity: _rentPriceOpacity,
              duration: const Duration(milliseconds: 500),
              child: _buildModernCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Average Rent Price",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AspectRatio(
                      aspectRatio: 1.70,
                      child: AverageGraphs(title: "Average House Price", graphType: "rent"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Row 6: Average House Price
            AnimatedOpacity(
              opacity: _rentPriceOpacity,
              duration: const Duration(milliseconds: 500),
              child: _buildModernCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Average House Price",
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AspectRatio(
                      aspectRatio: 1.70,
                      child: AverageGraphs(title: "Average House Price", graphType: "house"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);

    bool isSmallScreen = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: isSmallScreen ? _buildMobileLayout(context) : _buildWebLayout(context),
    );
  }
}
