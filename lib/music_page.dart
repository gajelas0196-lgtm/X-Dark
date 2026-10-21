import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart'; // Import package audio

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  List<dynamic> laguList = [];
  bool isLoading = true;

  // Variabel untuk pemutar musik
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl; // Untuk ngecek lagu mana yang lagi nyala

  @override
  void initState() {
    super.initState();
    fetchMusic();
  }

  // Fungsi ambil data dari server Pterodactyl
  Future<void> fetchMusic() async {
    try {
      final response = await http.get(
        // Pastikan query 'q' sesuai dengan yang dicari
        Uri.parse('http://panel4.ikyyhost.cloud:2283/api/music/search?q=coldplay'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          laguList = data['tracks'] ?? []; // Ambil list lagu
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  // Fungsi untuk memutar / menghentikan lagu
  Future<void> _playMusic(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preview lagu tidak tersedia")),
      );
      return;
    }

    try {
      if (_currentlyPlayingUrl == url) {
        // Kalau lagu yang diklik sama dengan yang lagi diputar, maka Pause
        await _audioPlayer.pause();
        setState(() => _currentlyPlayingUrl = null);
      } else {
        // Kalau beda lagu, putar lagu baru
        await _audioPlayer.setUrl(url);
        _audioPlayer.play();
        setState(() => _currentlyPlayingUrl = url);
      }
    } catch (e) {
      print("Error memutar lagu: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // Wajib ditutup biar ga bocor memori
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Tema gelap
      appBar: AppBar(
        title: const Text("Music Player", style: TextStyle(fontFamily: 'Rajdhani')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
          : laguList.isEmpty
              ? const Center(child: Text("Lagu tidak ditemukan", style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: laguList.length,
                  itemBuilder: (context, index) {
                    final lagu = laguList[index];
                    final isPlaying = _currentlyPlayingUrl == lagu['preview_url'];

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        // Tampilkan gambar album dari Spotify
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            lagu['image'] ?? '',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.music_note, color: Colors.tealAccent, size: 40),
                          ),
                        ),
                        title: Text(
                          lagu['title'] ?? 'Judul Tidak Diketahui', 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Rajdhani'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          lagu['artist'] ?? 'Artis Tidak Diketahui', 
                          style: const TextStyle(color: Colors.grey, fontFamily: 'Rajdhani'),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                            color: Colors.tealAccent,
                            size: 36,
                          ),
                          onPressed: () => _playMusic(lagu['preview_url']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}