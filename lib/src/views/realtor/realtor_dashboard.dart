import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../user_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _isLoading = false;

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

  List<Map<String, dynamic>> notifications = [];


  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    try {
      // Ensure user data is loaded
      if (userProvider.uid == null) {
        await userProvider.fetchUserData();
      }
      
      final realtorUid = userProvider.uid;
      if (realtorUid == null) {
        throw Exception('Realtor UID not found');
      }

      // 1. Get realtor's liked properties
      final realtorLikedSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(realtorUid)
          .collection('decisions')
          .where('liked', isEqualTo: true)
          .get();

      final realtorLikedProperties = realtorLikedSnapshot.docs.map((doc) => doc.id).toList();

      // 2. Get all investors assigned to this realtor
      final investorsSnapshot = await FirebaseFirestore.instance
          .collection('investors')
          .where('realtorId', isEqualTo: realtorUid)
          .get();

      final List<Map<String, dynamic>> matches = [];
      
      // Process matches in parallel
      await Future.wait(investorsSnapshot.docs.map((investorDoc) async {
        final investorId = investorDoc.id;
        
        final investorLikedSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(investorId)
            .collection('decisions')
            .where('liked', isEqualTo: true)
            .get();

        await Future.wait(investorLikedSnapshot.docs.map((decisionDoc) async {
          if (realtorLikedProperties.contains(decisionDoc.id)) {
            final propertyFuture = FirebaseFirestore.instance
                .collection('listings')
                .doc(decisionDoc.id)
                .get();

            final investorFuture = FirebaseFirestore.instance
                .collection('users')
                .doc(investorId)
                .get();

            final results = await Future.wait([propertyFuture, investorFuture]);
            final propertySnapshot = results[0];
            final investorSnapshot = results[1];

            matches.add({
              'timestamp': decisionDoc.data()['timestamp'],
              'investorEmail': investorSnapshot.data()?['email'] ?? 'Unknown',
              'propertyAddress': propertySnapshot.data()?['street'] ?? 'Unknown',
              'message': 'Investor ${investorSnapshot.data()?['firstName'] ?? ''}approved '
                  '${propertySnapshot.data()?['street']}',
            });
          }
        }));
      }));

      // Sort by most recent first
      matches.sort((a, b) => (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));

      setState(() {
        notifications = matches.map((match) => ({
              'message': match['message'],
              'investorEmail': match['investorEmail'],
              'timestamp': DateFormat('yyyy-MM-dd – HH:mm').format((match['timestamp'] as Timestamp).toDate()),
              'propertyAddress': match['propertyAddress'],
            })).toList();
      });
    } catch (e) {
      print('Error fetching notifications: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading matches: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildNotifications() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Investor Matches",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        notifications.isEmpty
            ? const Text('No recent matches found')
            : _buildModernCard(
                Column(
                  children: notifications.map((notification) {
                    return ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(notification['message']),
                      subtitle: Text(notification['investorEmail']),
                      trailing: Text(notification['timestamp']),
                      onTap: () async {
                        final email = notification['investorEmail'];
                        if (email == null || email.isEmpty) return;
                        
                        final Uri emailLaunchUri = Uri(
                          scheme: 'mailto',
                          path: email,
                          queryParameters: {
                            'subject': 'Regarding ${notification['propertyAddress']}',
                            'body': 'Hello,',
                          },
                        );

                        try {
                          await launch(emailLaunchUri.toString());
                        } catch (e) {
                          print('Error launching email client: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not launch email client'),
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Welcome, ${userProvider.firstName ?? 'Realtor'}",
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _fetchNotifications,
                  tooltip: 'Refresh notifications',
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

