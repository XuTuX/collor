import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/game_state.dart';
import '../core/app_theme.dart';
import '../data/models.dart';
import '../gameplay/turn_manager.dart';
import '../widgets/joker_card_widget.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final G = context.watch<GameState>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            // ─── Header ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("상점", style: AppTheme.heading1),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text("🪙", style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text("${G.gold}", style: AppTheme.heading2.copyWith(color: AppTheme.goldDark)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ─── Jokers ───
            if (G.jokers.isNotEmpty) ...[
              SizedBox(
                height: 85,
                child: Row(
                  children: [
                    Text("보유 조커", style: AppTheme.subtitle),
                    const SizedBox(width: 16),
                    ...G.jokers.map((j) => Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: JokerCardWidget(joker: j),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(height: 1, color: AppTheme.border),
              const SizedBox(height: 24),
            ],

            // ─── Shop Items ───
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: G.shopItems.length,
                itemBuilder: (context, index) {
                  final item = G.shopItems[index];
                  return _buildShopItemCard(context, G, item);
                },
              ),
            ),
            const SizedBox(height: 24),

            // ─── Next Round Button ───
            ElevatedButton(
              onPressed: () {
                if (G.checkVictory()) {
                  G.notice("게임 클리어! 모든 Ante를 정복했습니다.", "ok");
                  // You can add a victory screen here
                  G.reset();
                } else {
                  TurnManager.newRound(G);
                }
              },
              style: AppTheme.primaryButton.copyWith(
                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
              ),
              child: const Text("다음 라운드로", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopItemCard(BuildContext context, GameState G, ShopItemData item) {
    final isJoker = item.type == ShopItemType.joker;

    return GestureDetector(
      onTap: () {
        if (!item.sold && G.gold >= item.price) {
          if (G.purchaseItem(item)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("${item.name} 구매 완료!"), backgroundColor: AppTheme.success),
            );
          }
        }
      },
      child: Container(
        decoration: AppTheme.panelDecoration().copyWith(
          color: item.sold ? AppTheme.surfaceAlt : AppTheme.surface,
          border: Border.all(
            color: isJoker ? AppTheme.accent.withValues(alpha: 0.5) : AppTheme.border,
            width: isJoker ? 2.0 : 1.5,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isJoker)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      // Text("JOKER", style: AppTheme.label.copyWith(color: AppTheme.accent)),
                    ),
                  Text(item.name, style: AppTheme.heading3),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Text(
                      item.desc,
                      style: AppTheme.body.copyWith(color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(isJoker ? "조커" : "아이템", style: AppTheme.caption),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.warningLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "🪙 ${item.price}",
                          style: AppTheme.label.copyWith(color: AppTheme.goldDark, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (item.sold)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: -0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.danger, width: 3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "SOLD OUT",
                        style: AppTheme.heading2.copyWith(color: AppTheme.danger, letterSpacing: 2),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
