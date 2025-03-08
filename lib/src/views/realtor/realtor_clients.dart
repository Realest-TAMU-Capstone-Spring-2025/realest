import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:provider/provider.dart'; // For UserProvider
import 'package:mailer/mailer.dart'; // For sending emails
import 'package:mailer/smtp_server/gmail.dart'; // For Gmail SMTP
import '../../../user_provider.dart'; // Assuming this is the file with UserProvider

class RealtorClients extends StatelessWidget {
  const RealtorClients({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Fetch realtor data when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchRealtorData();
    });

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First Row: "Clients" Title with Invitation Code
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
                                size: 20,
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

            // Second Row: Two Columns (Search/Filters and Invite Clients)
            Row(
              children: [
                // First Column: Search Bar and Filters
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      // Search Bar
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search clients...',
                            prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface),
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildFilterButton(context, 'Active'),
                      const SizedBox(width: 8),
                      _buildFilterButton(context, 'Pending'),
                      const SizedBox(width: 8),
                      _buildFilterButton(context, 'Closed'),
                      const SizedBox(width: 8),
                      _buildFilterButton(
                        context,
                        'More Filters',
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
                // Second Column: Invite Clients Button
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: inviteClientsButton(
                      onPressed: () => _showInviteDialog(context), // Show dialog on press
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Third Row: Three Columns with Background Colors and Rounded Corners
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Latest Updated Clients
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildClientColumn(context, 'Latest', [
                        'Client A - Updated 03/07/25',
                        'Client B - Updated 03/06/25',
                      ]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Current Clients
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildClientColumn(context, 'Current', [
                        'Client C - Active',
                        'Client D - Active',
                      ]),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // All Clients
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildClientColumn(context, 'All Clients', [
                        'Client A',
                        'Client B',
                        'Client C',
                        'Client D',
                        'Client E',
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build filter buttons
  Widget _buildFilterButton(BuildContext context, String label, {VoidCallback? onPressed, IconData? icon}) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: onPressed ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$label filter applied')),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.cardColor,
        foregroundColor: theme.colorScheme.onSurface,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        textStyle: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: theme.colorScheme.onSurface),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );
  }

  // New InviteClientsButton widget
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            textStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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

  // Method to send email using Gmail SMTP
  Future<void> _sendInviteEmail(String clientEmail, String invitationCode, BuildContext context) async {
    const String username = 'eshwarreddygadi@gmail.com'; // Your Gmail address
    const String password = 'quoc epui gwdl sujg'; // Replace with your Gmail App Password

    final smtpServer = gmail(username, password); // Gmail SMTP server

    final message = Message()
      ..from = const Address(username, 'Realtor App')
      ..recipients.add(clientEmail)
      ..subject = 'Invitation to Join Realtor App'
      ..text = '''
Dear Client,

You have been invited to join the Realtor App! Please follow these steps to get started:

1. Download and install the Realtor App from the Google Play Store or Apple App Store.
2. Create an account using your email address.
3. Enter the following invitation code to log in and access all features:

Invitation Code: $invitationCode

We look forward to having you on board!

Best regards,
The Realtor App Team
''';

    try {
      final sendReport = await send(message, smtpServer);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invite successfully sent to $clientEmail')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send invite: $e')),
      );
    }
  }

  // Method to show the invite dialog
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
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email input section
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: 'Enter client\'s email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (emailController.text.isNotEmpty) {
                        final userProvider = Provider.of<UserProvider>(context, listen: false);
                        final invitationCode = userProvider.invitationCode ?? 'N/A';
                        await _sendInviteEmail(emailController.text, invitationCode, context);
                        Navigator.of(context).pop(); // Close dialog
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
                    child: const Text('Send Invite'),
                  ),
                ),
                const SizedBox(height: 16),
                // Invitation code section
                Text(
                  'Share this invitation code and ask them to install our app:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
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

  // Helper method to build client columns
  Widget _buildClientColumn(BuildContext context, String title, List<String> clients) {
    final theme = Theme.of(context);
    final isLightTheme = theme.brightness == Brightness.light;

    // Determine title color and dot color based on title
    Color titleColor;
    switch (title) {
      case 'Latest':
        titleColor = isLightTheme ? Colors.blue : Colors.blueAccent;
        break;
      case 'Current':
        titleColor = isLightTheme ? Colors.purple : Colors.purpleAccent;
        break;
      case 'All Clients':
        titleColor = isLightTheme ? Colors.green : Colors.greenAccent;
        break;
      default:
        titleColor = theme.colorScheme.onSurface;
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: clients.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
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
                  );
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  padding: const EdgeInsets.all(16),
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
                  child: Text(
                    clients[index - 1],
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}