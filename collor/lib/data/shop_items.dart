import 'dart:ui';
import 'models.dart';
import 'characters.dart';
import 'jokers.dart';

class ShopItemsData {
  static Color? colorValue(String name) {
    for (var c in charactersData) {
      if (c.name == name) {
        return c.color;
      }
    }
    return null;
  }

  static List<ShopItemData> buildPool() {
    List<ShopItemData> pool = [
      ShopItemData(
        type: ShopItemType.upgrade,
        hand: "Mono",
        name: "모노 반짝임",
        desc: "모노 규칙 레벨 +1\n(기본 +15 별, +1 콤보)",
        price: 3,
      ),
      ShopItemData(
        type: ShopItemType.upgrade,
        hand: "Mirror",
        name: "대칭 반짝임",
        desc: "대칭 규칙 레벨 +1\n(기본 +20 별, +1.5 콤보)",
        price: 3,
      ),
      ShopItemData(
        type: ShopItemType.upgrade,
        hand: "Twins",
        name: "쌍둥이 반짝임",
        desc: "쌍둥이 규칙 레벨 +1\n(기본 +12 별, +1 콤보)",
        price: 3,
      ),
      ShopItemData(
        type: ShopItemType.upgrade,
        hand: "Crescendo",
        name: "크레센도 반짝임",
        desc: "크레센도 규칙 레벨 +1\n(기본 +25 별, +2 콤보)",
        price: 3,
      ),
      ShopItemData(
        type: ShopItemType.upgrade,
        hand: "Zigzag",
        name: "지그재그 반짝임",
        desc: "지그재그 규칙 레벨 +1\n(기본 +18 별, +1.2 콤보)",
        price: 3,
      ),
      ShopItemData(
        type: ShopItemType.deckAdd,
        colorName: "Red",
        colorVal: colorValue("Red"),
        name: "빨강 추가",
        desc: "빨강 색친구 1개를\n주머니에 계속 추가",
        price: 2,
      ),
      ShopItemData(
        type: ShopItemType.deckAdd,
        colorName: "Black",
        colorVal: colorValue("Black"),
        name: "검정 추가",
        desc: "검정 색친구 1개를\n주머니에 계속 추가",
        price: 2,
      ),
      ShopItemData(
        type: ShopItemType.deckRemove,
        name: "랜덤 삭제",
        desc: "무작위 색친구 1개를\n주머니에서 삭제",
        price: 3,
      ),
      ShopItemData(
        type: ShopItemType.deckRemoveColor,
        colorName: "Red",
        name: "빨강 삭제",
        desc: "빨강 색친구 1개를\n주머니에서 삭제",
        price: 4,
      ),
      ShopItemData(
        type: ShopItemType.deckRemoveColor,
        colorName: "Black",
        name: "검정 삭제",
        desc: "검정 색친구 1개를\n주머니에서 삭제",
        price: 4,
      ),
      ShopItemData(
        type: ShopItemType.deckTransform,
        fromColor: "Red",
        toColor: "Orange",
        toColorVal: colorValue("Orange"),
        name: "빨강->주황",
        desc: "빨강 1개를\n주황으로 바꾸기",
        price: 4,
      ),
      ShopItemData(
        type: ShopItemType.deckTransform,
        fromColor: "Orange",
        toColor: "Yellow",
        toColorVal: colorValue("Yellow"),
        name: "주황->노랑",
        desc: "주황 1개를\n노랑으로 바꾸기",
        price: 4,
      ),
      ShopItemData(
        type: ShopItemType.deckTransform,
        fromColor: "Yellow",
        toColor: "White",
        toColorVal: colorValue("White"),
        name: "노랑->하양",
        desc: "노랑 1개를\n하양으로 바꾸기",
        price: 5,
      ),
      ShopItemData(
        type: ShopItemType.deckTransform,
        fromColor: "White",
        toColor: "Black",
        toColorVal: colorValue("Black"),
        name: "하양->검정",
        desc: "하양 1개를\n검정으로 바꾸기",
        price: 5,
      ),
    ];

    for (var joker in jokersData) {
      pool.add(ShopItemData(
        type: ShopItemType.joker,
        name: joker.name,
        desc: joker.desc,
        price: joker.price,
        jokerId: joker.id,
      ));
    }

    return pool;
  }
}
