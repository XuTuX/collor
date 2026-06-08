import 'package:flutter/material.dart';

class AppTheme {
  // ─── Background & Surface ───
  static const Color bg = Color(0xFFF5F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF0F2F8);
  static const Color border = Color(0xFFE2E5EE);
  static const Color borderStrong = Color(0xFF1A1A2E);

  // ─── Text ───
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // ─── Accents ───
  static const Color accent = Color(0xFF4F6AF6);
  static const Color accentLight = Color(0xFFE8ECFF);
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldDark = Color(0xFFD97706);

  // ─── Score Colors ───
  static const Color chips = Color(0xFF3B82F6);
  static const Color chipsLight = Color(0xFFDBEAFE);
  static const Color mult = Color(0xFFEF4444);
  static const Color multLight = Color(0xFFFEE2E2);

  // ─── Card Color Gradients ───
  static const Map<String, List<Color>> cardGradients = {
    'Red': [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
    'Orange': [Color(0xFFFFB347), Color(0xFFFF6348)],
    'Yellow': [Color(0xFFFFE66D), Color(0xFFFFC048)],
    'White': [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
    'Black': [Color(0xFF2D3436), Color(0xFF636E72)],
  };

  static const Map<String, Color> cardTextColors = {
    'Red': Colors.white,
    'Orange': Colors.white,
    'Yellow': Color(0xFF5D4E37),
    'White': Color(0xFF343A40),
    'Black': Colors.white,
  };

  // ─── Pattern Colors ───
  static const Map<String, Color> patternColors = {
    'MONO': Color(0xFF10B981),
    'MIRROR': Color(0xFF8B5CF6),
    'TWINS': Color(0xFFEC4899),
    'CRESCENDO': Color(0xFFF59E0B),
    'ZIGZAG': Color(0xFF3B82F6),
  };

  // ─── Edition Effects ───
  static const Map<String, Color> editionColors = {
    'normal': Colors.transparent,
    'foil': Color(0xFF6366F1),
    'holo': Color(0xFFEC4899),
    'gold': Color(0xFFF59E0B),
  };

  // ─── Common Decorations ───
  static BoxDecoration panelDecoration({Color? color}) => BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration cardDecoration({required Color color, bool selected = false}) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardGradients[_colorNameFromColor(color)] ?? [color, color],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? accent : Colors.black.withValues(alpha: 0.15),
          width: selected ? 3.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? accent.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.12),
            blurRadius: selected ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      );

  static String? _colorNameFromColor(Color color) {
    // Match by checking proximity to known card colors
    for (var entry in cardGradients.entries) {
      if (_colorDistance(color, entry.value[0]) < 80) return entry.key;
    }
    return null;
  }

  static double _colorDistance(Color a, Color b) {
    final dr = (a.r * 255 - b.r * 255);
    final dg = (a.g * 255 - b.g * 255);
    final db = (a.b * 255 - b.b * 255);
    return (dr * dr + dg * dg + db * db);
  }

  // ─── Button Styles ───
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: accent,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
  );

  static ButtonStyle dangerButton = ElevatedButton.styleFrom(
    backgroundColor: danger,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
  );

  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: surfaceAlt,
    foregroundColor: textPrimary,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: border),
    ),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  // ─── Text Styles ───
  static const TextStyle heading1 = TextStyle(
    fontSize: 36, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5,
  );
  static const TextStyle heading2 = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.3,
  );
  static const TextStyle heading3 = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary,
  );
  static const TextStyle subtitle = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: textSecondary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500, color: textMuted,
  );
  static const TextStyle label = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w700, color: textSecondary, letterSpacing: 0.8,
  );

  // ─── Animation Durations ───
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration scoring = Duration(milliseconds: 400);
}
