import 'package:flutter/material.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart' as algolia;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:realest/user_provider.dart';
import 'package:realest/src/views/realtor/clients/client_details_drawer.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';


class PinnedClientsSection extends StatefulWidget {
  const PinnedClientsSection({super.key});

  @override
  PinnedClientsSectionState createState() => PinnedClientsSectionState();
}

class PinnedClientsSectionState extends State<PinnedClientsSection> {
  final algolia.HitsSearcher _searcher = algolia.HitsSearcher(
    applicationID: dotenv.env['ALGOLIA_APP_ID']!,
    apiKey: dotenv.env['ALGOLIA_API_KEY']!,
    indexName: 'investors',
  );
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<DocumentReference> _pinnedClients = [];
  bool _isLoading = true;
  bool _showSearchBar = false;
  Timer? _batchUpdateTimer;


  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    await _loadCachedClients();
    await _loadFirestoreClients();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadCachedClients() async {
    final cachedFile = await _cacheManager.getFileFromCache('pinnedClients');
    if (cachedFile != null) {
      final cachedData = await cachedFile.file.readAsString();
      setState(() {
        _pinnedClients = (jsonDecode(cachedData) as List)
            .map((ref) => FirebaseFirestore.instance.doc(ref))
            .toList();
      });
    }
  }

  void _removeClientFromPin(DocumentReference clientRef) async {
    setState(() {
      _pinnedClients.remove(clientRef);
    });

    // Update both cache and Firestore
    await _cacheClients(_pinnedClients);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await FirebaseFirestore.instance
        .collection('realtors')
        .doc(userProvider.uid)
        .update({
      'pinnedClients': FieldValue.arrayRemove([clientRef])
    });
  }


  Future<void> _loadFirestoreClients() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('realtors')
          .doc(userProvider.uid)
          .get();
      if (doc.exists) {
        final clients = (doc.data()?['pinnedClients'] as List? ?? [])
            .cast<DocumentReference>();
        await _cacheClients(clients);
        setState(() {
          _pinnedClients = clients;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error loading clients: ${e.toString()}');
    }
  }

  Future<void> _cacheClients(List<DocumentReference> clients) async {
    await _cacheManager.putFile(
      'pinnedClients',
      utf8.encode(jsonEncode(clients.map((e) => e.path).toList())),
    );
  }

  void _scheduleBatchUpdate() {
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = Timer(const Duration(seconds: 5), _performBatchUpdate);
  }

  Future<void> _performBatchUpdate() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final batch = FirebaseFirestore.instance.batch();
    final userRef = FirebaseFirestore.instance
        .collection('realtors')
        .doc(userProvider.uid);
    batch.update(userRef, {'pinnedClients': _pinnedClients});
    await batch.commit();
    await _cacheClients(_pinnedClients);
  }

