import 'package:flutter/material.dart';

class MeshBackground extends StatelessWidget {
  final Widget child;

  const MeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF0E5), // Light warm
            Color(0xFFFFB2A6), // Peachy pink
            Color(0xFFFF8A66), // Vibrant orange
          ],
          stops: [0.1, 0.5, 0.9],
        ),
      ),
      child: SafeArea(child: child),
    );
  }
}
