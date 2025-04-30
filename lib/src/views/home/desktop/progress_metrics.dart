import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProgressMetricsSection extends StatefulWidget {
  final ScrollController? scrollController;

  const ProgressMetricsSection({super.key, this.scrollController});

  @override
  _ProgressMetricsSectionState createState() => _ProgressMetricsSectionState();
}

class _ProgressMetricsSectionState extends State<ProgressMetricsSection> with SingleTickerProviderStateMixin {
  static const Color neonPurple = Color(0xFFa78cde);
  late AnimationController _controller;
  late Animation<double> _fadeScaleAnimation;
  late Animation<int> _countAnimation1;
  late Animation<int> _countAnimation2;
  late Animation<int> _countAnimation3;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _countAnimation1 = IntTween(begin: 0, end: 86).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _countAnimation2 = IntTween(begin: 0, end: 92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _countAnimation3 = IntTween(begin: 0, end: 63).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    widget.scrollController?.addListener(_checkVisibility);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (!mounted) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.of(context).size.height;
      final widgetTop = position.dy;
      final widgetBottom = widgetTop + renderBox.size.height;

      if (widgetTop < screenHeight * 0.8 && widgetBottom > 0 && !_isVisible) {
        setState(() => _isVisible = true);
        _controller.forward();
      } else if ((widgetBottom < 0 || widgetTop > screenHeight) && _isVisible) {
        setState(() => _isVisible = false);
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.scrollController?.removeListener(_checkVisibility);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 30 : 60,
        horizontal: isMobile ? 10 : 20,
      ),
      color: const Color(0xFF1f1e25),
      child: Column(
        children: [
          _buildMetricsSection(isMobile),
          SizedBox(height: isMobile ? 40 : 80),
          Column(
            children: [
              Text(
                'Join 400+ Agents Who’ve Reclaimed 1,200+ Hours This Year',
                style: TextStyle(
                  color: neonPurple,
                  fontSize: isMobile ? 18 : 24,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: neonPurple,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 30,
                    vertical: isMobile ? 12 : 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Get Started',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(bool isMobile) {
    final metrics = [
      _buildMetricColumn(
        _countAnimation1,
        'Time Reduction on Initial Analysis',
        'Pilot Study Result',
        isPercentage: true,
        isMobile: isMobile,
      ),
      _buildMetricColumn(
        _countAnimation2,
        'Client Satisfaction with Swipe UI',
        'User Testing Data',
        isPercentage: true,
        isMobile: isMobile,
      ),
      _buildMetricColumn(
        _countAnimation3,
        'Avg. Properties Reviewed/Month',
        'Industry Benchmark',
        isPercentage: false,
        isMobile: isMobile,
      ),
    ];

    return isMobile
        ? Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        metrics[0],
        SizedBox(height: isMobile ? 50 : 40),
        metrics[1],
        SizedBox(height: isMobile ? 50 : 40),
        metrics[2],
      ],
    )
        : Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: metrics[0]),
        const SizedBox(width: 40),
        Expanded(child: metrics[1]),
        const SizedBox(width: 40),
        Expanded(child: metrics[2]),
      ],
    );
  }

  Widget _buildMetricColumn(
      Animation<int> countAnimation,
      String title,
      String subtitle, {
        required bool isPercentage,
        required bool isMobile,
      }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _fadeScaleAnimation.value,
              child: Opacity(
                opacity: _fadeScaleAnimation.value,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.7, 1.0],
                      colors: [neonPurple, Colors.white, Colors.white],
                    ).createShader(bounds);
                  },
                  child: Text(
                    isPercentage
                        ? '${countAnimation.value}%'
                        : '${countAnimation.value}',
                    style: TextStyle(
                      fontSize: isMobile ? 48 : 72,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: isMobile ? 20 : 30),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 16 : 20,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isMobile ? 14 : 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}