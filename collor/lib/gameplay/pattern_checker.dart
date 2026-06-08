import '../data/models.dart';
import '../data/characters.dart';
import '../core/constants.dart';

class PatternChecker {
  static int boardLen(List<TileData?> boardTable) {
    int n = 0;
    for (int i = 0; i < Constants.bn; i++) {
      if (boardTable.length <= i || boardTable[i] == null) break;
      n = i + 1;
    }
    return n;
  }

  static String getShortName(String name) {
    for (var c in charactersData) {
      if (c.name == name) return c.shortName;
    }
    return "?";
  }

  static final Map<String, int> rankMap = {
    "Red": 1,
    "Orange": 2,
    "Yellow": 3,
    "White": 4,
    "Black": 5,
  };

  static List<Map<String, dynamic>> getRuns(List<TileData?> boardTable) {
    List<Map<String, dynamic>> runs = [];
    if (boardTable.isEmpty || boardTable[0] == null) return runs;

    String col = boardTable[0]!.name;
    int st = 0;
    int len = 1;
    int n = boardLen(boardTable);

    for (int i = 1; i < n; i++) {
      if (boardTable[i]!.name == col) {
        len++;
      } else {
        runs.add({"color": col, "start": st, "length": len});
        col = boardTable[i]!.name;
        st = i;
        len = 1;
      }
    }
    runs.add({"color": col, "start": st, "length": len});
    return runs;
  }

  static List<DetectedPattern> checkMono(List<TileData?> boardTable) {
    List<DetectedPattern> results = [];
    var runs = getRuns(boardTable);
    for (var r in runs) {
      int length = r["length"];
      if (length >= 3) {
        String colName = r["color"];
        String shortName = getShortName(colName);
        String patternStr = "";
        for (int i = 0; i < length; i++) {
          patternStr += shortName;
        }

        List<int> indices = [];
        for (int i = r["start"]; i < r["start"] + length; i++) {
          indices.add(i);
        }
        results.add(DetectedPattern(
            cat: "MONO",
            name: "Mono",
            length: length,
            pat: patternStr,
            idx: indices));
      }
    }
    return results;
  }

  static List<DetectedPattern> checkMirror(List<TileData?> boardTable) {
    List<DetectedPattern> results = [];
    int n = boardLen(boardTable);

    bool checkSymmetry(int si, int length) {
      int ei = si + length - 1;
      if (ei >= n) return false;
      for (int i = si; i <= ei; i++) {
        if (boardTable[i] == null) return false;
      }

      for (int i = 0; i < (length ~/ 2); i++) {
        if (boardTable[si + i]!.name != boardTable[ei - i]!.name) return false;
      }

      Set<String> colors = {};
      for (int i = si; i <= ei; i++) {
        colors.add(boardTable[i]!.name);
      }
      return colors.length >= 2;
    }

    String makePatternString(int si, int length) {
      String p = "";
      for (int i = si; i < si + length; i++) {
        p += getShortName(boardTable[i]!.name);
      }
      return p;
    }

    List<int> getIndices(int si, int length) {
      List<int> indices = [];
      for (int i = si; i < si + length; i++) {
        indices.add(i);
      }
      return indices;
    }

    for (int length = n; length >= 3; length--) {
      for (int start = 0; start <= n - length; start++) {
        if (checkSymmetry(start, length)) {
          results.add(DetectedPattern(
              cat: "MIRROR",
              name: "Mirror",
              length: length,
              pat: makePatternString(start, length),
              idx: getIndices(start, length)));
          return results;
        }
      }
    }
    return results;
  }

