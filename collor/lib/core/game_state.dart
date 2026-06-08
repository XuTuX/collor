import 'dart:ui';
import 'package:flutter/foundation.dart';
import '../data/models.dart';
import '../data/patterns.dart';
import '../data/characters.dart';
import '../data/balance.dart';
import '../core/constants.dart';

class GameState extends ChangeNotifier {
  List<TileData?> board = List.filled(Constants.bn, null);
  List<TileData> hand = [];
  List<TileData> deck = [];

  int score = 0;
  int totalScore = 0;
  int targetScore = 300;
  int round = 1;
  int dScore = 0;
  int rndScore = 0;

  int execLeft = Constants.maxExec;
  int discLeft = Constants.maxDisc;

  String phase = "title"; // title, play, executing, scoring, result, gameover, shop

  int ante = 1;
  int stage = 1;
  String bossGimmick = "none";
  int gold = 4;

  List<JokerData> jokers = [];
  List<ShopItemData> shopItems = [];
  List<TileData> deckConfig = [];

  Map<String, HandStat> handStats = {};
  List<DetectedPattern> detected = [];

  String noticeText = "";
  String noticeKind = "info";

  bool roundCleared = false;
  int discardMultBonus = 0; // reroll_boost 조커용 임시 배수

  // ─── Notifications ───
  void notice(String text, [String kind = "info"]) {
    noticeText = text;
    noticeKind = kind;
    notifyListeners();
  }

