import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MiniMusicPlayer extends StatefulWidget {
  const MiniMusicPlayer({super.key});

  @override
  State<MiniMusicPlayer> createState() => _MiniMusicPlayerState();
}

class _MiniMusicPlayerState extends State<MiniMusicPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  double volume = 0.5;

  // DAFTAR LAGU DEFAULT (Ganti URL-nya dengan lagu asli kamu)
  final List<Map<String, String>> daftarLagu = [
    {
      "judul": "Rumah ke Rumah",
      "url": "assets/music/Rumah-Ke-Rumah.mp3"
    },
    {
     
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      // Set lagu pertama sebagai default
      await _audioPlayer.setUrl(daftarLagu[_currentIndex]['url']!);
      _audioPlayer.setVolume(volume);
    } catch (e) {
      print("Gagal load lagu default: $e");
    }
  }

  void _togglePlay() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
    setState(() => isPlaying = !isPlaying);
  }

  // Fungsi untuk ganti lagu saat dipilih dari list
  Future<void> _pilihLagu(int index) async {
    setState(() {
      _currentIndex = index;
      isPlaying = true;
    });
    await _audioPlayer.setUrl(daftarLagu[index]['url']!);
    await _audioPlayer.play();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // ==========================================
  // BOTTOM SHEET (Tampilan Menu Musik)
  // ==========================================
  void _tampilkanMenuMusik() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Biar bisa custom radius
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder( // Agar state di dalam bottom sheet bisa berubah
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7, // 70% layar
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A2E), // Warna gelap kebiruan (sesuaikan dengan tema)
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  // Garis kecil di atas
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  
                  // Ikon dan Judul
                  const Icon(Icons.music_note, color: Colors.cyanAccent, size: 40),
                  const SizedBox(height: 10),
                  const Text("BACKGROUND MUSIC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 18)),
                  const SizedBox(height: 5),
                  Text("🎵 ${daftarLagu[_currentIndex]['judul']}", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                  
                  const SizedBox(height: 20),

                  // List Lagu
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: daftarLagu.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _currentIndex;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.music_note, color: isSelected ? Colors.cyanAccent : Colors.grey),
                            title: Text(
                              daftarLagu[index]['judul']!,
                              style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 14, fontFamily: 'Rajdhani'),
                            ),
                            onTap: () {
                              _pilihLagu(index);
                              setModalState(() {}); // Update tampilan list
                              setState(() {}); // Update tombol play di header
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  // Tombol Play / Pause
                  TextButton.icon(
                    onPressed: () {
                      _togglePlay();
                      setModalState(() {});
                      setState(() {});
                    },
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                    label: Text(isPlaying ? "PAUSE" : "PLAY", style: const TextStyle(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.bold)),
                  ),

                  // Slider Volume
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Icon(Icons.volume_down, color: Colors.grey),
                        Expanded(
                          child: Slider(
                            value: volume,
                            min: 0.0, max: 1.0,
                            activeColor: Colors.cyanAccent,
                            inactiveColor: Colors.grey[800],
                            onChanged: (val) {
                              setModalState(() => volume = val);
                              _audioPlayer.setVolume(val);
                            },
                          ),
                        ),
                        Text("${(volume * 100).toInt()}%", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // WIDGET DI HEADER (Tombol Kecil)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tampilkanMenuMusik, // Jika diklik, munculkan Bottom Sheet
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.music_note,
          color: Colors.cyanAccent,
          size: 18,
        ),
      ),
    );
  }
}