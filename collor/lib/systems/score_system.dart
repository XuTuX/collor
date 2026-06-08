import '../data/models.dart';
import '../data/characters.dart';
import '../core/constants.dart';
import '../core/game_state.dart';
import 'joker_system.dart';

class ScoreState {
  bool active = false;
  int idx = 0;
  double timer = 0;
  String phase = "idle";

  int dChips = 0;
  int dMult = 1;
  int tChips = 0;
  int tMult = 1;
  double xMult = 1.0;
  int dTotal = 0;

  List<DetectedPattern> revealed = [];
  Map<int, bool> hopIdx = {};
  List<ScoreEvent> events = [];
  ScoreEvent? currentEvent;

  int? activeJokerIndex;
  double activeJokerTimer = 0;

  int prevDChips = 0;
  int prevDMult = 0;

  void clear() {
    active = false;
    idx = 0;
    timer = 0;
    phase = "idle";
    dChips = 0;
    dMult = 1;
    tChips = 0;
    tMult = 1;
    xMult = 1.0;
    dTotal = 0;
    revealed.clear();
    hopIdx.clear();
    events.clear();
    currentEvent = null;
    activeJokerIndex = null;
    activeJokerTimer = 0;
    prevDChips = 0;
    prevDMult = 0;
  }
}

class ScoreSystem {
  static final ScoreState state = ScoreState();

  static int get finalScore => state.dTotal;

  static void start(List<TileData?> board, List<DetectedPattern> detectedPatterns, List<JokerData> jokers, GameState G) {
    state.clear();
    state.active = true;

    Map<String, bool> uniqueColors = {};
    for (int i = 0; i < Constants.bn; i++) {
      if (i < board.length && board[i] != null) {
        uniqueColors[board[i]!.name] = true;
      }
    }

    int ucCount = uniqueColors.length;
    if (ucCount >= 3) {
      int c = 0, m = 0;
      if (ucCount == 3) { c = 5; m = 2; }
      else if (ucCount == 4) { c = 15; m = 3; }
      else { c = 30; m = 4; }
      state.events.add(ScoreEvent(type: "diversity", count: ucCount, chips: c, mult: m));
    }

    for (int i = 0; i < Constants.bn; i++) {
      if (i >= board.length) break;
      var card = board[i];
      if (card != null) {
        int baseVal = 10;
        for (var info in charactersData) {
          if (info.name == card.name) { baseVal = info.baseValue; break; }
        }

        int extraChips = 0;
        int extraMult = 0;
        if (card.edition == "foil") {
          extraChips = 15;
        } else if (card.edition == "holo") {
          extraMult = 3;
        } else if (card.edition == "gold") {
          G.gold++;
        }

        state.events.add(ScoreEvent(
          type: "card",
          idx: i,
          chips: baseVal + extraChips,
          mult: extraMult,
          name: card.name,
          edition: card.edition,
        ));
      }
    }

    for (var h in detectedPatterns) {
      state.events.add(ScoreEvent(type: "rule", rule: h));
    }

    JokerSystem.evaluate(jokers, uniqueColors, ucCount, detectedPatterns, state.events, board, G);

    state.events.add(ScoreEvent(type: "total"));

    if (state.events.length == 1) {
      state.phase = "nohand";
      state.dTotal = 0;
    } else {
      state.phase = "process";
      processEvents();
    }
  }

  static int processEvents() {
    state.tChips = 0;
    state.tMult = 0;
    state.xMult = 1.0;

    for (var event in state.events) {
      switch (event.type) {
        case "diversity":
          state.tChips += event.chips ?? 0;
          state.tMult += event.mult ?? 0;
          break;

        case "card":
          state.tChips += event.chips ?? 0;
          state.tMult += event.mult ?? 0;
          break;

        case "rule":
          if (event.rule != null) {
            state.tChips += event.rule!.chips;
            state.tMult += event.rule!.mult;
          }
          break;

        case "joker":
          state.tChips += event.chips ?? 0;
          state.tMult += event.mult ?? 0;
          if (event.xmult != null && event.xmult! > 1.0) {
            state.xMult *= event.xmult!;
          }
          break;

        case "total":
          break;
      }
    }

    if (state.tMult <= 0) state.tMult = 1;

    state.dTotal = (state.tChips * state.tMult * state.xMult).floor();
    state.dChips = state.tChips;
    state.dMult = state.tMult;

    return state.dTotal;
  }
}
