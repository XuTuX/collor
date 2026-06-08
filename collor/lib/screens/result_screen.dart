import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/game_state.dart';
import '../core/app_theme.dart';
import '../data/balance.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppTheme.normal);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final G = context.watch<GameState>();
    final isSuccess = G.roundCleared;
    final reward = BalanceData.calcGoldReward(G.gold, G.discLeft, G.jokers);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(40),
              decoration: AppTheme.panelDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isSuccess ? "관문 통과!" : "도전 실패...",
                    style: AppTheme.heading1.copyWith(
                      color: isSuccess ? AppTheme.success : AppTheme.danger,
                      fontSize: 48,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text("목표 점수", style: AppTheme.caption),
                          Text("${G.targetScore}", style: AppTheme.heading2),
                        ],
                      ),
                      Column(
                        children: [
                          Text("달성 점수", style: AppTheme.caption),
                          Text(
                            "${G.score}",
                            style: AppTheme.heading2.copyWith(
                              color: isSuccess ? AppTheme.success : AppTheme.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (isSuccess) ...[
                    Container(height: 1, color: AppTheme.border),
                    const SizedBox(height: 24),
                    Text("획득 보상", style: AppTheme.subtitle),
                    const SizedBox(height: 16),
                    _buildRewardRow("기본 보상", "\$${reward['base']}"),
                    _buildRewardRow("바꾸기 횟수 보너스", "\$${reward['discBonus']}"),
                    _buildRewardRow("이자", "\$${reward['interest']}"),
                    if (reward['jokerBonus']! > 0)
                      _buildRewardRow("조커 보너스", "\$${reward['jokerBonus']}"),
                    const SizedBox(height: 12),
                    _buildRewardRow("합계", "🪙 ${reward['total']}", isTotal: true),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        G.advanceStage();
                        G.generateShopItems();
                        G.phase = "shop";
                        G.refresh();
                      },
                      style: AppTheme.primaryButton.copyWith(
                        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
                      ),
                      child: const Text("상점으로 이동", style: TextStyle(fontSize: 18)),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: () {
                        G.reset();
                      },
                      style: AppTheme.secondaryButton,
                      child: const Text("메인 메뉴로", style: TextStyle(fontSize: 18)),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal ? AppTheme.subtitle.copyWith(color: AppTheme.textPrimary) : AppTheme.body,
          ),
          Text(
            value,
            style: isTotal
                ? AppTheme.heading3.copyWith(color: AppTheme.goldDark)
                : AppTheme.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
