import 'package:flutter/material.dart';


//tile for google and apple sign in
class ProviderTile extends StatelessWidget {
  final String logoPath;
  const ProviderTile({super.key, required this.logoPath});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Image.asset(logoPath),
    );
    }
  }