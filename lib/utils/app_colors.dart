import 'package:flutter/material.dart';

class AppColors {
  // Colores principales (negro)
  static const Color primaryBlack = Color(0xFF121212);
  static const Color surfaceBlack = Color(0xFF1E1E1E);
  static const Color cardBlack = Color(0xFF2A2A2A);

  // Colores pasteles
  static const Color pastelPink = Color(0xFFFFB3E6);
  static const Color pastelBlue = Color(0xFFB3D9FF);
  static const Color pastelGreen = Color(0xFFB3FFB3);
  static const Color pastelPurple = Color(0xFFD9B3FF);
  static const Color pastelOrange = Color(0xFFFFD9B3);

  // Colores básicos
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFF9E9E9E);
  static const Color darkGrey = Color(0xFF424242);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pastelPink, pastelBlue],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pastelPurple, pastelGreen],
  );

  static const RadialGradient backgroundGradient = RadialGradient(
    center: Alignment.center,
    radius: 1.0,
    colors: [surfaceBlack, primaryBlack],
  );
}