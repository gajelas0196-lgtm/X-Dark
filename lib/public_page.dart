import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PublicChatPage extends StatefulWidget {
  final String username;
  const PublicChatPage({super.key, required this.username});

  @override
  State<PublicChatPage> createState() => _PublicChatPageState();
}

class _PublicChatPageState extends State<PublicChatPage> {
  // --- KONFIGURASI URL SERVER ---
  final String baseUrl = "http://alfa-store-officials.alfamarket2.my.id:3771"; 

  // Controllers
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // State
  List<dynamic> _messages = [];
  Timer? _refreshTimer;
  bool _isSending = false;

  // --- STYLE BARU (BLACK & BLUE THEME) ---
  // UBAH: Pink diganti jadi Blue
  final Color _primaryPink = const Color(0xFF00D4AA); // Material Blue
  final Color _softPink = const Color(0xFF4DECD0); // Light Blue
  final Color _bgDark = const Color(0xFF090E14); // Pure Black
  final Color _bubbleMe = const Color(0xFF00D4AA).withOpacity(0.8); // Blue Bubble
  final Color _bubbleOther = const Color(0xFF2C2C2C); // Dark Grey (Tetap)

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    
    // Auto Refresh Chat Setiap 2 Detik (Polling)
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchMessages();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- LOGIC ---

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/chat"));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          // Sorting agar pesan terbaru di bawah
          data.sort((a, b) => a['timestamp'].toString().compareTo(b['timestamp'].toString()));
          
          if (mounted) {
            setState(() {
              _messages = data;
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      // Silent error for polling
      print("Polling error: $e");
    }
  }

  Future<void> _sendMessage() async {
    if (_msgController.text.isEmpty) return;
    
    setState(() => _isSending = true);

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": widget.username,
          "message": _msgController.text,
        }),
      );

      if (response.statusCode == 200) {
        _msgController.clear();
        _fetchMessages(); // Refresh langsung
      } else {
        _showError("Gagal mengirim pesan");
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani')), 
        backgroundColor: Colors.red
      )
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- UI BUILDER (BLACK & BLUE) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark, 
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            _buildHeader(),

            // CHAT LIST
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['username'] == widget.username;
                  return _buildChatBubble(msg, isMe);
                },
              ),
            ),

            // INPUT AREA
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: _primaryPink.withOpacity(0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.public, color: _primaryPink, size: 20),
              const SizedBox(width: 10),
              Text(
                "Public Chat",
                style: TextStyle(
                  color: _primaryPink, 
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Rajdhani'
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          Text("Live • ${_messages.length} messages", 
            style: TextStyle(color: _softPink.withOpacity(0.7), fontSize: 11, fontFamily: 'Rajdhani')),
        ],
      ),
    );
  }

  Widget _buildChatBubble(dynamic msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Nama User (Jika bukan saya)
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(msg['username'] ?? "Unknown", 
                  style: TextStyle(color: _softPink, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani')),
              ),
            
            // Bubble Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? _bubbleMe : _bubbleOther,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 5),
                  bottomRight: Radius.circular(isMe ? 5 : 20),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg['message'] ?? "", style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Rajdhani')),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(msg['time'] ?? "", 
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, fontFamily: 'Rajdhani')),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111820), // Abu gelap
        border: Border(top: BorderSide(color: _primaryPink.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _primaryPink.withOpacity(0.3)),
              ),
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani'),
                cursorColor: _primaryPink,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: _softPink.withOpacity(0.4), fontFamily: 'Rajdhani'),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isSending ? Colors.grey : _primaryPink,
                shape: BoxShape.circle,
                boxShadow: [
                  if (!_isSending)
                    BoxShadow(color: _primaryPink.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)
                ]
              ),
              child: Icon(
                _isSending ? Icons.hourglass_top_rounded : Icons.send_rounded, 
                color: Colors.white, size: 22
              ),
            ),
          )
        ],
      ),
    );
  }
}