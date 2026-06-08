import '../data/models.dart';
import '../core/constants.dart';
import '../core/game_state.dart';

class JokerSystem {
  static bool canAddJoker(List<JokerData> ownedJokers) {
    return ownedJokers.length < Constants.maxJokers;
  }

  static void evaluate(
      List<JokerData> ownedJokers,
      Map<String, bool> uniqueColors,
      int ucCount,
      List<DetectedPattern> detectedPatterns,
      List<ScoreEvent> eventsList,
      List<TileData?> board,
      GameState G) {
    bool hasMirror = false;
    bool hasCrescendo = false;

    for (var h in detectedPatterns) {
      if (h.cat == "MIRROR" && h.chips > 0) hasMirror = true;
      if (h.cat == "CRESCENDO" && h.chips > 0) hasCrescendo = true;
    }

    int redCount = 0;
    int yellowCount = 0;
    for (int i = 0; i < Constants.bn; i++) {
      if (i >= board.length) break;
      var card = board[i];
      if (card != null) {
        if (card.name == "Red") redCount++;
        if (card.name == "Yellow") yellowCount++;
      }
    }

    Map<String, bool> triggered = {};
    for (var j in ownedJokers) {
      bool isTrig = false;
      if (j.id == "shiny_eye" && (uniqueColors["White"] ?? false)) {
        isTrig = true;
      } else if (j.id == "dark_side" && (uniqueColors["Black"] ?? false)) {
        isTrig = true;
      } else if (j.id == "mirror_shield" && hasMirror) {
        isTrig = true;
      } else if (j.id == "rainbow" && ucCount >= 4) {
        isTrig = true;
      } else if (j.id == "ladder_master" && hasCrescendo) {
        isTrig = true;
      } else if (j.id == "chaos" && detectedPatterns.isEmpty) {
        isTrig = true;
      } else if (j.id == "savings") {
        isTrig = true;
      } else if (j.id == "mono_pride" && ucCount == 1 && board.any((e) => e != null)) {
        isTrig = true;
      } else if (j.id == "burning" && redCount > 0) {
        isTrig = true;
      } else if (j.id == "lemonade" && yellowCount > 0) {
        isTrig = true;
      } else if (j.id == "eclipse" && (uniqueColors["White"] ?? false) && (uniqueColors["Black"] ?? false)) {
        isTrig = true;
      } else if (j.id == "alchemy" && redCount >= 2 && yellowCount >= 2) {
        isTrig = true;
      } else if (j.id == "resonance" && hasMirror && hasCrescendo) {
        isTrig = true;
      } else if (j.id == "reroll_boost" && G.discardMultBonus > 0) {
        isTrig = true;
      }
      triggered[j.id] = isTrig;
    }

    int activeCount = 0;
    triggered.forEach((id, trig) {
      if (trig && id != "overload") {
        activeCount++;
      }
    });

    for (int idx = 0; idx < ownedJokers.length; idx++) {
      var j = ownedJokers[idx];
      bool trigger = false;
      int bonusChips = 0;
      int bonusMult = 0;
      double bonusXMult = 1.0;

      if (j.id == "shiny_eye" && (triggered["shiny_eye"] ?? false)) {
        trigger = true; bonusChips = 50;
      } else if (j.id == "dark_side" && (triggered["dark_side"] ?? false)) {
        trigger = true; bonusMult = 5;
      } else if (j.id == "mirror_shield" && (triggered["mirror_shield"] ?? false)) {
        trigger = true; bonusXMult = 1.8;
      } else if (j.id == "rainbow" && (triggered["rainbow"] ?? false)) {
        trigger = true; bonusChips = 60; bonusMult = 6;
      } else if (j.id == "ladder_master" && (triggered["ladder_master"] ?? false)) {
        trigger = true; bonusChips = 100;
      } else if (j.id == "chaos" && (triggered["chaos"] ?? false)) {
        trigger = true; bonusXMult = 2.2;
      } else if (j.id == "savings") {
        trigger = true; bonusMult = (G.gold / 2).floor();
      } else if (j.id == "mono_pride" && (triggered["mono_pride"] ?? false)) {
        trigger = true; bonusXMult = 2.5;
      } else if (j.id == "burning" && (triggered["burning"] ?? false)) {
        trigger = true; bonusMult = redCount * 3;
      } else if (j.id == "lemonade" && (triggered["lemonade"] ?? false)) {
        trigger = true; bonusChips = yellowCount * 25;
      } else if (j.id == "overload" && activeCount > 0) {
        trigger = true; bonusMult = activeCount * 4;
      } else if (j.id == "eclipse" && (triggered["eclipse"] ?? false)) {
        trigger = true; bonusXMult = 1.8;
      } else if (j.id == "alchemy" && (triggered["alchemy"] ?? false)) {
        trigger = true; bonusChips = 80; G.gold += 2;
      } else if (j.id == "resonance" && (triggered["resonance"] ?? false)) {
        trigger = true; bonusXMult = 2.0;
      } else if (j.id == "reroll_boost" && (triggered["reroll_boost"] ?? false)) {
        trigger = true; bonusMult = G.discardMultBonus;
      }

      if (trigger) {
        eventsList.add(ScoreEvent(
          type: "joker",
          jokerId: j.id,
          name: j.name,
          jokerIndex: idx,
          chips: bonusChips,
          mult: bonusMult,
          xmult: bonusXMult,
        ));
      }
    }
  }
}
