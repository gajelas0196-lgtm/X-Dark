import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

const _baseUrl = 'http://darknovaaa.onlinedigitalcloud.biz.id:11198';

// ─── Palette ──────────────────────────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFF060B14);
  static const surface   = Color(0xFF0C1424);
  static const card      = Color(0xFF101A2E);
  static const border    = Color(0xFF1A2D4A);
  static const borderLit = Color(0xFF1E3A5F);
  static const blue      = Color(0xFF1B6FBD);
  static const blueMid   = Color(0xFF2D8FE8);
  static const blueLight = Color(0xFF56AEF5);
  static const blueFrost = Color(0xFF90CEF7);
  static const green     = Color(0xFF22C55E);
  static const greenDim  = Color(0xFF16A34A);
  static const amber     = Color(0xFFF59E0B);
  static const red       = Color(0xFFEF4444);
  static const purple    = Color(0xFF000000); // DIUBAH: dari ungu jadi hitam
  static const text      = Color(0xFFE2EDF9);
  static const textSub   = Color(0xFF7A9BBF);
  static const textDim   = Color(0xFF3A5470);

  static const LinearGradient btnGrad = LinearGradient(
    colors: [blueMid, blueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'owner':    return const Color(0xFFF59E0B);
    case 'admin':    return const Color(0xFFEF4444);
    case 'moderator': return const Color(0xFF22C55E);
    case 'partner':  return const Color(0xFF000000); // DIUBAH: dari ungu jadi hitam
    case 'vip':      return const Color(0xFF000000); // DIUBAH: dari ungu jadi hitam
    case 'reseller': return const Color(0xFF22C55E);
    default:         return _C.blueLight;
  }
}

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final targetCtrl = TextEditingController();

  String selectedBugId = '';
  String _bugMode      = 'number';   // number | group
  String _senderType   = 'private';  // private | global
  bool   _isSending    = false;
  String? _responseMsg;

  List<String> _globalSenders   = [];
  bool         _isLoadingSenders = false;

  late AnimationController _bgCtrl;
  late AnimationController _entranceCtrl;
  late AnimationController _sendBtnCtrl;
  late AnimationController _resultCtrl;
  late AnimationController _waveCtrl;

  late Animation<double> _entrance;
  late Animation<double> _sendPulse;
  late Animation<double> _sendGlow;
  late Animation<double> _resultFade;
  late Animation<Offset>  _resultSlide;

  late VideoPlayerController _videoCtrl;
  ChewieController? _chewieCtrl;
  bool _videoReady = false;

  bool get canAccessGlobalSender {
    final r = widget.role.toLowerCase();
    return r == 'owner' || 
           r == 'admin' || 
           r == 'moderator' || 
           r == 'partner' || 
           r == 'vip';
  }

  @override
  void initState() {
    super.initState();
    if (widget.listBug.isNotEmpty) selectedBugId = widget.listBug[0]['bug_id'];

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();

    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _entrance = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic);

    _sendBtnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _sendPulse = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _sendBtnCtrl, curve: Curves.easeInOut));
    _sendGlow = Tween<double>(begin: 0.25, end: 0.65)
        .animate(CurvedAnimation(parent: _sendBtnCtrl, curve: Curves.easeInOut));

    _resultCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _resultFade  = CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOut);
    _resultSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _resultCtrl, curve: Curves.easeOutCubic));

    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

    _entranceCtrl.forward();
    _initVideo();
    _loadGlobalSenders();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entranceCtrl.dispose();
    _sendBtnCtrl.dispose();
    _resultCtrl.dispose();
    _waveCtrl.dispose();
    targetCtrl.dispose();
    _videoCtrl.dispose();
    _chewieCtrl?.dispose();
    super.dispose();
  }

  // ─── Video ────────────────────────────────────────────────────────────────
  void _initVideo() {
    _videoCtrl = VideoPlayerController.asset('assets/videos/banner.mp4');
    _videoCtrl.initialize().then((_) {
      if (!mounted) return;
      _videoCtrl.setVolume(0);
      setState(() {
        _chewieCtrl = ChewieController(
          videoPlayerController: _videoCtrl,
          autoPlay: true,
          looping: true,
          showControls: false,
        );
        _videoReady = true;
      });
    });
  }

  // ─── Load Global Senders dari Server ──────────────────────────────────────
  Future<void> _loadGlobalSenders() async {
    setState(() => _isLoadingSenders = true);
    try {
      final res = await http.get(Uri.parse(
        '$_baseUrl/getActiveSenders?key=${widget.sessionKey}',
      )).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body);
      if (data['valid'] == true && data['senders'] != null) {
        if (mounted) setState(() => _globalSenders = List<String>.from(data['senders']));
      } else {
        if (mounted) setState(() => _globalSenders = []);
      }
    } catch (_) {
      if (mounted) setState(() => _globalSenders = []);
    } finally {
      if (mounted) setState(() => _isLoadingSenders = false);
    }
  }

  // ─── Send ─────────────────────────────────────────────────────────────────
  Future<void> _sendBug() async {
    final rawInput = targetCtrl.text.trim();
    final key      = widget.sessionKey;

    // Validasi input
    if (_bugMode == 'number') {
      if (formatPhone(rawInput) == null) {
        _showAlert('Nomor Tidak Valid', 'Gunakan format internasional.\nContoh: +62812xxxxxxxx');
        return;
      }
    } else {
      if (!isValidGroupLink(rawInput)) {
        _showAlert('Link Tidak Valid',
            'Masukkan link grup WhatsApp yang valid.\nContoh: https://chat.whatsapp.com/XXX');
        return;
      }
    }

    if (_senderType == 'global' && !canAccessGlobalSender) {
      _showAlert('Akses Ditolak', 'Sender Global hanya untuk Owner, Admin, Moderator, Partner & VIP!');
      return;
    }

    if (selectedBugId.isEmpty) {
      _showAlert('Pilih Bug', 'Silakan pilih bug terlebih dahulu.');
      return;
    }

    setState(() { _isSending = true; _responseMsg = null; });
    _resultCtrl.reset();

    try {
      final encodedTarget = Uri.encodeComponent(rawInput);
      final url = Uri.parse(
        '$_baseUrl/sendBug'
        '?key=$key'
        '&target=$encodedTarget'
        '&bug=$selectedBugId'
        '${_senderType == 'global' ? '&senderMode=global' : ''}',
      );

      final res  = await http.get(url).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);

      if (data['valid'] == false) {
        _setResponse('error', 'Session key tidak valid. Silakan login ulang.');
      } else if (data['cooldown'] == true) {
        final wait = data['wait'] ?? 0;
        _setResponse('warning', 'Cooldown aktif! Tunggu $wait detik lagi.');
      } else if (data['sended'] == true) {
        final label = _bugMode == 'group' ? 'grup target' : rawInput;
        final role  = data['role'] ?? widget.role;
        _setResponse('success', 'Bug berhasil dikirim ke $label! [$role]');
        targetCtrl.clear();
      } else {
        _setResponse('error', 'Gagal mengirim. Server sedang maintenance.');
      }
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _setResponse('error', 'Request timeout. Periksa koneksi internet.');
      } else {
        _setResponse('error', 'Koneksi error. Periksa jaringan dan coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _setResponse(String type, String msg) {
    if (!mounted) return;
    setState(() => _responseMsg = '$type|$msg');
    _resultCtrl.forward(from: 0);
  }

  String? formatPhone(String s) {
    final c = s.replaceAll(RegExp(r'[^\d+]'), '');
    return (c.startsWith('+') && c.length >= 8) ? c : null;
  }

  bool isValidGroupLink(String s) =>
      s.startsWith('https://') && s.contains('chat.whatsapp.com');

  void _showAlert(String title, String msg) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, __) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.amber.withOpacity(0.3), width: 1.5),
            boxShadow: [BoxShadow(color: _C.amber.withOpacity(0.12), blurRadius: 40)],
          ),
          padding: const EdgeInsets.all(26),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _C.amber.withOpacity(0.1),
                border: Border.all(color: _C.amber.withOpacity(0.3)),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: _C.amber, size: 26),
            ),
            const SizedBox(height: 14),
            Text(title, style: const TextStyle(color: _C.text, fontSize: 17,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center,
                style: const TextStyle(color: _C.textSub, fontSize: 13, height: 1.5)),
            const SizedBox(height: 22),
            _GradBtn(label: 'OK', fullWidth: true, onTap: () => Navigator.pop(ctx)),
          ]),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(children: [
        Positioned.fill(child: _AnimatedBg(controller: _bgCtrl)),
        SafeArea(
          child: FadeTransition(
            opacity: _entrance,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              child: Column(children: [
                _buildProfileCard(),
                const SizedBox(height: 16),
                _buildVideoCard(),
                const SizedBox(height: 20),
                _buildModeToggle(),
                const SizedBox(height: 16),
                _buildTargetInput(),
                const SizedBox(height: 14),
                _buildBugSelector(),
                const SizedBox(height: 14),
                _buildSenderCard(),
                const SizedBox(height: 28),
                _buildSendButton(),
                const SizedBox(height: 12),
                if (_responseMsg != null) _buildResultBanner(),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildProfileCard() {
    final rColor = _roleColor(widget.role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border),
        boxShadow: [BoxShadow(color: _C.blue.withOpacity(0.07), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: rColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: rColor.withOpacity(0.4), width: 2),
            boxShadow: [BoxShadow(color: rColor.withOpacity(0.25), blurRadius: 14)],
          ),
          child: Icon(Icons.person_rounded, color: rColor, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.username, style: const TextStyle(color: _C.text, fontSize: 16,
              fontWeight: FontWeight.w800, letterSpacing: -0.3)),
          const SizedBox(height: 4),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: rColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: rColor.withOpacity(0.3)),
              ),
              child: Text(widget.role.toUpperCase(),
                  style: TextStyle(color: rColor, fontSize: 10,
                      fontWeight: FontWeight.w800, letterSpacing: 0.8)),
            ),
            const SizedBox(width: 8),
            Text('Exp: ${widget.expiredDate}',
                style: const TextStyle(color: _C.textSub, fontSize: 11)),
          ]),
        ])),
        Column(children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: _C.green,
                boxShadow: [BoxShadow(color: Color(0x5522C55E), blurRadius: 8)]),
          ),
          const SizedBox(height: 3),
          const Text('LIVE', style: TextStyle(color: _C.green, fontSize: 8,
              fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ]),
      ]),
    );
  }

  Widget _buildVideoCard() {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.borderLit),
        boxShadow: [BoxShadow(color: _C.blue.withOpacity(0.12), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: _videoReady && _chewieCtrl != null
          ? Stack(children: [
              AspectRatio(aspectRatio: _videoCtrl.value.aspectRatio,
                  child: Chewie(controller: _chewieCtrl!)),
              Positioned(top: 0, left: 0, right: 0,
                child: Container(height: 2,
                  decoration: const BoxDecoration(gradient: LinearGradient(
                    colors: [Colors.transparent, _C.blueMid, Colors.transparent])))),
            ])
          : const SizedBox(height: 180, child: Center(child: _DotsLoader())),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
      ),
      child: Row(children: [
        _ModeTab(icon: Icons.phone_android_rounded, label: 'Bug Nomor',
          active: _bugMode == 'number',
          onTap: () => setState(() { _bugMode = 'number'; targetCtrl.clear(); })),
        _ModeTab(icon: Icons.group_rounded, label: 'Bug Group',
          active: _bugMode == 'group',
          onTap: () => setState(() { _bugMode = 'group'; targetCtrl.clear(); })),
      ]),
    );
  }

  Widget _buildTargetInput() {
    return _InputSection(
      icon: _bugMode == 'number' ? Icons.phone_android_rounded : Icons.link_rounded,
      label: _bugMode == 'number' ? 'Nomor Target' : 'Link Grup WhatsApp',
      child: _BugInput(
        controller: targetCtrl,
        hint: _bugMode == 'number' ? 'Contoh: +62812xxxxxxxx' : 'Contoh: https://chat.whatsapp.com/...',
        keyboardType: _bugMode == 'number' ? TextInputType.phone : TextInputType.url,
        icon: _bugMode == 'number' ? Icons.phone_android_rounded : Icons.link_rounded,
      ),
    );
  }

  Widget _buildBugSelector() {
    return _InputSection(
      icon: Icons.bug_report_rounded,
      label: 'Pilih Bug',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedBugId.isNotEmpty ? selectedBugId : null,
            isExpanded: true,
            dropdownColor: _C.card,
            icon: const Icon(Icons.expand_more_rounded, color: _C.textSub, size: 20),
            style: const TextStyle(color: _C.text, fontSize: 14, fontWeight: FontWeight.w500),
            items: widget.listBug.map((bug) {
              return DropdownMenuItem<String>(
                value: bug['bug_id'],
                child: Row(children: [
                  Container(width: 7, height: 7,
                      decoration: BoxDecoration(shape: BoxShape.circle,
                          color: _C.blueLight.withOpacity(0.7))),
                  const SizedBox(width: 10),
                  Text(bug['bug_name'], style: const TextStyle(color: _C.text)),
                ]),
              );
            }).toList(),
            onChanged: (v) => setState(() => selectedBugId = v ?? ''),
          ),
        ),
      ),
    );
  }

  Widget _buildSenderCard() {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.border),
        boxShadow: [BoxShadow(color: _C.blue.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _C.border.withOpacity(0.6)))),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: _C.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9), border: Border.all(color: _C.borderLit)),
              child: const Icon(FontAwesomeIcons.server, color: _C.blueLight, size: 14),
            ),
            const SizedBox(width: 12),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sender Type', style: TextStyle(color: _C.text, fontSize: 14, fontWeight: FontWeight.w700)),
              Text('Pilih sumber nomor pengirim', style: TextStyle(color: _C.textSub, fontSize: 11)),
            ]),
            const Spacer(),
            // Refresh button
            GestureDetector(
              onTap: _loadGlobalSenders,
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: _C.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _C.border),
                ),
                child: _isLoadingSenders
                    ? const Padding(padding: EdgeInsets.all(7),
                        child: CircularProgressIndicator(strokeWidth: 2, color: _C.blueLight))
                    : const Icon(Icons.refresh_rounded, color: _C.textSub, size: 16),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(child: _SenderOption(
              icon: FontAwesomeIcons.globe,
              label: 'Global',
              sublabel: _isLoadingSenders ? 'Loading...' : '${_globalSenders.length} sender',
              selected: _senderType == 'global',
              locked: !canAccessGlobalSender,
              onTap: () {
                if (!canAccessGlobalSender) {
                  _showAlert('Akses Ditolak', 'Sender Global hanya untuk Owner, Admin, Moderator, Partner & VIP!');
                  return;
                }
                setState(() => _senderType = 'global');
                _loadGlobalSenders();
              },
            )),
            const SizedBox(width: 10),
            Expanded(child: _SenderOption(
              icon: FontAwesomeIcons.userShield,
              label: 'Private',
              sublabel: 'Session lu sendiri',
              selected: _senderType == 'private',
              locked: false,
              onTap: () => setState(() => _senderType = 'private'),
            )),
          ]),
        ),
        if (_senderType == 'global' && _globalSenders.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _C.surface, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _C.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.format_list_bulleted_rounded, color: _C.textSub, size: 13),
                const SizedBox(width: 6),
                Text('${_globalSenders.length} sender aktif',
                    style: const TextStyle(color: _C.textSub, fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 8),
              ...(_globalSenders.take(3).map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Container(width: 5, height: 5,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: _C.green)),
                  const SizedBox(width: 8),
                  Text(s, style: const TextStyle(color: _C.blueLight, fontSize: 11, fontFamily: 'monospace')),
                ]),
              ))),
              if (_globalSenders.length > 3)
                Text('+ ${_globalSenders.length - 3} lainnya...',
                    style: const TextStyle(color: _C.textDim, fontSize: 10)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _sendBtnCtrl,
      builder: (_, __) => GestureDetector(
        onTap: _isSending ? null : _sendBug,
        child: Transform.scale(
          scale: _isSending ? 1.0 : _sendPulse.value,
          child: Container(
            height: 62, width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B6FBD), Color(0xFF2D8FE8), Color(0xFF56AEF5)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(
                color: _C.blueMid.withOpacity(_isSending ? 0.2 : _sendGlow.value * 0.55),
                blurRadius: 28, offset: const Offset(0, 8),
              )],
            ),
            child: Stack(children: [
              if (_isSending)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedBuilder(
                    animation: _waveCtrl,
                    builder: (_, __) => CustomPaint(
                      painter: _WavePainter(_waveCtrl.value),
                      size: const Size(double.infinity, 62),
                    ),
                  ),
                ),
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isSending
                      ? const Row(key: ValueKey('sending'), mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
                          SizedBox(width: 12),
                          Text('Mengirim Bug...', style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w800, fontSize: 16)),
                        ])
                      : const Row(key: ValueKey('idle'), mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 12),
                          Text('KIRIM BUG ATTACK', style: TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
                        ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildResultBanner() {
    if (_responseMsg == null) return const SizedBox();
    final parts = _responseMsg!.split('|');
    final type  = parts[0];
    final msg   = parts.length > 1 ? parts[1] : '';

    Color color;
    IconData icon;
    switch (type) {
      case 'success': color = _C.green;   icon = Icons.check_circle_rounded; break;
      case 'warning': color = _C.amber;   icon = Icons.warning_rounded; break;
      default:        color = _C.red;     icon = Icons.error_rounded;
    }

    return FadeTransition(
      opacity: _resultFade,
      child: SlideTransition(
        position: _resultSlide,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.35)),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 16)],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 32, height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12)),
                child: Icon(icon, color: color, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                type == 'success' ? 'Berhasil' : type == 'warning' ? 'Peringatan' : 'Gagal',
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(msg, style: const TextStyle(color: _C.textSub, fontSize: 12, height: 1.4)),
            ])),
            GestureDetector(
              onTap: () { setState(() => _responseMsg = null); _resultCtrl.reset(); },
              child: const Icon(Icons.close_rounded, color: _C.textDim, size: 16),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────
class _ModeTab extends StatelessWidget {
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  const _ModeTab({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? _C.blueMid.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: active ? Border.all(color: _C.blueMid.withOpacity(0.4)) : null,
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16, color: active ? _C.blueLight : _C.textDim),
            const SizedBox(width: 7),
            Text(label, style: TextStyle(color: active ? _C.blueLight : _C.textDim,
                fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
          ]),
        ),
      ),
    );
  }
}

