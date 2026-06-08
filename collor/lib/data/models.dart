import 'dart:ui';

class CharacterData {
  final String name;
  final String shortName;
  final Color color;
  final Color darkColor;
  final int baseValue;
  final int count;

  const CharacterData({
    required this.name,
    required this.shortName,
    required this.color,
    required this.darkColor,
    required this.baseValue,
    required this.count,
  });
}

class HandStat {
  int level;
  int chips;
  double mult;
  final int scaleChips;
  final double scaleMult;

  HandStat({
    required this.level,
    required this.chips,
    required this.mult,
    required this.scaleChips,
    required this.scaleMult,
  });

  HandStat copy() {
    return HandStat(
      level: level,
      chips: chips,
      mult: mult,
      scaleChips: scaleChips,
      scaleMult: scaleMult,
    );
  }
}

class JokerData {
  final String id;
  final String name;
  final String desc;
  final int price;

  const JokerData({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
  });
}

enum ShopItemType { upgrade, deckAdd, deckRemove, deckRemoveColor, deckTransform, joker }

class ShopItemData {
  final ShopItemType type;
  final String name;
  final String desc;
  final int price;
  final String? hand; // for upgrade
  final String? colorName; // for deck manipulations
  final Color? colorVal;
  final String? fromColor;
  final String? toColor;
  final Color? toColorVal;
  final String? jokerId; // for jokers
  bool sold;

  ShopItemData({
    required this.type,
    required this.name,
    required this.desc,
    required this.price,
    this.hand,
    this.colorName,
    this.colorVal,
    this.fromColor,
    this.toColor,
    this.toColorVal,
    this.jokerId,
    this.sold = false,
  });

  ShopItemData copy() {
    return ShopItemData(
      type: type,
      name: name,
      desc: desc,
      price: price,
      hand: hand,
      colorName: colorName,
      colorVal: colorVal,
      fromColor: fromColor,
      toColor: toColor,
      toColorVal: toColorVal,
      jokerId: jokerId,
      sold: sold,
    );
  }
}

class DetectedPattern {
  final String cat;
  final String name;
  final int? length;
  final int? pairs;
  final String pat;
  final List<int> idx;
  int chips;
  int mult;

  DetectedPattern({
    required this.cat,
    required this.name,
    this.length,
    this.pairs,
    required this.pat,
    required this.idx,
    this.chips = 0,
    this.mult = 0,
  });
}

class TileData {
  String name;
  Color color;
  String edition;
  bool sel;
  double? visX;
  double hovScale;
  double hovTilt;

  TileData({
    required this.name,
    required this.color,
    this.edition = "normal",
    this.sel = false,
    this.visX,
    this.hovScale = 1.0,
    this.hovTilt = 0.0,
  });

  TileData copy() {
    return TileData(
      name: name,
      color: color,
      edition: edition,
      sel: sel,
    );
  }
}

class ScoreEvent {
  final String type; // diversity, card, rule, joker, total
  final int? count;
  final int? chips;
  final int? mult;
  final double? xmult;
  final int? idx;
  final String? name;
  final String? edition;
  final DetectedPattern? rule;
  final String? jokerId;
  final int? jokerIndex;

  ScoreEvent({
    required this.type,
    this.count,
    this.chips,
    this.mult,
    this.xmult,
    this.idx,
    this.name,
    this.edition,
    this.rule,
    this.jokerId,
    this.jokerIndex,
  });
}



