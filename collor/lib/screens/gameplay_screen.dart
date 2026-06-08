import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/game_state.dart';
import '../core/constants.dart';
import '../core/app_theme.dart';
import '../data/models.dart';
import '../gameplay/tile.dart';
import '../gameplay/turn_manager.dart';
import '../gameplay/pattern_checker.dart';
import '../gameplay/rule_engine.dart';
import '../systems/score_system.dart';
import '../widgets/card_widget.dart';
import '../widgets/joker_card_widget.dart';
import '../widgets/score_overlay.dart';
import '../widgets/pattern_preview_widget.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  @override
  Widget build(BuildContext context) {
    final G = context.watch<GameState>();
    // 실시간 감지 패턴
    var currentPatterns = PatternChecker.evaluate(G.board);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            // ─── Left Panel (Info) ───
            Container(
              width: 260,
              decoration: AppTheme.panelDecoration(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceAlt,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Ante ${G.ante}  •  Stage ${G.stage}",
                      style: AppTheme.subtitle.copyWith(color: AppTheme.accent),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (G.stage == 3 && G.bossGimmick != "none")
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerLight,
                        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _getGimmickName(G.bossGimmick),
                            style: AppTheme.label.copyWith(color: AppTheme.danger),
                          ),
                        ],
                      ),
                    ),
                  Text("목표 점수", style: AppTheme.caption),
                  Text("${G.targetScore}", style: AppTheme.heading2.copyWith(color: AppTheme.accent)),
                  const SizedBox(height: 16),
                  Text("현재 점수", style: AppTheme.caption),
                  Text("${G.dScore}", style: AppTheme.heading1),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: G.targetScore > 0 ? min(G.dScore / G.targetScore, 1.0) : 0,
                      backgroundColor: AppTheme.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        G.dScore >= G.targetScore ? AppTheme.success : AppTheme.accent,
                      ),
                      minHeight: 8,
                    ),
                  ),
                  if (G.rndScore > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text("+${G.rndScore}", style: AppTheme.subtitle.copyWith(color: AppTheme.success)),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warningLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("🪙", style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Text("${G.gold}", style: AppTheme.heading2.copyWith(color: AppTheme.goldDark)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // ─── Center Area (Board & Hand) ───
            Expanded(
              child: Column(
                children: [
                  // Jokers
                  if (G.jokers.isNotEmpty)
                    SizedBox(
                      height: 85,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: G.jokers.map((j) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: JokerCardWidget(joker: j),
                          );
                        }).toList(),
                      ),
                    )
                  else
                    const SizedBox(height: 85), // Placeholder

                  const Spacer(),

                  // Board
                  Container(
                    height: 120,
                    padding: const EdgeInsets.all(12),
                    decoration: AppTheme.panelDecoration().copyWith(
                      color: AppTheme.surfaceAlt.withValues(alpha: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(Constants.bn, (index) {
                        var card = index < G.board.length ? G.board[index] : null;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: card != null
                              ? CardWidget(card: card)
                              : Container(
                                  width: 70,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    border: Border.all(
                                      color: AppTheme.border,
                                      style: BorderStyle.solid,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 16),
                  AnimatedCrossFade(
                    firstChild: ScoreOverlay(
                      chips: ScoreSystem.state.dChips,
                      mult: ScoreSystem.state.dMult,
                      xMult: ScoreSystem.state.xMult,
                      visible: G.phase == "scoring",
                    ),
                    secondChild: PatternPreviewWidget(patterns: currentPatterns),
                    crossFadeState: G.phase == "scoring"
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: AppTheme.normal,
                    firstCurve: Curves.easeOutBack,
                    secondCurve: Curves.easeIn,
                  ),

                  const Spacer(),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: (G.phase == "play" && G.execLeft > 0)
                            ? () {
                                if (TurnManager.executeHand(G)) {
                                  _scoreBoard(G);
                                }
                              }
                            : null,
                        style: AppTheme.primaryButton,
                        child: Text("실행 (${G.execLeft})"),
                      ),
                      const SizedBox(width: 24),
                      ElevatedButton(
                        onPressed: (G.phase == "play" && G.discLeft > 0)
                            ? () => TurnManager.discard(G)
                            : null,
                        style: AppTheme.dangerButton,
                        child: Text("바꾸기 (${G.discLeft})"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Hand
                  SizedBox(
                    height: 130,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: G.hand.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var card = entry.value;
                        // Fan effect
                        double angle = (idx - (G.hand.length - 1) / 2) * 0.05;
                        return Transform.rotate(
                          angle: angle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: CardWidget(
                              card: card,
                              onTap: () {
                                if (G.phase == "play") {
                                  TileLogic.toggleSelect(G.hand, idx, (msg, kind) {
                                    G.notice(msg, kind);
                                  });
                                  G.refresh();
                                }
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // ─── Right Panel (Deck) ───
            Container(
              width: 220,
              decoration: AppTheme.panelDecoration(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("남은 카드", style: AppTheme.caption),
                  Text("${G.deck.length}장", style: AppTheme.heading2),
                  const SizedBox(height: 16),
                  // Simple color distribution bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: _buildDeckDistribution(G.deck),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(height: 1, color: AppTheme.border),
                  const SizedBox(height: 24),
                  Text("규칙 현황", style: AppTheme.caption),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: G.handStats.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key, style: AppTheme.body),
                              Text("Lv.${e.value.level}", style: AppTheme.label.copyWith(color: AppTheme.accent)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (G.noticeText.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: G.noticeKind == "warn" ? AppTheme.dangerLight : AppTheme.successLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        G.noticeText,
                        style: AppTheme.body.copyWith(
                          color: G.noticeKind == "warn" ? AppTheme.danger : AppTheme.success,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGimmickName(String bossGimmick) {
    switch (bossGimmick) {
      case "no_red": return "빨강 무효";
      case "no_black": return "검정 무효";
      case "no_discard": return "바꾸기 금지";
      case "high_target": return "목표 1.5배";
      default: return "";
    }
  }

  List<Widget> _buildDeckDistribution(List<TileData> deck) {
    if (deck.isEmpty) return [Expanded(child: Container(color: AppTheme.border))];
    Map<String, int> counts = {};
    for (var c in deck) {
      counts[c.name] = (counts[c.name] ?? 0) + 1;
    }
    List<Widget> segments = [];
    counts.forEach((colorName, count) {
      segments.add(
        Expanded(
          flex: count,
          child: Container(color: AppTheme.cardGradients[colorName]?.first ?? Colors.grey),
        ),
      );
    });
    return segments;
  }

  void _scoreBoard(GameState G) async {
    G.clearNotice();
    G.detected = PatternChecker.evaluate(G.board);
    RuleEngine.applyStatsAndGimmicks(G.detected, G.handStats, G.stage, G.bossGimmick);

    G.phase = "scoring";
    G.refresh();
    ScoreSystem.start(G.board, G.detected, G.jokers, G);

    // Simple delay for animation
    await Future.delayed(const Duration(milliseconds: 1500));

    G.rndScore = ScoreSystem.finalScore;
    G.score += G.rndScore;
    G.dScore = G.score;

    if (G.score >= G.targetScore) {
      G.roundCleared = true;
    }

    if (G.execLeft <= 0 && !G.roundCleared) {
      G.phase = "gameover";
    } else if (G.roundCleared) {
      G.phase = "result";
    } else {
      G.phase = "play";
      // Refill hand
      int toDraw = Constants.hn - G.hand.length;
      if (toDraw > 0) {
        var drawn = TileLogic.drawCards(G.deck, toDraw);
        G.hand.addAll(drawn);
      }
    }
    G.refresh();
  }
}
