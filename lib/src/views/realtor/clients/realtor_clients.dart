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
import 'package:realest/src/views/realtor/clients/client_details_drawer.dart';



class RealtorClients extends StatefulWidget {
  const RealtorClients({Key? key}) : super(key: key);

  @override
  _RealtorClientsState createState() => _RealtorClientsState();
}

class _RealtorClientsState extends State<RealtorClients> {
  bool _isLeadExpanded = true;
  bool _isQualifiedLeadExpanded = true;
  bool _isClientExpanded = true;
  bool _isLoading = false;
  String? _errorMessage;
  final algolia.HitsSearcher _searcher = algolia.HitsSearcher(
    applicationID: dotenv.env['ALGOLIA_APP_ID']!,
    apiKey: dotenv.env['ALGOLIA_API_KEY']!,
    indexName: 'investors',
  );
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  double _searchBarWidth = 0;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.fetchUserData(); // ensure data is loaded
        _fetchClients(); // only fetch clients after uid is available
      });


  }

  List<Map<String, dynamic>> _clients = [];

  Widget _buildFilterButton(BuildContext context, String label, {VoidCallback? onPressed, IconData? icon}) {
    return ElevatedButton.icon(
      icon: Icon(Icons.tune, size: 20),
      label: Text("More", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
        minimumSize: Size(160, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: showFilterDrawer,
    );
  }

  void showFilterDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Filters",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext dialogContext, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            color: Colors.white,
            child: Container(
              width: 400,
              height: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: StatefulBuilder(
                builder: (context, setModalState) =>
                    _buildFilterContent(setModalState, dialogContext), // pass outer context
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim1),
          child: child,
        );
      },
    );
  }

  Widget _buildFilterContent(void Function(void Function()) setModalState, BuildContext dialogContext) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Filters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),


              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Apply"),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

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
      setState(() {
        _clients = loadedClients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch clients: $e';
      });
    }
  }

  Future<void> _updateClientStatus(String uid, String newStatus) async {
    await FirebaseFirestore.instance.collection('investors').doc(uid).update({'status': newStatus});
    _fetchClients();
  }

  Future<void> _addNewLeadDialog() async {
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();

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
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              final firstName = firstNameController .text.trim();
              final lastName = lastNameController.text.trim();
              final contact = emailController.text.trim();
              if (firstName.isNotEmpty && contact.isNotEmpty) {
                final doc = await FirebaseFirestore.instance.collection('investors').add({
                  'firstName': firstName,
                  'lastName': lastName,
                  'contactEmail': contact,
                  'contactPhone':  '',
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

  Future<void> _deleteLead(String uid, name) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Lead"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("This action cannot be undone."),
            Text("Are you sure you want to delete this lead?"),
            const SizedBox(height: 12),
            // name of the lead
            Text("${name}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('investors').doc(uid).delete();
              _fetchClients();
              Navigator.pop(context, true);
            },
            child: const Text("Delete"),
          ),

        ],
      ),
    );


  }

  Future<void> _sendInviteEmail(Map<String, dynamic> client) async {
    //TODO: Implement email sending logic
  }

  Future<void> _acceptAsClient(String uid, String email) async {
    try {
      // Call the Cloud Function
      final result = await FirebaseFunctions.instance
          .httpsCallable('promoteClient')
          .call({'uid': uid, 'email': email});

      _fetchClients();
    } catch (e) {
      print("Error promoting client: $e");
    }
  }

  //delete client
  Future<void> _deleteClient(String uid, String name) async {
    // Show confirmation dialog
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Client"),
        content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("This action cannot be undone."),
          Text("Are you sure you want to delete this lead?"),
          const SizedBox(height: 12),
          // name of the lead
          Text("${name}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.red)),
        ],
      ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('investors').doc(uid).delete();
              //updaate the client list without calling the fetch clients
              setState(() {
                _clients.removeWhere((client) => client['uid'] == uid);
              });
              Navigator.pop(context, true);
              Navigator.pop(context, true);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  //client details dialog
  Future<void> _showClientDetailsDialog(String uid) async {
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


  Widget _buildNewLeadCard(Map<String, dynamic> client) {
    final theme = Theme.of(context);
    final uid = client['uid'];
    final TextEditingController notesController = TextEditingController(text: client['notes']);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  radius: 20,
                  backgroundImage: client['profilePicUrl'].isNotEmpty
                      ? NetworkImage(client['profilePicUrl'])
                      : const AssetImage('assets/images/profile.png') as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${client['firstName']} ${client['lastName']}', style: theme.textTheme.titleSmall),
                      Text(client['contactEmail'], style: theme.textTheme.bodySmall),
                      Text('+1 ${client['contactPhone']}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Edit Notes"),
                      content: TextField(
                        controller: notesController,
                        maxLines: 10,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                        ElevatedButton(
                          child: const Text("Save"),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('investors').doc(uid).update({'notes': notesController.text});
                            _fetchClients();
                            Navigator.pop(context);
                          },
                        )
                      ],
                    ),
                  ),
                  child: const Text("Notes"),
                ),

                ElevatedButton(
                  onPressed: () => _updateClientStatus(uid, 'qualified-lead'),
                  child: const Text("Qualify"),
                ),
                OutlinedButton(
                  onPressed: () => _deleteLead(uid, client['firstName'] + " " + client['lastName']),
                  child: const Text("Disqualify"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQualifiedLeadCard(Map<String, dynamic> client) {
    final theme = Theme.of(context);
    final uid = client['uid'];
    final TextEditingController notesController = TextEditingController(text: client['notes']);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  radius: 20,
                  backgroundImage: client['profilePicUrl'].isNotEmpty
                      ? NetworkImage(client['profilePicUrl'])
                      : const AssetImage('assets/images/profile.png') as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${client['firstName']} ${client['lastName']}', style: theme.textTheme.titleSmall),
                      Text(client['contactEmail'], style: theme.textTheme.bodySmall),
                      Text('+1 ${client['contactPhone']}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Edit Notes"),
                      content: TextField(
                        controller: notesController,
                        maxLines: 10,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                        ElevatedButton(
                          child: const Text("Save"),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('investors').doc(uid).update({'notes': notesController.text});
                            _fetchClients();
                            Navigator.pop(context);
                          },
                        )
                      ],
                    ),
                  ),
                  child: const Text("Notes"),
                ),
                ElevatedButton(
                  onPressed: () => _acceptAsClient(uid, client['contactEmail']),
                  child: const Text("Accept as Client"),
                ),
                OutlinedButton(
                  onPressed: () => _deleteLead(uid,  client['firstName'] + " " + client['lastName']),
                  child: const Text("Reject"),
                ),
                ElevatedButton(
                  onPressed: () => _sendInviteEmail(client),
                  child: const Text("Send Invite Email"),
                ),
              ],
            )

          ],
        ),
      ),
    );
  }

  Widget _buildClientCard( Map<String, dynamic> client) {
    final theme = Theme.of(context);
    final uid = client['uid'];
    final TextEditingController notesController = TextEditingController(text: client['notes']);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showClientDetailsDialog(uid);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: client['profilePicUrl'].isNotEmpty
                        ? NetworkImage(client['profilePicUrl'])
                        : const AssetImage('assets/images/profile.png') as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${client['firstName']} ${client['lastName']}', style: theme.textTheme.titleSmall),
                        Text(client['contactEmail'], style: theme.textTheme.bodySmall),
                        Text('+1 ${client['contactPhone']}', style: theme.textTheme.bodySmall),
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
  return snapshot.hits
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

Widget _buildSearchOptions(BuildContext context,
  AutocompleteOnSelected<Map<String, dynamic>> onSelected,
  Iterable<Map<String, dynamic>> options) {
  final double availableWidth = _searchBarWidth > 0 
    ? _searchBarWidth 
    : MediaQuery.of(context).size.width - 32;
  
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
                  final isName = 
                      (option['firstName']?.isNotEmpty == true &&
                          option['lastName']?.isNotEmpty == true);
                  return ListTile(
                    title: Text(
                    (isName) ? '${option['firstName']} ${option['lastName']}'
                      : option['contactEmail'] ?? 'Unknown Client',
                    ),
                    subtitle: (isName) ? Text(option['contactEmail'] ?? '') : null,
                    onTap: () => onSelected(option),
                  );
                },
              ),
      ),
    ),
  );
}

  void _showClientDetails(String clientId) {
    showDialog(
      context: context,
      builder: (context) => ClientDetailsDrawer(
        clientUid: clientId,
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUserData();
    });

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MouseRegionProvider()),
      ],
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Client Management',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: RawAutocomplete<Map<String, dynamic>>(
                                  focusNode: _searchFocusNode,
                                  textEditingController: _searchController,
                                  optionsBuilder: _searchClients,
                                  displayStringForOption: (option) =>
                                      '${option['firstName']} ${option['lastName']}',
                                  fieldViewBuilder:
                                      (context, controller, focusNode, onFieldSubmitted) {
                                    final searchBarKey = GlobalKey();
                                    return TextField(
                                      key: searchBarKey,
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        hintText: 'Search clients...',
                                        prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface),
                                        border: const OutlineInputBorder(),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      onTap: () {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (searchBarKey.currentContext != null) {
                                            // final RenderBox box = searchBarKey.currentContext!.findRenderObject() as RenderBox;
                                            // _searchBarWidth = box.size.width;
                                            setState(() {});
                                          }
                                        });
                                      },
                                    );
                                  },
                                  optionsViewBuilder: (context, onSelected, options) => 
                                      _buildSearchOptions(context, onSelected, options),
                                  onSelected: (option) {
                                    _showClientDetails(option['objectID']);
                                  },
                                )
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ExpansionPanelList(
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _isLeadExpanded = !_isLeadExpanded;
                  });
                },
                children: [
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: Row(
                          children: [
                            const Text(
                              "New Leads",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _addNewLeadDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text("Add Lead"),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },

                    body: Builder(
                      builder: (context) {
                        final leadClients = _clients.where((client) => client['status'] == 'lead').toList();

                        return leadClients.isEmpty
                            ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text(
                            'No leads available.',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        )
                            : Column(
                          children: leadClients.map<Widget>(_buildNewLeadCard).toList(),
                        );
                      },
                    ),
                    isExpanded: _isLeadExpanded,
                    canTapOnHeader: true,
                  ),
                ]),
              const SizedBox(height: 15),
              ExpansionPanelList(
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _isQualifiedLeadExpanded = !_isQualifiedLeadExpanded;
                  });
                },
                children: [
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return const ListTile(
                        title: Text(
                          "Qualified Leads",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
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
                          child: Text(
                            'No qualified leads available.',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
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
              ),
              const SizedBox(height: 15),
              ExpansionPanelList(
                expansionCallback: (int index, bool isExpanded) {
                  setState(() {
                    _isClientExpanded = !_isClientExpanded;
                  });
                },
                children: [
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Clients",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
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
                          child: Text(
                            'No clients yet.',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        )
                            : Column(
                          children: clientList.map<Widget>(_buildClientCard).toList(),
                        );
                      },
                    ),
                    isExpanded: _isClientExpanded,
                    canTapOnHeader: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }
}