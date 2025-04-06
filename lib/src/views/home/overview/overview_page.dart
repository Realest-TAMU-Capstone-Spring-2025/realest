import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'header_hero_page.dart';
import 'app_overview.dart';
import 'value_proposition.dart';
import 'wave_clipper.dart';
import 'progress_metrics.dart';
import 'realtor_stats.dart';
import '../footer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const Color neonPurple = Color(0xFFa78cde);
  late VideoPlayerController _headerController;
  late VideoPlayerController _overviewController1;
  late VideoPlayerController _overviewController2;
  late VideoPlayerController _overviewController3;
  bool _isVideoInitialized = false;
  String? _statusMessage;
  late ScrollController _scrollController;
  double _videoOpacity = 1.0;
  late Future<void> _videosInitialization;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    _scrollController.addListener(_updateVideoOpacity);
    _videosInitialization = _initializeVideos();
  }

  Future<void> _initializeVideos() async {
    debugPrint('Starting video initialization...');
    _headerController =
        VideoPlayerController.asset('assets/videos/triangle.mp4');
    _overviewController1 =
        VideoPlayerController.asset('assets/videos/triangle.mp4');
    _overviewController2 =
        VideoPlayerController.asset('assets/videos/triangle.mp4');
    _overviewController3 =
        VideoPlayerController.asset('assets/videos/triangle.mp4');

    try {
      await Future.wait([
        _headerController.initialize(),
        _overviewController1.initialize(),
        _overviewController2.initialize(),
        _overviewController3.initialize(),
      ]);
      debugPrint('All videos initialized successfully');
      setState(() {
        _isVideoInitialized = true;
        _statusMessage = 'Videos loaded';
      });
      // Set looping and start playback.
      _headerController.setLooping(true);
      _headerController.play();
      _overviewController1.setLooping(true);
      _overviewController1.play();
      _overviewController2.setLooping(true);
      _overviewController2.play();
      _overviewController3.setLooping(true);
      _overviewController3.play();
    } catch (error) {
      debugPrint('Error during video initialization: $error');
      setState(() {
        _isVideoInitialized = false;
        _statusMessage = 'Error initializing videos: $error';
      });
    }
  }

  void _updateVideoOpacity() {
    const double fadeStart = 1; // Start fading at 1px scroll
    const double fadeEnd = 700;
    double scrollOffset = _scrollController.offset;

    setState(() {
      if (scrollOffset < fadeStart) {
        _videoOpacity = 1.0;
      } else if (scrollOffset >= fadeStart && scrollOffset <= fadeEnd) {
        _videoOpacity =
            1.0 - ((scrollOffset - fadeStart) / (fadeEnd - fadeStart));
      } else {
        _videoOpacity = 0.0;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isVideoInitialized) return;
    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed, restarting video playback');
      _headerController.play();
      _overviewController1.play();
      _overviewController2.play();
      _overviewController3.play();
    } else if (state == AppLifecycleState.paused) {
      debugPrint('App paused, pausing video playback');
      _headerController.pause();
      _overviewController1.pause();
      _overviewController2.pause();
      _overviewController3.pause();
    }
  }

  @override
  void dispose() {
    debugPrint('Disposing video controllers and scroll controller');
    WidgetsBinding.instance.removeObserver(this);
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
        textTheme:
        Theme.of(context).textTheme.apply(fontFamily: 'homePage'),
        buttonTheme:
        const ButtonThemeData(textTheme: ButtonTextTheme.primary),
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF1f1e25),
        body: FutureBuilder<void>(
          future: _videosInitialization,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: neonPurple,
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error initializing videos: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            } else {
              return SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HeaderHeroPage(
                      videoController: _headerController,
                      isVideoInitialized: _isVideoInitialized,
                      videoOpacity: _videoOpacity,
                    ),
                    if (_statusMessage != null &&
                        _statusMessage!.startsWith('Error'))
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _statusMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 16),
                        ),
                      ),
                    const Divider(
                        height: 10,
                        color: neonPurple,
                        indent: 100,
                        endIndent: 100),
                    AppOverview(),
                    const Divider(
                        height: 10,
                        color: neonPurple,
                        indent: 100,
                        endIndent: 100),
                    ValuePropositions(),
                    const SizedBox(height: 100),
                    ProgressMetricsSection(scrollController: _scrollController),
                    const SizedBox(height: 40),
                    const Divider(
                        height: 10,
                        color: neonPurple,
                        indent: 100,
                        endIndent: 100),
                    RealtorStats(scrollController: _scrollController),
                    const SizedBox(height: 80),
                    ClipPath(
                      clipper: WaveClipper(),
                      child: Container(
                        height: 110,
                        color: const Color(0xFFa78cde),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.zero,
                      padding: EdgeInsets.zero,
                      child: Footer(),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