  void _showClientDetails(DocumentReference clientRef) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<DocumentSnapshot>(
        future: clientRef.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ClientDetailsDrawer(
            clientUid: clientRef.id,
            onClose: () {
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
      } else {
        // Focus the search field when showing
        Future.delayed(const Duration(milliseconds: 100), () {
          _searchFocusNode.requestFocus();
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Column(
          children: [
            _buildHeader(),
            StreamBuilder<algolia.SearchResponse>(
              stream: _searcher.responses,
              builder: (context, snapshot) {
                if (_showSearchBar &&
                    snapshot.hasData &&
                    snapshot.data!.hits.isEmpty &&
                    _searchController.text.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: 1,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            'No results found',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildPinnedClientsList(),
            ),
          ],


    );
  }

  Widget _buildPinnedClientsList() {
    return _pinnedClients.isEmpty
        ? const Center(child: Text('No pinned clients'))
        : Card(
      color:  Theme.of(context).colorScheme.onTertiary,

      margin: const EdgeInsets.all(16.0),
                child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                buildDefaultDragHandles: _showSearchBar,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                  if (oldIndex < newIndex) newIndex -= 1;
                  final client = _pinnedClients.removeAt(oldIndex);
                  _pinnedClients.insert(newIndex, client);
                  });

                  // Update both cache and Firestore with the new order
                  _cacheClients(_pinnedClients);
                  _scheduleBatchUpdate();
                },
                itemCount: _pinnedClients.length,
                itemBuilder: (context, index) {
                  final clientRef = _pinnedClients[index];
                  return FutureBuilder<DocumentSnapshot>(
                  key: ValueKey(clientRef.id),
                  future: clientRef.get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return SizedBox.shrink();
                    }

                    if (!snapshot.hasData || snapshot.data!.data() == null) {
                      return SizedBox.shrink();
                    }
                    final data = snapshot.data!.data() as Map<String, dynamic>;

                    final isName =
                      (data['firstName']?.isNotEmpty == true &&
                        data['lastName']?.isNotEmpty == true);
                    return ListTile(
                    title: Text(
                    (isName) ? '${data['firstName']} ${data['lastName']}'
                      : data['contactEmail'] ?? 'Unknown Client: ${clientRef.id}',
                    ),
                    subtitle: (isName) ? Text(data['contactEmail'] ?? '') : null,
                    trailing: _showSearchBar
                      ? IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: () => _removeClientFromPin(clientRef),
                        )
                      : null,
                    onTap: () => _showClientDetails(clientRef),
                    );
                  },
                  );
                },
              ),
          );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: _showSearchBar
          ? _buildSearchBarInHeader()
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pinned Clients',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _toggleSearchBar,
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBarInHeader() {
  final searchBarKey = GlobalKey();

  return RawAutocomplete<Map<String, dynamic>>(
    focusNode: _searchFocusNode,
    textEditingController: _searchController,
    optionsBuilder: _searchClients,
    displayStringForOption: (option) =>
        '${option['firstName']} ${option['lastName']}',
    fieldViewBuilder:
        (context, controller, focusNode, onFieldSubmitted) {
      return TextField(
        key: searchBarKey,
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: 'Search clients...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _toggleSearchBar,
          ),
        ),
        onTap: () {
          // After the widget is built, get its size
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (searchBarKey.currentContext != null) {
              final RenderBox box = searchBarKey.currentContext!.findRenderObject() as RenderBox;
              // Store the width for use in the options builder
              setState(() {});
            }
          });
        },
      );
    },
    optionsViewBuilder: (context, onSelected, options) =>
        _buildSearchOptions(context, onSelected, options),
    onSelected: (option) {
      _addClientToPin(option);
      _toggleSearchBar();
    },
  );
}


  Future<Iterable<Map<String, dynamic>>> _searchClients(
      TextEditingValue textEditingValue) async {
      if (textEditingValue.text.isEmpty) return const [];

      final userProvider =
          Provider.of<UserProvider>(context, listen: false);
      final pinnedIds = _pinnedClients.map((ref) => ref.id).toList();

      _searcher.applyState((state) => state.copyWith(
            filterGroups: {
              algolia.FilterGroup.facet(
                filters: {
                  algolia.Filter.facet('realtorId', userProvider.uid),
                  ...pinnedIds.map((id) =>
                      algolia.Filter.facet('objectID', id, isNegated: true)),
                }.toSet(),
              ),
            },
            query: textEditingValue.text,
          ));

      final snapshot = await _searcher.responses.first;
      return snapshot.hits
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    void _addClientToPin(Map<String, dynamic> option) async {
      final userProvider =
          Provider.of<UserProvider>(context, listen: false);
      final clientRef = FirebaseFirestore.instance.doc('investors/${option['objectID']}');

      setState(() {
        _pinnedClients.add(clientRef);
      });

      await _cacheClients(_pinnedClients);
      await FirebaseFirestore.instance
          .collection('realtors')
          .doc(userProvider.uid)
          .update({
        'pinnedClients': FieldValue.arrayUnion([clientRef])
      });
    }

  Widget _buildSearchOptions(
      BuildContext context,
      AutocompleteOnSelected<Map<String, dynamic>> onSelected,
      Iterable<Map<String, dynamic>> options,
      ) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final double availableWidth =  300;
    final double maxHeight = MediaQuery.of(context).size.height * 0.5;

    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: availableWidth, // ✅ Constrain width here
            maxHeight: maxHeight,
          ),
          child: options.isEmpty
              ? Container(
            padding: const EdgeInsets.all(16.0),
            alignment: Alignment.center,
            child: const Text(
              "No results found",
              style: TextStyle(color: Colors.grey),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              final isName = option['firstName']?.isNotEmpty == true &&
                  option['lastName']?.isNotEmpty == true;
              return ListTile(
                title: Text(
                  isName
                      ? '${option['firstName']} ${option['lastName']}'
                      : option['contactEmail'] ?? 'Unknown Client: ${option['objectID']}',
                ),
                subtitle: isName ? Text(option['contactEmail'] ?? '') : null,
                onTap: () => onSelected(option),
              );
            },
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    _batchUpdateTimer?.cancel();
    _searcher.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
