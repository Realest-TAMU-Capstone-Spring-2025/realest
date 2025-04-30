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

/// Displays and manages a list of pinned clients for the realtor.
class PinnedClientsSection extends StatefulWidget {
  const PinnedClientsSection({super.key});

  @override
  PinnedClientsSectionState createState() => PinnedClientsSectionState();
}

/// State for [PinnedClientsSection]. Handles loading, caching, and searching pinned clients.
class PinnedClientsSectionState extends State<PinnedClientsSection> {
  /// Algolia search client for querying clients.
  final algolia.HitsSearcher _searcher = algolia.HitsSearcher(
    applicationID: 'BFVXJ9G642',
    apiKey: '5341f6a026fbb648426f933b6e3cead7',
    indexName: 'investors',
  );

  /// Cache manager for storing pinned clients locally.
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  /// Controller for the search input field.
  final TextEditingController _searchController = TextEditingController();

  /// Focus node for the search input field.
  final FocusNode _searchFocusNode = FocusNode();

  /// List of pinned client document references.
  List<DocumentReference> _pinnedClients = [];

  /// Indicates if client data is being loaded.
  bool _isLoading = true;

  /// Toggles visibility of the search bar.
  bool _showSearchBar = false;

  /// Timer for batch updates to Firestore.
  Timer? _batchUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  /// Loads pinned clients from cache and Firestore.
  Future<void> _loadClients() async {
    await _loadCachedClients();
    await _loadFirestoreClients();
    setState(() {
      _isLoading = false;
    });
  }

  /// Loads pinned clients from cache.
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

  /// Removes a client from the pinned list and updates cache and Firestore.
  ///
  /// [clientRef] is the document reference of the client to remove.
  void _removeClientFromPin(DocumentReference clientRef) async {
    setState(() {
      _pinnedClients.remove(clientRef);
    });
    await _cacheClients(_pinnedClients);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await FirebaseFirestore.instance
        .collection('realtors')
        .doc(userProvider.uid)
        .update({
      'pinnedClients': FieldValue.arrayRemove([clientRef])
    });
  }

  /// Loads pinned clients from Firestore and caches them.
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

  /// Caches the list of pinned clients locally.
  ///
  /// [clients] is the list of client document references to cache.
  Future<void> _cacheClients(List<DocumentReference> clients) async {
    await _cacheManager.putFile(
      'pinnedClients',
      utf8.encode(jsonEncode(clients.map((e) => e.path).toList())),
    );
  }

  /// Schedules a batch update to Firestore with a delay.
  void _scheduleBatchUpdate() {
    _batchUpdateTimer?.cancel();
    _batchUpdateTimer = Timer(const Duration(seconds: 5), _performBatchUpdate);
  }

  /// Performs a batch update to Firestore with the current pinned clients list.
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

  /// Shows a dialog with client details for the given [clientRef].
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

  /// Displays an error snackbar with the given [message].
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Toggles the visibility of the search bar and manages focus.
  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
      } else {
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
            return const SizedBox.shrink();
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

  /// Builds the list of pinned clients with reorderable functionality.
  Widget _buildPinnedClientsList() {
    return _pinnedClients.isEmpty
        ? const Center(child: Text('No pinned clients'))
        : Card(
      color: Theme.of(context).colorScheme.onTertiary,
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
              if (!snapshot.hasData || snapshot.data!.data() == null) {
                return const SizedBox.shrink();
              }
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final isName = (data['firstName']?.isNotEmpty == true &&
                  data['lastName']?.isNotEmpty == true);
              return ListTile(
                title: Text(
                  isName
                      ? '${data['firstName']} ${data['lastName']}'
                      : data['contactEmail'] ?? 'Unknown Client: ${clientRef.id}',
                ),
                subtitle: isName ? Text(data['contactEmail'] ?? '') : null,
                trailing: _showSearchBar
                    ? IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
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

  /// Builds the header with title or search bar based on state.
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: _showSearchBar ? _buildSearchBarInHeader() : _buildTitleHeader(),
    );
  }

  /// Builds the title header with an edit button.
  Widget _buildTitleHeader() {
    return Row(
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
    );
  }

  /// Builds the search bar with autocomplete functionality.
  Widget _buildSearchBarInHeader() {
    final searchBarKey = GlobalKey();
    return RawAutocomplete<Map<String, dynamic>>(
      focusNode: _searchFocusNode,
      textEditingController: _searchController,
      optionsBuilder: _searchClients,
      displayStringForOption: (option) =>
      '${option['firstName']} ${option['lastName']}',
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (searchBarKey.currentContext != null) {
                final RenderBox box =
                searchBarKey.currentContext!.findRenderObject() as RenderBox;
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

  /// Searches for clients using Algolia, excluding already pinned clients.
  ///
  /// [textEditingValue] contains the search query.
  /// Returns a list of matching client data.
  Future<Iterable<Map<String, dynamic>>> _searchClients(
      TextEditingValue textEditingValue) async {
    if (textEditingValue.text.isEmpty) return const [];
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final pinnedIds = _pinnedClients.map((ref) => ref.id).toList();
    _searcher.applyState((state) => state.copyWith(
      filterGroups: {
        algolia.FilterGroup.facet(
          filters: {
            algolia.Filter.facet('realtorId', userProvider.uid),
            ...pinnedIds.map(
                    (id) => algolia.Filter.facet('objectID', id, isNegated: true)),
          }.toSet(),
        ),
      },
      query: textEditingValue.text,
    ));
    final snapshot = await _searcher.responses.first;
    return snapshot.hits.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Adds a client to the pinned list and updates cache and Firestore.
  ///
  /// [option] contains the client data from the search result.
  void _addClientToPin(Map<String, dynamic> option) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final clientRef =
    FirebaseFirestore.instance.doc('investors/${option['objectID']}');
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

  /// Builds the UI for search autocomplete options.
  ///
  /// [context] is the build context.
  /// [onSelected] is the callback when an option is selected.
  /// [options] is the list of search results.
  Widget _buildSearchOptions(
      BuildContext context,
      AutocompleteOnSelected<Map<String, dynamic>> onSelected,
      Iterable<Map<String, dynamic>> options,
      ) {
    final double availableWidth = 300;
    final double maxHeight = MediaQuery.of(context).size.height * 0.5;
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: availableWidth,
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
                      : option['contactEmail'] ??
                      'Unknown Client: ${option['objectID']}',
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