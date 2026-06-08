import 'dart:ui';
import 'models.dart';

final List<CharacterData> charactersData = [
  CharacterData(
    name: "Red",
    shortName: "R",
    color: Color.fromRGBO((0.92 * 255).toInt(), (0.22 * 255).toInt(), (0.25 * 255).toInt(), 1.0),
    darkColor: Color.fromRGBO((0.65 * 255).toInt(), (0.10 * 255).toInt(), (0.12 * 255).toInt(), 1.0),
    baseValue: 1,
    count: 16,
  ),
  CharacterData(
    name: "Orange",
    shortName: "O",
    color: Color.fromRGBO((0.95 * 255).toInt(), (0.55 * 255).toInt(), (0.15 * 255).toInt(), 1.0),
    darkColor: Color.fromRGBO((0.68 * 255).toInt(), (0.35 * 255).toInt(), (0.06 * 255).toInt(), 1.0),
    baseValue: 2,
    count: 12,
  ),
  CharacterData(
    name: "Yellow",
    shortName: "Y",
    color: Color.fromRGBO((0.95 * 255).toInt(), (0.85 * 255).toInt(), (0.15 * 255).toInt(), 1.0),
    darkColor: Color.fromRGBO((0.68 * 255).toInt(), (0.60 * 255).toInt(), (0.06 * 255).toInt(), 1.0),
    baseValue: 3,
    count: 10,
  ),
  CharacterData(
    name: "White",
    shortName: "W",
    color: Color.fromRGBO((0.94 * 255).toInt(), (0.94 * 255).toInt(), (0.96 * 255).toInt(), 1.0),
    darkColor: Color.fromRGBO((0.70 * 255).toInt(), (0.70 * 255).toInt(), (0.72 * 255).toInt(), 1.0),
    baseValue: 4,
    count: 8,
  ),
  CharacterData(
    name: "Black",
    shortName: "K",
    color: Color.fromRGBO((0.12 * 255).toInt(), (0.12 * 255).toInt(), (0.16 * 255).toInt(), 1.0),
    darkColor: Color.fromRGBO((0.05 * 255).toInt(), (0.05 * 255).toInt(), (0.07 * 255).toInt(), 1.0),
    baseValue: -1,
    count: 4,
  ),
];
