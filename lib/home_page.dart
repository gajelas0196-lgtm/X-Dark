// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

// ── WARNA TEMA MANTA'X ──────────────────────────────────────────────────
const Color _primary  = Color(0xFF00D4AA);
const Color _bg       = Color(0xFF090E14);
const Color _cardBg   = Color(0xFF111820);
const Color _cardBg2  = Color(0xFF0D1720);

class AttackPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const AttackPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<AttackPage> createState() => _AttackPageState();
}

class _AttackPageState extends State<AttackPage>
    with TickerProviderStateMixin {
  final targetController = TextEditingController();
  static const String baseUrl = "http://alfa-store-officials.alfamarket2.my.id:3771";

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  String selectedBugId = "";
  bool _isSending = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.9).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
    }
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.startsWith('0') || cleaned.length < 8) return null;
    return cleaned;
  }

  Future<void> _sendBug() async {
    if (_isSending) return;
    setState(() => _isSending = true);

    final rawInput = targetController.text.trim();
    final target = formatPhoneNumber(rawInput);
    final key = widget.sessionKey;

    if (target == null || key.isEmpty) {
      _showAlert("❌ INVALID NUMBER",
          "Gunakan nomor internasional (628xxx), bukan 08xxx.");
      setState(() => _isSending = false);
      return;
    }

    try {
      final res = await http.get(Uri.parse(
          "$baseUrl/api/whatsapp/sendBug?key=$key&target=$target&bug=$selectedBugId"));
      final data = jsonDecode(res.body);
      if (data["cooldown"] == true) {
        _showAlert("⏳ COOLDOWN", "Tunggu beberapa saat.");
      } else if (data["valid"] == false) {
        _showAlert("❌ KEY INVALID", "Login ulang.");
      } else {
        setState(() => _isSuccess = true);
        _showSuccessDialog(target);
      }
    } catch (_) {
      _showAlert("❌ ERROR", "Terjadi kesalahan koneksi.");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSuccessDialog(String target) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _primary.withOpacity(0.4)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: _primary, size: 48),
            ),
            const SizedBox(height: 14),
            const Text("SUCCESS!",
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 6),
            Text("Terkirim ke $target",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: 'Rajdhani',
                    fontSize: 14)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                setState(() => _isSuccess = false);
              },
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _primary.withOpacity(0.5)),
                ),
                child: const Center(
                  child: Text("DONE",
                      style: TextStyle(
                          color: _primary,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _primary.withOpacity(0.3)),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        content: Text(msg,
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontFamily: 'Rajdhani',
                fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK",
                style: TextStyle(
                    color: _primary,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER USER INFO ─────────────────────────────────
              _buildUserHeader(),
              const SizedBox(height: 20),

              // ── BUG MENU TITLE (mirip Manta'X Bug Menu) ──────────
              _buildBugMenuTitle(),
              const SizedBox(height: 20),

              // ── BUG CARD ─────────────────────────────────────────
              _buildBugCard(),
              const SizedBox(height: 20),

              // ── INPUT TARGET ─────────────────────────────────────
              _buildSectionLabel("TARGET DESTINATION"),
              const SizedBox(height: 8),
              _buildInput(
                controller: targetController,
                hint: "62xxx (contoh: 6281234567890)",
                icon: FontAwesomeIcons.crosshairs,
              ),
              const SizedBox(height: 16),

              // ── SELECT BUG ───────────────────────────────────────
              _buildSectionLabel("PILIH BUG"),
              const SizedBox(height: 8),
              _buildDropdown(),
              const SizedBox(height: 32),

              // ── TOMBOL EXECUTE ───────────────────────────────────
              _buildExecuteButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // WIDGETS
  // ──────────────────────────────────────────────────────────────────────

  Widget _buildUserHeader() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _primary.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(
                            0.4 * _glowAnimation.value),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -6,
                  left: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        widget.role.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ahlan Wa Sahlan!!",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                  Text(
                    widget.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "EXP: ${widget.expiredDate}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 10,
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                ],
              ),
            ),

            // TANIX badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  "WINCLICK",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    fontFamily: 'Orbitron',
                  ),
                ),
                Text(
                  "STREET-CODE",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 8,
                    fontFamily: 'Rajdhani',
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBugMenuTitle() {
    return Row(
      children: [
        const Text(
          "BUG MENU",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            fontFamily: 'Orbitron',
            letterSpacing: 2,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _primary.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                "ONLINE v2.0",
                style: TextStyle(
                  color: _primary,
                  fontSize: 9,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                "Elegant Edition",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 9,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBugCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _cardBg,
            const Color(0xFF0A1A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bug_report_outlined,
                    color: _primary, size: 22),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: Text(
                  "RECOMMENDED",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 9,
                    fontFamily: 'Orbitron',
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            "WINCLICK BUG",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Orbitron',
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Bug tanpa custom",
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontFamily: 'Rajdhani',
            ),
          ),
          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 8),
          Text(
            "Gunakan langsung tanpa custom delay dan loops",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontFamily: 'Rajdhani',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _buildChip("★ Mudah digunakan"),
              _buildChip("★ Function terbaru"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.55),
          fontSize: 11,
          fontFamily: 'Rajdhani',
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.35),
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        fontFamily: 'Orbitron',
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.phone,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Rajdhani',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: _primary,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _primary.withOpacity(0.7), size: 18),
          hintText: hint,
          hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.2),
              fontFamily: 'Rajdhani',
              fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    if (widget.listBug.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Text(
          "Tidak ada bug tersedia",
          style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontFamily: 'Rajdhani'),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _cardBg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedBugId,
          dropdownColor: const Color(0xFF111820),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: _primary),
          items: widget.listBug
              .map((bug) => DropdownMenuItem<String>(
                    value: bug['bug_id'],
                    child: Text(
                      bug['bug_name'].toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (val) => setState(() => selectedBugId = val!),
        ),
      ),
    );
  }

  Widget _buildExecuteButton() {
    return GestureDetector(
      onTap: _isSending ? null : _sendBug,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _primary.withOpacity(_isSending ? 0.3 : 0.8),
            width: 1.5,
          ),
          color: _primary.withOpacity(_isSending ? 0.04 : 0.1),
        ),
        child: Center(
          child: _isSending
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: _primary, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.send_rounded, color: _primary, size: 18),
                    SizedBox(width: 10),
                    Text(
                      "EXECUTE ATTACK",
                      style: TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontFamily: 'Orbitron',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    targetController.dispose();
    super.dispose();
  }
}