  static List<DetectedPattern> checkTwins(List<TileData?> boardTable) {
    List<DetectedPattern> results = [];
    int n = boardLen(boardTable);
    if (n < 2) return results;

    int pairsCount = 0;
    List<int> idx = [];
    String pat = "";
    int i = 0;

    while (i < n - 1) {
      if (boardTable[i] != null &&
          boardTable[i + 1] != null &&
          boardTable[i]!.name == boardTable[i + 1]!.name) {
        pairsCount++;
        idx.add(i);
        idx.add(i + 1);
        pat += getShortName(boardTable[i]!.name) +
            getShortName(boardTable[i + 1]!.name);
        i += 2;
      } else {
        i++;
      }
    }

    if (pairsCount >= 1) {
      results.add(DetectedPattern(
          cat: "TWINS", name: "Twins", pairs: pairsCount, pat: pat, idx: idx));
    }
    return results;
  }

  static List<DetectedPattern> checkCrescendo(List<TileData?> boardTable) {
    List<DetectedPattern> results = [];
    int n = boardLen(boardTable);
    if (n < 3) return results;

    bool checkSeq(int si, int length) {
      int ei = si + length - 1;
      if (ei >= n) return false;
      for (int i = si; i <= ei; i++) {
        if (boardTable[i] == null) return false;
      }

      bool isIncreasing = true;
      bool isDecreasing = true;

      for (int i = si; i < ei; i++) {
        int? r1 = rankMap[boardTable[i]!.name];
        int? r2 = rankMap[boardTable[i + 1]!.name];
        if (r1 == null || r2 == null) return false;

        if (r2 <= r1) isIncreasing = false;
        if (r2 >= r1) isDecreasing = false;
      }
      return isIncreasing || isDecreasing;
    }

    String makePatternString(int si, int length) {
      String p = "";
      for (int i = si; i < si + length; i++) {
        p += getShortName(boardTable[i]!.name);
      }
      return p;
    }

    List<int> getIndices(int si, int length) {
      List<int> indices = [];
      for (int i = si; i < si + length; i++) {
        indices.add(i);
      }
      return indices;
    }

    for (int length = n; length >= 3; length--) {
      for (int start = 0; start <= n - length; start++) {
        if (checkSeq(start, length)) {
          results.add(DetectedPattern(
              cat: "CRESCENDO",
              name: "Crescendo",
              length: length,
              pat: makePatternString(start, length),
              idx: getIndices(start, length)));
          return results;
        }
      }
    }
    return results;
  }

  static List<DetectedPattern> checkZigzag(List<TileData?> boardTable) {
    List<DetectedPattern> results = [];
    int n = boardLen(boardTable);
    if (n < 3) return results;

    bool checkAlternating(int si, int length) {
      int ei = si + length - 1;
      if (ei >= n) return false;
      for (int i = si; i <= ei; i++) {
        if (boardTable[i] == null) return false;
      }

      String c1 = boardTable[si]!.name;
      String c2 = boardTable[si + 1]!.name;
      if (c1 == c2) return false;

      for (int i = 0; i < length; i++) {
        String expected = (i % 2 == 0) ? c1 : c2;
        if (boardTable[si + i]!.name != expected) {
          return false;
        }
      }
      return true;
    }

    String makePatternString(int si, int length) {
      String p = "";
      for (int i = si; i < si + length; i++) {
        p += getShortName(boardTable[i]!.name);
      }
      return p;
    }

    List<int> getIndices(int si, int length) {
      List<int> indices = [];
      for (int i = si; i < si + length; i++) {
        indices.add(i);
      }
      return indices;
    }

    for (int length = n; length >= 3; length--) {
      for (int start = 0; start <= n - length; start++) {
        if (checkAlternating(start, length)) {
          results.add(DetectedPattern(
              cat: "ZIGZAG",
              name: "Zigzag",
              length: length,
              pat: makePatternString(start, length),
              idx: getIndices(start, length)));
          return results;
        }
      }
    }
    return results;
  }

  static List<DetectedPattern> evaluate(List<TileData?> boardTable) {
    List<DetectedPattern> detected = [];
    detected.addAll(checkMono(boardTable));
    detected.addAll(checkMirror(boardTable));
    detected.addAll(checkCrescendo(boardTable));
    detected.addAll(checkTwins(boardTable));
    detected.addAll(checkZigzag(boardTable));
    return detected;
  }
}
