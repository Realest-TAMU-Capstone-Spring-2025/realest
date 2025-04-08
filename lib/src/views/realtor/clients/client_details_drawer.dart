import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:realest/util/property_fetch_helpers.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dashboard/new_notes.dart';
import '../widgets/property_card/property_list_card.dart';
import '../widgets/property_detail_sheet.dart';

class ClientDetailsDrawer extends StatefulWidget {
  final String clientUid;
  final VoidCallback onClose;

  const ClientDetailsDrawer({
    super.key,
    required this.clientUid,
    required this.onClose,
  });

  @override
  _ClientDetailsDrawerState createState() => _ClientDetailsDrawerState();
}

class _ClientDetailsDrawerState extends State<ClientDetailsDrawer>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _clientData;
  Map<String, List<Map<String, dynamic>>> _groupedDecisions = {
    'liked': [],
    'disliked': [],
    'sent': [],
    'sentAndLiked': [],
  };
  bool _isLoading = true;
  String? _error;
  bool _notesExpanded = false;

  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  late AnimationController _animationController;
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _availableTags = [];
  List<String> _assignedTags = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();

    _loadClientData();
  }

  Future<void> _loadClientData() async {
    try {
      final investorDoc = await FirebaseFirestore.instance
          .collection('investors')
          .doc(widget.clientUid)
          .get();

      if (!investorDoc.exists) {
        setState(() {
          _error = 'Investor not found';
          _isLoading = false;
        });
        return;
      }

      final data = investorDoc.data()!;
      data['createdAt'] =
          (data['createdAt'] as Timestamp?)?.toDate().toIso8601String() ??
              DateTime.now().toIso8601String();
      _clientData = data;

      final realtorId = FirebaseAuth.instance.currentUser?.uid;

      final snapshot = await FirebaseFirestore.instance
          .collection('realtors')
          .doc(realtorId)
          .collection('interactions')
          .where('investorId', isEqualTo: widget.clientUid)
          .get();

      for (var doc in snapshot.docs) {
        final status = doc['status'] ?? 'unknown';
        final propertyId = doc['propertyId'];
        final propertyData = doc['propertyData'];
        final sentByRealtor = doc['sentByRealtor'] == true;

        if (propertyId == null || propertyData == null) continue;

        final entry = {
          'propertyId': propertyId,
          'status': status,
          'timestamp': (doc['timestamp'] as Timestamp?)?.toDate(),
          'propertyData': propertyData,
        };

        if (_groupedDecisions.containsKey(status)) {
          _groupedDecisions[status]!.add(entry);
        }

        // Special case for "Sent + Liked"
        if (status == 'liked' && sentByRealtor) {
          _groupedDecisions['sentAndLiked']!.add(entry);
        }
        final notesSnapshot = await FirebaseFirestore.instance
            .collection('realtors')
            .doc(realtorId)
            .collection('notes')
            .where('investorId', isEqualTo: widget.clientUid)
            .orderBy('timestamp', descending: true)
            .get();

        _notes = notesSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // include Firestore document ID
          return data;
        }).toList();
      }
      final tagsSnapshot = await FirebaseFirestore.instance
          .collection('realtors')
          .doc(realtorId)
          .collection('tags')
          .get();

      _availableTags = tagsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      _assignedTags = _availableTags
          .where((tag) => (tag['investors'] as List).contains(widget.clientUid))
          .map((tag) => tag['id'] as String)
          .toList();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('Error loading client data: $e, message: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildInteractionList(
      String title, IconData icon, List<Map<String, dynamic>> items) {
    final theme = Theme.of(context);

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No $title interactions.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final property = items[index];
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: PropertyListCard(
                property: property['propertyData'],
                onTap: () async {
                  final propertyData =
                      await fetchPropertyData(property['propertyId']);
                  if (!mounted) return;
                  showModalBottomSheet(
                    context: context,
                    constraints: const BoxConstraints(maxWidth: 1000),
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => PropertyDetailSheet(property: propertyData),
                    enableDrag: false,
                  );
                },
                color: Colors.white,
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_clientData == null)
      return const Center(child: Text('Client not found'));

    final name =
        '${_clientData?['firstName'] ?? ''} ${_clientData?['lastName'] ?? ''}';
    final email = _clientData?['contactEmail'] ?? 'N/A';
    final phone = _clientData?['contactPhone'] ?? 'N/A';
    final profilePicUrl = _clientData?['profilePicUrl'] ?? '';
    final notes = _clientData?['notes'] ?? '';
    final createdAt = DateTime.parse(_clientData!['createdAt']);
    final status = _clientData?['status'] ?? 'inactive';

    return SlideTransition(
        position:
            Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.ease),
        ),
        child: Center(
          child: Material(
            borderRadius: BorderRadius.circular(16),
            elevation: 10,
            color: Colors.white,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 1000,
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: profilePicUrl.isNotEmpty
                              ? NetworkImage(profilePicUrl)
                              : const AssetImage('assets/images/profile.png')
                                  as ImageProvider,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                              Text(status.toUpperCase(),
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _showManageTagsDialog,
                      icon: Icon(Icons.label_outline, color: Theme.of(context).colorScheme.primary),
                      label: Text('Manage Tags'),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.grey[200],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Contact Info',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.email_outlined, size: 20),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () async {
                                    final uri =
                                        Uri(scheme: 'mailto', path: email);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                  child: Text(
                                    email,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 20),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () async {
                                    final uri = Uri(scheme: 'tel', path: phone);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri);
                                    }
                                  },
                                  child: Text(
                                    phone,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          decoration: TextDecoration.underline,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: Colors.grey[200],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Account Details',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Created: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    ExpansionPanelList(
                      expansionCallback: (panelIndex, isExpanded) {
                        setState(() {
                          _notesExpanded = !_notesExpanded;
                        });
                      },
                      children: [
                        ExpansionPanel(
                          isExpanded: _notesExpanded,
                          canTapOnHeader: true,
                          headerBuilder: (context, isExpanded) {
                            return ListTile(
                              title: Text(
                                'Client Notes',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            );
                          },
                          body: _notes.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text('No notes yet.'),
                                )
                              : Column(
                                  children: _notes.map((note) {
                                    final ts = (note['timestamp'] as Timestamp?)
                                        ?.toDate();
                                    final formattedTime = ts != null
                                        ? '${ts.month}/${ts.day}/${ts.year} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}'
                                        : 'N/A';

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      child: NoteCard(
                                        name: _clientData?['firstName'] ?? '',
                                        email:
                                            _clientData?['contactEmail'] ?? '',
                                        note: note['note'] ?? '',
                                        propertyId: note['propertyId'] ?? '',
                                        read: note['read'] ?? false,
                                        timestamp: formattedTime,
                                        profilePicUrl:
                                            _clientData?['profilePicUrl'],
                                        onPropertyTap: () => _openPropertyDetails(note['propertyId']),
                                        onDelete: () async {
                                          final realtorId = FirebaseAuth.instance.currentUser?.uid;
                                          final noteId = note['id']; // Make sure `id` is included when loading notes
                                          print("Deleting note with ID: $noteId");
                                          if (noteId != null && realtorId != null) {
                                            await FirebaseFirestore.instance
                                                .collection('realtors')
                                                .doc(realtorId)
                                                .collection('notes')
                                                .doc(noteId)
                                                .delete();

                                            setState(() {
                                              _notes.removeWhere((n) => n['id'] == noteId);
                                            });
                                          }
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                     DefaultTabController(
                        length: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const TabBar(
                              labelColor: Colors.deepPurple,
                              unselectedLabelColor: Colors.black54,
                              tabs: [
                                Tab(
                                    icon: Icon(Icons.favorite_border),
                                    text: 'Liked'),
                                Tab(
                                    icon: Icon(Icons.thumb_down_alt_outlined),
                                    text: 'Disliked'),
                                Tab(
                                    icon: Icon(Icons.send_outlined),
                                    text: 'Sent'),
                                Tab(icon: Icon(Icons.check), text: 'Matched')
                              ],
                            ),
                            const SizedBox(height: 8),

                           SizedBox(
                             height: 400, // Or any reasonable height
                             child: TabBarView(
                                    children: [
                                      _buildScrollableTabContent(
                                          'Liked',
                                          Icons.favorite_border,
                                          _groupedDecisions['liked']!),
                                      _buildScrollableTabContent(
                                          'Disliked',
                                          Icons.thumb_down_alt_outlined,
                                          _groupedDecisions['disliked']!),
                                      _buildScrollableTabContent(
                                          'Sent',
                                          Icons.send_outlined,
                                          _groupedDecisions['sent']!),
                                      _buildScrollableTabContent(
                                          'properties that you sent and client liked',
                                          Icons.check,
                                          _groupedDecisions['sentAndLiked']!),
                                    ],

                                ),
                               )],
                        ),
                      ),

                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Future<void> _openPropertyDetails(String propertyId) async {
    final doc = await FirebaseFirestore.instance.collection('listings').doc(propertyId).get();

    if (!doc.exists) {
      print("Property not found");
      return;
    }

    final propertyData = await fetchPropertyData(propertyId);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(maxWidth: 1000),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PropertyDetailSheet(property: propertyData),
      enableDrag: false,
    );
  }


  Widget _buildScrollableTabContent(
      String title, IconData icon, List<Map<String, dynamic>> items) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: _buildInteractionList(title, icon, items),
    );
  }

  void _showManageTagsDialog() async {
    final realtorId = FirebaseAuth.instance.currentUser?.uid;
    final clientUid = widget.clientUid;

    if (realtorId == null) return;

    final tagsSnapshot = await FirebaseFirestore.instance
        .collection('realtors')
        .doc(realtorId)
        .collection('tags')
        .get();

    final allTags = tagsSnapshot.docs;
    List<String> assignedTags = allTags
        .where((doc) => (doc['investors'] as List).contains(clientUid))
        .map((doc) => doc.id)
        .toList();

    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          final filteredTags = allTags.where((doc) {
            final name = doc['name'].toString().toLowerCase();
            final searchText = searchController.text.toLowerCase();
            return name.contains(searchText);
          }).toList();

          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Assign Tags", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search tags...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredTags.length,
                      itemBuilder: (context, index) {
                        final tagDoc = filteredTags[index];
                        final isAssigned = assignedTags.contains(tagDoc.id);

                        return CheckboxListTile(
                          secondary: CircleAvatar(
                            backgroundColor: Color(tagDoc['color']),
                          ),
                          title: Text(tagDoc['name']),
                          value: isAssigned,
                          onChanged: (checked) async {
                            final docRef = FirebaseFirestore.instance
                                .collection('realtors')
                                .doc(realtorId)
                                .collection('tags')
                                .doc(tagDoc.id);

                            if (checked == true) {
                              await docRef.update({
                                'investors': FieldValue.arrayUnion([clientUid])
                              });
                              assignedTags.add(tagDoc.id);
                            } else {
                              await docRef.update({
                                'investors': FieldValue.arrayRemove([clientUid])
                              });
                              assignedTags.remove(tagDoc.id);
                            }

                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Done"),
                    ),
                  )
                ],
              ),
            ),
          );
        });
      },
    );
  }

}
