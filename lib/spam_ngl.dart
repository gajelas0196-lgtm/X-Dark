import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NglPage extends StatefulWidget {
  const NglPage({super.key});

  @override
  State<NglPage> createState() => _NglPageState();
}

class _NglPageState extends State<NglPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool isRunning = false;
  int counter = 0;
  String statusLog = "";
  Timer? timer;

  // WARNA TEMA: BLACK & BLUE
  final Color _themeColor = const Color(0xFF00D4AA); // Material Blue

  // generate deviceId random
  String generateDeviceId(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  Future<void> sendMessage(String username, String message) async {
    final deviceId = generateDeviceId(42);
    final url = Uri.parse("https://ngl.link/api/submit");

    final headers = {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0",
      "Accept": "*/*",
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      "X-Requested-With": "XMLHttpRequest",
      "Referer": "https://ngl.link/$username",
      "Origin": "https://ngl.link"
    };

    final body =
        "username=$username&question=$message&deviceId=$deviceId&gameSlug=&referrer=";

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        setState(() {
          counter++;
          statusLog = "✅ [$counter] Pesan terkirim";
        });
      } else {
        setState(() {
          statusLog = "❌ Ratelimit (${response.statusCode}), tunggu 5 detik...";
        });
      }
    } catch (e) {
      setState(() {
        statusLog = "❌ Error: ${e.toString()}";
      });
    }
  }

  void startSending() {
    timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      await sendMessage(usernameController.text, messageController.text);
    });
  }

  void stopLoop() {
    timer?.cancel();
    setState(() {
      isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF00D4AA)),
        title: const Text(
          "NGL Spammer",
          style: TextStyle(
            color: Color(0xFF00D4AA),
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input Username
            TextField(
              controller: usernameController,
              style: TextStyle(color: Colors.white, fontFamily: 'Rajdhani'),
              decoration: InputDecoration(
                hintText: "Target Username",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Rajdhani'),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _themeColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00D4AA)),
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Input Message
            TextField(
              controller: messageController,
              style: TextStyle(color: Colors.white, fontFamily: 'Rajdhani'),
              decoration: InputDecoration(
                hintText: "Message",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Rajdhani'),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _themeColor.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF00D4AA)),
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            // Status Log
            Text(
              statusLog,
              style: TextStyle(
                color: _themeColor,
                fontSize: 16,
                fontFamily: 'Rajdhani',
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (counter > 0)
              Text(
                "Total terkirim: $counter",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Rajdhani',
                ),
              ),
            
            const Spacer(),

            // Tombol Start/Stop
            ElevatedButton.icon(
              onPressed: () {
                if (isRunning) {
                  stopLoop();
                } else {
                  setState(() {
                    isRunning = true;
                  });
                  startSending();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
              label: Text(
                isRunning ? "Stop" : "Start",
                style: TextStyle(
                  fontFamily: 'Rajdhani',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}