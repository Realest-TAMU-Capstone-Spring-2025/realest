import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import 'package:realest/user_provider.dart';
import 'client_details_drawer.dart';
import 'mouse_region_provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:algolia_helper_flutter/algolia_helper_flutter.dart' as algolia;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RealtorClients extends StatefulWidget {
  const RealtorClients({Key? key}) : super(key: key);

  @override
  _RealtorClientsState createState() => _RealtorClientsState();
}

class _RealtorClientsState extends State<RealtorClients> {
  bool _isLeadExpanded = false;
  bool _isQualifiedLeadExpanded = false;
  bool _isClientExpanded = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedClientUid;

  final algolia.HitsSearcher _searcher = algolia.HitsSearcher(
    applicationID: dotenv.env['ALGOLIA_APP_ID']!,
    apiKey: dotenv.env['ALGOLIA_API_KEY']!,
    indexName: 'investors',
  );
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchUserData(); // ensure data is loaded
      if (!mounted) return; // ✅ Prevent setState on disposed widget
      _fetchClients();
    });
  }

  List<Map<String, dynamic>> _clients = [];

  Future<void> _fetchClients() async {
    // print("Fetching clients...");
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final String? realtorId = userProvider.uid;

      if (realtorId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in.';
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('investors')
          .where('realtorId', isEqualTo: realtorId)
          .get();

      final List<Map<String, dynamic>> loadedClients = snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'uid': doc.id,
            'firstName': data['firstName'] ?? '',
            'lastName': data['lastName'] ?? '',
            'contactEmail': data['contactEmail'] ?? '',
            'contactPhone': data['contactPhone'] ?? '',
            'profilePicUrl': data['profilePicUrl'] ?? '',
            'status': data['status'] ?? '',
            'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
            'notes': doc['notes'] ?? '', // ✅ Add this line
          };
        } catch (e) {
          print("Error mapping doc: $e");
          return <String, dynamic>{}; // 🔁 Return an empty map of correct type
        }
      }).toList();

      // print("Successfully fetched clients: ${loadedClients.length}");
      if (!mounted) return;
      setState(() {
        _clients = loadedClients;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch clients: $e';
      });
    }
  }

  Future<void> _addNewLeadDialog() async {
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Lead"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Add"),
            onPressed: () async {
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);
              final firstName = firstNameController.text.trim();
              final lastName = lastNameController.text.trim();
              final contact = emailController.text.trim();
              final phone = phoneController.text.trim();

              if (firstName.isNotEmpty && contact.isNotEmpty) {
                final doc = await FirebaseFirestore.instance
                    .collection('investors')
                    .add({
                  'firstName': firstName,
                  'lastName': lastName,
                  'contactEmail': contact,
                  'contactPhone': phone,
                  'status': 'lead',
                  'createdAt': Timestamp.now(),
                  'notes': '',
                  'realtorId': userProvider.uid,
                });
                Navigator.pop(context);
                _fetchClients();
              }
            },
          )
        ],
      ),
    );
  }

  //delete client
  Future<void> _deleteClient(String uid, String name) async {
    // Show confirmation dialog
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("This action cannot be undone."),
            Text("Are you sure you want to delete this lead?"),
            const SizedBox(height: 12),
            // name of the lead
            Text("${name}",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('investors')
                  .doc(uid)
                  .delete();
              //updaate the client list without calling the fetch clients
              setState(() {
                _clients.removeWhere((client) => client['uid'] == uid);
              });
              Navigator.pop(context, true);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  //client details dialog
  void _showClientDetails(String uid) {
    final isWide = MediaQuery.of(context).size.width >= 1000;
    if (isWide) {
      setState(() => _selectedClientUid = uid);
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 500,
            child: ClientDetailsDrawer(
              clientUid: uid,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildNewLeadCard(Map<String, dynamic> client) {
    final theme = Theme.of(context);
    final uid = client['uid'];
    final String fullName = '${client['firstName']} ${client['lastName']}';
    final String email = client['contactEmail'] ?? 'No email';
    final String phone = client['contactPhone']?.isNotEmpty == true
        ? '+1 ${client['contactPhone']}'
        : 'No phone';
    final TextEditingController notesController =
    TextEditingController(text: client['notes']);

    return InkWell(
      onTap: () => _showClientDetails(uid),
      child: Card(
        color: Theme.of(context).colorScheme.onTertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: client['profilePicUrl'].isNotEmpty
                        ? NetworkImage(client['profilePicUrl'])
                        : const AssetImage('assets/images/profile.png') as ImageProvider,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          fullName,
                          style: theme.textTheme.titleMedium,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.email, size: 16, color: theme.hintColor),
                            const SizedBox(width: 4),
                            Text(
                              email,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone, size: 16, color: theme.hintColor),
                            const SizedBox(width: 4),
                            Text(
                              phone,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildQualifiedLeadCard(Map<String, dynamic> client) {
    final theme = Theme.of(context);
    final uid = client['uid'];
    final String fullName = '${client['firstName']} ${client['lastName']}';
    final String email = client['contactEmail'] ?? 'No email';
    final String phone = client['contactPhone']?.isNotEmpty == true
        ? '+1 ${client['contactPhone']}'
        : 'No phone';

    return InkWell(
      onTap: () => _showClientDetails(uid),
      child: Card(
        color: theme.colorScheme.onTertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: client['profilePicUrl'].isNotEmpty
                    ? NetworkImage(client['profilePicUrl'])
                    : const AssetImage('assets/images/profile.png') as ImageProvider,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 24,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(fullName, style: theme.textTheme.titleMedium),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.email, size: 16, color: theme.hintColor),
                        const SizedBox(width: 4),
                        Text(email, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone, size: 16, color: theme.hintColor),
                        const SizedBox(width: 4),
                        Text(phone, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client) {
    final theme = Theme.of(context);
    final uid = client['uid'];
    final String fullName = '${client['firstName']} ${client['lastName']}';
    final String email = client['contactEmail'] ?? 'No email';
    final String phone = client['contactPhone']?.isNotEmpty == true
        ? '+1 ${client['contactPhone']}'
        : 'No phone';

    return Card(
      color:  Theme.of(context).colorScheme.onTertiary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      elevation: 2,
      child: InkWell(
        onTap: () => _showClientDetails(uid),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: client['profilePicUrl'].isNotEmpty
                    ? NetworkImage(client['profilePicUrl'])
                    : const AssetImage('assets/images/profile.png') as ImageProvider,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 24,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      fullName,
                      style: theme.textTheme.titleMedium,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.email, size: 16, color: theme.hintColor),
                        const SizedBox(width: 4),
                        Text(
                          email,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone, size: 16, color: theme.hintColor),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }

// Updated tags management dialog with color picker
  Future<void> _showTagsManagementDialog() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final realtorId = userProvider.uid;

    final tagsSnapshot = await FirebaseFirestore.instance
        .collection('realtors')
        .doc(realtorId)
        .collection('tags')
        .get();

    List<QueryDocumentSnapshot> tagsDocs = tagsSnapshot.docs;

    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController tagController = TextEditingController();
        Color selectedColor = Colors.blue; // default color

        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: const Text("Manage Tags"),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: tagsDocs.map((doc) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(doc['color']),
                          ),
                          title: Text(doc['name']),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('realtors')
                                  .doc(realtorId)
                                  .collection('tags')
                                  .doc(doc.id)
                                  .delete();
                              Navigator.pop(context);
                              _showTagsManagementDialog();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  TextField(
                    controller: tagController,
                    decoration: const InputDecoration(
                      labelText: "New Tag Name",
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("Pick Color:", style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Select Tag Color'),
                              content: SingleChildScrollView(
                                child: ColorPicker(
                                  pickerColor: selectedColor,
                                  onColorChanged: (color) {
                                    setModalState(() {
                                      selectedColor = color;
                                    });
                                  },
                                ),
                              ),
                              actions: [
                                ElevatedButton(
                                  child: const Text('Done'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: selectedColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text("Add Tag"),
                onPressed: () async {
                  final name = tagController.text.trim();
                  if (name.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('realtors')
                        .doc(realtorId)
                        .collection('tags')
                        .add({
                      'name': name,
                      'color': selectedColor.value,
                      'investors': [],
                    });
                    Navigator.pop(context);
                    _showTagsManagementDialog();
                  }
                },
              ),
            ],
          );
        });
      },
    );
  }

  Future<Iterable<Map<String, dynamic>>> _searchClients(
      TextEditingValue textEditingValue) async {
    if (textEditingValue.text.isEmpty) return const [];

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final realtorId = userProvider.uid;

    _searcher.applyState((state) => state.copyWith(
          filterGroups: {
            algolia.FilterGroup.facet(
              filters: {
                algolia.Filter.facet('realtorId', realtorId),
              }.toSet(),
            ),
          },
          query: textEditingValue.text,
        ));

    final snapshot = await _searcher.responses.first;
    return snapshot.hits.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Widget _buildSearchOptions(
      BuildContext context,
      AutocompleteOnSelected<Map<String, dynamic>> onSelected,
      Iterable<Map<String, dynamic>> options) {
    final double availableWidth = 300;

    final double maxHeight = MediaQuery.of(context).size.height * 0.5;

    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        child: Container(
          width: availableWidth,
          constraints: BoxConstraints(maxHeight: maxHeight),
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
                    final isName = (option['firstName']?.isNotEmpty == true &&
                        option['lastName']?.isNotEmpty == true);
                    return ListTile(
                      title: Text(
                        (isName)
                            ? '${option['firstName']} ${option['lastName']}'
                            : option['contactEmail'] ?? 'Unknown Client',
                      ),
                      subtitle:
                          (isName) ? Text(option['contactEmail'] ?? '') : null,
                      onTap: () => onSelected(option),
                    );
                  },
                ),
        ),
      ),
    );
  }

  // 🟩 Search Bar
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: RawAutocomplete<Map<String, dynamic>>(
            focusNode: _searchFocusNode,
            textEditingController: _searchController,
            optionsBuilder: _searchClients,
            displayStringForOption: (option) =>
            '${option['firstName'] ?? ''} ${option['lastName'] ?? ''}',
            fieldViewBuilder: (context, controller, focusNode, _) {
              return TextField(
                autofillHints: const [AutofillHints.name],
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  hintText: 'Search clients...',
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) =>
                _buildSearchOptions(context, onSelected, options),
            onSelected: (option) {
              _showClientDetails(option['objectID']);
            },
          ),
        ),
      ],
    );
  }

// 🟦 Leads Panel
  Widget _buildLeadsPanel() {
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _isLeadExpanded = !_isLeadExpanded;
        });
      },
      children: [
        ExpansionPanel(
          headerBuilder: (context, isExpanded) {
            return ListTile(
              title: Row(
                children: [
                  const Text("New Leads",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      onPressed: _addNewLeadDialog, icon: const Icon(Icons.add))
                ],
              ),
            );
          },
          body: Builder(
            builder: (context) {
              final leadClients = _clients
                  .where((client) => client['status'] == 'lead')
                  .toList();

              return leadClients.isEmpty
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('No leads available.',
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic)),
              )
                  : Column(
                children:
                leadClients.map<Widget>(_buildNewLeadCard).toList(),
              );
            },
          ),
          isExpanded: _isLeadExpanded,
          canTapOnHeader: true,
        ),
      ],
    );
  }

