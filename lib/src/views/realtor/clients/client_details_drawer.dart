import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
  // Data holders
  Map<String, dynamic>? _clientData;
  List<String>? _decisions;
  bool _isLoading = true;
  String? _error;

  // Cache manager
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    try {
      // Try to load from cache first
      await _loadFromCache();

      // Then fetch from Firestore (this will update the UI again if different from cache)
      await _fetchFromFirestore();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFromCache() async {
    try {
      // Load client data from cache
      final clientCacheFile =
          await _cacheManager.getFileFromCache('client_${widget.clientUid}');
      if (clientCacheFile != null) {
        final clientCacheData = await clientCacheFile.file.readAsString();
        setState(() {
          _clientData = jsonDecode(clientCacheData);
          _isLoading = false;
        });
      }

      // Load decisions from cache
      final decisionsCacheFile =
          await _cacheManager.getFileFromCache('decisions_${widget.clientUid}');
      if (decisionsCacheFile != null) {
        final decisionsCacheData = await decisionsCacheFile.file.readAsString();
        setState(() {
          _decisions = List<String>.from(jsonDecode(decisionsCacheData));
        });
      }
    } catch (e) {
      print('Error loading from cache: $e');
      // Continue execution, we'll try to fetch from Firestore
    }
  }

  Future<void> _fetchFromFirestore() async {
    try {
      // Fetch investor data
      final investorDoc = await FirebaseFirestore.instance
          .collection('investors')
          .doc(widget.clientUid)
          .get();

      if (investorDoc.exists) {
        final investorData = investorDoc.data() as Map<String, dynamic>;

        if (investorData['createdAt'] is Timestamp) {
          investorData['createdAt'] =
              (investorData['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        // Cache the investor data
        await _cacheManager.putFile(
          'client_${widget.clientUid}',
          utf8.encode(jsonEncode(investorData)),
        );

        setState(() {
          _clientData = investorData;
          _isLoading = false;
        });

        // Get the user UID for this investor
        final userUid = investorData['uid'] as String? ?? widget.clientUid;

        // Fetch decisions from user document
        final decisionsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userUid)
            .collection('decisions')
            .get();

        // Extract listing IDs from decisions
        final listingIds =
            decisionsSnapshot.docs.map((doc) => doc.id).toList();

        // Cache the decisions
        await _cacheManager.putFile(
          'decisions_${widget.clientUid}',
          utf8.encode(jsonEncode(listingIds)),
        );

        setState(() {
          _decisions = listingIds;
        });
      } else {
        setState(() {
          _error = 'Investor not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('Error: $_error'));
    if (_clientData == null) return Center(child: Text('Client not found'));

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
              CurvedAnimation(parent: _animationController, curve: Curves.ease)),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.white, // Solid background color
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: profilePicUrl.isNotEmpty
                          ? NetworkImage(profilePicUrl)
                          : const AssetImage('assets/images/profile.png')
                              as ImageProvider,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style:
                                Theme.of(context).textTheme.headlineSmall),
                        Text(status.toUpperCase(),
                            style:
                                Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact Information',
                          style:
                              Theme.of(context).textTheme.titleLarge),
                      Text('Email: $email'),
                      Text('Phone: $phone'),
                      const SizedBox(height: 16),
                      Text('Account Details',
                          style:
                              Theme.of(context).textTheme.titleLarge),
                      Text('Created At:',
                          style:
                              Theme.of(context).textTheme.bodyMedium),
                      Text('${createdAt.day}/${createdAt.month}/${createdAt.year}'),
                      const SizedBox(height: 16),
                      Text('Notes:', style:
                          Theme.of(context).textTheme.bodyMedium),
                      Text(notes.isEmpty ? 'No notes' : notes),
                      const SizedBox(height: 16),
                      Text('Listings Decisions',
                          style:
                              Theme.of(context).textTheme.titleLarge),
                      ...?_decisions?.map((listingId) => ListTile(
                            title:
                                Text('Listing ID $listingId'),
                          )),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}