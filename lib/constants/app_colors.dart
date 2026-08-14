import 'package:flutter/material.dart';

/// Rakshak Connect – Brand Color Palette
/// Primary: Red (#D32F2F) | Background: White | Accent: Blue (#1976D2)
class AppColors {
  AppColors._();

  // ── Primary Red ──────────────────────────────────
  static const Color primary = Color(0xFFD32F2F);
  static const Color primaryDark = Color(0xFF9A0007);
  static const Color primaryLight = Color(0xFFFF6659);
  static const Color primaryContainer = Color(0xFFFFCDD2);

  // ── Accent Blue ───────────────────────────────────
  static const Color accent = Color(0xFF1976D2);
  static const Color accentLight = Color(0xFF63A4FF);
  static const Color accentDark = Color(0xFF004BA0);

  // ── Background & Surface ─────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F8F8);
  static const Color surfaceVariant = Color(0xFFF1F1F1);

  // ── Dark Mode ─────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkDivider = Color(0xFF3A3A3A);

  // ── Status Colors ─────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFB00020);
  static const Color errorLight = Color(0xFFFFEBEE);

  // ── Text ──────────────────────────────────────────
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFE0E0E0);

  // ── Misc ──────────────────────────────────────────
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);
  static const Color transparent = Colors.transparent;

  // ── SOS Specific ──────────────────────────────────
  static const Color sosPulse = Color(0x33D32F2F);
  static const Color sosRing1 = Color(0x22D32F2F);
  static const Color sosRing2 = Color(0x11D32F2F);
}
