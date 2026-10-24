import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MiniMusicPlayer extends StatefulWidget {
  const MiniMusicPlayer({super.key});

  @override
  State<MiniMusicPlayer> createState() => _MiniMusicPlayerState();
}

class _MiniMusicPlayerState extends State<MiniMusicPlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    // Pastiin nama file sesuai dengan yang ada di pubspec.yaml
    await _player.setAsset('assets/music/Rumah-Ke-Rumah.mp3');
    _player.setLoopMode(LoopMode.all); // Biar muter terus
    await _player.setAsset('assets/music/Cincin.mp3');
    _player.setLoopMode(LoopMode.all); // Biar muter terus
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tampilan Mini Player (bisa ditaruh di AppBar atau mana aja)
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            color: const Color(0xFF00D4AA), // Warna tema X-Dark
            size: 28,
          ),
          onPressed: _togglePlay,
        ),
        const Text(
          "Music",
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}