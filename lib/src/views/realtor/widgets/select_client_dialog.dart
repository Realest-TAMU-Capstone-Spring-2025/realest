import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realest/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SelectClientDialog extends StatefulWidget {
  final Function(List<String>) onClientsSelected;
  final Map<String, dynamic> property;

  const SelectClientDialog({
    Key? key,
    required this.onClientsSelected,
    required this.property,
  }) : super(key: key);

  @override
  _SelectClientDialogState createState() => _SelectClientDialogState();
}

class _SelectClientDialogState extends State<SelectClientDialog> {
  List<String> selectedClientIds = [];
  String searchQuery = '';
  List<Map<String, dynamic>> filteredClients = [];
  List<Map<String, dynamic>> selectedTags = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          maxWidth: 400,
        ),
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.clients.isEmpty && userProvider.userRole == 'realtor') {
              userProvider.fetchUserData();
              return const Center(child: CircularProgressIndicator());
            }

            if (userProvider.clients.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("No clients available."),
              );
            }

            filteredClients = userProvider.clients.where((client) {
              final name = client['name']?.toLowerCase() ?? '';
              final email = client['email']?.toLowerCase() ?? '';
              final query = searchQuery.toLowerCase();
              return name.contains(query) || email.contains(query);
            }).toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search clients...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.filter_list),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Filters coming soon!')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      userProvider.tags.isEmpty
                          ? const Text('No tags available.')
                          : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: userProvider.tags.map((tag) {
                          final tagColor = _parseColor(tag['color']);
                          final isSelected = selectedTags.contains(tag);
                          return ChoiceChip(
                            label: Text(
                              tag['name'] ?? 'Unnamed Tag',
                              style: TextStyle(
                                color: isSelected
                                    ? (tagColor.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white)
                                    : Colors.black,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: tagColor,
                            backgroundColor: tagColor.withOpacity(0.3),
                            onSelected: (bool selected) {
                              setState(() {
                                if (selected) {
                                  selectedTags.add(tag);
                                  _updateSelectedClientsFromTags();
                                } else {
                                  selectedTags.remove(tag);
                                  _updateSelectedClientsFromTags();
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];
                      final isSelected = selectedClientIds.contains(client['id']);
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: client['profilePicUrl'] != null
                              ? NetworkImage(client['profilePicUrl'])
                              : null,
                          child: client['profilePicUrl'] == null
                              ? Text(
                            client['name']?.isNotEmpty == true
                                ? client['name'][0].toUpperCase()
                                : 'C',
                            style: const TextStyle(fontSize: 20),
                          )
                              : null,
                        ),
                        title: Text(client['name'] ?? 'Unnamed Client'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(client['email'] ?? 'No email'),
                            Text(
                              client['contactPhone']?.isNotEmpty == true
                                  ? client['contactPhone']
                                  : 'No number',
                            ),
                          ],
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedClientIds.add(client['id']);
                                _checkAndRemoveTags();
                              } else {
                                selectedClientIds.remove(client['id']);
                                _checkAndRemoveTags();
                              }
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedClientIds.remove(client['id']);
                              _checkAndRemoveTags();
                            } else {
                              selectedClientIds.add(client['id']);
                              _checkAndRemoveTags();
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: selectedClientIds.isEmpty
                            ? null
                            : () {
                          _showConfirmationDialog(context, userProvider);
                        },
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, UserProvider userProvider) {
    final currencyFormat = NumberFormat("#,##0", "en_US");
    final primaryPhoto = widget.property["primary_photo"]?.toString().isNotEmpty == true
        ? widget.property["primary_photo"].toString().replaceAll("http://", "https://")
        : "https://bearhomes.com/wp-content/uploads/2019/01/default-featured.png";
    final address = widget.property["full_street_line"]?.toString() ?? "N/A";
    final price = widget.property["list_price"] != null
        ? "\$${currencyFormat.format(widget.property["list_price"])}"
        : "N/A";

    print("Showing confirmation dialog...");
    print("Property Data: ${widget.property}");
    print("Primary Photo: $primaryPhoto");
    print("Address: $address");
    print("Price: $price");
    print("Selected Clients: $selectedClientIds");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Sending Property'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: primaryPhoto,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) {
                        print("CachedNetworkImage error: $error");
                        return Image.asset(
                          'assets/images/property.jpg', // make sure this image is available in your assets
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  )
                ),
                const SizedBox(height: 12),
                Text(
                  address,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Price: $price',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sending to:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (selectedClientIds.isEmpty)
                  const Text("No clients selected.")
                else
                  ...selectedClientIds.map((clientId) {
                    final client = userProvider.clients.firstWhere(
                          (c) => c['id'] == clientId,
                      orElse: () => {'name': 'Unknown Client', 'id': clientId},
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage: client['profilePicUrl'] != null
                                ? NetworkImage(client['profilePicUrl'])
                                : null,
                            child: client['profilePicUrl'] == null
                                ? Text(
                              client['name']?.isNotEmpty == true
                                  ? client['name'][0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(fontSize: 16),
                            )
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(client['name'] ?? 'Unnamed Client')),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print("Cancel pressed");
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                print("Confirm pressed");
                widget.onClientsSelected(selectedClientIds);
                Navigator.pop(dialogContext); // Close confirmation dialog
                Navigator.pop(context); // Close SelectClientDialog
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    ).then((_) {
      print("Confirmation dialog closed");
    }).catchError((error) {
      print("Error showing confirmation dialog: $error");
    });
  }

  void _updateSelectedClientsFromTags() {
    selectedClientIds.clear();
    for (var tag in selectedTags) {
      final tagInvestorIds = List<String>.from(tag['investors'] ?? []);
      for (var client in filteredClients) {
        if (tagInvestorIds.contains(client['id']) && !selectedClientIds.contains(client['id'])) {
          selectedClientIds.add(client['id']);
        }
      }
    }
  }

  void _checkAndRemoveTags() {
    final tagsToCheck = List<Map<String, dynamic>>.from(selectedTags);
    for (var tag in tagsToCheck) {
      final tagInvestorIds = List<String>.from(tag['investors'] ?? []);
      final selectedTagClients = tagInvestorIds.where((id) => selectedClientIds.contains(id)).toList();
      if (selectedTagClients.length != tagInvestorIds.length ||
          selectedClientIds.length > tagInvestorIds.length) {
        selectedTags.remove(tag);
      }
    }
  }

  Color _parseColor(dynamic colorValue) {
    try {
      if (colorValue is String) {
        final hexCode = colorValue.replaceAll('#', '');
        return Color(int.parse('FF$hexCode', radix: 16));
      } else if (colorValue is int) {
        return Color(colorValue);
      } else {
        return Colors.grey;
      }
    } catch (e) {
      return Colors.grey;
    }
  }
}