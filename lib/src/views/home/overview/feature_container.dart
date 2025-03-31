import 'package:flutter/material.dart';

class FeatureContainer extends StatelessWidget {
  final IconData icon;
  final String title;
  final String cta;

  const FeatureContainer({
    required this.icon,
    required this.title,
    required this.cta,
    super.key,
  });

  static const Color neonPurple = Color(0xFFD500F9);

  @override
  Widget build(BuildContext context) {
    final hoverNotifier = ValueNotifier<bool>(false);

    return MouseRegion(
      onEnter: (_) => hoverNotifier.value = true,
      onExit: (_) => hoverNotifier.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: hoverNotifier,
        builder: (context, isHovered, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isHovered ? 220 : 200,
            padding: const EdgeInsets.all(16),
            transform: isHovered ? Matrix4.identity().scaled(1.05) : Matrix4.identity(),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: neonPurple),
              borderRadius: BorderRadius.circular(12),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: isHovered ? 0.9 : 1.5,
                colors: const [Colors.black, neonPurple],
                stops: isHovered ? [0.0, 1.0] : [0.3, 1.0],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: neonPurple,
                  size: isHovered ? 40 : 36,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 40,
                  alignment: Alignment.center,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isHovered ? 14 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.all(isHovered ? 6 : 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isHovered ? neonPurple.withOpacity(0.8) : Colors.transparent,
                      width: isHovered ? 1 : 0,
                    ),
                  ),
                  child: Text(
                    cta,
                    style: TextStyle(
                      color: neonPurple,
                      fontSize: isHovered ? 15 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}