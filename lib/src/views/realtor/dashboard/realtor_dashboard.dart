import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:realest/src/views/realtor/dashboard/pinned_clients.dart';

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
                  children: [
                        Text(
                          "Dashboard",
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        _buildModernCard(
                          Column(
                            children: [
                              const SizedBox(height: 16),
                              // Provide a fixed height for PinnedClientsSection
                              SizedBox(
                                height: screenHeight * 0.6, // 60% of screen height
                                child: const PinnedClientsSection(),
                              ),
                            ],
                          ),
                        ),
                    if (!isMobile) const SizedBox(height: 24),
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
