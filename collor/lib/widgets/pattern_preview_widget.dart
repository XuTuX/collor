import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/patterns.dart';
import '../core/app_theme.dart';

class PatternPreviewWidget extends StatelessWidget {
  final List<DetectedPattern> patterns;

  const PatternPreviewWidget({super.key, required this.patterns});

  @override
  Widget build(BuildContext context) {
    if (patterns.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(
          "감지된 패턴 없음",
          style: AppTheme.body.copyWith(color: AppTheme.textMuted, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: patterns.map((p) {
        final color = AppTheme.patternColors[p.cat] ?? AppTheme.textSecondary;
        final name = PatternsData.catNames[p.cat] ?? p.name;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: AppTheme.label.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              if (p.chips > 0 || p.mult > 0) ...[
                Text("⭐${p.chips}", style: AppTheme.caption.copyWith(color: AppTheme.chips, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text("🔥${p.mult}", style: AppTheme.caption.copyWith(color: AppTheme.mult, fontWeight: FontWeight.bold)),
              ] else ...[
                Text(p.pat, style: AppTheme.caption),
              ]
            ],
          ),
        );
      }).toList(),
    );
  }
}
