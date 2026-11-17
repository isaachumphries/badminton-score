import 'package:badminton_score/engine/game.dart';
import 'package:badminton_score/engine/rulesets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isGameWon', () {
    test('bwf21', () {
      expect(isGameWon(21, 19, bwf21), isTrue);
      expect(isGameWon(21, 20, bwf21), isFalse);
      expect(isGameWon(22, 20, bwf21), isTrue);
      expect(isGameWon(20, 20, bwf21), isFalse);
      expect(isGameWon(29, 29, bwf21), isFalse);
      expect(isGameWon(30, 29, bwf21), isTrue);
    });
    test('bwf15', () {
      expect(isGameWon(15, 13, bwf15), isTrue);
      expect(isGameWon(15, 14, bwf15), isFalse);
      expect(isGameWon(16, 14, bwf15), isTrue);
      expect(isGameWon(21, 20, bwf15), isTrue);
    });
  });
  group('wouldWinGame', () {
    test('bwf21', () {
      expect(wouldWinGame(20, 18, bwf21), isTrue);
      expect(wouldWinGame(20, 20, bwf21), isFalse);
      expect(wouldWinGame(29, 29, bwf21), isTrue);
    });
    test('bwf15', () {
      expect(wouldWinGame(14, 14, bwf15), isFalse);
      expect(wouldWinGame(14, 13, bwf15), isTrue);
    });
  });

  test('customRuleset', () {
    final r = customRuleset(11, winBy2: false);
    expect(isGameWon(11, 10, r), isTrue);
    final w = customRuleset(5, winBy2: true);
    expect(isGameWon(5, 4, w), isFalse);
    expect(isGameWon(6, 4, w), isTrue);
    expect(isGameWon(14, 13, w), isTrue); // cap = 5 + 9
  });
}
