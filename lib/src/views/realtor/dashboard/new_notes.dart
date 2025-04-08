import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:realest/src/views/realtor/widgets/property_detail_sheet.dart';

import '../../../../util/property_fetch_helpers.dart';

class NewNotesSection extends StatelessWidget {
  const NewNotesSection({Key? key}) : super(key: key);

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
          "New Notes",
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('realtors')
                .doc(currentUser.uid)
                .collection('notes')
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
                return const Center(child: Text('No notes available'));
              }
              
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final noteDoc = snapshot.data!.docs[index];
                  final noteData = noteDoc.data() as Map<String, dynamic>;
                  
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _getInvestorDetails(noteData['investorId']),
                    builder: (context, investorSnapshot) {
                      if (investorSnapshot.connectionState == ConnectionState.waiting) {
                        return const NoteSkeletonCard();
                      }
                      
                      final investorData = investorSnapshot.data ?? {};
                      final hasName = investorData['firstName'] != null && investorData['lastName'] != null;
                      final name = hasName 
                          ? '${investorData['firstName']} ${investorData['lastName']}'
                          : 'Unknown Investor';
                      final email = investorData['contactEmail'] ?? 'No email';
                      
                      // Format timestamp
                      final timestamp = noteData['timestamp'] as Timestamp?;
                      final formattedDate = timestamp != null
                          ? DateFormat('MMM d, yyyy • h:mm a').format(timestamp.toDate())
                          : 'Unknown date';

                      return NoteCard(
                        name: name,
                        email: email,
                        note: noteData['note'] ?? 'No note content',
                        propertyId: noteData['propertyId'] ?? 'Unknown',
                        read: noteData['read'] ?? false,
                        timestamp: formattedDate,
                        onPropertyTap: () => _showPropertyDetails(context, noteData['propertyId']),
                        profilePicUrl: investorData['profilePicUrl'] != null
                            ? investorData['profilePicUrl']!
                            : 'assets/images/profile.png',
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Delete Note"),
                              content: const Text("Are you sure you want to delete this note?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('realtors')
                                .doc(currentUser.uid)
                                .collection('notes')
                                .doc(noteDoc.id)
                                .delete();
                          }
                        },
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

  Future<Map<String, dynamic>> _getInvestorDetails(String? investorId) async {
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
      print('Error fetching investor details: $e');
      return {};
    }
  }

  Future<void> _showPropertyDetails(BuildContext context, String propertyId) async {
    try {
      // Get the property from Firestore
      final propertyRef = FirebaseFirestore.instance.collection('listings').doc(propertyId);
      final snapshot = await propertyRef.get();

      if (!snapshot.exists) {
        print("Property not found");
        return;
      }

      // Optional: set some state here if needed
      // setState(() => _selectedPropertyId = propertyId);

      // Fetch full property data
      final propertyData = await fetchPropertyData(propertyId);

      // Show the modal bottom sheet
      await showModalBottomSheet(
        context: context,
        constraints: const BoxConstraints(maxWidth: 1000),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: false,
        builder: (_) => PropertyDetailSheet(property: propertyData),
      );
    } catch (e) {
      print('Error fetching property details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load property details')),
      );
    }
  }
}

class NoteCard extends StatelessWidget {
  final String name;
  final String email;
  final String note;
  final String propertyId;
  final bool read;
  final String timestamp;
  final VoidCallback onPropertyTap;
  final VoidCallback onDelete; // <- NEW
  final String? profilePicUrl;

  const NoteCard({
    Key? key,
    required this.name,
    required this.email,
    required this.note,
    required this.propertyId,
    required this.read,
    required this.timestamp,
    required this.onPropertyTap,
    required this.onDelete, // <- NEW
    this.profilePicUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  backgroundImage: profilePicUrl != null
                      ? NetworkImage(profilePicUrl!)
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
                  icon: const Icon(Icons.delete_outline),
                  color: theme.colorScheme.error,
                  onPressed: onDelete,
                  tooltip: 'Delete note',
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
            Text(
              note,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Property ID: $propertyId',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
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
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}

// Add NoteSkeletonCard similar to ClientActivitySkeletonCard
class NoteSkeletonCard extends StatelessWidget {
  const NoteSkeletonCard({Key? key}) : super(key: key);

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
                const CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 16,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 16,
                  width: 100,
                  color: Colors.grey,
                ),
                Container(
                  height: 16,
                  width: 100,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