class _InputSection extends StatelessWidget {
  final IconData icon; final String label; final Widget child;
  const _InputSection({required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: _C.card, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _C.border.withOpacity(0.6)))),
          child: Row(children: [
            Icon(icon, color: _C.textSub, size: 15),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: _C.textSub, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(12), child: child),
      ]),
    );
  }
}

class _BugInput extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final IconData icon;
  const _BugInput({required this.controller, required this.hint,
      required this.keyboardType, required this.icon});

  @override
  State<_BugInput> createState() => _BugInputState();
}

class _BugInputState extends State<_BugInput> {
  bool _focused = false;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _focused ? _C.blueMid : _C.border, width: _focused ? 1.5 : 1.0),
        boxShadow: _focused
            ? [BoxShadow(color: _C.blueMid.withOpacity(0.1), blurRadius: 14, offset: const Offset(0, 4))]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        keyboardType: widget.keyboardType,
        style: const TextStyle(color: _C.text, fontSize: 14, fontWeight: FontWeight.w500),
        cursorColor: _C.blueMid,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: _C.textDim, fontSize: 13),
          prefixIcon: Icon(widget.icon, color: _focused ? _C.blueLight : _C.textSub, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _SenderOption extends StatefulWidget {
  final IconData icon; final String label; final String sublabel;
  final bool selected; final bool locked; final VoidCallback onTap;
  const _SenderOption({required this.icon, required this.label, required this.sublabel,
      required this.selected, required this.locked, required this.onTap});

  @override
  State<_SenderOption> createState() => _SenderOptionState();
}

class _SenderOptionState extends State<_SenderOption> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? _C.green : _C.textSub;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: widget.selected ? _C.green.withOpacity(0.08) : _C.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.selected ? _C.green.withOpacity(0.4) : _C.border,
              width: widget.selected ? 1.5 : 1,
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, children: [
              Icon(widget.icon, color: color, size: 20),
              if (widget.locked)
                Positioned(right: -4, top: -4,
                  child: Container(width: 12, height: 12,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: _C.amber,
                        border: Border.all(color: _C.card, width: 1.5)),
                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 7))),
            ]),
            const SizedBox(height: 8),
            Text(widget.label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(widget.sublabel, textAlign: TextAlign.center,
                style: const TextStyle(color: _C.textDim, fontSize: 10, height: 1.3)),
            if (widget.selected) ...[
              const SizedBox(height: 6),
              Container(width: 20, height: 3,
                  decoration: BoxDecoration(color: _C.green, borderRadius: BorderRadius.circular(2))),
            ],
          ]),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double t;
  _WavePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.06)..style = PaintingStyle.fill;
    final path = Path();
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = size.height * 0.5 +
          math.sin((x / size.width * 4 * math.pi) + (t * math.pi * 2)) * size.height * 0.15;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}

