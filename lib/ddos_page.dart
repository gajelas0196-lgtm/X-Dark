// tools_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'chat_ai_page.dart';
import 'phone_lookup.dart'; 
import 'subdomain_finder_page.dart';
import 'anime.dart';

class ToolsPage extends StatefulWidget {
  final String sessionKey;
  final String userRole;

  const DdosPage({
    super.key,
    required this.sessionKey,
    required this.userRole,
  });

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _listController;
  late Animation<double> _headerAnimation;
  late List<Animation<double>> _itemAnimations;

  // Definisi Warna Tema: BLACK & BLUE (RYU EDITION)
  static const Color primaryColor = Color(0xFF00D4AA); // Material Blue

  @override
  void initState() {
    super.initState();
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );

    _itemAnimations = List.generate(
      5, // Jumlah tools asli
      (index) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _listController,
          curve: Interval(
            index * 0.1,
            0.5 + (index * 0.1),
            curve: Curves.easeOutBack,
          ),
        ),
      ),
    );

    _headerController.forward();
    _listController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // --- Background Hitam ---
          Container(color: Colors.black),

          // --- Pola Grid (CustomPainter) ---
          Positioned.fill(
            child: CustomPaint(
              painter: GridPatternPainter(),
            ),
          ),
          
          // Layer gelap semi-transparan (Opsional, menjaga kontras)
          Container(
            color: Colors.black.withOpacity(0.4), 
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNewHeader(), 
                const SizedBox(height: 10),
                Expanded(child: _buildNewGridList()), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HEADER ---
  Widget _buildNewHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TOOLS",
            style: TextStyle(
              color: Colors.white, 
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: "Rajdhani", 
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 20,
            child: MarqueeText(
              text: "tools available utilities",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontFamily: "Rajdhani",
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- GRID LIST ---
  Widget _buildNewGridList() {
    final newTools = [
      {'icon': Icons.article_outlined, 'label': 'Chat AI'},
      {'icon': Icons.badge_outlined, 'label': 'NIK Check'},
      {'icon': Icons.phone_android_rounded, 'label': 'Phone Lookup'},
      {'icon': Icons.dns_outlined, 'label': 'Subdomain'},
      {'icon': Icons.movie_creation_outlined, 'label': 'Anime'},
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, 
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8, 
      ),
      itemCount: newTools.length,
      itemBuilder: (context, index) {
        final tool = newTools[index];
        return _buildAnimatedToolItem(
          icon: tool['icon'] as IconData,
          label: tool['label'] as String,
          description: '', 
          animation: _itemAnimations[index],
          onTap: () => _navigateToTool(tool['label'] as String),
        );
      },
    );
  }

  // --- NAVIGASI TOOLS ---
  void _navigateToTool(String toolName) {
    Widget page;
    switch (toolName) {
      case 'Chat AI':
        page = ChatAIPage(sessionKey: widget.sessionKey);
        break;
      case 'NIK Check':
        page = const SizedBox();
        break;
      case 'Phone Lookup':
        page = PhoneLookupPage(sessionKey: widget.sessionKey);
        break;
      case 'Anime':
        page = HomeAnimePage();
        break;
      case 'Subdomain':
        page = SubdomainFinderPage(sessionKey: widget.sessionKey);
        break;
      default:
        return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildAnimatedToolItem({
    required IconData icon,
    required String label,
    required String description,
    required Animation<double> animation,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - animation.value) * 50),
          child: Opacity(
            opacity: animation.value,
            child: _InteractiveToolItem(icon: icon, label: label, description: description, onTap: onTap),
          ),
        );
      },
    );
  }
}

// --- MARQUEE TEXT WIDGET ---
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  
  const MarqueeText({super.key, required this.text, required this.style});

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final width = MediaQuery.of(context).size.width;
              final dx = width - (_controller.value * (width + 300)); 
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
        );
      },
    );
  }
}

class _InteractiveToolItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _InteractiveToolItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  State<_InteractiveToolItem> createState() => _InteractiveToolItemState();
}

class _InteractiveToolItemState extends State<_InteractiveToolItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  static const Color primaryColor = Color(0xFF00D4AA); 

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF090E14).withOpacity(0.9), 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPressed
                      ? primaryColor.withOpacity(0.8) 
                      : primaryColor.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1421), 
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: primaryColor, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Rajdhani",
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- PAINTER UNTUK GRID ---
class GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D4AA).withOpacity(0.2) // Dibuat halus
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    const gridSize = 30.0;
    for (double x = 0; x < size.width; x += gridSize) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += gridSize) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
