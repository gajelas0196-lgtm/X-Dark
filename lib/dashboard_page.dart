// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

// ─── Import Pages ─────────────────────────────────────────────────────────
import 'telegram.dart';
import 'admin_page.dart';
import 'owner_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';
import 'ddos_page.dart';
import 'chat_page.dart';
import 'login_page.dart';
import 'custom_bug.dart';
import 'bug_group.dart';
import 'ddos_panel.dart';
import 'sender_page.dart';
import 'spams_page.dart';
import 'public_page.dart';
import 'nik_check.dart';
import 'tools_gateway.dart';
import 'bug_sender.dart';
import 'contact_page.dart';
import 'profile_page.dart';
import 'riwayat_page.dart';
import 'info_page.dart';

// ═════════════════════════════════════════════════════════════════════════════
// ─── COLOR PALETTE (CYBERPUNK + BLUE THEME) ─────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════

class _Color {
  // Background & Surface
  static const bg        = Color(0xFF060B14);      // Ultra dark bg
  static const surface   = Color(0xFF0C1424);      // Panel surface
  static const card      = Color(0xFF101A2E);      // Card bg
  static const border    = Color(0xFF1A2D4A);      // Border color
  static const borderLit = Color(0xFF1E3A5F);      // Border highlight

  // Primary Colors (Blue theme)
  static const blue      = Color(0xFF1B6FBD);      // Primary blue
  static const blueMid   = Color(0xFF2D8FE8);      // Mid blue
  static const blueLight = Color(0xFF56AEF5);      // Light blue
  static const blueFrost = Color(0xFF90CEF7);      // Frost blue

  // Accent Colors (Cyberpunk theme)
  static const primary   = Color(0xFFB04AFF);      // Violet neon
  static const accent    = Color(0xFFFF2D78);      // Pink accent
  static const accentBlue= Color(0xFF00C8FF);      // Cyan

  // Status Colors
  static const green     = Color(0xFF22C55E);      // Success
  static const amber     = Color(0xFFF59E0B);      // Warning
  static const red       = Color(0xFFEF4444);      // Error

  // Text Colors
  static const text      = Color(0xFFE2EDF9);      // Primary text
  static const textSub   = Color(0xFF7A9BBF);      // Secondary text
  static const textDim   = Color(0xFF3A5470);      // Dimmed text

  // Gradients
  static const LinearGradient btnGrad = LinearGradient(
    colors: [blueMid, blueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGrad = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// ─── Role helpers ──────────────────────────────────────────────────────────
Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'owner':    return _Color.amber;
    case 'admin':    return _Color.red;
    case 'reseller': return _Color.green;
    case 'vip':      return _Color.primary;
    default:         return _Color.blueLight;
  }
}

IconData _roleIcon(String role) {
  switch (role.toLowerCase()) {
    case 'owner':    return Icons.workspace_premium_rounded;
    case 'admin':    return Icons.admin_panel_settings_rounded;
    case 'reseller': return Icons.storefront_rounded;
    case 'vip':      return Icons.star_rounded;
    default:         return Icons.person_rounded;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ─── MAIN DASHBOARD PAGE ────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listPayload;
  final List<Map<String, dynamic>> listDDoS;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listPayload,
    required this.listDDoS,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  // ─── State Variables ───────────────────────────────────────────────────
  late String sessionKey, username, password, role, expiredDate;
  late List<Map<String, dynamic>> listBug, listPayload, listDDoS;
  late List<dynamic> newsList;

  late WebSocketChannel channel;
  String androidId = 'unknown';
  File? _profileImage;
  VideoPlayerController? _menuVideoCtrl;

  int _navIndex = 0;
  Widget _body = const SizedBox();
  int onlineUsers = 0;
  int activeConns = 0;

  // ─── Animation Controllers ────────────────────────────────────────────
  late AnimationController _bgCtrl;
  late AnimationController _pageCtrl;
  late AnimationController _menuCtrl;
  late AnimationController _floatingBtnCtrl;

  late Animation<double> _pageFade;
  late Animation<Offset> _pageSlide;

  // ─── UI State ──────────────────────────────────────────────────────────
  int _activePage = 0;
  bool _isMenuOpen = false;
  bool _isBugToolsExpanded = false;
  Offset _assistiveTouchPosition = const Offset(20, 150);
  bool _isAssistiveMenuOpen = false;

  // ─── News Carousel ────────────────────────────────────────────────────
  final PageController _newsPageCtrl = PageController(viewportFraction: 0.88);
  int _newsPage = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // ─ Copy widget data
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listPayload = widget.listPayload;
    listDDoS = widget.listDDoS;
    newsList = widget.news;

    // ─ Animation Controllers
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pageCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
            .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOutCubic));

