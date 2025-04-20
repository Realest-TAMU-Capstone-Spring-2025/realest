import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:realest/main.dart';
import '../../user_provider.dart';

class ProfilePic extends StatelessWidget {
  final VoidCallback toggleTheme;
  final VoidCallback onAccountSettings;


   ProfilePic({
    Key? key,
    required this.toggleTheme,
    required this.onAccountSettings,
   }) : super(key: key);


  void _showProfileDialog(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String fullName = '${userProvider.firstName ?? ''} ${userProvider.lastName ?? ''}'.trim();
    final String contactEmail = userProvider.contactEmail ?? '';
    final String profilePicUrl = userProvider.profilePicUrl ?? '';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: profilePicUrl.isNotEmpty
                          ? NetworkImage(profilePicUrl)
                          : const AssetImage('assets/images/profile.png') as ImageProvider,
                      onBackgroundImageError: (_, __) {
                        debugPrint("Error loading profile picture, showing default.");
                      },
                    ),
                    const SizedBox(height: 15),
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
                    const SizedBox(height: 20),
                    const Divider(color: Colors.grey),
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
                    SwitchListTile(
                      secondary: Icon(Icons.notifications, color: theme.disabledColor),
                      title: Text(
                        "Notifications",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: theme.disabledColor,
                        ),
                      ),
                      subtitle: Text(
                        "Coming soon",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.disabledColor,
                        ),
                      ),
                      value: true, // or false depending on your default
                      onChanged: null,
                    ),

                    const Divider(color: Colors.grey),
                    SwitchListTile(
                      secondary: Icon(Icons.dark_mode, color: theme.colorScheme.onSurface),
                      title: Text(
                        "Dark Mode",
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                      ),
                      value: themeModeNotifier.value == ThemeMode.dark, // ✅ use directly
                      onChanged: (bool value) {
                        toggleTheme(); // Flip between dark and light
                      },
                    ),

                    const Divider(color: Colors.grey),
                    const SizedBox(height: 10),
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
                                    //clear user data from provider
                                    userProvider.clearUserData();
                                    context.go("/login");
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
                          Icon(Icons.logout, color: Colors.red),
                          const SizedBox(width: 12),
                          Text(
                            "Log Out",
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.red,
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
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    final String profilePicUrl = userProvider.profilePicUrl ?? '';
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