import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class FloatingMusicPlayer extends StatefulWidget {
  const FloatingMusicPlayer({super.key});

  @override
  State<FloatingMusicPlayer> createState() => _FloatingMusicPlayerState();
}

class _FloatingMusicPlayerState extends State<FloatingMusicPlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _player.setAsset('assets/music/Cincin.mp3'); // GANTI NAMA LAGU
      _player.setLoopMode(LoopMode.one);
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ini widget pop-up yang bisa digeser
    return Draggable(
      feedback: _buildPlayerCard(),
      childWhenDragging: const SizedBox(),
      child: _buildPlayerCard(),
    );
  }

  Widget _buildPlayerCard() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF101A2E).withOpacity(0.95),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF2D8FE8).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D8FE8).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tombol Play/Pause
            GestureDetector(
              onTap: _togglePlay,
              child: Icon(
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: const Color(0xFF56AEF5),
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
            // Teks Judul Lagu
            const Text(
              "Now Playing",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(width: 8),
            // Tombol Close (Sembunyiin)
            GestureDetector(
              onTap: () => setState(() => _isMinimized = !_isMinimized),
              child: const Icon(Icons.drag_indicator, color: Colors.grey, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}