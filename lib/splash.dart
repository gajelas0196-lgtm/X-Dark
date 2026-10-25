import 'dashboard_page.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';


class SplashPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const SplashPage({super.key, required this.data});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.asset('assets/videos/load.mp4')
      ..initialize().then((_) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
        _controller.setVolume(1.0);
      });

    _controller.addListener(() {
      if (_controller.value.isInitialized &&
          _controller.value.position >= _controller.value.duration) {
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    if (_isNavigating) return;
    _isNavigating = true;

    _controller.pause();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DashboardPage(
          username: widget.data['username'] ?? '',
          password: widget.data['password'] ?? '',
          role: widget.data['role'] ?? 'user',
          expiredDate: widget.data['expiredDate'] ?? '-',
          sessionKey: widget.data['key'] ?? '',
          listBug: List<Map<String, dynamic>>.from(widget.data['listBug'] ?? []),
          listPayload: List<Map<String, dynamic>>.from(widget.data['listPayload'] ?? []),
          listDDoS: List<Map<String, dynamic>>.from(widget.data['listDDoS'] ?? []),
          news: List<Map<String, dynamic>>.from(widget.data['news'] ?? []),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitialized)
            SizedBox.expand(
              child: VideoPlayer(_controller),
            )
          else
            const Center(
              child: SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  color: Color(0xFF00D4AA),
                  strokeWidth: 2,
                ),
              ),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      "X•Dark",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3.0,
                        color: Colors.transparent,
                        shadows: [
                          Shadow(
                            blurRadius: 0,
                            offset: Offset(5, 5),
                            color: Color(0xFF000833),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      "X•Dark",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3.0,
                        color: Colors.transparent,
                        shadows: [
                          Shadow(
                            blurRadius: 40,
                            color: Color(0xFF00D4AA),
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "X•Dark",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rajdhani',
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3.0,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 3.0
                          ..color = Colors.white,
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF00D4AA),
                          Color(0xFF00D4AA),
                          Color(0xFF007A5E),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      blendMode: BlendMode.srcIn,
                      child: const Text(
                        "X•Dark",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: 120,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D4AA).withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Design By X•Dark TEAM",
                  style: TextStyle(
                    fontFamily: 'Rajdhani',
                    fontSize: 13,
                    color: Colors.white70,
                    letterSpacing: 4.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 50,
            right: 25,
            child: IgnorePointer(
              ignoring: _isNavigating,
              child: GestureDetector(
                onTap: _navigateToDashboard,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "SKIP",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 2.0,
                              fontFamily: 'Rajdhani',
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 11),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}