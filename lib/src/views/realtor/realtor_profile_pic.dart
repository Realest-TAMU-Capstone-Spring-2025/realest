import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../user_provider.dart';

class RealtorProfilePic extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final VoidCallback onAccountSettings; // New callback to set selected index to 5

  const RealtorProfilePic({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
    required this.onAccountSettings,
  }) : super(key: key);

  void _showProfileDialog(BuildContext context) {
    // Grab user data from the provider.
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String fullName =
    '${userProvider.firstName ?? ''} ${userProvider.lastName ?? ''}'.trim();
    final String contactEmail = userProvider.contactEmail ?? '';
    final String contactPhone = userProvider.contactPhone ?? '';
    final String profilePicUrl = userProvider.profilePicUrl ?? '';
    final String agencyName = userProvider.agencyName ?? '';
    final String licenseNumber = userProvider.licenseNumber ?? '';
    final String address = userProvider.address ?? '';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5), // Grey overlay
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300, // Fixed width for the dialog
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor, // Uses your defined cardColor
                borderRadius: BorderRadius.circular(15),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile Picture at the Top
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: profilePicUrl.isNotEmpty
                          ? NetworkImage(profilePicUrl)
                          : const AssetImage('assets/images/profile.png')
                      as ImageProvider,
                      onBackgroundImageError: (_, __) {
                        debugPrint("Error loading profile picture, showing default.");
                      },
                    ),
                    const SizedBox(height: 15),
                    // User Details
                    Text(
                      fullName.isNotEmpty ? fullName : 'No Name',
                      style: theme.textTheme.bodyLarge?.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      contactEmail.isNotEmpty ? contactEmail : 'No Email',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      contactPhone.isNotEmpty ? contactPhone : 'No Phone',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.grey),
                    // Account Settings: Instead of navigating, call the callback.
                    ListTile(
                      leading: Icon(Icons.settings, color: theme.colorScheme.onSurface),
                      title: Text(
                        "Account Settings",
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        onAccountSettings();
                      },
                    ),
                    const Divider(color: Colors.grey),
                    // Notifications Toggle with Icon
                    SwitchListTile(
                      secondary: Icon(Icons.notifications, color: theme.colorScheme.onSurface),
                      title: Text(
                        "Notifications",
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                      ),
                      value: true, // Replace with your actual notification state
                      onChanged: (bool value) {
                        // Handle notifications toggle
                      },
                    ),
                    const Divider(color: Colors.grey),
                    // Dark Mode Toggle with Icon – calls global toggleTheme function.
                    SwitchListTile(
                      secondary: Icon(Icons.dark_mode, color: theme.colorScheme.onSurface),
                      title: Text(
                        "Dark Mode",
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                      ),
                      value: isDarkMode,
                      onChanged: (bool value) {
                        toggleTheme();
                      },
                    ),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 10),
                    // Log Out Button with Icon and Themed Confirmation Dialog
                    InkWell(
                      onTap: () async {
                        showDialog(
                          context: context,
                          builder: (BuildContext dialogContext) {
                            final theme = Theme.of(dialogContext);
                            final bool currentDarkMode = theme.brightness == Brightness.dark;
                            return AlertDialog(
                              backgroundColor: theme.cardColor,
                              title: Text(
                                "Confirm Logout",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                "Are you sure you want to log out?",
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  child: Text("Cancel", style: TextStyle(color: theme.colorScheme.primary)),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(dialogContext).pop();
                                    await FirebaseAuth.instance.signOut();
                                    Navigator.pushReplacementNamed(context, '/login');
                                  },
                                  child: Text(
                                    "Logout",
                                    style: TextStyle(
                                      color: currentDarkMode ? Colors.redAccent : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Row(
                        children: [
                          const SizedBox(width: 18),
                          Icon(Icons.logout, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            "Log Out",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final String profilePicUrl = userProvider.profilePicUrl ?? '';
    print("Profile Pic URL: $profilePicUrl"); // Debug print)
    return GestureDetector(
      onTap: () => _showProfileDialog(context),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[300],
        backgroundImage: profilePicUrl.isNotEmpty
            ? NetworkImage(profilePicUrl)
            : const AssetImage('assets/images/profile.png') as ImageProvider,
        onBackgroundImageError: (_, __) {
          debugPrint("Error loading profile picture, showing default.");
        },
      ),
    );
  }
}
