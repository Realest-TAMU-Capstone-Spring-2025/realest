import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_sheet.dart';
import '../../../../util/property_fetch_helpers.dart';

class InvestorActivitySection extends StatelessWidget {
  const InvestorActivitySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('User not logged in'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Client Activity",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('realtors')
                .doc(currentUser.uid)
                .collection('long_activity')
                .orderBy('timestamp', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No client activity available'));
              }
              
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final activityDoc = snapshot.data!.docs[index];
                  final activityData = activityDoc.data() as Map<String, dynamic>;
                  
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _getClientDetails(activityData['clientId']),
                    builder: (context, clientSnapshot) {
                      if (clientSnapshot.connectionState == ConnectionState.waiting) {
                        return const ClientActivitySkeletonCard();
                      }
                      
                      final clientData = clientSnapshot.data ?? {};
                      final hasName = clientData['firstName'] != null && clientData['lastName'] != null;
                      final name = hasName 
                          ? '${clientData['firstName']} ${clientData['lastName']}'
                          : 'Unknown Client';
                      final email = clientData['contactEmail'] ?? 'No email';
                      final phone = clientData['contactPhone'];
                      final hasPhone = phone != null && phone.toString().isNotEmpty;
                      
                      // Format timestamp
                      final timestamp = activityData['timestamp'] as Timestamp?;
                      final formattedDate = timestamp != null
                          ? DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toDate())
                          : 'Unknown date';
                      
                      // Calculate duration
                      final duration = activityData['duration'] ?? 0;
                      final formattedDuration = _formatDuration(duration);
                      
                      return ClientActivityCard(
                        name: name,
                        email: email,
                        phone: hasPhone ? phone.toString() : null,
                        propertyId: activityData['listingId'] ?? 'Unknown',
                        timestamp: formattedDate,
                        duration: formattedDuration,
                        onPropertyTap: () => _showPropertyDetails(context, activityData['propertyId']),
                        profilePicUrl: clientData['profilePicUrl'] != null ?
                        clientData['profilePicUrl']!
                        :  'assets/images/profile.png',

                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getClientDetails(String? investorId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('investors')
          .doc(investorId)
          .get();
      
      if (doc.exists) {
        return doc.data() ?? {};
      }
      return {};
    } catch (e) {
      print('Error fetching client details: $e');
      return {};
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      return '${(seconds / 60).floor()} min';
    } else {
      final hours = (seconds / 3600).floor();
      final minutes = ((seconds % 3600) / 60).floor();
      return '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
    }
  }

  void _showPropertyDetails(BuildContext context, String? propertyId) {
    if (propertyId == null) return;
    // Show property detail sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: fetchPropertyData(propertyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No property data available'));
          }
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return PropertyDetailSheet(
                property: snapshot.data!,
              );
            },
          );
        },
      ),
    );
  }
}

class ClientActivityCard extends StatelessWidget {
  final String name;
  final String email;
  final String? phone;
  final String propertyId;
  final String timestamp;
  final String duration;
  final VoidCallback onPropertyTap;
  final String? profilePicUrl;

  const ClientActivityCard({
    Key? key,
    required this.name,
    required this.email,
    this.phone,
    required this.propertyId,
    required this.timestamp,
    required this.duration,
    required this.onPropertyTap,
    required this.profilePicUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhone = phone != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  backgroundImage: profilePicUrl != null ?
                       NetworkImage(profilePicUrl!)
                      : const AssetImage('assets/images/profile.png') as ImageProvider,
                    ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      GestureDetector(
                        onTap: () => _launchEmail(email),
                        child: Text(
                          email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.phone,
                    color: hasPhone 
                        ? theme.colorScheme.primary 
                        : theme.disabledColor,
                  ),
                  onPressed: hasPhone ? () => _launchPhone(phone!) : null,
                ),
                IconButton(
                  icon: Icon(
                    Icons.home_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                  onPressed: onPropertyTap,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                Text(
                  timestamp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchPhone(String phone) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phone,
    );
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }
}

class ClientActivitySkeletonCard extends StatelessWidget {
  const ClientActivitySkeletonCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonCircle(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonLine(width: 120, height: 18),
                      SizedBox(height: 4),
                      SkeletonLine(width: 180, height: 14),
                    ],
                  ),
                ),
                const SkeletonCircle(size: 32),
                const SizedBox(width: 8),
                const SkeletonCircle(size: 32),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonLine(width: 80, height: 12),
                SkeletonLine(width: 120, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Skeleton widgets for loading state
class SkeletonLine extends StatelessWidget {
  final double width;
  final double height;
  
  const SkeletonLine({
    Key? key,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;
  
  const SkeletonCircle({
    Key? key,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
    );
  }
}