import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore
import '../../../../realtor_user_provider.dart';
import 'client_details_drawer.dart';
import 'mouse_region_provider.dart';
import 'email_service.dart';

class RealtorClients extends StatefulWidget {
  const RealtorClients({Key? key}) : super(key: key);

  @override
  _RealtorClientsState createState() => _RealtorClientsState();
}

class _RealtorClientsState extends State<RealtorClients> {
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _latestFilteredClients = [];
  List<Map<String, dynamic>> _activeFilteredClients = []; // Added for Active column
  List<Map<String, dynamic>> _allFilteredClients = [];    // Added for All Clients column
  bool _isLoading = true;
  String? _errorMessage;
  Set<String> _selectedFilters = {'Account Created', 'Liked a Property', 'Responded to Message'};
  final TextEditingController _searchController = TextEditingController(); // Added search controller
  String _searchQuery = ''; // Added search query state

  @override
  void initState() {
    super.initState();
    _fetchClients(); // This will call _applyFiltersAndSearch after fetching
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
        _applyFiltersAndSearch();
      });
    });
    _applyFiltersAndSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchClients() async {
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
          _errorMessage = 'User not logged in. Please log in to view clients.';
        });
        return;
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('investors')
          .where('realtorId', isEqualTo: realtorId)
          .get();

      final clients = querySnapshot.docs.map((doc) {
        return {
          'firstName': doc['firstName'] ?? 'Unknown',
          'lastName': doc['lastName'] ?? '',
          'contactEmail': doc['contactEmail'] ?? 'N/A',
          'contactPhone': doc['contactPhone'] ?? 'N/A',
          'profilePicUrl': doc['profilePicUrl'] ?? '',
          'createdAt': doc['createdAt']?.toDate() ?? DateTime.now(),
          'status': doc['status'] ?? 'inactive',
          'notes': doc['notes'] ?? '',
        };
      }).toList();

      clients.sort((a, b) => b['createdAt'].compareTo(a['createdAt']));

      setState(() {
        _clients = clients;
        _applyFiltersAndSearch(); // This ensures filters are applied immediately
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load clients: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load clients: $e')),
      );
    }
  }

  void _applyFiltersAndSearch() {
    var filteredClients = _clients.where((client) {
      final fullName = '${client['firstName']} ${client['lastName']}'.toLowerCase();
      final email = (client['contactEmail'] as String).toLowerCase();
      return _searchQuery.isEmpty ||
          fullName.contains(_searchQuery) ||
          email.contains(_searchQuery);
    }).toList();

    // Modified to show all Update clients when all filters are selected
    if (_selectedFilters.length == 3) { // All filters selected
      _latestFilteredClients = filteredClients.where((c) => c['status'] == 'Update').toList();
    } else if (_selectedFilters.isEmpty) {
      _latestFilteredClients = []; // Show nothing when no filters selected
    } else {
      _latestFilteredClients = filteredClients.where((client) {
        final notes = client['notes'] as String;
        final isUpdated = client['status'] == 'Update';
        return isUpdated && _selectedFilters.contains(notes);
      }).toList();
    }

    _activeFilteredClients = filteredClients
        .where((c) => c['status'] == 'Update' || c['status'] == 'Active')
        .toList();

    _allFilteredClients = filteredClients.toList();
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
      _applyFiltersAndSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchRealtorData();
    });

    return MultiProvider(
        providers: [
        ChangeNotifierProvider(create: (_) => MouseRegionProvider()),
    ],
    child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Your Clients',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final invitationCode = userProvider.invitationCode ?? 'Loading...';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              invitationCode,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 18,
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                size: 14,
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: invitationCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invitation code copied to clipboard!')),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        Text(
                          'Invitation Code',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    );
                  },
                ),
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
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search clients...',
                            prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildFilterButton(
                        context,
                        'Filters',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('More filters coming soon!')),
                          );
                        },
                        icon: Icons.filter_list,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: inviteClientsButton(
                      onPressed: () => _showInviteDialog(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildClientColumn(
                      context,
                      'Update',
                      _latestFilteredClients,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildClientColumn(
                      context,
                      'Active',
                      _activeFilteredClients,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildClientColumn(
                      context,
                      'All Clients',
                      _allFilteredClients,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }


  Widget _buildFilterIconButton(String filter, IconData icon, Color color) {
    final isSelected = _selectedFilters.contains(filter);

    return GestureDetector(
      onTap: () => _toggleFilter(filter),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[300], // Original color when selected, grey when unselected
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 24,
          color: Colors.white, // Always white
        ),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, String label, {VoidCallback? onPressed, IconData? icon}) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: onPressed ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label filter applied')),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
  }

  Widget inviteClientsButton({required VoidCallback onPressed}) {
    return Builder(
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text('Invite Clients'),
            ],
          ),
        );
      },
    );
  }

  void _showInviteDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Invite Clients',
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter client\'s email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (emailController.text.isNotEmpty) {
                        final userProvider = Provider.of<UserProvider>(context, listen: false);
                        final invitationCode = userProvider.invitationCode ?? 'N/A';
                        // Use the new EmailService
                        await EmailService.sendInviteEmail(
                          emailController.text,
                          invitationCode,
                          context,
                        );
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter an email address')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Send Invite', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Share this invitation code and ask them to install our app:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    final invitationCode = userProvider.invitationCode ?? 'Loading...';
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          invitationCode,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.copy,
                            color: theme.colorScheme.onSurface,
                          ),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: invitationCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invitation code copied to clipboard!')),
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildClientColumn(BuildContext context, String title, List<Map<String, dynamic>> clients) {
    final theme = Theme.of(context);
    final isLightTheme = theme.brightness == Brightness.light;

    Color titleColor;
    switch (title) {
      case 'Update':
        titleColor = isLightTheme ? Colors.blue : Colors.blueAccent;
        break;
      case 'Active':
        titleColor = isLightTheme ? Colors.purple : Colors.purpleAccent;
        break;
      case 'All Clients':
        titleColor = isLightTheme ? Colors.green : Colors.greenAccent;
        break;
      default:
        titleColor = theme.colorScheme.onSurface;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 8.0, right: 8.0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: titleColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (title == 'Update') ...[
                      _buildFilterIconButton('Account Created', Icons.account_circle, Colors.green),
                      const SizedBox(width: 8),
                      _buildFilterIconButton('Liked a Property', Icons.business, Colors.red),
                      const SizedBox(width: 8),
                      _buildFilterIconButton('Responded to Message', Icons.message, Colors.blue),
                      const SizedBox(width: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${clients.length} clients',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                final name = '${client['firstName']} ${client['lastName'] ?? ''}';
                final email = client['contactEmail'] ?? 'N/A';
                final phone = client['contactPhone'] ?? 'N/A';
                final profilePicUrl = client['profilePicUrl'] ?? '';
                final notes = client['notes'] ?? '';
                final uniqueKey = '$title-$index';

                Color tagColor;
                IconData tagIcon;
                switch (notes) {
                  case 'Account Created':
                    tagColor = Colors.green;
                    tagIcon = Icons.account_circle;
                    break;
                  case 'Liked a Property':
                    tagColor = Colors.red;
                    tagIcon = Icons.business;
                    break;
                  case 'Responded to Message':
                    tagColor = Colors.blue;
                    tagIcon = Icons.message;
                    break;
                  default:
                    tagColor = Colors.grey;
                    tagIcon = Icons.info;
                }

                return Consumer<MouseRegionProvider>(
                  builder: (context, mouseProvider, child) {
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => mouseProvider.setHover(uniqueKey, true),
                      onExit: (_) => mouseProvider.setHover(uniqueKey, false),
                      child: GestureDetector(
                        onTap: () {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Close',
                            barrierColor: Colors.grey.withOpacity(0.5),
                            transitionDuration: const Duration(milliseconds: 300),
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return Stack(
                                children: [
                                  ClientDetailsDrawer(
                                    client: client,
                                    onClose: () => Navigator.of(context).pop(),
                                  ),
                                ],
                              );
                            },
                            transitionBuilder: (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              );
                            },
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: mouseProvider.isHovered(uniqueKey)
                                ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 2.0,
                            )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          transform: Matrix4.identity()
                            ..scale(
                              mouseProvider.isHovered(uniqueKey) ? 1.04 : 1.0,
                            ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundImage: profilePicUrl.isNotEmpty
                                    ? NetworkImage(profilePicUrl)
                                    : const AssetImage('assets/images/profile.png') as ImageProvider,
                                backgroundColor: theme.colorScheme.surface,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (notes.isNotEmpty && title == 'Update')
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: tagColor,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  tagIcon,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  notes,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '+1 $phone',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}