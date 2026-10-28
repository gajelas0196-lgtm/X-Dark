import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

// ─── Import Pages ─────────────────────────────────────────────────────────
import 'login_page.dart';
import 'admin_page.dart';
import 'seller_page.dart';
import 'change_password_page.dart';

class _Color {
  static const bg        = Color(0xFF060B14);
  static const surface   = Color(0xFF0C1424);
  static const primary   = Color(0xFFB04AFF);
  static const accent    = Color(0xFFFF2D78);
  static const text      = Color(0xFFE2EDF9);
  static const red       = Color(0xFFEF4444);
  
  static const LinearGradient primaryGrad = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class DashboardPage extends StatefulWidget {
  final String username, password, role, expiredDate, sessionKey;
  final List<Map<String, dynamic>> listBug, listPayload, listDDoS;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username, required this.password, required this.role,
    required this.expiredDate, required this.listBug, required this.listPayload,
    required this.listDDoS, required this.sessionKey, required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late String sessionKey, username, role, expiredDate;
  WebSocketChannel? channel;
  String androidId = 'unknown';
  int _navIndex = 0;
  Widget _body = const SizedBox();
  
  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    role = widget.role;
    expiredDate = widget.expiredDate;
    
    _initAndroidId();
  }

  @override
  void dispose() {
    channel?.sink.close(status.goingAway);
    super.dispose();
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
        Uri.parse('ws://alfa-store-officials.alfamarket2.my.id:3505'),
      );

      channel?.sink.add(jsonEncode({
        'type': 'validate',
        'key': sessionKey,
        'androidId': androidId,
      }));

      channel?.sink.add(jsonEncode({'type': 'stats'}));

      channel?.stream.listen(
        (event) {
          final data = jsonDecode(event);
          if (data['type'] == 'stats' && mounted) {
            setState(() {});
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('WebSocket error: $e');
    }
  }

  void _navigateTo(int index, Widget page) {
    setState(() {
      _navIndex = index;
      _body = page;
    });
  }

  void _selectFromMenu(String item) {
    Widget nextPage;
    int nextIndex = _navIndex;

    switch (item) {
      case 'admin':
        nextPage = AdminPage(sessionKey: sessionKey);
        break;
      case 'seller':
        nextPage = SellerPage(keyToken: sessionKey);
        break;
      case 'settings':
        nextPage = ChangePasswordPage(
          username: username, 
          sessionKey: sessionKey,
        );
        break;
      default:
        nextPage = const Center(child: Text('Halaman belum siap', style: TextStyle(color: Colors.white)));
    }
    _navigateTo(nextIndex, nextPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Color.bg,
      appBar: AppBar(
        backgroundColor: _Color.surface,
        title: Text('Welcome, $username', style: const TextStyle(fontFamily: 'Rajdhani')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: _Color.red),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          )
        ],
      ),
      drawer: Drawer(
        backgroundColor: _Color.surface,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(gradient: _Color.primaryGrad),
              child: Center(
                child: Text(username, style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Rajdhani')),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: _Color.text),
              title: const Text('Beranda', style: TextStyle(color: _Color.text, fontFamily: 'Rajdhani')),
              onTap: () => setState(() => _navIndex = 0),
            ),
            if (role.toLowerCase() == 'admin' || role.toLowerCase() == 'owner')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: _Color.text),
                title: const Text('Admin Panel', style: TextStyle(color: _Color.text, fontFamily: 'Rajdhani')),
                onTap: () {
                  Navigator.pop(context);
                  _selectFromMenu('admin');
                },
              ),
            if (role.toLowerCase() == 'reseller')
              ListTile(
                leading: const Icon(Icons.storefront, color: _Color.text),
                title: const Text('Seller Panel', style: TextStyle(color: _Color.text, fontFamily: 'Rajdhani')),
                onTap: () {
                  Navigator.pop(context);
                  _selectFromMenu('seller');
                },
              ),
            ListTile(
              leading: const Icon(Icons.lock, color: _Color.text),
              title: const Text('Settings', style: TextStyle(color: _Color.text, fontFamily: 'Rajdhani')),
              onTap: () {
                Navigator.pop(context);
                _selectFromMenu('settings');
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: _body is SizedBox 
          ? const Text('Selamat Datang di Dashboard', style: TextStyle(color: Colors.white, fontFamily: 'Rajdhani'))
          : _body,
      ),
    );
  }
}
