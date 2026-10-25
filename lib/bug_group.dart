// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:ui';

class GroupBugPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final String role;
  final String expiredDate;

  const GroupBugPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<GroupBugPage> createState() => _GroupBugPageState();
}

class _GroupBugPageState extends State<GroupBugPage> with TickerProviderStateMixin {
  final linkGroupController = TextEditingController();
  static const String baseUrl = "http://alfa-store-officials.alfamarket2.my.id:3771";

  late AnimationController _buttonController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  late VideoPlayerController _videoController;
  bool _videoInitialized = false;

  bool _isSending = false;
  // WARNA YANG DIROMBAK: Dari 0xFF2196F3 (Biru Standar) menjadi 0xFF00AAFF (Biru Neon)
  final Color _themeColor = const Color(0xFF00D4AA);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeVideoController();
  }

  void _initializeAnimations() {
    _buttonController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut));
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
  }

  void _initializeVideoController() {
    _videoController = VideoPlayerController.asset('assets/videos/bug.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _videoInitialized = true);
          _videoController.setLooping(true);
          _videoController.play();
          _videoController.setVolume(0);
        }
      });
  }

  bool _isValidGroupLink(String input) {
    final regex = RegExp(r'https://chat\.whatsapp\.com/[a-zA-Z0-9]{22}');
    return regex.hasMatch(input);
  }

  Future<void> _sendGroupBug() async {
    if (_isSending) return;
    setState(() => _isSending = true);
    _buttonController.forward().then((_) => _buttonController.reverse());

    final linkGroup = linkGroupController.text.trim();
    final key = widget.sessionKey;

    if (linkGroup.isEmpty || !_isValidGroupLink(linkGroup)) {
      _showAlert("❌ INVALID LINK", "Please enter a valid WhatsApp group link.");
      setState(() => _isSending = false);
      return;
    }

    try {
      final res = await http.get(Uri.parse("$baseUrl/api/whatsapp/groupBug?key=$key&linkGroup=$linkGroup"));
      final data = jsonDecode(res.body);
      if (data["valid"] == false) {
        _showAlert("❌ FAILED", data["message"] ?? "Failed to send group bug.");
      } else {
        _showSuccessPopup(linkGroup, data);
      }
    } catch (_) {
      _showAlert("❌ ERROR", "Terjadi kesalahan. Coba lagi.");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSuccessPopup(String linkGroup, Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GroupBugSuccessDialog(
        linkGroup: linkGroup,
        data: data,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: _themeColor)),
        title: Text(title, style: TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontWeight: FontWeight.bold)),
        content: Text(msg, style: const TextStyle(color: Colors.white70, fontFamily: 'Rajdhani')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK", style: TextStyle(color: _themeColor, fontFamily: 'Rajdhani', fontWeight: FontWeight.bold)))]
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfoHeader(), 
              const SizedBox(height: 25),
              _buildVideoHeader(),
              const SizedBox(height: 30),
              _buildLabel("GROUP DESTINATION"),
              _buildGlassInput(controller: linkGroupController, hint: "https://chat.whatsapp.com/...", icon: FontAwesomeIcons.link),
              const SizedBox(height: 40),
              _buildMainButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _themeColor, width: 2), image: const DecorationImage(image: AssetImage('assets/images/http://alfa-store-officials.alfamarket2.my.id:3771.png'), fit: BoxFit.cover)),
              ),
              Positioned(
                bottom: -5, left: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(color: _themeColor, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(widget.role.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani'))),
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.username.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Rajdhani')),
              Text("Expired: ${widget.expiredDate}", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontFamily: 'Rajdhani')),
            ]),
          ),
          const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text("http://alfa-store-officials.alfamarket2.my.id:3771", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'Rajdhani')),
            Text("GROUP-BUG", style: TextStyle(color: Colors.white38, fontSize: 8, fontFamily: 'Rajdhani')),
          ]),
        ],
      ),
    );
  }

  Widget _buildVideoHeader() {
    return Container(
      height: 180, width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: _themeColor.withOpacity(0.3))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: _videoInitialized
          ? FittedBox(fit: BoxFit.cover, child: SizedBox(width: _videoController.value.size.width, height: _videoController.value.size.height, child: VideoPlayer(_videoController)))
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(padding: const EdgeInsets.only(left: 8, bottom: 8), child: Text(text, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontFamily: 'Rajdhani')));
  }

  Widget _buildGlassInput({required TextEditingController controller, required String hint, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Rajdhani'),
        decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontFamily: 'Rajdhani'), prefixIcon: Icon(icon, color: _themeColor, size: 18), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 15)),
      ),
    );
  }

  Widget _buildMainButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTap: _isSending ? null : _sendGroupBug,
            child: Container(
              width: double.infinity, height: 60,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: LinearGradient(colors: [Colors.black, _themeColor.withOpacity(0.8)]), border: Border.all(color: _themeColor.withOpacity(0.5)), boxShadow: [BoxShadow(color: _themeColor.withOpacity(0.3 * _glowAnimation.value), blurRadius: 15)]),
              child: Center(child: _isSending ? const CircularProgressIndicator(color: Colors.white) : Text("ATTACK GROUP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: 'Rajdhani', fontSize: 16))),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _glowController.dispose();
    _videoController.dispose();
    linkGroupController.dispose();
    super.dispose();
  }
}

class GroupBugSuccessDialog extends StatelessWidget {
  final String linkGroup;
  final Map<String, dynamic> data;
  final VoidCallback onDismiss;

  const GroupBugSuccessDialog({super.key, required this.linkGroup, required this.data, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: const Color(0xFF00D4AA))),
      title: const Text("SENT SUCCESS", style: TextStyle(color: const Color(0xFF00D4AA), fontWeight: FontWeight.bold, fontFamily: 'Rajdhani')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Group Attack Sent To:", style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Rajdhani')),
          const SizedBox(height: 5),
          Text(linkGroup, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani')),
        ],
      ),
      actions: [TextButton(onPressed: onDismiss, child: const Text("DONE", style: TextStyle(color: const Color(0xFF00D4AA), fontFamily: 'Rajdhani', fontWeight: FontWeight.bold)))],
    );
  }
}