  void clearNotice() {
    noticeText = "";
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  // ─── Stage Progression ───
  void advanceStage() {
    // 골드 보상 지급
    var reward = BalanceData.calcGoldReward(gold, discLeft, jokers);
    gold += reward["total"]!;

    stage++;
    if (stage > Constants.stagesPerAnte) {
      stage = 1;
      ante++;
      // 새 Ante 진입 시 보스 기믹 변경
      final gimmicks = BalanceData.bossGimmicks;
      bossGimmick = (gimmicks.toList()..shuffle()).first;
    }
    notifyListeners();
  }

  // ─── Game Over Check ───
  bool checkGameOver() {
    if (execLeft <= 0 && score < targetScore) {
      phase = "gameover";
      notifyListeners();
      return true;
    }
    return false;
  }

  // ─── Victory Check ───
  bool checkVictory() {
    return ante > Constants.maxAnte;
  }

  // ─── Shop Purchase ───
  bool purchaseItem(ShopItemData item) {
    if (item.sold || gold < item.price) return false;

    gold -= item.price;
    item.sold = true;

    switch (item.type) {
      case ShopItemType.upgrade:
        if (item.hand != null && handStats.containsKey(item.hand)) {
          var stat = handStats[item.hand]!;
          stat.level++;
          stat.chips += stat.scaleChips;
          stat.mult += stat.scaleMult;
        }
        break;

      case ShopItemType.deckAdd:
        if (item.colorName != null && item.colorVal != null) {
          deckConfig.add(TileData(name: item.colorName!, color: item.colorVal!));
        }
        break;

      case ShopItemType.deckRemove:
        if (deckConfig.isNotEmpty) {
          deckConfig.shuffle();
          deckConfig.removeLast();
        }
        break;

      case ShopItemType.deckRemoveColor:
        if (item.colorName != null) {
          int idx = deckConfig.lastIndexWhere((c) => c.name == item.colorName);
          if (idx >= 0) {
            deckConfig.removeAt(idx);
          } else {
            gold += item.price;
            item.sold = false;
            notice("해당 색의 카드가 없어요!", "warn");
            notifyListeners();
            return false;
          }
        }
        break;

      case ShopItemType.deckTransform:
        if (item.fromColor != null && item.toColor != null && item.toColorVal != null) {
          int idx = deckConfig.lastIndexWhere((c) => c.name == item.fromColor);
          if (idx >= 0) {
            deckConfig[idx] = TileData(name: item.toColor!, color: item.toColorVal!);
          } else {
            gold += item.price;
            item.sold = false;
            notice("변환할 카드가 없어요!", "warn");
            notifyListeners();
            return false;
          }
        }
        break;

      case ShopItemType.joker:
        if (jokers.length >= Constants.maxJokers) {
          gold += item.price;
          item.sold = false;
          notice("조커 슬롯이 가득 찼어요!", "warn");
          notifyListeners();
          return false;
        }
        if (item.jokerId != null) {
          // Find joker data
          final jokerData = _findJokerById(item.jokerId!);
          if (jokerData != null) {
            jokers.add(jokerData);
          }
        }
        break;
    }

    notifyListeners();
    return true;
  }

  JokerData? _findJokerById(String id) {
    // Import from jokers data
    try {
      return const [
        JokerData(id: "shiny_eye", name: "반짝이는 눈", desc: "위에 하양이 있으면\n+50 별", price: 6),
        JokerData(id: "dark_side", name: "밤빛 친구", desc: "위에 검정이 있으면\n+5 콤보", price: 6),
        JokerData(id: "mirror_shield", name: "거울 방패", desc: "대칭 규칙이 나오면\nx1.8 콤보", price: 6),
        JokerData(id: "rainbow", name: "무지개", desc: "다른 색이 4종류\n이상이면\n+60 별, +6 콤보", price: 7),
        JokerData(id: "ladder_master", name: "크레센도 대장", desc: "크레센도 규칙이 나오면\n+100 별", price: 5),
        JokerData(id: "gold_rush", name: "코인 주머니", desc: "관문 종료 시\n+\$4 코인 추가", price: 5),
        JokerData(id: "chaos", name: "혼돈의 카오스", desc: "맞는 규칙이 없으면\nx2.2 콤보", price: 6),
        JokerData(id: "savings", name: "저축왕", desc: "보유한 코인 \$2 마다\n+1 콤보 추가", price: 6),
        JokerData(id: "mono_pride", name: "일편단심", desc: "보드판 전체가 단 1가지\n색이면 x2.5 콤보", price: 8),
        JokerData(id: "burning", name: "불타는 열정", desc: "보드판 위의 빨강\n카드 1개당 +3 콤보", price: 5),
        JokerData(id: "lemonade", name: "레몬에이드", desc: "보드판 위의 노랑\n카드 1개당 +25 별", price: 5),
        JokerData(id: "overload", name: "증강 가속기", desc: "다른 활성화 증강체\n1개당 +4 콤보 추가", price: 7),
        JokerData(id: "eclipse", name: "일식", desc: "하양과 검정 카드가\n같이 있으면 x1.8 배수", price: 8),
        JokerData(id: "alchemy", name: "금단 연금술", desc: "빨강과 노랑이\n각 2장 이상이면\n별 +80, +\$2", price: 6),
        JokerData(id: "resonance", name: "공명 주파수", desc: "대칭과 크레센도 규칙\n동시 발동 시 x2.0 배수", price: 7),
        JokerData(id: "reroll_spark", name: "재굴림 스파크", desc: "바꾸기 시 35% 확률로\n패의 무작위 카드 1장\n특수 에디션으로 강화", price: 6),
        JokerData(id: "reroll_boost", name: "재굴림 증폭기", desc: "바꾸기 시 40% 확률로\n이번 라운드 배수 +3 추가", price: 6),
      ].firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Generate Shop Items ───
  void generateShopItems() {
    shopItems = [];
    final pool = <ShopItemData>[];

    // Add all non-joker items
    pool.addAll(_buildShopPool().where((item) => item.type != ShopItemType.joker));
    pool.shuffle();
    shopItems.addAll(pool.take(Constants.shopItemCount));

    // Add joker items separately
    final jokerPool = _buildShopPool().where((item) => item.type == ShopItemType.joker).toList();
    jokerPool.shuffle();
    shopItems.addAll(jokerPool.take(Constants.shopJokerCount));
  }

  List<ShopItemData> _buildShopPool() {
    // Inline a simplified version to avoid circular deps
    List<ShopItemData> pool = [
      ShopItemData(type: ShopItemType.upgrade, hand: "Mono", name: "모노 반짝임", desc: "모노 규칙 레벨 +1\n(+15 별, +1 콤보)", price: 3),
      ShopItemData(type: ShopItemType.upgrade, hand: "Mirror", name: "대칭 반짝임", desc: "대칭 규칙 레벨 +1\n(+20 별, +1.5 콤보)", price: 3),
      ShopItemData(type: ShopItemType.upgrade, hand: "Twins", name: "쌍둥이 반짝임", desc: "쌍둥이 규칙 레벨 +1\n(+12 별, +1 콤보)", price: 3),
      ShopItemData(type: ShopItemType.upgrade, hand: "Crescendo", name: "크레센도 반짝임", desc: "크레센도 규칙 레벨 +1\n(+25 별, +2 콤보)", price: 3),
      ShopItemData(type: ShopItemType.upgrade, hand: "Zigzag", name: "지그재그 반짝임", desc: "지그재그 규칙 레벨 +1\n(+18 별, +1.2 콤보)", price: 3),
      ShopItemData(type: ShopItemType.deckAdd, colorName: "Red", colorVal: const Color(0xFFFF6B6B), name: "빨강 추가", desc: "빨강 1개 추가", price: 2),
      ShopItemData(type: ShopItemType.deckAdd, colorName: "Black", colorVal: const Color(0xFF2D3436), name: "검정 추가", desc: "검정 1개 추가", price: 2),
      ShopItemData(type: ShopItemType.deckRemove, name: "랜덤 삭제", desc: "무작위 카드 1개 삭제", price: 3),
      ShopItemData(type: ShopItemType.deckRemoveColor, colorName: "Red", name: "빨강 삭제", desc: "빨강 1개 삭제", price: 4),
      ShopItemData(type: ShopItemType.deckRemoveColor, colorName: "Black", name: "검정 삭제", desc: "검정 1개 삭제", price: 4),
      ShopItemData(type: ShopItemType.deckTransform, fromColor: "Red", toColor: "Orange", toColorVal: const Color(0xFFFFB347), name: "빨강→주황", desc: "빨강→주황 변환", price: 4),
      ShopItemData(type: ShopItemType.deckTransform, fromColor: "Orange", toColor: "Yellow", toColorVal: const Color(0xFFFFE66D), name: "주황→노랑", desc: "주황→노랑 변환", price: 4),
      ShopItemData(type: ShopItemType.deckTransform, fromColor: "Yellow", toColor: "White", toColorVal: const Color(0xFFF8F9FA), name: "노랑→하양", desc: "노랑→하양 변환", price: 5),
      ShopItemData(type: ShopItemType.deckTransform, fromColor: "White", toColor: "Black", toColorVal: const Color(0xFF2D3436), name: "하양→검정", desc: "하양→검정 변환", price: 5),
    ];

    // Add jokers
    for (var j in const [
      JokerData(id: "shiny_eye", name: "반짝이는 눈", desc: "위에 하양이 있으면\n+50 별", price: 6),
      JokerData(id: "dark_side", name: "밤빛 친구", desc: "위에 검정이 있으면\n+5 콤보", price: 6),
      JokerData(id: "mirror_shield", name: "거울 방패", desc: "대칭 규칙이 나오면\nx1.8 콤보", price: 6),
      JokerData(id: "rainbow", name: "무지개", desc: "다른 색이 4종류\n이상이면\n+60 별, +6 콤보", price: 7),
      JokerData(id: "ladder_master", name: "크레센도 대장", desc: "크레센도 규칙이 나오면\n+100 별", price: 5),
      JokerData(id: "gold_rush", name: "코인 주머니", desc: "관문 종료 시\n+\$4 코인 추가", price: 5),
      JokerData(id: "chaos", name: "혼돈의 카오스", desc: "맞는 규칙이 없으면\nx2.2 콤보", price: 6),
      JokerData(id: "savings", name: "저축왕", desc: "보유한 코인 \$2 마다\n+1 콤보 추가", price: 6),
      JokerData(id: "mono_pride", name: "일편단심", desc: "보드판 전체가 단 1가지\n색이면 x2.5 콤보", price: 8),
      JokerData(id: "burning", name: "불타는 열정", desc: "보드판 위의 빨강\n카드 1개당 +3 콤보", price: 5),
      JokerData(id: "lemonade", name: "레몬에이드", desc: "보드판 위의 노랑\n카드 1개당 +25 별", price: 5),
      JokerData(id: "overload", name: "증강 가속기", desc: "다른 활성화 증강체\n1개당 +4 콤보 추가", price: 7),
      JokerData(id: "eclipse", name: "일식", desc: "하양과 검정 카드가\n같이 있으면 x1.8 배수", price: 8),
      JokerData(id: "alchemy", name: "금단 연금술", desc: "빨강과 노랑이\n각 2장 이상이면\n별 +80, +\$2", price: 6),
      JokerData(id: "resonance", name: "공명 주파수", desc: "대칭과 크레센도 규칙\n동시 발동 시 x2.0 배수", price: 7),
      JokerData(id: "reroll_spark", name: "재굴림 스파크", desc: "바꾸기 시 35% 확률로\n패의 무작위 카드 1장\n특수 에디션으로 강화", price: 6),
      JokerData(id: "reroll_boost", name: "재굴림 증폭기", desc: "바꾸기 시 40% 확률로\n이번 라운드 배수 +3 추가", price: 6),
    ]) {
      pool.add(ShopItemData(
        type: ShopItemType.joker,
        name: j.name,
        desc: j.desc,
        price: j.price,
        jokerId: j.id,
      ));
    }

    return pool;
  }

  // ─── Reset ───
  void reset() {
    score = 0;
    totalScore = 0;
    dScore = 0;
    rndScore = 0;
    round = 1;
    ante = 1;
    stage = 1;
    gold = 4;
    jokers = [];
    discardMultBonus = 0;

    final gimmicks = ["no_red", "no_black", "no_discard", "high_target"];
    bossGimmick = (gimmicks.toList()..shuffle()).first;
    roundCleared = false;

    handStats = PatternsData.handStatsTemplate.map((key, value) => MapEntry(key, value.copy()));

    deckConfig = [];
    for (var c in charactersData) {
      for (int i = 0; i < c.count; i++) {
        deckConfig.add(TileData(name: c.name, color: c.color));
      }
    }

    phase = "title";
    notifyListeners();
  }
}
