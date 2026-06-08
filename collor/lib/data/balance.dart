import 'dart:math';
import 'models.dart';

class BalanceData {
  static const List<int> targets = [
    300, 1000, 2500, 6000, 15000, 35000, 80000, 180000, 400000, 1000000
  ];

  static const List<String> bossGimmicks = [
    "no_red", "no_black", "no_discard", "high_target"
  ];

  static int getTargetScore(int ante, int stage, String bossGimmick) {
    int base = 180;
    int target = 0;
    if (ante == 1) {
      if (stage == 1) {
        target = 300;
      } else if (stage == 2) {
        target = 700;
      } else {
        target = 1500;
      }
    } else {
      double multi = (stage == 1 ? 1.0 : stage == 2 ? 1.8 : 3.5);
      target = (base * pow(2.1, ante - 1) * multi * 10).floor();
      target = (target ~/ 100) * 100;
    }

    if (stage == 3 && bossGimmick == "high_target") {
      target = (target * 1.5).floor();
    }

    return target;
  }

  static Map<String, int> calcGoldReward(int currentGold, int discLeft, List<JokerData> jokers) {
    int baseVal = 3;
    int discBonus = discLeft;
    int interest = min(5, currentGold ~/ 5);
    int jokerBonus = 0;

    for (var j in jokers) {
      if (j.id == "gold_rush") {
        jokerBonus += 4;
      }
    }

    int total = baseVal + discBonus + interest + jokerBonus;
    return {
      "total": total,
      "base": baseVal,
      "discBonus": discBonus,
      "interest": interest,
      "jokerBonus": jokerBonus,
    };
  }
}
