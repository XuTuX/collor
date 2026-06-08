import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:collor/data/models.dart';
import 'package:collor/gameplay/pattern_checker.dart';

TileData createTile(String name) {
  return TileData(name: name, color: const Color(0xFF000000));
}

void main() {
  group('PatternChecker Tests', () {
    test('checkMono detects consecutive identical colors', () {
      List<TileData?> board = [
        createTile('Red'),
        createTile('Red'),
        createTile('Red'),
        null,
        null,
      ];
      var results = PatternChecker.checkMono(board);
      expect(results.length, 1);
      expect(results[0].cat, 'MONO');
      expect(results[0].length, 3);
    });

    test('checkMirror detects symmetrical patterns', () {
      List<TileData?> board = [
        createTile('Red'),
        createTile('Yellow'),
        createTile('Red'),
        null,
        null,
      ];
      var results = PatternChecker.checkMirror(board);
      expect(results.length, 1);
      expect(results[0].cat, 'MIRROR');
      expect(results[0].length, 3);
    });

    test('checkCrescendo detects ascending/descending rank patterns', () {
      List<TileData?> board = [
        createTile('Red'),     // Rank 1
        createTile('Orange'),  // Rank 2
        createTile('Yellow'),  // Rank 3
        null,
        null,
      ];
      var results = PatternChecker.checkCrescendo(board);
      expect(results.length, 1);
      expect(results[0].cat, 'CRESCENDO');
      expect(results[0].length, 3);
    });
  });
}
