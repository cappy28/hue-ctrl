import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const bg      = Color(0xFF050508);
  static const panel   = Color(0xFF0D0D14);
  static const border  = Color(0x10FFFFFF);
  static const accent  = Color(0xFF00E5FF);
  static const accentR = Color(0xFFFF3D6E);
  static const accentP = Color(0xFF7C3AED);
  static const textDim = Color(0x66E0E0F0);

  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: accent, secondary: accentR, surface: panel,
    ),
    textTheme: GoogleFonts.rajdhaniTextTheme(
      const TextTheme(bodyMedium: TextStyle(color: Color(0xFFE0E0F0))),
    ),
    sliderTheme: SliderThemeData(
      thumbColor: accent, activeTrackColor: accent,
      inactiveTrackColor: border,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      trackHeight: 4,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: panel, foregroundColor: accent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        side: const BorderSide(color: accent, width: 1),
      ),
    ),
  );

  static TextStyle get orbitron => GoogleFonts.orbitron(
    color: const Color(0xFFE0E0F0), letterSpacing: 2,
  );
  static TextStyle get rajdhani => GoogleFonts.rajdhani(
    color: const Color(0xFFE0E0F0),
  );
}
