

class Constants {
  // Board
  static const int bn = 5; // Board slot count (unified)
  static const double bsw = 74;
  static const double bsh = 96;
  static const double bgap = 10;
  static const double bw = bn * bsw + (bn - 1) * bgap;

  // Hand
  static const int hn = 7;
  static const int deckSize = 50;
  static const int maxDisc = 3;
  static const int maxExec = 4;
  static const int maxJokers = 3;

  // Shop
  static const int shopItemCount = 5;
  static const int shopJokerCount = 2;

  // Progression
  static const int maxAnte = 8;
  static const int stagesPerAnte = 3;

  // Scoring animation timing (ms)
  static const int scoreStepDelay = 350;
  static const int scoreCardDelay = 200;
  static const int scoreRuleDelay = 400;
  static const int scoreJokerDelay = 350;
  static const int scoreTotalDelay = 600;
}