class _DotsLoader extends StatefulWidget {
  const _DotsLoader();

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
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
              child: Container(width: 8, height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: _C.blueMid.withOpacity(0.4 + s * 0.6))),
            ),
          );
        }),
      ),
    );
  }
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
    final grid = Paint()..color = _C.border.withOpacity(0.22)..strokeWidth = 0.5;
    const step = 38.0;
    for (double x = 0; x < size.width; x += step)
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    for (double y = 0; y < size.height; y += step)
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        _C.blue.withOpacity(0.10 + math.sin(t * math.pi * 2) * 0.03),
        Colors.transparent,
      ], radius: 0.9).createShader(
          Rect.fromCircle(center: Offset(size.width / 2, 0), radius: size.width));
    canvas.drawCircle(Offset(size.width / 2, 0), size.width, glow);
  }

  @override
  bool shouldRepaint(_BgPainter old) => old.t != t;
}

class _GradBtn extends StatefulWidget {
  final String label; final VoidCallback onTap; final bool fullWidth;
  const _GradBtn({required this.label, required this.onTap, this.fullWidth = false});

  @override
  State<_GradBtn> createState() => _GradBtnState();
}

class _GradBtnState extends State<_GradBtn> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) { setState(() => _down = false); widget.onTap(); },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 46,
          width: widget.fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: _C.btnGrad,
            borderRadius: BorderRadius.circular(13),
            boxShadow: _down ? [] : [
              BoxShadow(color: _C.blueMid.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: Center(child: Text(widget.label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
        ),
      ),
    );
  }
}