    _menuCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _floatingBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _body = _buildNewsPage();
    _pageCtrl.forward();

    _initAndroidId();
    _loadProfileImage();
    _initMenuVideo();
  }

  @override
  void dispose() {
    channel.sink.close(status.goingAway);
    _bgCtrl.dispose();
    _pageCtrl.dispose();
    _menuCtrl.dispose();
    _floatingBtnCtrl.dispose();
    _menuVideoCtrl?.dispose();
    _newsPageCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ─── INITIALIZATION ───────────────────────────────────────────────────
  // ═════════════════════════════════════════════════════════════════════════

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('profile_image_$username');
    if (path != null && path.isNotEmpty && mounted) {
      setState(() => _profileImage = File(path));
    }
  }

  void _initMenuVideo() {
    try {
      _menuVideoCtrl = VideoPlayerController.asset('assets/videos/banner.mp4')
        ..initialize().then((_) {
          if (mounted) setState(() {});
          _menuVideoCtrl?.setLooping(true);
          _menuVideoCtrl?.play();
        });
    } catch (e) {
      debugPrint('Menu video error: $e');
    }
  }

  Future<void> _initAndroidId() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      androidId = info.id;
      _connectWebSocket();
    } catch (e) {
      debugPrint('AndroidId error: $e');
    }
  }

  void _connectWebSocket() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse('ws://kgtau.indocloud.biz.id:10335'),
      );

      channel.sink.add(jsonEncode({
        'type': 'validate',
        'key': sessionKey,
        'androidId': androidId,
      }));

      channel.sink.add(jsonEncode({'type': 'stats'}));

      channel.stream.listen(
        (event) {
          final data = jsonDecode(event);

          if (data['type'] == 'myInfo' && data['valid'] == false) {
            final reason = data['reason'];
            _handleInvalidSession(
              reason == 'androidIdMismatch'
                  ? 'Akun ini login di perangkat lain.'
                  : 'Sesi tidak valid. Silakan login ulang.',
            );
          }

          if (data['type'] == 'stats' && mounted) {
            setState(() {
              onlineUsers = data['onlineUsers'] ?? 0;
              activeConns = data['activeConnections'] ?? 0;
            });
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('WebSocket error: $e');
    }
  }

  Future<void> _openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _handleInvalidSession(String message) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _Color.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _Color.primary.withOpacity(0.5), width: 1),
        ),
        title: const Text(
          '⚠️ Sesi Berakhir',
          style: TextStyle(color: _Color.text, fontFamily: 'Rajdhani'),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: _Color.textSub,
            fontFamily: 'Rajdhani',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('OK', style: TextStyle(color: _Color.text)),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ─── NAVIGATION ───────────────────────────────────────────────────────────
  // ═════════════════════════════════════════════════════════════════════════

  void _navigateTo(int index, {Widget? page}) {
    setState(() {
      _navIndex = index;
      _isMenuOpen = false;
      _isAssistiveMenuOpen = false;
      _isBugToolsExpanded = false;
    });

    _pageCtrl.reset();

    if (page != null) {
      _body = page;
    } else {
      _body = _buildNewsPage();
    }

    _pageCtrl.forward();
  }

  void _selectFromMenu(String item) {
    setState(() => _isMenuOpen = false);

    Widget nextPage = _buildNewsPage();
    int nextIndex = _navIndex;

    switch (item) {
      case 'home':
        nextIndex = 0;
        nextPage = _buildNewsPage();
        break;
      case 'admin':
        nextPage = AdminPage(
          username: username,
          password: password,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
        break;
      case 'owner':
        nextPage = OwnerPage(
          username: username,
          password: password,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
        break;
      case 'seller':
        nextPage = SellerPage(
          username: username,
          password: password,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
        break;
      case 'ddos':
        nextPage = DdosPage(
          username: username,
          password: password,
          listDDoS: listDDoS,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
        break;
      case 'tools':
        nextPage = ToolsGateway(
          username: username,
          password: password,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
        break;
      case 'bug':
        nextPage = AttackPage(
          username: username,
          password: password,
          listBug: listBug,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
        break;
      case 'profile':
        nextPage = ProfilePage(
          username: username,
          password: password,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
        break;
      case 'settings':
        nextPage = ChangePasswordPage(
          username: username,
          password: password,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
        break;
    }

    _navigateTo(nextIndex, page: nextPage);
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ─── PAGE BUILDERS ─────────────────────────────────────────────────────────
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildNewsPage() {
    return Center(
      child: Text(
        'News & Updates',
        style: TextStyle(color: _Color.text.withOpacity(0.5)),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // ─── BUILD METHODS ────────────────────────────────────────────────────────
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isRightSide =
        _assistiveTouchPosition.dx > (screenSize.width / 2);
    final bool isBottomSide =
        _assistiveTouchPosition.dy > (screenSize.height / 2);

    return PopScope(
      canPop: _navIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _selectFromMenu('home');
      },
      child: Scaffold(
        key: _scaffoldKey,
        extendBodyBehindAppBar: true,
        backgroundColor: _Color.bg,
        drawer: _buildDrawer(),
        body: Stack(
          children: [
            // ─ Animated Background
            Positioned.fill(
              child: _AnimatedBg(controller: _bgCtrl),
            ),

            // ─ Scanlines
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _ScanlinePainter()),
              ),
            ),

            // ─ Body
            SafeArea(
              top: false,
              bottom: false,
              child: FadeTransition(
                opacity: _pageFade,
                child: SlideTransition(
                  position: _pageSlide,
                  child: _body,
                ),
              ),
            ),

            // ─ Header (Home only)
            if (_navIndex == 0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildHeader(),
              ),

            // ─ Floating Button
            Positioned(
              left: _assistiveTouchPosition.dx,
              top: _assistiveTouchPosition.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    if (_isAssistiveMenuOpen) {
                      _isAssistiveMenuOpen = false;
                      _isBugToolsExpanded = false;
                    }
                    double newX =
                        _assistiveTouchPosition.dx + details.delta.dx;
                    double newY =
                        _assistiveTouchPosition.dy + details.delta.dy;
                    newX = newX.clamp(0.0, screenSize.width - 60.0);
                    newY = newY.clamp(0.0, screenSize.height - 120.0);
                    _assistiveTouchPosition = Offset(newX, newY);
                  });
                },
                onTap: () {
                  setState(() {
                    _isAssistiveMenuOpen = !_isAssistiveMenuOpen;
                    if (!_isAssistiveMenuOpen) {
                      _isBugToolsExpanded = false;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: _isAssistiveMenuOpen
                        ? _Color.primaryGrad
                        : LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.7),
                              _Color.card
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isAssistiveMenuOpen
                          ? _Color.primary
                          : _Color.primary.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isAssistiveMenuOpen
                            ? _Color.primary.withOpacity(0.6)
                            : Colors.black.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─ Floating Menu
            if (_isAssistiveMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isAssistiveMenuOpen = false;
                      _isBugToolsExpanded = false;
                    });
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              left: isRightSide
                  ? _assistiveTouchPosition.dx - 250
                  : _assistiveTouchPosition.dx + 70,
              top: isBottomSide
                  ? _assistiveTouchPosition.dy - 350
                  : _assistiveTouchPosition.dy,
              child: AnimatedScale(
                scale: _isAssistiveMenuOpen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                alignment: isRightSide
                    ? (isBottomSide ? Alignment.bottomRight : Alignment.topRight)
                    : (isBottomSide ? Alignment.bottomLeft : Alignment.topLeft),
                child: _buildFloatingMenu(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_Color.bg, _Color.bg.withOpacity(0.8)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: _Color.blue.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _Color.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _Color.border),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: _Color.textSub,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $username',
                    style: const TextStyle(
                      color: _Color.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                  Row(
                    children: [
                      Icon(_roleIcon(role), size: 12, color: _roleColor(role)),
                      const SizedBox(width: 4),
                      Text(
                        role.toUpperCase(),
                        style: TextStyle(
                          color: _roleColor(role),
                          fontSize: 10,
                          fontFamily: 'Rajdhani',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _Color.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _Color.border),
              ),
              child: Text(
                'ID: ${androidId.substring(0, 8)}',
                style: const TextStyle(
                  color: _Color.textSub,
                  fontSize: 10,
                  fontFamily: 'Rajdhani',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: _Color.surface,
      child: ListView(
        children: [
          // ─ Drawer Header with Video
          Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: _Color.primaryGrad,
              border: Border(bottom: BorderSide(color: _Color.border)),
            ),
            child: Stack(
              children: [
                if (_menuVideoCtrl?.value.isInitialized == true)
                  VideoPlayer(_menuVideoCtrl!)
                else
                  Container(
                    color: _Color.card,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: _Color.primary,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        _Color.surface.withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          color: _Color.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Rajdhani',
                        ),
                      ),
                      Text(
                        'Exp: $expiredDate',
                        style: const TextStyle(
                          color: _Color.textSub,
                          fontSize: 12,
                          fontFamily: 'Rajdhani',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─ Menu Items
          _buildDrawerItem(
            Icons.home_rounded,
            'Beranda',
            'home',
            isActive: _navIndex == 0,
          ),
          if (role.toLowerCase() == 'admin' || role.toLowerCase() == 'owner')
            _buildDrawerItem(
              Icons.admin_panel_settings_rounded,
              'Admin Panel',
              'admin',
            ),
          if (role.toLowerCase() == 'owner')
            _buildDrawerItem(
              Icons.workspace_premium_rounded,
              'Owner Panel',
              'owner',
            ),
          if (role.toLowerCase() == 'reseller')
            _buildDrawerItem(
              Icons.storefront_rounded,
              'Seller Panel',
              'seller',
            ),
          _buildDrawerItem(
            Icons.bug_report_rounded,
            'Attack Tools',
            'bug',
          ),
          _buildDrawerItem(
            Icons.cloud_off_rounded,
            'DDoS Panel',
            'ddos',
          ),
          _buildDrawerItem(
            Icons.construction_rounded,
            'Tools Gateway',
            'tools',
          ),
          _buildDrawerItem(
            Icons.person_rounded,
            'Profile',
            'profile',
          ),
          _buildDrawerItem(
            Icons.lock_rounded,
            'Settings',
            'settings',
          ),
          const Divider(color: _Color.border),
          _buildDrawerItem(
            Icons.logout_rounded,
            'Logout',
            'logout',
            color: _Color.red,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String label,
    String action, {
    Color color = _Color.textSub,
    bool isActive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isActive ? _Color.primary : color, size: 20),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? _Color.primary : _Color.text,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontFamily: 'Rajdhani',
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (action == 'logout') {
          _handleLogout();
        } else {
          _selectFromMenu(action);
        }
      },
      hoverColor: _Color.card,
      selectedTileColor: _Color.card,
    );
  }

  Widget _buildFloatingMenu() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _Color.surface,
        border: Border.all(color: _Color.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _Color.primary.withOpacity(0.2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFloatingMenuItem(
            Icons.home_rounded,
            'Home',
            () => _selectFromMenu('home'),
          ),
          _buildFloatingMenuItem(
            Icons.person_rounded,
            'Profile',
            () => _selectFromMenu('profile'),
          ),
          _buildFloatingMenuItem(
            Icons.lock_rounded,
            'Settings',
            () => _selectFromMenu('settings'),
          ),
          const Divider(color: _Color.border, height: 8),
          _buildFloatingMenuItem(
            Icons.logout_rounded,
            'Logout',
            _handleLogout,
            color: _Color.red,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingMenuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color color = _Color.blueLight,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontFamily: 'Rajdhani',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ─── PAINTER & HELPER CLASSES ─────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.012);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedBg extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBg({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(painter: _BgPainter(controller.value)),
    );
  }
}

class _BgPainter extends CustomPainter {
  final double t;
  _BgPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Grid background
    final grid = Paint()
      ..color = _Color.border.withOpacity(0.25)
      ..strokeWidth = 0.5;

    const step = 38.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Animated glow
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          _Color.blue.withOpacity(0.10 + math.sin(t * math.pi * 2) * 0.03),
          Colors.transparent,
        ],
        radius: 0.9,
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, 0),
          radius: size.width,
        ),
      );
    canvas.drawCircle(Offset(size.width / 2, 0), size.width, glow);
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}

// ═════════════════════════════════════════════════════════════════════════════
// ─── NEWS MEDIA WIDGET ─────────────────────────────────────────────────────────
// ═════════════════════════════════════════════════════════════════════════════

class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});

  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          setState(() {});
          _controller?.setLooping(true);
          _controller?.play();
        });
    }
  }

  bool _isVideo(String url) {
    return url.endsWith('.mp4') ||
        url.endsWith('.webm') ||
        url.endsWith('.mov') ||
        url.endsWith('.mkv');
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      } else {
        return Container(
          color: _Color.surface,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: _Color.primary,
                strokeWidth: 2,
              ),
            ),
          ),
        );
      }
    } else {
      return Image.network(
        widget.url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _Color.primary.withOpacity(0.2),
                _Color.accent.withOpacity(0.1)
              ],
            ),
          ),
        ),
      );
    }
  }
}
