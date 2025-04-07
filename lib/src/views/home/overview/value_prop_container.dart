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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      onEnter: (_) => hoverNotifier.value = true,
      onExit: (_) => hoverNotifier.value = false,
      child: ValueListenableBuilder<bool>(
        valueListenable: hoverNotifier,
        builder: (context, isHovered, _) {
          if (isMobile) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isHovered ? 270 : 250,
              height: 250,
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.all(12),
              transform: isHovered
                  ? Matrix4.identity().scaled(1.03)
                  : Matrix4.identity(),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: neonPurple,
                    size: isHovered ? 56 : 50,
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isHovered ? 26 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      subheading,
                      style: TextStyle(
                        color: neonPurple,
                        fontSize: isHovered ? 22 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: details
                            .map(
                              (detail) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Text(
                              detail,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isHovered ? 320 : 300,
              height: 400,
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.all(20),
              transform: isHovered
                  ? Matrix4.identity().scaled(1.01)
                  : Matrix4.identity(),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: neonPurple,
                    size: isHovered ? 60 : 56,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isHovered ? 32 : 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      subheading,
                      style: TextStyle(
                        color: neonPurple,
                        fontSize: isHovered ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: details
                            .map(
                              (detail) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              detail,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}