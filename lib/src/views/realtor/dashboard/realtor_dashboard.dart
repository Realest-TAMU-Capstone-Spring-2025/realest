import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:realest/src/views/realtor/dashboard/pinned_clients.dart';
import 'package:realest/src/views/realtor/dashboard/investor_activity.dart';
import 'package:realest/src/views/realtor/dashboard/new_notes.dart';

import '../../../../user_provider.dart';

class RealtorDashboard extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const RealtorDashboard({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  RealtorDashboardState createState() => RealtorDashboardState();
}

class RealtorDashboardState extends State<RealtorDashboard> {
  double _contentOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _contentOpacity = 1.0);
    });
  }

  Widget _buildModernCard(Widget child) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final screenHeight = MediaQuery.of(context).size.height;

    UserProvider userProvider = Provider.of<UserProvider>(context);

    final firstName = userProvider.firstName;
    return Scaffold(
      body: AnimatedOpacity(
        opacity: _contentOpacity,
        duration: const Duration(milliseconds: 500),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dashboard",
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.start,

                    ),
                    const SizedBox(height: 16),
                    isMobile 
                      ? Column(
                          children: [
                            _buildModernCard(
                              SizedBox(
                                height: screenHeight * 0.3,
                                child: const PinnedClientsSection(),
                              ),
                            ),
                            _buildModernCard(
                              SizedBox(
                                height: screenHeight * 0.3,
                                child: const InvestorActivitySection(),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Pinned Clients (Left half on desktop)
                            Expanded(
                              child: _buildModernCard(
                                SizedBox(
                                  height: screenHeight * 0.35,
                                  child: const PinnedClientsSection(),
                                ),
                              ),
                            ),
                            // Realtor Activity (Right half on desktop)
                            Expanded(
                              child: _buildModernCard(
                                SizedBox(
                                  height: screenHeight * 0.35,
                                  child: const InvestorActivitySection(),
                                ),
                              ),
                            ),
                          ],
                        ),
                    
                    const SizedBox(height: 16),
                    _buildModernCard(
                      SizedBox(
                        height: screenHeight * 0.4,
                        child: const NewNotesSection(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}