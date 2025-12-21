import 'package:flutter/material.dart';
import 'dart:ui';

/// Common blurred ellipse background widget for top bar
/// This widget creates a blurred purple ellipse at the top center of the screen
class BlurredEllipseBackground extends StatelessWidget {
  const BlurredEllipseBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -170,
      left: MediaQuery.of(context).size.width / 2 - 175,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 180),
        child: Container(
          width: 350,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFF3E25F6).withOpacity(0.7),
            borderRadius: BorderRadius.circular(180),
          ),
        ),
      ),
    );
  }
}

