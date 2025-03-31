import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'header_hero_page.dart';
import 'app_overview.dart';
import 'value_proposition.dart';
import 'wave_clipper.dart';
import 'progress_metrics.dart';
import '../footer.dart';

class HomePage extends StatefulWidget {

  const HomePage({
    super.key,
  });


  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color neonPurple = Color(0xFFD500F9);
  late VideoPlayerController _headerController;
  late VideoPlayerController _overviewController1;
  late VideoPlayerController _overviewController2;
  late VideoPlayerController _overviewController3;
  bool _isVideoInitialized = false;
  String? _statusMessage;
  late ScrollController _scrollController;
  double _videoOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateVideoOpacity);
    _initializeVideos();
  }

  void _initializeVideos() {
    print('Starting video initialization...');
    _headerController = VideoPlayerController.asset('assets/videos/triangle.mp4');
    _overviewController1 = VideoPlayerController.asset('assets/videos/triangle.mp4');
    _overviewController2 = VideoPlayerController.asset('assets/videos/triangle.mp4');
    _overviewController3 = VideoPlayerController.asset('assets/videos/triangle.mp4');

    Future.wait([
      _headerController.initialize(),
      _overviewController1.initialize(),
      _overviewController2.initialize(),
      _overviewController3.initialize(),
    ]).then((_) {
      print('All videos initialized successfully');
      setState(() {
        _isVideoInitialized = true;
        _statusMessage = 'Videos loaded';
        _headerController.setLooping(true);
        _headerController.play();
        _overviewController1.setLooping(true);
        _overviewController1.play();
        _overviewController2.setLooping(true);
        _overviewController2.play();
        _overviewController3.setLooping(true);
        _overviewController3.play();
      });
    }).catchError((error) {
      print('Error during video initialization: $error');
      setState(() {
        _isVideoInitialized = false;
        _statusMessage = 'Error initializing videos: $error';
      });
    }).timeout(const Duration(seconds: 5), onTimeout: () {
      print('Video initialization timed out');
      setState(() {
        _isVideoInitialized = false;
        _statusMessage = 'Video initialization timed out';
      });
    });
  }

  void _updateVideoOpacity() {
    const double fadeStart = 1; // Start fading at 1px scroll
    const double fadeEnd = 700;
    double scrollOffset = _scrollController.offset;

    setState(() {
      if (scrollOffset < fadeStart) {
        _videoOpacity = 1.0;
      } else if (scrollOffset >= fadeStart && scrollOffset <= fadeEnd) {
        _videoOpacity = 1.0 - ((scrollOffset - fadeStart) / (fadeEnd - fadeStart));
      } else {
        _videoOpacity = 0.0;
      }
    });
  }

  @override
  void dispose() {
    print('Disposing video controllers and scroll controller');
    _scrollController.removeListener(_updateVideoOpacity);
    _scrollController.dispose();
    _headerController.dispose();
    _overviewController1.dispose();
    _overviewController2.dispose();
    _overviewController3.dispose();
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
        backgroundColor: Colors.black,
        body: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeaderHeroPage(
                videoController: _headerController,
                isVideoInitialized: _isVideoInitialized,
                videoOpacity: _videoOpacity,
              ),
              if (_statusMessage != null && _statusMessage!.startsWith('Error'))
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              const Divider(height: 10, color: neonPurple, indent: 100, endIndent: 100),
              AppOverview(),
              const Divider(height: 10, color: neonPurple, indent: 100, endIndent: 100),
              ValuePropositions(),
              const SizedBox(height: 80),
              const Divider(height: 10, color: neonPurple, indent: 100, endIndent: 100),
              const SizedBox(height: 60),
              ProgressMetricsSection(scrollController: _scrollController),
              // Wave separation before Footer
              ClipPath(
                clipper: WaveClipper(),
                child: Container(
                  height: 100, // Height of the wave section
                  color: const Color(0x33D500F9), // Match Footer's background color
                ),
              ),
              Footer(),
            ],
          ),
        ),
      ),
    );
  }
}