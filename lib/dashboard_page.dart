import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:device_info_plus/device_info_plus.dart';
import 'login_page.dart';
import 'home_page.dart';

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

class _DashboardPageState extends State<DashboardPage> {
  WebSocketChannel? channel;
  String androidId = 'unknown';

  @override
  void initState() {
    super.initState();
    _initAndroidId();
  }

  Future<void> _initAndroidId() async {
    final info = await DeviceInfoPlugin().androidInfo;
    androidId = info.id;
    _connectWS();
  }

  void _connectWS() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse('wss://alfa-store-officials.alfamarket2.my.id:3771'),
      );
      channel!.sink.add(jsonEncode({
        'type': 'validate', 'key': widget.sessionKey, 'androidId': androidId,
      }));
      channel!.sink.add(jsonEncode({'type': 'stats'}));
      channel!.stream.listen((event) {}, cancelOnError: true);
    } catch (e) {
      debugPrint('WebSocket error: $e');
    }
  }

  @override
  void dispose() {
    channel?.sink.close(status.goingAway);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1424),
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Halo, ${widget.username} 👋', style: const TextStyle(color: Colors.white, fontSize: 20)),
          Text('Exp: ${widget.expiredDate}', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => AttackPage(
                  username: widget.username, password: widget.password,
                  listBug: widget.listBug, role: widget.role,
                  expiredDate: widget.expiredDate, sessionKey: widget.sessionKey,
                ),
              ));
            },
            child: const Text('Attack Tools'),
          ),
        ],
      ),
    );
  }
}
