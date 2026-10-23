import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dashboard_page.dart';

// ─── Palette: Biru Modern (sama dengan halaman lain) ─────────────────────────
class _C {
  static const bg         = Color(0xFF0A1929);      // Biru gelap background
  static const surface    = Color(0xFF0F2B40);      // Biru tua surface
  static const card       = Color(0xFF143D5C);      // Biru card
  static const border     = Color(0xFF1A5A8A);      // Biru border
  static const borderLit  = Color(0xFF2B7ABF);      // Biru terang border
  
  static const blueDark   = Color(0xFF0A4D8C);
  static const blueMid    = Color(0xFF1A6FB0);
  static const blueLight  = Color(0xFF2D8FD9);
  static const blueAccent = Color(0xFF4AA5F0);
  
  static const green      = Color(0xFF22C55E);
  static const amber      = Color(0xFFF59E0B);
  static const red        = Color(0xFFEF4444);
  
  static const text       = Color(0xFFF0F8FF);      // Putih kebiruan
  static const textSub    = Color(0xFFB0D4F0);      // Biru muda
  static const textDim    = Color(0xFF5A9BC0);      // Biru redup
  
  static const LinearGradient btnGrad = LinearGradient(
    colors: [Color(0xFF1A6FB0), Color(0xFF2D8FD9), Color(0xFF4AA5F0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class SplashScreen extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const SplashScreen({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.sessionKey,
    required this.listBug,
    required this.listDoos,
    required this.news,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _videoCtrl;
  bool _videoReady = false;
  bool _fadeOutStarted = false;

  // Animations
  late AnimationController _fadeOutCtrl;   // video fade to black
  late AnimationController _uiCtrl;        // UI entrance
  late AnimationController _glowCtrl;      // text glow pulse
  late AnimationController _ringCtrl;      // rotating ring
  late AnimationController _progressCtrl;  // loading bar
  late AnimationController _particleCtrl;  // floating particles

  late Animation<double> _uiFade;
  late Animation<Offset>  _uiSlide;
  late Animation<double>  _glowAnim;
  late Animation<double>  _fadeOut;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initVideo();
  }

  void _initAnimations() {
    _fadeOutCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeOut = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _fadeOutCtrl, curve: Curves.easeIn));

    _uiCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _uiFade  = CurvedAnimation(parent: _uiCtrl, curve: Curves.easeOut);
    _uiSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _uiCtrl, curve: Curves.easeOutCubic));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 5))
      ..repeat();

    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4));

    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
  }

  void _initVideo() {
    _videoCtrl = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _videoReady = true);
        _videoCtrl.setLooping(false);
        _videoCtrl.play();

        // Start UI animations after video loads
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _uiCtrl.forward();
            _progressCtrl.forward();
          }
        });

        _videoCtrl.addListener(_onVideoProgress);
      }).catchError((_) {
        // Fallback: no video, still show UI and auto-navigate
        if (mounted) {
          setState(() => _videoReady = false);
          _uiCtrl.forward();
          _progressCtrl.forward();
          Future.delayed(const Duration(seconds: 4), _navigate);
        }
      });
  }

  void _onVideoProgress() {
    if (!mounted) return;
    final pos = _videoCtrl.value.position;
    final dur = _videoCtrl.value.duration;
    if (dur == Duration.zero) return;

    // Start fade-out 1s before end
    if (pos >= dur - const Duration(seconds: 1) && !_fadeOutStarted) {
      _fadeOutStarted = true;
      _fadeOutCtrl.forward();
    }

    // Navigate when done
    if (pos >= dur) _navigate();
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => DashboardPage(
          username:    widget.username,
          password:    widget.password,
          role:        widget.role,
          expiredDate: widget.expiredDate,
          sessionKey:  widget.sessionKey,
          listBug:     widget.listBug,
          listDoos:    widget.listDoos,
          news:        widget.news,
        ),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoCtrl.removeListener(_onVideoProgress);
    _videoCtrl.dispose();
    _fadeOutCtrl.dispose();
    _uiCtrl.dispose();
    _glowCtrl.dispose();
    _ringCtrl.dispose();
    _progressCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Particles background ─────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particleCtrl.value),
              size: size,
            ),
          ),

          // ── Video (full cover) ────────────────────────────────────────
          if (_videoReady)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width:  _videoCtrl.value.size.width,
                  height: _videoCtrl.value.size.height,
                  child: VideoPlayer(_videoCtrl),
                ),
              ),
            ),

          // ── Dark overlay for readability ──────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(_videoReady ? 0.2 : 0.0),
                    Colors.black.withOpacity(_videoReady ? 0.7 : 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Center logo & title ───────────────────────────────────────
          Positioned.fill(
            child: FadeTransition(
              opacity: _uiFade,
              child: SlideTransition(
                position: _uiSlide,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogoRing(),
                    const SizedBox(height: 36),
                    _buildTitle(),
                    const SizedBox(height: 10),
                    _buildSubtitle(),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom progress & tagline ─────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: FadeTransition(
              opacity: _uiFade,
              child: _buildBottomBar(),
            ),
          ),

          // ── Fade-out overlay ──────────────────────────────────────────
          if (_fadeOutStarted)
            FadeTransition(
              opacity: _fadeOut,
              child: Container(color: _C.bg),
            ),
        ],
      ),
    );
  }

  // ─── Logo Ring ────────────────────────────────────────────────────────────
  Widget _buildLogoRing() {
    return AnimatedBuilder(
      animation: Listenable.merge([_ringCtrl, _glowCtrl]),
      builder: (_, __) => SizedBox(
        width: 160, height: 160,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer static ring
            Container(
              width: 158, height: 158,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _C.blueMid.withOpacity(_glowAnim.value * 0.15),
                  width: 1,
                ),
              ),
            ),
            // Rotating dashed-style ring
            Transform.rotate(
              angle: _ringCtrl.value * math.pi * 2,
              child: Container(
                width: 138, height: 138,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      _C.blueLight.withOpacity(_glowAnim.value * 0.7),
                      Colors.transparent,
                      _C.blueAccent.withOpacity(_glowAnim.value * 0.4),
                      Colors.transparent,
                      _C.blueLight.withOpacity(_glowAnim.value * 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Counter-rotating inner ring
            Transform.rotate(
              angle: -_ringCtrl.value * math.pi * 2 * 0.6,
              child: Container(
                width: 118, height: 118,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _C.blueDark.withOpacity(_glowAnim.value * 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            // Core glow
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.bg,
                boxShadow: [
                  BoxShadow(
                    color: _C.blueMid.withOpacity(_glowAnim.value * 0.55),
                    blurRadius: 40,
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: _C.blueLight.withOpacity(_glowAnim.value * 0.5),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.water_rounded,
                        color: _C.blueLight.withOpacity(_glowAnim.value),
                        size: 44),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Title ────────────────────────────────────────────────────────────────
  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => ShaderMask(
        shaderCallback: (b) => LinearGradient(
          colors: [
            _C.blueAccent,
            _C.blueLight.withOpacity(0.9 + _glowAnim.value * 0.1),
            _C.blueMid,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(b),
        child: Text(
          'TramsFlox',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: _C.blueMid.withOpacity(_glowAnim.value * 0.8),
                blurRadius: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: _C.border.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _C.blueMid.withOpacity(_glowAnim.value * 0.25),
          ),
        ),
        child: Text(
          'Project by @RamzMd ',
          style: TextStyle(
            color: _C.textSub.withOpacity(0.7 + _glowAnim.value * 0.3),
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 52),
      child: Column(
        children: [
          // Loading dots
          _LoadingDots(),
          const SizedBox(height: 18),

          // Progress bar
          AnimatedBuilder(
            animation: _progressCtrl,
            builder: (_, __) => Column(children: [
              // Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Stack(children: [
                  Container(
                    height: 3,
                    width: double.infinity,
                    color: _C.border.withOpacity(0.5),
                  ),
                  Container(
                    height: 3,
                    width: (MediaQuery.of(context).size.width - 64) *
                        _progressCtrl.value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_C.blueDark, _C.blueMid, _C.blueLight],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: _C.blueMid.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              Text(
                '${(_progressCtrl.value * 100).toInt()}%  Memuat...',
                style: const TextStyle(
                  color: _C.textSub,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Loading Dots ─────────────────────────────────────────────────────────────
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final t = ((_c.value - i / 3) % 1.0).clamp(0.0, 1.0);
          final s = math.sin(t * math.pi);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Transform.scale(
              scale: 0.4 + s * 0.6,
              child: Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.blueMid.withOpacity(0.35 + s * 0.65),
                  boxShadow: [
                    BoxShadow(
                      color: _C.blueMid.withOpacity(s * 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Particle Painter ─────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter(this.t);

  static final _rand = math.Random(42);
  static final _particles = List.generate(28, (i) => _Particle(
    x: _rand.nextDouble(),
    y: _rand.nextDouble(),
    size: 1.0 + _rand.nextDouble() * 2.0,
    speed: 0.04 + _rand.nextDouble() * 0.1,
    phase: _rand.nextDouble(),
    opacity: 0.15 + _rand.nextDouble() * 0.35,
  ));

  @override
  void paint(Canvas canvas, Size size) {
    // Grid
    final grid = Paint()
      ..color = _C.border.withOpacity(0.3)
      ..strokeWidth = 0.5;
    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Central glow
    final center = Offset(size.width / 2, size.height * 0.38);
    final glow   = Paint()
      ..shader = RadialGradient(colors: [
        _C.blueDark.withOpacity(0.18 + math.sin(t * math.pi * 2) * 0.06),
        Colors.transparent,
      ], radius: 0.6).createShader(
          Rect.fromCircle(center: center, radius: size.width * 0.7));
    canvas.drawCircle(center, size.width * 0.7, glow);

    // Floating particles
    for (final p in _particles) {
      final px = p.x * size.width;
      final rawY = p.y + (t * p.speed) % 1.0;
      final py = (rawY % 1.0) * size.height;
      final drift = math.sin((t + p.phase) * math.pi * 2) * 8;
      final osc = math.sin((t * 2 + p.phase) * math.pi);
      final opacity = p.opacity * (0.5 + osc * 0.5);

      canvas.drawCircle(
        Offset(px + drift, py),
        p.size,
        Paint()..color = _C.blueLight.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

class _Particle {
  final double x, y, size, speed, phase, opacity;
  const _Particle({
    required this.x, required this.y, required this.size,
    required this.speed, required this.phase, required this.opacity,
  });
}