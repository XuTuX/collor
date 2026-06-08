import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/game_state.dart';
import '../core/app_theme.dart';

class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppTheme.normal);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
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

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(40),
            decoration: AppTheme.panelDecoration().copyWith(
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sentiment_very_dissatisfied, size: 64, color: AppTheme.danger),
                const SizedBox(height: 16),
                Text("게임 오버", style: AppTheme.heading1.copyWith(color: AppTheme.danger)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow("도달 지점", "Ante ${G.ante} - Stage ${G.stage}"),
                      const SizedBox(height: 12),
                      _buildStatRow("최종 점수", "${G.score}"),
                      const SizedBox(height: 12),
                      _buildStatRow("최종 골드", "\$${G.gold}"),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    G.reset();
                  },
                  style: AppTheme.primaryButton.copyWith(
                    padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 48, vertical: 16)),
                  ),
                  child: const Text("메인 메뉴로", style: TextStyle(fontSize: 18)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.subtitle),
        Text(value, style: AppTheme.heading3),
      ],
    );
  }
}
