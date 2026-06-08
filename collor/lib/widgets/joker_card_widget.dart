import 'package:flutter/material.dart';
import '../data/models.dart';
import '../core/app_theme.dart';

class JokerCardWidget extends StatelessWidget {
  final JokerData joker;
  final bool triggered;
  final bool showPrice;
  final VoidCallback? onTap;

  const JokerCardWidget({
    super.key,
    required this.joker,
    this.triggered = false,
    this.showPrice = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.fast,
        width: 130,
        height: 85,
        decoration: AppTheme.panelDecoration().copyWith(
          border: Border.all(
            color: triggered ? AppTheme.success : AppTheme.border,
            width: triggered ? 2.0 : 1.5,
          ),
          boxShadow: triggered
              ? [
                  BoxShadow(
                    color: AppTheme.success.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ]
              : AppTheme.panelDecoration().boxShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // Left accent bar
            Container(
              width: 6,
              color: AppTheme.accent,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      joker.name,
                      style: AppTheme.body.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        joker.desc,
                        style: AppTheme.caption.copyWith(fontSize: 10, height: 1.2),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showPrice)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.warningLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "🪙 ${joker.price}",
                            style: AppTheme.label.copyWith(color: AppTheme.goldDark, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
