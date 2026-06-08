import 'dart:math';
import '../data/models.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import '../data/balance.dart';
import 'tile.dart';

class TurnManager {
  static bool discard(GameState G) {
    if (G.discLeft <= 0) {
      G.notice("바꾸기 기회가 없어요", "warn");
      return false;
    }

    var selectedIndices = TileLogic.getSelectedIndices(G.hand);
    int toDiscard = selectedIndices.length;

    if (toDiscard == 0) {
      G.notice("바꿀 색친구를 선택해주세요", "warn");
      return false;
    }

    selectedIndices.sort((a, b) => b.compareTo(a));
    for (int idx in selectedIndices) {
      G.hand.removeAt(idx);
    }

    var drawn = TileLogic.drawCards(G.deck, toDiscard);
    G.hand.addAll(drawn);

    G.discLeft -= 1;
    G.notice("$toDiscard명을 바꿨어요", "ok");

    bool hasRerollSpark = G.jokers.any((j) => j.id == "reroll_spark");
    if (hasRerollSpark && Random().nextDouble() < 0.35 && G.hand.isNotEmpty) {
      int idx = Random().nextInt(G.hand.length);
      var eds = ["foil", "holo", "gold"];
      G.hand[idx].edition = eds[Random().nextInt(eds.length)];
      G.notice("스파크 발동! 친구 강화!", "ok");
    }

    bool hasRerollBoost = G.jokers.any((j) => j.id == "reroll_boost");
    if (hasRerollBoost && Random().nextDouble() < 0.40) {
      G.discardMultBonus += 3;
      G.notice("증폭 성공! 이번 라운드 배수 +3!", "ok");
    }

    G.refresh();
    return true;
  }

  static bool executeHand(GameState G) {
    if (G.execLeft <= 0) {
      G.notice("실행 기회가 없어요", "warn");
      return false;
    }

    var selectedIndices = TileLogic.getSelectedIndices(G.hand);
    List<TileData> playCards = [];

    if (selectedIndices.isNotEmpty) {
      selectedIndices.sort((a, b) => b.compareTo(a));
      for (int idx in selectedIndices) {
        var card = G.hand.removeAt(idx);
        card.sel = false;
        playCards.insert(0, card);
      }
    } else {
      G.notice("보드판에 올릴 친구를 선택해주세요", "warn");
      return false;
    }

    G.execLeft -= 1;
    G.phase = "executing";

    for (var c in G.hand) {
      c.sel = false;
    }

    G.board = List.filled(Constants.bn, null);
    for (int i = 0; i < playCards.length && i < Constants.bn; i++) {
      G.board[i] = playCards[i];
    }

    G.refresh();
    return true;
  }

  static void newRound(GameState G) {
    G.score = 0;
    G.dScore = 0;
    G.rndScore = 0;
    G.execLeft = Constants.maxExec;
    G.discardMultBonus = 0;

    G.board = List.filled(Constants.bn, null);

    G.deck = TileLogic.createDeck(G.deckConfig);
    G.hand = TileLogic.drawCards(G.deck, Constants.hn);
    G.discLeft = Constants.maxDisc;

    if (G.stage == 3 && G.bossGimmick == "no_discard") {
      G.discLeft = 0;
    }

    G.phase = "play";
    G.detected = [];
    G.roundCleared = false;

    G.targetScore = BalanceData.getTargetScore(G.ante, G.stage, G.bossGimmick);
    
    G.refresh();
  }
}
