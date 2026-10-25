// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:ui';

class CustomAttackPage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listPayload;
  final String role; 
  final String expiredDate;

  const CustomAttackPage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listPayload,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<CustomAttackPage> createState() => _CustomAttackPageState();
}

class _CustomAttackPageState extends State<CustomAttackPage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  final qtyController = TextEditingController(text: "5");
  final delayController = TextEditingController(text: "100");
  static const String baseUrl = "http://alfa-store-officials.alfamarket2.my.id:3771";

  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  
  // State variables
  List<String> selectedBugs = [];
  String _senderType = "global"; // "global" or "private"
  bool _isSending = false;
  Map<String, String> _senderTypeLimits = {};
  int _activeStep = 0;

  // COUNTER ASLI (Bukan Pajangan - Update tiap hit sukses)
  int _totalSent = 0; 

  // WARNA CUSTOM YANG DIROMBAK JADI BIRU
  final Color _mainNeon = const Color(0xFF00D4AA); 
  final Color _bgCard = const Color(0xFF0D1720).withOpacity(0.6);

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    if (widget.listPayload.isNotEmpty) {
      selectedBugs.add(widget.listPayload[0]['bug_id'].toString());
    }
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/banner.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _videoInitialized = true);
          _videoController.setLooping(true);
          _videoController.play();
          _videoController.setVolume(0);
        }
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    targetController.dispose();
    qtyController.dispose();
    delayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // BACKGROUND LAYER: VIDEO BLURRED
          if (_videoInitialized)
            SizedBox.expand(
              child: Stack(
                children: [
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.black.withOpacity(0.7)),
                  ),
                ],
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                _buildHeaderTop(),
                Expanded(
                  child: SingleChildScrollView(
                    // FIX MENTOK SCROLL: Diubah jadi Clamping & ditambah bottom padding
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 20, right: 20, bottom: 100),
                    child: Column(
                      children: [
                        _buildProfileMantaStyle(),
                        const SizedBox(height: 25),
                        _buildTargetPanel(),
                        const SizedBox(height: 25),
                        _buildSenderTypeSelector(), 
                        const SizedBox(height: 25),
                        _buildBugSelectorLabel(),
                        const SizedBox(height: 12),
                        _buildBugHorizontalList(),
                        const SizedBox(height: 25),
                        _buildConfigAndExecute(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTop() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: _mainNeon, size: 24),
              const SizedBox(width: 10),
              Text("X•Dark", style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani', letterSpacing: 1.5)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.1))),
            child: Text("V1.0", style: TextStyle(color: _mainNeon, fontSize: 10, fontFamily: 'Rajdhani', fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildProfileMantaStyle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _bgCard,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 75, height: 75,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _mainNeon, width: 2)),
                    child: const CircleAvatar(
                      backgroundColor: Colors.black,
                      backgroundImage: AssetImage('assets/images/winclick.png'),
                    ),
                  ),
                  Positioned(
                    bottom: -10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                      decoration: BoxDecoration(
                        color: _mainNeon,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: _mainNeon.withOpacity(0.4), blurRadius: 10)],
                      ),
                      child: Text(
                        widget.role.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'Rajdhani', letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 25),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.username, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani')),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, color: _mainNeon, size: 12),
                        const SizedBox(width: 5),
                        Text("EXP: ${widget.expiredDate}", style: TextStyle(color: const Color(0xFF00D4AA).withOpacity(0.4), fontSize: 11, fontFamily: 'Rajdhani')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40), 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(FontAwesomeIcons.bug, "$_totalSent", "Total Bugs"),
              _statItem(FontAwesomeIcons.boltLightning, "GACOR", "Success Rate"),
              _statItem(Icons.verified, "ACTIVE", "Status"),
            ],
          )
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String val, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _mainNeon.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: _mainNeon, size: 16),
        ),
        const SizedBox(height: 8),
        Text(val, style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Rajdhani')),
        Text(label, style: TextStyle(color: const Color(0xFF00D4AA).withOpacity(0.4), fontSize: 9, fontFamily: 'Rajdhani')),
      ],
    );
  }

  Widget _buildTargetPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.smartphone, color: _mainNeon, size: 18),
              const SizedBox(width: 10),
              Text("NOMOR TARGET", style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Rajdhani')),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(15)),
            child: TextField(
              controller: targetController,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontFamily: 'Rajdhani', letterSpacing: 1.5, fontSize: 18),
              decoration: InputDecoration(
                hintText: "e.g. +62xxxxxxxxxxxx", 
                hintStyle: TextStyle(color: const Color(0xFF00D4AA).withOpacity(0.1)), 
                border: InputBorder.none,
                icon: Icon(Icons.public, color: const Color(0xFF00D4AA).withOpacity(0.25), size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFF00D4AA).withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(Icons.send_rounded, color: Colors.blueAccent, size: 14),
            ),
            const SizedBox(width: 10),
            Text("PILIH SENDER", style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Rajdhani')),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            // PRIVATE (KIRI)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _senderType = "private"),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _senderType == "private" ? _mainNeon.withOpacity(0.15) : Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _senderType == "private" ? _mainNeon : const Color(0xFF00D4AA).withOpacity(0.1), width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: _senderType == "private" ? _mainNeon.withOpacity(0.2) : const Color(0xFF00D4AA).withOpacity(0.05), shape: BoxShape.circle),
                            child: Icon(Icons.person_outline, color: _senderType == "private" ? _mainNeon : const Color(0xFF00D4AA).withOpacity(0.25), size: 18),
                          ),
                          const SizedBox(height: 12),
                          Text("PRIVATE", style: TextStyle(color: _senderType == "private" ? _mainNeon : Colors.white.withOpacity(0.85), fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Rajdhani')),
                          const SizedBox(height: 4),
                          Text("Sender Pribadi", style: TextStyle(color: const Color(0xFF00D4AA).withOpacity(0.4), fontSize: 10, fontFamily: 'Rajdhani')),
                        ],
                      ),
                      if (_senderType == "private")
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _mainNeon,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: _mainNeon.withOpacity(0.4), blurRadius: 10)],
                            ),
                            child: const Icon(Icons.check, color: Colors.black, size: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            // GLOBAL (KANAN)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _senderType = "global"),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _senderType == "global" ? _mainNeon.withOpacity(0.15) : Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _senderType == "global" ? _mainNeon : const Color(0xFF00D4AA).withOpacity(0.1), width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: _senderType == "global" ? _mainNeon.withOpacity(0.2) : const Color(0xFF00D4AA).withOpacity(0.05), shape: BoxShape.circle),
                            child: Icon(Icons.public, color: _senderType == "global" ? _mainNeon : const Color(0xFF00D4AA).withOpacity(0.25), size: 18),
                          ),
                          const SizedBox(height: 12),
                          Text("GLOBAL", style: TextStyle(color: _senderType == "global" ? _mainNeon : Colors.white.withOpacity(0.85), fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Rajdhani')),
                          const SizedBox(height: 4),
                          Text("Sender Global", style: TextStyle(color: const Color(0xFF00D4AA).withOpacity(0.4), fontSize: 10, fontFamily: 'Rajdhani')),
                        ],
                      ),
                      if (_senderType == "global")
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _mainNeon,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: _mainNeon.withOpacity(0.4), blurRadius: 10)],
                            ),
                            child: const Icon(Icons.check, color: Colors.black, size: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBugSelectorLabel() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: const Color(0xFF00D4AA).withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(Icons.pest_control, color: Colors.blueAccent, size: 14),
        ),
        const SizedBox(width: 10),
        Text("PiliH BUG", style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Rajdhani')),
      ],
    );
  }

  Widget _buildBugHorizontalList() {
    return SizedBox(
      height: 165,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.listPayload.length,
        itemBuilder: (context, index) {
          final bug = widget.listPayload[index];
          final id = bug['bug_id'].toString();
          final isSelected = selectedBugs.contains(id);
          return GestureDetector(
            onTap: () => setState(() => isSelected ? selectedBugs.remove(id) : selectedBugs.add(id)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 160,
              margin: const EdgeInsets.only(right: 15),
              decoration: BoxDecoration(
                color: isSelected ? Colors.transparent : Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: isSelected ? _mainNeon : const Color(0xFF00D4AA).withOpacity(0.1), width: 2),
                gradient: isSelected ? LinearGradient(colors: [_mainNeon.withOpacity(0.1), Colors.transparent], begin: Alignment.topLeft) : null,
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: isSelected ? _mainNeon.withOpacity(0.2) : const Color(0xFF00D4AA).withOpacity(0.05), shape: BoxShape.circle),
                          child: Icon(Icons.security, color: isSelected ? _mainNeon : const Color(0xFF00D4AA).withOpacity(0.25), size: 18),
                        ),
                        const Spacer(),
                        Text(bug['bug_name'].toString().toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Rajdhani', height: 1.2)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.1))),
                          child: Text(id, style: TextStyle(color: const Color(0xFF00D4AA).withOpacity(0.4), fontSize: 9, fontFamily: 'Rajdhani')),
                        )
                      ],
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      bottom: 15, right: 15,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.lightBlueAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.lightBlueAccent.withOpacity(0.4), blurRadius: 10)]),
                        child: const Icon(Icons.check, color: Colors.black, size: 12),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfigAndExecute() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _bgCard, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _miniInput("QTY", qtyController)),
              const SizedBox(width: 15),
              Expanded(child: _miniInput("DELAY", delayController)),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _isSending ? null : _sendAttack,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(colors: [_mainNeon, _mainNeon.withOpacity(0.7)]),
                boxShadow: [BoxShadow(color: _mainNeon.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 5))],
              ),
              child: Center(
                child: _isSending 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text("INITIALIZE ATTACK", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: 'Rajdhani', fontSize: 16)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _miniInput(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: const Color(0xFF00D4AA).withOpacity(0.4), fontSize: 10, fontFamily: 'Rajdhani', fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontFamily: 'Rajdhani'),
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ],
    );
  }

  Future<void> _sendAttack() async {
    final target = targetController.text.trim();
    
    // VALIDASI KOSONG
    if (target.isEmpty) {
      _showCustomDialog("INVALID NUMBER", "Nomor target tidak boleh kosong.", isError: true);
      return;
    }

    // VALIDASI FORMAT 08xxx (WAJIB NO ERROR)
    if (target.startsWith('08') || target.startsWith('8')) {
      _showCustomDialog("INVALID NUMBER", "Gunakan nomor internasional (628xxx), bukan 08xxx.", isError: true);
      return;
    }

    // VALIDASI BUG BELUM DIPILIH
    if (selectedBugs.isEmpty) {
      _showCustomDialog("DATA BELUM LENGKAP", "Silakan pilih minimal satu bug.", isError: true);
      return;
    }

    setState(() => _isSending = true);
    try {
      final bugsParam = selectedBugs.join(',');
      final url = "$baseUrl/api/whatsapp/customBug?key=${widget.sessionKey}&target=$target&bug=$bugsParam&qty=${qtyController.text}&delay=${delayController.text}";
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      final data = jsonDecode(res.body);
      
      if (data["valid"] == true) {
        int inputQty = int.tryParse(qtyController.text) ?? 0;
        setState(() => _totalSent += inputQty);
        _showCustomDialog("ATTACK SUCCESS", "Bug berhasil dikirim ke target.", isSuccess: true);
      } else {
        _showCustomDialog("SYSTEM FAILED", "Terjadi kesalahan pada sistem saat mengirim.", isError: true);
      }
    } catch (e) {
      _showCustomDialog("CONNECTION ERROR", "Tidak dapat terhubung ke server.", isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // CUSTOM DIALOG POPUP GAYA GAMBAR
  void _showCustomDialog(String title, String subtitle, {bool isSuccess = false, bool isError = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF090E14), // Background hitam dop
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _mainNeon.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(color: _mainNeon.withOpacity(0.1), blurRadius: 20, spreadRadius: 2)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ICON ATAS
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isError ? Colors.red.withOpacity(0.1) : isSuccess ? Colors.green.withOpacity(0.1) : const Color(0xFF00D4AA).withOpacity(0.1),
                  ),
                  child: Icon(
                    isError ? Icons.close : isSuccess ? Icons.check_circle : Icons.info_outline,
                    color: isError ? Colors.red : isSuccess ? Colors.green : _mainNeon,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                
                // JUDUL BESAR
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Rajdhani',
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                
                // DESKRIPSI KECIL
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontFamily: 'Rajdhani',
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 25),
                
                // TOMBOL OK BIRU
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _mainNeon,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: _mainNeon.withOpacity(0.3), blurRadius: 10)],
                    ),
                    child: const Center(
                      child: Text(
                        "OK",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani', fontSize: 16, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}