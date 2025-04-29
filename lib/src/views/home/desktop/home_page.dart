import 'package:flutter/material.dart';
import 'header_hero_page.dart';
import 'app_overview.dart';
import 'value_proposition.dart';
import 'wave_clipper.dart';
import 'progress_metrics.dart';
import 'realtor_stats.dart';
import 'footer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color neonPurple = Color(0xFFa78cde);
  late ScrollController _scrollController;
  double _gifOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_updateGifOpacity);
  }

  void _updateGifOpacity() {
    const double fadeStart = 1; // Start fading at 1px scroll
    const double fadeEnd = 700;
    double scrollOffset = _scrollController.offset;

    setState(() {
      if (scrollOffset < fadeStart) {
        _gifOpacity = 1.0;
      } else if (scrollOffset >= fadeStart && scrollOffset <= fadeEnd) {
        _gifOpacity = 1.0 - ((scrollOffset - fadeStart) / (fadeEnd - fadeStart));
      } else {
        _gifOpacity = 0.0;
      }
    });
  }

  @override
  void dispose() {
    debugPrint('Disposing scroll controller');
    _scrollController.removeListener(_updateGifOpacity);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'homePage'),
        buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF1f1e25),
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeaderHeroPage(gifOpacity: _gifOpacity),
              const Divider(
                  height: 10, color: neonPurple, indent: 100, endIndent: 100),
              AppOverview(),
              const Divider(
                  height: 10, color: neonPurple, indent: 100, endIndent: 100),
              ValuePropositions(),
              const SizedBox(height: 100),
              ProgressMetricsSection(scrollController: _scrollController),
              const SizedBox(height: 40),
              const Divider(
                  height: 10, color: neonPurple, indent: 100, endIndent: 100),
              RealtorStats(scrollController: _scrollController),
              const SizedBox(height: 80),
              ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  height: 100,
                  color: neonPurple,
                ),
              ),
              Container(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                color: neonPurple,
                child: Footer(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}