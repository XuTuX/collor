import 'dart:math';
import '../data/models.dart';
import '../core/constants.dart';

class TileLogic {
  static List<TileData> createDeck(List<TileData> deckConfig) {
    List<TileData> d = [];
    for (var card in deckConfig) {
      d.add(card.copy());
    }
    d.shuffle(Random());
    return d;
  }

  static List<TileData> drawCards(List<TileData> deckList, int count) {
    List<TileData> drawn = [];
    for (int i = 0; i < count; i++) {
      if (deckList.isNotEmpty) {
        var c = deckList.removeLast();
        c.sel = false;
        if (c.edition.isEmpty) {
          c.edition = "normal";
        }
        drawn.add(c);
      }
    }
    return drawn;
  }

  static bool toggleSelect(List<TileData> handList, int index, Function(String, String)? noticeCallback) {
    if (index < 0 || index >= handList.length) return false;
    var card = handList[index];

    if (card.sel) {
      card.sel = false;
    } else {
      int selCount = handList.where((c) => c.sel).length;
      if (selCount >= Constants.bn) {
        if (noticeCallback != null) {
          noticeCallback("더 이상 고를 수 없어요", "warn");
        }
        return false;
      }
      card.sel = true;
    }
    return true;
  }

  static int getSelectionCount(List<TileData> handList) {
    return handList.where((c) => c.sel).length;
  }

  static List<int> getSelectedIndices(List<TileData> handList) {
    List<int> s = [];
    for (int i = 0; i < handList.length; i++) {
      if (handList[i].sel) s.add(i);
    }
    return s;
  }
}
