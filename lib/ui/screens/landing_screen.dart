import 'dart:math' as math;
import 'package:codebuzzer/services/alarm_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'main_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  Future<void> _completeOnboarding(BuildContext context) async {
    if (context.mounted) {
      await _showPermissionDialog(context);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_landing', true);

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  Future<void> _showPermissionDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1E22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Permissions Required',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'GoogleSans',
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'To ensure alarms work properly in the background, we need:',
              style: TextStyle(color: Colors.white70, fontFamily: 'GoogleSans'),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(
                Icons.notifications_active,
                color: Color(0xFF1CD065),
              ),
              title: Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'GoogleSans',
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.timer, color: Color(0xFF1CD065)),
              title: Text(
                'Exact Alarms',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'GoogleSans',
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.layers, color: Color(0xFF1CD065)),
              title: Text(
                'Overlay Permission',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'GoogleSans',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await AlarmService.requestAllPermissions();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'GRANT ALL',
              style: TextStyle(
                color: Color(0xFF1CD065),
                fontWeight: FontWeight.bold,
                fontFamily: 'GoogleSans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1012),
      body: Stack(
        children: [
          // 1. Animated Nebula Background
          const _NebulaBlob(
            color: Color(0xFF1CD065),
            top: 100,
            left: -50,
            size: 300,
          ),
          const _NebulaBlob(
            color: Color(0xFF1A3B33),
            bottom: 150,
            right: -80,
            size: 400,
          ),

          // 2. Depth Layer (Blur)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
            child: Container(color: Colors.transparent),
          ),

          // 3. Spacial Starfield of Logos
          const Positioned(
            top: 80,
            left: 30,
            child: DancingLogo(assetPath: 'assets/codeforces.png', index: 0),
          ),
          const Positioned(
            top: 100,
            right: 30,
            child: DancingLogo(assetPath: 'assets/codingninja.png', index: 1),
          ),
          const Positioned(
            top: 240,
            right: 140,
            child: DancingLogo(assetPath: 'assets/leetcode.png', index: 4),
          ),
          const Positioned(
            bottom: 450,
            left: 30,
            child: DancingLogo(assetPath: 'assets/codechef.png', index: 2),
          ),
          const Positioned(
            bottom: 430,
            right: 40,
            child: DancingLogo(assetPath: 'assets/atcoder.png', index: 3),
          ),

          // 4. Content Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Text(
                    'Never Miss A\nContest Again',
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: Colors.white,
                      fontFamily: 'GoogleSans',
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Automated high-volume alarms that wake you up exactly when competitive programming contests start.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.5,
                      fontFamily: 'GoogleSans',
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildGetStartedButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1CD065).withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1CD065),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 22),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () => _completeOnboarding(context),
        child: const Text(
          'GET STARTED',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            fontFamily: 'GoogleSans',
          ),
        ),
      ),
    );
  }
}

class _NebulaBlob extends StatefulWidget {
  final Color color;
  final double? top, bottom, left, right;
  final double size;

  const _NebulaBlob({
    required this.color,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
  });

  @override
  State<_NebulaBlob> createState() => _NebulaBlobState();
}

class _NebulaBlobState extends State<_NebulaBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: widget.top != null
              ? widget.top! + (20 * _controller.value)
              : null,
          bottom: widget.bottom != null
              ? widget.bottom! + (20 * _controller.value)
              : null,
          left: widget.left != null
              ? widget.left! + (20 * _controller.value)
              : null,
          right: widget.right != null
              ? widget.right! + (20 * _controller.value)
              : null,
          child: Container(
            width: widget.size + (50 * _controller.value),
            height: widget.size + (50 * _controller.value),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.3 + (0.2 * _controller.value)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class DancingLogo extends StatefulWidget {
  final String assetPath;
  final int index;

  const DancingLogo({super.key, required this.assetPath, required this.index});

  @override
  State<DancingLogo> createState() => _DancingLogoState();
}

class _DancingLogoState extends State<DancingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4 + widget.index),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;
        final xOffset = 20.0 * math.sin(t * 0.8 + widget.index);
        final yOffset = 30.0 * math.cos(t * 1.1 + widget.index * 1.5);
        final rotation = 0.15 * math.sin(t * 0.5 + widget.index);

        return Transform.translate(
          offset: Offset(xOffset, yOffset),
          child: Transform.rotate(
            angle: rotation,
            child: Opacity(
              opacity: 0.6 + (0.4 * (math.sin(t * 0.5 + widget.index) + 1) / 2),
              child: Image.asset(
                widget.assetPath,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.code, size: 60, color: Color(0xFF1CD065)),
              ),
            ),
          ),
        );
      },
    );
  }
}
