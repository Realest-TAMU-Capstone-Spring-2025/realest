import 'package:flutter/material.dart';

class ValuePropContainer extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subheading;
  final List<String> details;

  const ValuePropContainer({
    required this.icon,
    required this.title,
    required this.subheading,
    required this.details,
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
            width: isHovered ? 320 : 300, // Increased width for more content
            height: 400, // Fixed height to accommodate details
            padding: const EdgeInsets.all(20),
            transform: isHovered ? Matrix4.identity().scaled(1.05) : Matrix4.identity(),
            transformAlignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: neonPurple),
              borderRadius: BorderRadius.circular(16),
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
                  size: isHovered ? 60 : 56, // Slightly larger icon
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isHovered ? 32 : 28, // Larger title font
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subheading,
                  style: TextStyle(
                    color: neonPurple,
                    fontSize: isHovered ? 20 : 18, // Larger title font
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 40),
                // Details list
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: details.map((detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 28.0),
                    child: Text(
                      detail,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
                ),
                const Spacer(),
              ],
            ),
          );
        },
      ),
    );
  }
}