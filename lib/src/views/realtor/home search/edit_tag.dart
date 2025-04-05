import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:realest/user_provider.dart';

class EditTagWidget extends StatefulWidget {
  final Map<String, dynamic> tag;
  final String tagId;

  const EditTagWidget({Key? key, required this.tag, required this.tagId})
      : super(key: key);

  @override
  _EditTagWidgetState createState() => _EditTagWidgetState();
}

class _EditTagWidgetState extends State<EditTagWidget> {
  late TextEditingController _tagNameController;
  late Color _selectedColor;
  late List<String> _selectedInvestorIds;

  @override
  void initState() {
    super.initState();
    _tagNameController = TextEditingController(text: widget.tag['name'] ?? '');
    if (widget.tag['color'] is int) {
      _selectedColor = Color(widget.tag['color']);
    } else if (widget.tag['color'] is String) {
      final hexCode = widget.tag['color'].replaceAll('#', '');
      _selectedColor = Color(int.parse('FF$hexCode', radix: 16));
    } else {
      _selectedColor = Colors.blue;
    }
    _selectedInvestorIds = List<String>.from(widget.tag['investors'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final clients = userProvider.clients;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Edit Tag",
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _tagNameController,
                  decoration: const InputDecoration(labelText: "Tag Name"),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text("Pick Color:"),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showColorPicker,
                      child: CircleAvatar(
                        backgroundColor: _selectedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Select Clients for this Tag:"),
                // Wrap the client list in a container with a max height constraint.
                Container(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      final clientId = client['id'];
                      final isSelected = _selectedInvestorIds.contains(clientId);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: client['profilePicUrl'] != null
                              ? NetworkImage(client['profilePicUrl'])
                              : null,
                          child: client['profilePicUrl'] == null
                              ? Text(
                              client['name'] != null && client['name'].isNotEmpty
                                  ? client['name'][0].toUpperCase()
                                  : 'C')
                              : null,
                        ),
                        title: Text(client['name'] ?? 'Unnamed Client'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                client['email'] ?? 'No Email',
                                softWrap: false,
                              ),
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                client['contactPhone'] ?? 'No Phone',
                                softWrap: false,
                              ),
                            ),
                          ],
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedInvestorIds.add(clientId);
                              } else {
                                _selectedInvestorIds.remove(clientId);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: _editTag,
                      child: const Text("Save"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = _selectedColor;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select Tag Color'),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: _selectedColor,
                    onColorChanged: (color) {
                      tempColor = color;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  child: const Text('Done'),
                  onPressed: () {
                    setState(() {
                      _selectedColor = tempColor;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editTag() async {
    final tagName = _tagNameController.text.trim();
    if (tagName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tag name cannot be empty.")),
      );
      return;
    }
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final realtorId = userProvider.uid;
    if (realtorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in.")),
      );
      return;
    }
    await FirebaseFirestore.instance
        .collection('realtors')
        .doc(realtorId)
        .collection('tags')
        .doc(widget.tagId)
        .update({
      'name': tagName,
      'color': _selectedColor.value,
      'investors': _selectedInvestorIds,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tag updated successfully.")),
    );
    await userProvider.fetchUserData();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _tagNameController.dispose();
    super.dispose();
  }
}
