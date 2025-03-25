import 'package:flutter/material.dart';

class ClientDetailsDrawer extends StatelessWidget {
  final Map<String, dynamic> client;
  final VoidCallback onClose;
  final bool isSmallScreen = false;

  const ClientDetailsDrawer({
    Key? key,
    required this.client,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = '${client['firstName']} ${client['lastName'] ?? ''}';
    final email = client['contactEmail'] ?? 'N/A';
    final phone = client['contactPhone'] ?? 'N/A';
    final profilePicUrl = client['profilePicUrl'] ?? '';
    final notes = client['notes'] ?? '';
    final createdAt = client['createdAt'] as DateTime? ?? DateTime.now();
    final status = client['status'] ?? 'inactive';
    final isSmallScreen = MediaQuery.of(context).size.width < 800;

    return isSmallScreen ? _buildMobileLayout(context, theme, name, email, phone, profilePicUrl, notes, createdAt, status)
        : _buildWebLayout(context, theme, name, email, phone, profilePicUrl, notes, createdAt, status);
  }

  Widget _buildMobileLayout(
      BuildContext context,
      ThemeData theme,
      String name,
      String email,
      String phone,
      String profilePicUrl,
      String notes,
      DateTime createdAt,
      String status,
      ) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: MediaQuery.of(context).size.width, // Full screen width for mobile
        child: Drawer(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12), // Reduced padding
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30, // Smaller avatar for mobile
                            backgroundImage: profilePicUrl.isNotEmpty
                                ? NetworkImage(profilePicUrl)
                                : const AssetImage('assets/images/profile.png') as ImageProvider,
                            backgroundColor: theme.colorScheme.surface,
                          ),
                          const SizedBox(width: 8), // Reduced spacing
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24, // Smaller font size
                                ),
                              ),
                              Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: status == 'Update'
                                      ? Colors.blue
                                      : status == 'Active'
                                      ? Colors.purple
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14, // Added font size for clarity
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12), // Reduced padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(theme, 'Contact Information'),
                        _buildInfoRow(context, Icons.email, 'Email', email),
                        _buildInfoRow(context, Icons.phone, 'Phone', '+1 $phone'),
                        const SizedBox(height: 16), // Reduced spacing
                        _buildSectionTitle(theme, 'Account Details'),
                        _buildInfoRow(
                          context,
                          Icons.calendar_today,
                          'Account Created',
                          '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        ),
                        _buildInfoRow(context, Icons.note, 'Notes', notes.isEmpty ? 'No notes' : notes),
                        const SizedBox(height: 16), // Reduced spacing
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              context,
                              icon: Icons.message,
                              label: 'Message',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Message feature coming soon!')),
                                );
                              },
                            ),
                            _buildActionButton(
                              context,
                              icon: Icons.edit,
                              label: 'Edit',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Edit feature coming soon!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout(
      BuildContext context,
      ThemeData theme,
      String name,
      String email,
      String phone,
      String profilePicUrl,
      String notes,
      DateTime createdAt,
      String status,
      ) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5, // Half screen width
        child: Drawer(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: profilePicUrl.isNotEmpty
                                ? NetworkImage(profilePicUrl)
                                : const AssetImage('assets/images/profile.png') as ImageProvider,
                            backgroundColor: theme.colorScheme.surface,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                ),
                              ),
                              Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: status == 'Update'
                                      ? Colors.blue
                                      : status == 'Active'
                                      ? Colors.purple
                                      : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onClose,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(theme, 'Contact Information'),
                        _buildInfoRow(context, Icons.email, 'Email', email),
                        _buildInfoRow(context, Icons.phone, 'Phone', '+1 $phone'),
                        const SizedBox(height: 24),
                        _buildSectionTitle(theme, 'Account Details'),
                        _buildInfoRow(
                          context,
                          Icons.calendar_today,
                          'Account Created',
                          '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        ),
                        _buildInfoRow(context, Icons.note, 'Notes', notes.isEmpty ? 'No notes' : notes),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(
                              context,
                              icon: Icons.message,
                              label: 'Message',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Message feature coming soon!')),
                                );
                              },
                            ),
                            _buildActionButton(
                              context,
                              icon: Icons.edit,
                              label: 'Edit',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Edit feature coming soon!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: isSmallScreen ? 20 : 24, // Smaller font for mobile
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 800;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: isSmallScreen ? 18 : 20, // Smaller for mobile
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: isSmallScreen ? 16 : 18), // Smaller for mobile
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onPressed,
      }) {
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}