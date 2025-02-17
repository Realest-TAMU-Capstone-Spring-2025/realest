import 'package:flutter/material.dart';

class BubbleAnimation extends StatefulWidget {
  const BubbleAnimation({super.key});

  @override
  _BubbleAnimationState createState() => _BubbleAnimationState();
}

class _BubbleAnimationState extends State<BubbleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget buildBubble({
    required double size,
    required double startBottom,
    required double startRight,
    required double endBottom,
    required double endRight,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double bottomPosition =
            startBottom + (endBottom - startBottom) * _controller.value;
        double rightPosition =
            startRight + (endRight - startRight) * _controller.value;
        return Positioned(
          bottom: bottomPosition,
          right: rightPosition,
          child: Opacity(
            opacity: _controller.value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // We place the bubbles relative to the bottom right corner
    return Stack(
      children: [
        buildBubble(
          size: 500,
          startBottom: 20,
          startRight: 20,
          endBottom: -300,
          endRight: 150,
          color: Colors.blue.withOpacity(0.3),
        ),
        buildBubble(
          size: 100,
          startBottom: 20,
          startRight: 20,
          endBottom: 10,
          endRight: 300,
          color: Colors.purple.withOpacity(0.3),
        ),
        buildBubble(
          size: 40,
          startBottom: 20,
          startRight: 120,
          endBottom: 120,
          endRight: 300,
          color: Colors.green.withOpacity(0.3),
        ),
        buildBubble(
          size: 70,
          startBottom: 20,
          startRight: 120,
          endBottom: 10,
          endRight: 220,
          color: Colors.orange.withOpacity(0.3),
        ),
      ],
    );
  }
}