// 🟧 Qualified Leads Panel
  Widget _buildQualifiedLeadsPanel() {
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _isQualifiedLeadExpanded = !_isQualifiedLeadExpanded;
        });
      },
      children: [
        ExpansionPanel(
          headerBuilder: (context, isExpanded) {
            return const ListTile(
              title: Text("Qualified Leads",
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            );
          },
          body: Builder(
            builder: (context) {
              final qualifiedClients = _clients
                  .where((client) => client['status'] == 'qualified-lead')
                  .toList();

              return qualifiedClients.isEmpty
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('No qualified leads available.',
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic)),
              )
                  : Column(
                children: qualifiedClients
                    .map<Widget>(_buildQualifiedLeadCard)
                    .toList(),
              );
            },
          ),
          isExpanded: _isQualifiedLeadExpanded,
          canTapOnHeader: true,
        ),
      ],
    );
  }

// 🟨 Clients Panel
  Widget _buildClientsPanel() {
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          _isClientExpanded = !_isClientExpanded;
        });
      },
      children: [
        ExpansionPanel(
          headerBuilder: (context, isExpanded) {
            return ListTile(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Clients",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: _showTagsManagementDialog,
                  ),
                ],
              ),
            );
          },
          body: Builder(
            builder: (context) {
              final clientList = _clients
                  .where((client) => client['status'] == 'client')
                  .toList();

              return clientList.isEmpty
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('No clients yet.',
                    style: TextStyle(
                        color: Colors.grey, fontStyle: FontStyle.italic)),
              )
                  : Column(
                children:
                clientList.map<Widget>(_buildClientCard).toList(),
              );
            },
          ),
          isExpanded: _isClientExpanded,
          canTapOnHeader: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1000;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MouseRegionProvider()),
      ],
      child: Scaffold(
        body: Row(
          children: [
            // LEFT PANEL: Main content (Client management, panels, etc.)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text("Client Management",
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 16),
                      _buildSearchBar(),
                      const SizedBox(height: 24),
                      _buildLeadsPanel(),
                      const SizedBox(height: 15),
                      _buildQualifiedLeadsPanel(),
                      const SizedBox(height: 15),
                      _buildClientsPanel(),
                    ],
                  ),
                ),)
              ),
            ),

            // RIGHT PANEL: Client Details (only on wide screen)
            if (isWide && _selectedClientUid != null)
              Container(
                width: 500,
                child: KeyedSubtree(
                  key: ValueKey(_selectedClientUid),
                  child: ClientDetailsDrawer(
                    clientUid: _selectedClientUid!,
                    onClose: () => setState(() => _selectedClientUid = null),
                    onStatusChange: (clientId, newStatus) {
                      final index = _clients.indexWhere((c) => c['uid'] == clientId);
                      if (index != -1) {
                        setState(() {
                          _clients[index]['status'] = newStatus;
                        });
                      }
                    },
                    onDelete: _deleteClient, // 👈 pass the parent’s method
                  ),

                ),
              ),
          ],
        ),
      ),
    );
  }
}
