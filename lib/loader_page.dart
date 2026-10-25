// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
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
import 'dart:ui';
import 'dart:math' as math;

import 'telegram.dart';
import 'admin_page.dart';
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

// ══ TEMA BARU: CYBERPUNK VIOLET ══════════════════════════════════════════
const Color _primary    = Color(0xFFB04AFF);   // violet neon
const Color _accent     = Color(0xFFFF2D78);   // pink accent
const Color _accentBlue = Color(0xFF00C8FF);   // cyan highlight
const Color _bg         = Color(0xFF07050F);   // background ultra dark
const Color _cardBg     = Color(0xFF100D1E);   // card dark violet
const Color _cardBg2    = Color(0xFF150F26);   // card alt

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

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late WebSocketChannel channel;

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listPayload;
  late List<Map<String, dynamic>> listDDoS;
  late List<dynamic> newsList;
  String androidId = "unknown";

  int _selectedIndex = 0;
  Widget _selectedPage = const Placeholder();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentNewsIndex = 0;

  Offset _assistiveTouchPosition = const Offset(20, 150);
  bool _isAssistiveMenuOpen = false;
  
  bool _isBugToolsExpanded = false; 
  String _activePage = 'home'; 

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listPayload = widget.listPayload;
    listDDoS = widget.listDDoS;
    newsList = widget.news;

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    _selectedPage = _buildNewsPage();

    _initAndroidIdAndConnect();
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    if(mounted) {
      setState(() {
        androidId = deviceInfo.id;
      });
    }
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    try {
      channel = WebSocketChannel.connect(Uri.parse('ws://kgtau.indocloud.biz.id:10335'));

      channel.sink.add(jsonEncode({
        "type": "validate",
        "key": sessionKey,
        "androidId": androidId,
      }));

      channel.stream.listen(
        (event) {
          final data = jsonDecode(event);

          if (data['type'] == 'myInfo') {
            if (data['valid'] == false) {
              if (data['reason'] == 'androidIdMismatch') {
                _handleInvalidSession("Your account has logged on another device.");
              } else if (data['reason'] == 'keyInvalid') {
                _handleInvalidSession("Key is not valid. Please login again.");
              }
            } 
          } 
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint("WebSocket Connection Failed: $e");
    }
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
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _primary.withOpacity(0.5), width: 1), 
        ),
        title: const Text("⚠️ Session Expired", style: TextStyle(color: Colors.white, fontFamily: "Rajdhani")),
        content: Text(message, style: const TextStyle(color: Colors.white70, fontFamily: "Rajdhani")),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
            child: const Text("OK", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _selectFromDrawer(String page) {
    if (page == 'account') {
      setState(() {
        _isAssistiveMenuOpen = false; 
        _isBugToolsExpanded = false;
      });
      _showAccountMenu(); 
      return;
    }

    setState(() {
      _isAssistiveMenuOpen = false; 
      _activePage = page; 
    });

    Widget nextWidget = _buildNewsPage(); 
    
    if (page == 'home') {
      _selectedIndex = 0;
      nextWidget = _buildNewsPage();
    } else if (page == 'bug') {
      nextWidget = AttackPage(
        username: username,
        password: password,
        listBug: listBug,
        role: role,
        expiredDate: expiredDate,
        sessionKey: sessionKey,
      );
    } else if (page == 'custom_bug') {
      nextWidget = CustomAttackPage(
        username: username,
        password: password,
        listPayload: listPayload,
        role: role,
        expiredDate: expiredDate,
        sessionKey: sessionKey,
      );
    } else if (page == 'group_bug') {
      nextWidget = GroupBugPage(
        username: username,
        password: password,
        role: role,
        expiredDate: expiredDate,
        sessionKey: sessionKey,
      );
    } else if (page == 'telegram') {
      nextWidget = TelegramSpamPage(sessionKey: sessionKey);
    } else if (page == 'ddos') {
      nextWidget = AttackPanel(sessionKey: sessionKey, listDDoS: listDDoS);
    } else if (page == 'tools') {
      nextWidget = ToolsGatewayPage(sessionKey: sessionKey, userRole: role);
    } else if (page == 'reseller') {
      nextWidget = SellerPage(keyToken: sessionKey);
    } else if (page == 'admin') {
      nextWidget = AdminPage(sessionKey: sessionKey);
    } else if (page == 'sender') {
      nextWidget = SenderPage(sessionKey: sessionKey);
    }

    setState(() {
      _selectedPage = nextWidget;
      _controller.reset();
      _controller.forward();
    });
  }

  void _removeNavMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ── HEADER BARU ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12, left: 16, right: 16
      ),
      decoration: BoxDecoration(
        color: _bg.withOpacity(0.92),
        border: Border(bottom: BorderSide(color: _primary.withOpacity(0.3), width: 1.5)),
        boxShadow: [
          BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 20, spreadRadius: 0),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hamburger
          GestureDetector(
            onTap: () {
              setState(() {
                _isAssistiveMenuOpen = !_isAssistiveMenuOpen;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _primary.withOpacity(0.3), width: 1),
              ),
              child: const Icon(Icons.menu, color: Colors.white, size: 20),
            ),
          ),

          // Tengah: cuaca + logo + musik + notif
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wb_cloudy_outlined, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    const Text("29°C",
                      style: TextStyle(color: Colors.amber, fontSize: 12, fontFamily: "Rajdhani", fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Logo
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_primary.withOpacity(0.6), _accent.withOpacity(0.4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: _primary.withOpacity(0.6), width: 1.5),
                  boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 10)],
                ),
                child: ClipOval(
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.bolt, color: _primary, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.music_note, color: _primary.withOpacity(0.7), size: 20),
              const SizedBox(width: 10),
              Stack(
                children: [
                  Icon(Icons.notifications_outlined, color: Colors.white70, size: 22),
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: _accent, blurRadius: 6)],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Avatar kanan
          GestureDetector(
            onTap: _showAccountMenu,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [_primary.withOpacity(0.3), _accent.withOpacity(0.2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: _primary.withOpacity(0.5), width: 1.5),
              ),
              child: const Icon(Icons.person, color: Colors.white70, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 15),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, _accent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(color: _primary.withOpacity(0.8), blurRadius: 8, spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title, 
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 15, 
              fontWeight: FontWeight.bold, 
              fontFamily: "Rajdhani", 
              letterSpacing: 2.5
            ),
          ),
        ],
      ),
    );
  }

  // ── ACCOUNT CARD BARU ────────────────────────────────────────────────────
  Widget _buildAccountStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20), 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _primary.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(color: _primary.withOpacity(0.12), blurRadius: 30, spreadRadius: 3),
          BoxShadow(color: _accent.withOpacity(0.07), blurRadius: 40, spreadRadius: -5),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _cardBg2.withOpacity(0.95),
                  _primary.withOpacity(0.08),
                  _cardBg2.withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              children: [
                // Dekorasi background lingkaran
                Positioned(
                  right: -20, top: -20,
                  child: Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primary.withOpacity(0.05),
                    ),
                  ),
                ),
                Positioned(
                  left: -10, bottom: -15,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent.withOpacity(0.05),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [_primary, _accent],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [BoxShadow(color: _primary.withOpacity(0.5), blurRadius: 18, spreadRadius: 2)],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2.5),
                                  child: ClipOval(
                                    child: Image.asset('assets/images/logo.png', fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(Icons.shield, color: _primary, size: 30),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -6,
                                left: 0, right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [_primary, _accent]),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [BoxShadow(color: _primary.withOpacity(0.4), blurRadius: 8)],
                                    ),
                                    child: Text(
                                      role.toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: "Rajdhani", letterSpacing: 1.0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Info username
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Ahlan Wa Sahlan!!,",
                                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11, fontFamily: "Rajdhani", letterSpacing: 1.0),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  username,
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: "Rajdhani", letterSpacing: 1.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.verified_outlined, color: _accentBlue, size: 13),
                                    const SizedBox(width: 4),
                                    Text("WINCLICK MEMBER", style: TextStyle(color: _accentBlue, fontSize: 10, fontFamily: "Rajdhani", letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Expired info
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.withOpacity(0.4), width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.timer_outlined, color: Colors.orange, size: 12),
                                    const SizedBox(width: 4),
                                    const Text("EXP", style: TextStyle(color: Colors.orange, fontSize: 10, fontFamily: "Rajdhani", letterSpacing: 1.0)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                expiredDate.split(' ').first, 
                                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.bold, fontFamily: "Rajdhani", letterSpacing: 1.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Divider bergradient
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, _primary.withOpacity(0.5), Colors.transparent],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Label dashboard
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _primary.withOpacity(0.2), width: 1),
                          color: _primary.withOpacity(0.05),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.dashboard_outlined, color: _primary, size: 14),
                            const SizedBox(width: 8),
                            const Text(
                              "WINCLICK DASHBOARD",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 11,
                                fontFamily: "Rajdhani",
                                letterSpacing: 3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Stats row baru
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(Icons.people_outline, "0", "Online Users", _primary),
                          _buildStatDivider(),
                          _buildStatItem(Icons.link_outlined, "0", "Connections", _accentBlue),
                          _buildStatDivider(),
                          _buildStatItem(Icons.calendar_today_outlined, expiredDate.split(' ').first, "Expiration", Colors.orange),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: "Rajdhani")),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontFamily: "Rajdhani", letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, _primary.withOpacity(0.4), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  // ── SENDER BUTTON BARU ──────────────────────────────────────────────────
  Widget _buildSenderButton() {
    return GestureDetector(
      onTap: () => _selectFromDrawer('sender'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 76,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primary.withOpacity(0.85), _accent.withOpacity(0.7)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: _primary.withOpacity(0.35), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Manage Bug Sender",
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: "Rajdhani", letterSpacing: 1.0),
                  ),
                  Text(
                    "Pairing & Configuration",
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11, fontFamily: "Rajdhani", letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 16),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ── QUICK ACTION CARDS (baru) ────────────────────────────────────────────
  Widget _buildQuickActionsSection() {
    final actions = [
      {'icon': Icons.bug_report_rounded, 'label': 'Manta Bug', 'sub': 'Bug tanpa custom', 'page': 'bug', 'color1': _primary, 'color2': _accent, 'tag': 'RECOMMENDED'},
      {'icon': Icons.settings_outlined, 'label': 'Custom Bug', 'sub': 'Menu custom bug', 'page': 'custom_bug', 'color1': _accentBlue, 'color2': const Color(0xFF0044CC), 'tag': 'CUSTOM'},
      {'icon': Icons.group_outlined, 'label': 'Bug Group', 'sub': 'Kirim ke group', 'page': 'group_bug', 'color1': const Color(0xFF00CC88), 'color2': const Color(0xFF007755), 'tag': 'GROUP'},
      {'icon': Icons.send_rounded, 'label': 'Spam Pair', 'sub': 'WA & OTP Telegram', 'page': 'telegram', 'color1': const Color(0xFFFF6B00), 'color2': const Color(0xFFCC3300), 'tag': 'SPAM'},
      {'icon': Icons.wallet_outlined, 'label': 'TabunganKu', 'sub': 'Manage Duit', 'page': 'tools', 'color1': const Color(0xFF00DD55), 'color2': const Color(0xFF008833), 'tag': 'SAVE'},
      {'icon': Icons.shield_outlined, 'label': 'DDoS Panel', 'sub': 'Attack & Defend', 'page': 'ddos', 'color1': const Color(0xFFFF3333), 'color2': const Color(0xFF990000), 'tag': 'DDOS'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSectionTitle("QUICK ACTIONS"),
        ),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.72, initialPage: 0),
            itemCount: actions.length,
            itemBuilder: (context, i) {
              final a = actions[i];
              final c1 = a['color1'] as Color;
              final c2 = a['color2'] as Color;
              return GestureDetector(
                onTap: () => _selectFromDrawer(a['page'] as String),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: c1.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 6))],
                  ),
                  child: Stack(
                    children: [
                      // Hiasan dekorasi
                      Positioned(
                        right: -15, bottom: -15,
                        child: Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10, right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(a['tag'] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontFamily: "Rajdhani", fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(a['icon'] as IconData, color: Colors.white, size: 24),
                            ),
                            const SizedBox(height: 10),
                            Text(a['label'] as String,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: "Rajdhani", letterSpacing: 0.5)),
                            Text(a['sub'] as String,
                              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11, fontFamily: "Rajdhani")),
                          ],
                        ),
                      ),
                      // Tap arrow
                      Positioned(
                        bottom: 20, right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("Tap →", style: TextStyle(color: Colors.white, fontSize: 10, fontFamily: "Rajdhani")),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── CONNECT WITH TEAM (baru) ─────────────────────────────────────────────
  Widget _buildConnectSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg2.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.wifi_tethering, color: _accent, size: 18),
              const SizedBox(width: 8),
              const Text("CONNECT WITH WINCLICK TEAM",
                style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: "Rajdhani", letterSpacing: 1.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildConnectIcon(FontAwesomeIcons.paperPlane, _accentBlue),
              _buildConnectIcon(Icons.ondemand_video_rounded, _accent),
              _buildConnectIcon(Icons.music_note_rounded, Colors.white54),
              _buildConnectIcon(Icons.favorite_rounded, const Color(0xFFFF2D78)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectIcon(IconData icon, Color color) {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildNewsPage() {
    return RefreshIndicator(
      color: _primary, 
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {});
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.top + 70), 
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildAccountStatsCard(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSectionTitle("BERITA TERKINI"),
                ),
                _buildNewsCarousel(),
                const SizedBox(height: 28),
                _buildQuickActionsSection(),
                const SizedBox(height: 28),
                _buildConnectSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCarousel() {
    if (newsList.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withOpacity(0.3),
          border: Border.all(color: _primary.withOpacity(0.2)),
        ),
        child: const Center(child: Text("No news available", style: TextStyle(color: Colors.white54))),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 260, 
          child: PageView.builder(
            controller: _pageController,
            itemCount: newsList.length,
            onPageChanged: (index) {
              setState(() {
                _currentNewsIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final item = newsList[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: _cardBg, 
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primary.withOpacity(0.2), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 20, spreadRadius: 5, offset: const Offset(0, 10)),
                    BoxShadow(color: _primary.withOpacity(0.08), blurRadius: 30, spreadRadius: -10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6, 
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18.5)),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (item['image'] != null && item['image'].toString().isNotEmpty)
                              NewsMedia(url: item['image'])
                            else
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_primary.withOpacity(0.3), _accent.withOpacity(0.2)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            // Tag BACA
                            Positioned(
                              top: 10, right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _accent.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.open_in_new_rounded, color: Colors.white, size: 11),
                                    SizedBox(width: 4),
                                    Text("BACA", style: TextStyle(color: Colors.white, fontSize: 10, fontFamily: "Rajdhani", fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.black.withOpacity(0.5), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4, 
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.newspaper_outlined, color: _primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item['title'] ?? "WinClick Team", 
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: "Rajdhani", letterSpacing: 1.0),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.access_time_outlined, color: Colors.white38, size: 12),
                                const SizedBox(width: 4),
                                Text("Berita terbaru", style: TextStyle(color: Colors.white38, fontSize: 11, fontFamily: "Rajdhani")),
                                const Spacer(),
                                Icon(Icons.arrow_forward_rounded, color: _accent, size: 14),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (newsList.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                newsList.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: _currentNewsIndex == index ? 24 : 8, 
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: _currentNewsIndex == index
                        ? LinearGradient(colors: [_primary, _accent])
                        : null,
                    color: _currentNewsIndex == index ? null : Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _glassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _cardBg.withOpacity(0.9), 
        border: Border.all(color: _primary.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: _primary.withOpacity(0.05), blurRadius: 20, spreadRadius: 2)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), child: child),
      ),
    );
  }

  Widget _glassButton({required Icon icon, required Text label, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: icon,
      label: label,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: _primary, 
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _primary.withOpacity(0.3), width: 1)),
      ),
      onPressed: onPressed,
    );
  }

  void _showBugOptionsSheet() {
    final String currentRole = role.toLowerCase();
    final List<String> allowedGroupRoles = ['dev', 'high admin', 'admin', 'high owner', 'owner', 'reseller', 'vip'];
    final bool canAccessGroup = allowedGroupRoles.contains(currentRole);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _glassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Select Bug Type", style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: "Rajdhani")),
                const SizedBox(height: 20),
                _glassButton(
                  icon: const Icon(Icons.person_outline),
                  label: const Text("Bug Contact", style: TextStyle(color: Colors.white, fontFamily: "Rajdhani")),
                  onPressed: () { Navigator.pop(context); _selectFromDrawer('bug'); },
                ),
                if (canAccessGroup) ...[
                  const SizedBox(height: 10),
                  _glassButton(
                    icon: const Icon(FontAwesomeIcons.usersSlash),
                    label: const Text("Bug Group", style: TextStyle(color: Colors.white, fontFamily: "Rajdhani")),
                    onPressed: () { Navigator.pop(context); _selectFromDrawer('group_bug'); },
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAccountMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _glassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Account Info", style: TextStyle(color: Colors.white, fontSize: 20, fontFamily: "Rajdhani")),
                const SizedBox(height: 12),
                _infoCard(Icons.person, "Username", username),
                _infoCard(Icons.date_range, "Expired", expiredDate),
                _infoCard(Icons.security, "Role", role),
                const SizedBox(height: 20),
                _glassButton(
                  icon: const Icon(Icons.lock_reset),
                  label: const Text("Change Password", style: TextStyle(color: Colors.white, fontFamily: "Rajdhani")),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _activePage = 'change_password';
                      _selectedPage = ChangePasswordPage(username: username, sessionKey: sessionKey);
                      _controller.reset();
                      _controller.forward();
                    });
                  },
                ),
                const SizedBox(height: 10),
                _glassButton(
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout", style: TextStyle(color: Colors.white, fontFamily: "Rajdhani")),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.2), width: 1), 
      ),
      child: Row(
        children: [
          Icon(icon, color: _primary), 
          const SizedBox(width: 10),
          Text("$label:", style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value, style: TextStyle(color: _primary, fontFamily: "Rajdhani")), 
        ],
      ),
    );
  }

  Widget _buildAssistiveMenu() {
    final String currentRole = role.toLowerCase();
    final bool canAccessAdmin = ['dev', 'high admin', 'admin', 'high owner', 'owner'].contains(currentRole);
    final bool canAccessSeller = ['dev', 'high admin', 'admin', 'high owner', 'owner', 'reseller'].contains(currentRole);
    final bool canAccessAllBugs = ['dev', 'high admin', 'admin', 'high owner', 'owner'].contains(currentRole);
    final bool canAccessResellerBugs = ['reseller'].contains(currentRole);
    final bool isMember = !canAccessAllBugs && !canAccessResellerBugs;

    return Container(
      width: 240, 
      decoration: BoxDecoration(
        color: _cardBg, 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.3), width: 1), 
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 5)),
          BoxShadow(color: _primary.withOpacity(0.1), blurRadius: 20),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8), 
                _assistiveMenuItem(Icons.home, "Home", 'home'),
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    childrenPadding: EdgeInsets.zero,
                    leading: Icon(FontAwesomeIcons.whatsapp, color: _primary, size: 18), 
                    title: Text("Bug Tools", style: TextStyle(color: _primary, fontSize: 14, fontFamily: "Rajdhani", letterSpacing: 1.0)), 
                    trailing: Icon(_isBugToolsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white54, size: 18),
                    onExpansionChanged: (bool expanded) {
                      setState(() { _isBugToolsExpanded = expanded; });
                      if (isMember && expanded) {
                         setState(() { _isBugToolsExpanded = false; });
                         _selectFromDrawer('bug');
                      }
                    },
                    children: [
                      if (!isMember)
                        Padding(
                          padding: const EdgeInsets.only(left: 20, top: 4, bottom: 8, right: 16),
                          child: Stack(
                            children: [
                              Positioned(left: 7, top: 12, bottom: 12, child: Container(width: 1.5, color: Colors.white24)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (canAccessAllBugs || canAccessResellerBugs) ...[
                                    _buildTreeItem(icon: FontAwesomeIcons.usersSlash, title: "Group Bug", page: 'group_bug'),
                                    const SizedBox(height: 8),
                                  ],
                                  if (canAccessAllBugs) ...[
                                    _buildTreeItem(icon: Icons.terminal, title: "Custom Bug", page: 'custom_bug'),
                                    const SizedBox(height: 8),
                                  ],
                                  _buildTreeItem(icon: Icons.bolt, title: "Basic Bug", page: 'bug'),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                _assistiveMenuItem(FontAwesomeIcons.paperPlane, "Spam", 'telegram'),
                _assistiveMenuItem(FontAwesomeIcons.screwdriverWrench, "Tools", 'tools'),
                _assistiveMenuItem(Icons.security, "DDoS Attack", 'ddos'),
                const Divider(color: Colors.white12, height: 16, thickness: 1, indent: 16, endIndent: 16),
                _assistiveMenuItem(Icons.person, "Account Info", 'account'),
                if (canAccessSeller) _assistiveMenuItem(Icons.store, "Seller Panel", 'reseller'),
                if (canAccessAdmin) _assistiveMenuItem(Icons.admin_panel_settings, "Admin Panel", 'admin'),
                _assistiveMenuItem(FontAwesomeIcons.whatsapp, "Manage Sender", 'sender'),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _assistiveMenuItem(IconData icon, String title, String page) {
    bool isActive = _activePage == page; 

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: _primary.withOpacity(0.2), 
          highlightColor: _primary.withOpacity(0.1),
          onTap: () => _selectFromDrawer(page),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: isActive ? BoxDecoration(
              color: _primary.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primary.withOpacity(0.3), width: 1), 
            ) : null, 
            child: Row(
              children: [
                Icon(icon, color: isActive ? _primary : Colors.white70, size: 18),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title, 
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70, 
                      fontSize: 14, 
                      fontFamily: "Rajdhani", 
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      letterSpacing: 1.0
                    )
                  ),
                ),
                if (isActive) 
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(color: _primary, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTreeItem({required IconData icon, required String title, required String page}) {
    bool isActive = _activePage == page;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _selectFromDrawer(page),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), 
          child: Row(
            children: [
              Container(
                alignment: Alignment.center,
                width: 14,
                child: Icon(icon, color: isActive ? _primary : Colors.white70, size: 16), 
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? _primary : Colors.white70, 
                  fontSize: 13,
                  fontFamily: "Rajdhani",
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BOTTOM NAV BARU ──────────────────────────────────────────────────────
  Widget _buildFloatingNavBar() {
    return Positioned(
      bottom: 24, 
      left: 15,
      right: 15,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _cardBg.withOpacity(0.96), 
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _primary.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(color: _primary.withOpacity(0.2), blurRadius: 25, spreadRadius: 2),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildFloatingNavItem(Icons.home_filled, "Home", 'home'),
            _buildFloatingNavItem(Icons.chat_bubble_outline_rounded, "Bug", 'bug'),
            _buildFloatingNavItem(Icons.group_outlined, "Group", 'group_bug'),
            _buildFloatingNavItem(FontAwesomeIcons.screwdriverWrench, "Tools", 'tools'),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingNavItem(IconData icon, String label, String page) {
    bool isActive = _activePage == page || (page == 'bug' && (_activePage == 'group_bug' || _activePage == 'custom_bug'));

    return GestureDetector(
      onTap: () {
        if (page == 'bug') {
          _showBugOptionsSheet();
        } else {
          _selectFromDrawer(page);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primary.withOpacity(0.2), _accent.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _primary.withOpacity(0.5), width: 1.5),
                boxShadow: [BoxShadow(color: _primary.withOpacity(0.2), blurRadius: 10)],
              )
            : const BoxDecoration(), 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? _primary : Colors.white38, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white38,
                fontSize: 10,
                fontFamily: "Rajdhani",
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isRightSide = _assistiveTouchPosition.dx > (screenSize.width / 2);
    final bool isBottomSide = _assistiveTouchPosition.dy > (screenSize.height / 2);

    return PopScope(
      canPop: _activePage == 'home',
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _selectFromDrawer('home');
      },
      child: Scaffold(
        key: _scaffoldKey, 
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background gradient baru
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [Color(0xFF1A0933), Color(0xFF07050F), Color(0xFF07050F), Color(0xFF0A0315)],
                    stops: [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            // Scanline
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: ScanlinePainter(),
                ),
              ),
            ),
            SafeArea(
              top: false, 
              bottom: false, 
              child: FadeTransition(
                opacity: _animation,
                child: _selectedPage,
              ),
            ),
            if (_activePage == 'home')
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildHeader(),
              ),
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
              left: isRightSide ? _assistiveTouchPosition.dx - 250 : _assistiveTouchPosition.dx + 70,
              top: isBottomSide ? _assistiveTouchPosition.dy - 350 : _assistiveTouchPosition.dy,
              child: AnimatedScale(
                scale: _isAssistiveMenuOpen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack, 
                alignment: isRightSide 
                    ? (isBottomSide ? Alignment.bottomRight : Alignment.topRight)
                    : (isBottomSide ? Alignment.bottomLeft : Alignment.topLeft),
                child: _buildAssistiveMenu(),
              ),
            ),
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
                    double newX = _assistiveTouchPosition.dx + details.delta.dx;
                    double newY = _assistiveTouchPosition.dy + details.delta.dy;
                    newX = newX.clamp(0.0, screenSize.width - 60.0);
                    newY = newY.clamp(0.0, screenSize.height - 120.0);
                    _assistiveTouchPosition = Offset(newX, newY);
                  });
                },
                onTap: () {
                  setState(() {
                    _isAssistiveMenuOpen = !_isAssistiveMenuOpen;
                    if(!_isAssistiveMenuOpen) _isBugToolsExpanded = false;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: _isAssistiveMenuOpen
                        ? LinearGradient(colors: [_primary, _accent], begin: Alignment.topLeft, end: Alignment.bottomRight)
                        : LinearGradient(colors: [Colors.black.withOpacity(0.7), _cardBg], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isAssistiveMenuOpen ? _primary : _primary.withOpacity(0.5), 
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isAssistiveMenuOpen ? _primary.withOpacity(0.6) : Colors.black.withOpacity(0.5),
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
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildFloatingNavBar(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _removeNavMenu();
    channel.sink.close(status.goingAway);
    _controller.dispose();
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}

class ScanlinePainter extends CustomPainter {
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
    return url.endsWith(".mp4") || url.endsWith(".webm") || url.endsWith(".mov") || url.endsWith(".mkv");
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
        return Center(child: CircularProgressIndicator(color: _primary));
      }
    } else {
      return Image.network(
        widget.url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_primary.withOpacity(0.2), _accent.withOpacity(0.1)]),
          ),
        ),
      );
    }
  }
}
