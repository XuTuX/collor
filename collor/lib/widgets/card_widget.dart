import 'package:flutter/material.dart';
import '../data/models.dart';
import '../core/app_theme.dart';

class CardWidget extends StatelessWidget {
  final TileData card;
  final VoidCallback? onTap;

  const CardWidget({super.key, required this.card, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isSelected = card.sel;
    final Color textColor = AppTheme.cardTextColors[card.name] ?? Colors.white;
    final bool hasEdition = card.edition != 'normal' && card.edition.isNotEmpty;
    final Color editionColor = AppTheme.editionColors[card.edition] ?? Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.fast,
        curve: Curves.easeOut,
        width: 70,
        height: 92,
        transform: Matrix4.translationValues(0, isSelected ? -12.0 : 0, 0),
        decoration: AppTheme.cardDecoration(color: card.color, selected: isSelected).copyWith(
          border: hasEdition
              ? Border.all(color: editionColor, width: 2.0)
              : AppTheme.cardDecoration(color: card.color, selected: isSelected).border,
          boxShadow: [
            BoxShadow(
              color: isSelected ? AppTheme.accent.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
              blurRadius: isSelected ? 12 : 4,
              offset: Offset(0, isSelected ? 6 : 2),
            ),
            if (hasEdition)
              BoxShadow(
                color: editionColor.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                card.name[0],
                style: TextStyle(
                  color: textColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    )
                  ],
                ),
              ),
            ),
            if (hasEdition)
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: editionColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(color: editionColor.withValues(alpha: 0.5), blurRadius: 4)
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
