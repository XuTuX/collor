import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class ScoreOverlay extends StatelessWidget {
  final int chips;
  final int mult;
  final double xMult;
  final bool visible;

  const ScoreOverlay({
    super.key,
    required this.chips,
    required this.mult,
    this.xMult = 1.0,
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: AppTheme.fast,
      child: AnimatedScale(
        scale: visible ? 1.0 : 0.8,
        duration: AppTheme.fast,
        curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: AppTheme.panelDecoration().copyWith(
            color: AppTheme.surface.withValues(alpha: 0.95),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chips
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.chipsLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text("⭐ ", style: TextStyle(fontSize: 18)),
                        Text(
                          "$chips",
                          style: AppTheme.heading2.copyWith(color: AppTheme.chips),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text("×", style: AppTheme.heading2.copyWith(color: AppTheme.textMuted)),
                  const SizedBox(width: 16),
                  // Mult
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.multLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text("🔥 ", style: TextStyle(fontSize: 18)),
                        Text(
                          "$mult",
                          style: AppTheme.heading2.copyWith(color: AppTheme.mult),
                        ),
                      ],
                    ),
                  ),
                  // xMult (Optional)
                  if (xMult > 1.0) ...[
                    const SizedBox(width: 16),
                    Text("×", style: AppTheme.heading2.copyWith(color: AppTheme.textMuted)),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${xMult}x",
                        style: AppTheme.heading2.copyWith(color: AppTheme.accent),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Container(height: 1, width: 200, color: AppTheme.border),
              const SizedBox(height: 16),
              // Total
              Text(
                "= ${(chips * mult * xMult).floor()}",
                style: AppTheme.heading1.copyWith(fontSize: 42, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
