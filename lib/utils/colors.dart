import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AppColors {
  // ===== TURIVA PRIMARY COLORS =====
  static const Color primaryDark = Color(0xFF1A237E);      // Deep Blue
  static const Color primary = Color(0xFF0D47A1);          // Medium Blue
  static const Color primaryGreen = Color(0xFF00695C);     // Teal Green
  static const Color accentGold = Color(0xFFF5A623);       // Safari Gold
  static const Color accentOrange = Color(0xFFFF9800);     // Orange

  // ===== GRADIENTS =====
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primary, primaryGreen],
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [accentGold, accentOrange],
  );

  // ===== BACKGROUNDS =====
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardWhite = Colors.white;

  // ===== TEXT COLORS =====
  static const Color textDark = Color(0xFF212121);
  static const Color textGrey = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  static const Color textWhite = Colors.white;

  // ===== STATUS COLORS =====
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;
}