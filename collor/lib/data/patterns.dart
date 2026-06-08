import 'models.dart';

class PatternsData {
  static Map<String, HandStat> get handStatsTemplate => {
        "Mono": HandStat(level: 1, chips: 30, mult: 3.0, scaleChips: 15, scaleMult: 1.0),
        "Mirror": HandStat(level: 1, chips: 40, mult: 4.0, scaleChips: 20, scaleMult: 1.5),
        "Twins": HandStat(level: 1, chips: 25, mult: 2.5, scaleChips: 12, scaleMult: 1.0),
        "Crescendo": HandStat(level: 1, chips: 50, mult: 5.0, scaleChips: 25, scaleMult: 2.0),
        "Zigzag": HandStat(level: 1, chips: 35, mult: 3.5, scaleChips: 18, scaleMult: 1.2),
      };

  static const Map<String, String> ruleNames = {
    "Mono": "모노",
    "Mirror": "대칭",
    "Twins": "쌍둥이",
    "Crescendo": "크레센도",
    "Zigzag": "지그재그",
  };

  static const Map<String, String> catNames = {
    "MONO": "모노",
    "MIRROR": "대칭",
    "TWINS": "쌍둥이",
    "CRESCENDO": "크레센도",
    "ZIGZAG": "지그재그",
  };
}
