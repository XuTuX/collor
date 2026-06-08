import 'dart:math';
import '../data/models.dart';

class RuleEngine {
  static List<DetectedPattern> applyStatsAndGimmicks(
      List<DetectedPattern> detectedPatterns,
      Map<String, HandStat> handStats,
      int stage,
      String bossGimmick) {
    for (var h in detectedPatterns) {
      // 1. 규칙 강화 레벨 스탯 투영
      var stats = handStats[h.name];
      if (stats != null) {
        double S = 1.0;
        double power = 1.5;

        if (h.cat == "MONO" || h.cat == "MIRROR" || h.cat == "ZIGZAG") {
          S = max(1, (h.length ?? 0) - 2).toDouble();
          power = 1.5;
        } else if (h.cat == "CRESCENDO") {
          S = max(1, (h.length ?? 0) - 2).toDouble();
          power = 1.8;
        } else if (h.cat == "TWINS") {
          S = max(1, h.pairs ?? 0).toDouble();
          power = 1.5;
        }

        double scaleMultiplier = pow(S, power).toDouble();
        h.chips = (stats.chips * scaleMultiplier).floor();
        h.mult = (stats.mult * scaleMultiplier).floor();
      }

      // 2. 보스 기믹 적용 (Ante Stage 3 에서만 발동)
      if (stage == 3) {
        if (bossGimmick == "no_red" && h.pat.contains("R")) {
          h.chips = 0;
          h.mult = 0;
        } else if (bossGimmick == "no_black" && h.pat.contains("K")) {
          h.chips = 0;
          h.mult = 0;
        }
      }
    }
    return detectedPatterns;
  }
}
