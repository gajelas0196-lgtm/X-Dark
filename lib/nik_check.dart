// nik_check_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NIKCheckPage extends StatefulWidget {
  final String sessionKey;

  const NIKCheckPage({super.key, required this.sessionKey});

  @override
  State<NIKCheckPage> createState() => _NIKCheckPageState();
}

class _NIKCheckPageState extends State<NIKCheckPage> {
  final TextEditingController _nikController = TextEditingController();
  Map<String, dynamic>? _nikData;
  bool _isLoading = false;

  // COLOR THEME: BLACK & BLUE (RYU EDITION)
  final Color _themeColor = const Color(0xFF00D4AA); // Material Blue
  final Color _cardColor = const Color(0xFF111820); // Dark Grey Card
  final Color _inputColor = const Color(0xFF111820); // Input Field Dark

  // [PERBAIKAN RYU] Logic _checkNIK yang hilang tadi gue isi placeholder biar aman
  Future<void> _checkNIK() async {
    if (_nikController.text.length != 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("NIK harus 16 digit!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    _nikData = null;

    try {
      // Placeholder API call - sesuaikan dengan endpoint asli Tuan
      final response = await http.get(
        Uri.parse("http://panel4.ikyhost.cloud:2283/api/tools/nik/check?nik=${_nikController.text}&key=${widget.sessionKey}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true || data['data'] != null) {
          setState(() {
            _nikData = data;
          });
        } else {
          _showError("Data tidak ditemukan.");
        }
      } else {
        _showError("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'NIK Check',
          style: TextStyle(
            color: Colors.white, // Diubah jadi putih
            fontFamily: 'Rajdhani',
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Diubah jadi putih
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor, 
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _themeColor.withOpacity(0.2)), 
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter NIK Number',
                    style: TextStyle(
                      color: Colors.white, // Diubah jadi putih
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Rajdhani',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nikController,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Rajdhani'),
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    decoration: InputDecoration(
                      hintText: 'Enter 16-digit NIK number',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontFamily: 'Rajdhani'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: _inputColor, 
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _checkNIK,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _themeColor, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Check NIK', style: TextStyle(fontFamily: 'Rajdhani', fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_nikData != null) _buildNIKResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildNIKResult() {
    // Handling jika data nested (disesuaikan dengan response API umum)
    Map<String, dynamic> nikData;
    Map<String, dynamic> metadata;

    try {
      final data = _nikData!['data'] as Map<String, dynamic>;
      nikData = data['data'] as Map<String, dynamic>;
      metadata = data['metadata'] as Map<String, dynamic>;
    } catch (e) {
      // Fallback jika struktur datanya flat atau beda
      nikData = _nikData!;
      metadata = {};
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _themeColor.withOpacity(0.2)), 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NIK Information',
            style: TextStyle(
              color: Colors.white, // Diubah jadi putih
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Rajdhani',
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('NIK', nikData['nik'] ?? 'N/A'),
          _buildInfoRow('Name', nikData['nama'] ?? 'N/A'),
          _buildInfoRow('Gender', nikData['kelamin'] ?? 'N/A'),
          _buildInfoRow('Birth Date', nikData['tempat_lahir'] ?? 'N/A'),
          _buildInfoRow('Age', nikData['usia'] ?? 'N/A'),
          _buildInfoRow('Province', nikData['provinsi'] ?? 'N/A'),
          _buildInfoRow('Regency', nikData['kabupaten'] ?? 'N/A'),
          _buildInfoRow('District', nikData['kecamatan'] ?? 'N/A'),
          _buildInfoRow('Sub-district', nikData['kelurahan'] ?? 'N/A'),
          _buildInfoRow('Address', nikData['alamat'] ?? 'N/A'),
          _buildInfoRow('Zodiac', nikData['zodiak'] ?? 'N/A'),
          _buildInfoRow('Next Birthday', nikData['ultah_mendatang'] ?? 'N/A'),
          _buildInfoRow('Pasaran', nikData['pasaran'] ?? 'N/A'),
          const SizedBox(height: 16),
          const Text(
            'Metadata',
            style: TextStyle(
              color: Colors.white, // Diubah jadi putih
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Rajdhani',
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Search Method', metadata['metode_pencarian'] ?? 'N/A'),
          _buildInfoRow('Area Code', metadata['kode_wilayah'] ?? 'N/A'),
          _buildInfoRow('Sequence Number', metadata['nomor_urut'] ?? 'N/A'),
          _buildInfoRow('Age Category', metadata['kategori_usia'] ?? 'N/A'),
          _buildInfoRow('Area Type', metadata['jenis_wilayah'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                fontFamily: 'Rajdhani',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Rajdhani',
              ),
            ),
          ),
        ],
      ),
    );
  }
}