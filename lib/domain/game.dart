import 'dart:math';

import 'package:fifteenpuzzle/data/board.dart';
import 'package:fifteenpuzzle/data/chip.dart';
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';

abstract class Game {
  static Game instance = _GameImpl();

  Tuple2<bool, Board> swipe(Board board, {@required Point<int> point});

  Board spawn(Board board);
}

class _GameImpl implements Game {
  final _random = Random.secure();

  @override
  Tuple2<bool, Board> swipe(Board board, {Point<int> point}) {
    List<List<Chip>> matrix = List.generate(board.size, (i) {
      return List.generate(board.size, (j) {
        return null;
      });
    });

    board.chips.forEach((chip) {
      matrix[chip.currentPoint.x][chip.currentPoint.y] = chip;
    });

    Tuple2<int, int> Function(int, int) transform;
    if (point.y > 0) {
      transform = (x, y) => Tuple2(board.size - y - 1, board.size - x - 1);
    } else if (point.y < 0) {
      transform = (x, y) => Tuple2(board.size - y - 1, x);
    } else if (point.x > 0) {
      transform = (x, y) => Tuple2(board.size - x - 1, y);
    } else if (point.x < 0) {
      transform = (x, y) => Tuple2(x, y);
    } else {
      return Tuple2(false, board);
    }

    var scoreDelta = 0;
    var hasModifiedAtLeastOnce = false;
    for (var y = 0; y < board.size; y++) {
      var lastX = 0;
      for (var x = 0; x < board.size; x++) {
        final point = transform(x, y);
        final chip = matrix[point.item1][point.item2];
        if (chip.score > 0) {
          // We should merge this chip with the one from the left
          // side of the screen.
          var hasModified = false;
          for (var i = lastX; i < x; i++) {
            final j = transform(i, y);
            final candidateChip = matrix[j.item1][j.item2];
            if (candidateChip.score == 0 || candidateChip.score == chip.score) {
              // merge these two
              final score = chip.score + candidateChip.score;
              matrix[j.item1][j.item2] = chip.upgrade(score);
              matrix[point.item1][point.item2] = candidateChip.upgrade(
                0,
                identity: candidateChip.identity + 1,
              );

              if (candidateChip.score == 0) {
                lastX = i;
              } else {
                scoreDelta += score;
                // protect the modified chips
                lastX = i + 1;
              }

              hasModified = true;
              hasModifiedAtLeastOnce = true;
              break;
            }
          }
          if (!hasModified) {
            lastX = x;
          }
        }
      }
    }

    if (!hasModifiedAtLeastOnce) {
      return Tuple2(false, board);
    }

    // Apply new chips positions
    final chips = List.of(board.chips, growable: false);
    for (var x = 0; x < board.size; x++) {
      for (var y = 0; y < board.size; y++) {
        final chip = matrix[x][y];
        if (chip != null) {
          chips[chip.number] = chip.move(Point(x, y));
        }
      }
    }

    var tmpBoard = Board(board.size, board.score + scoreDelta, chips);
    return Tuple2(true, spawn(tmpBoard));
  }

  @override
  Board spawn(Board board) {
    final slotPos = () {
      final freeChips = board.chips.where((chip) => chip.score <= 0).toList();
      final freeChipsPos = _random.nextInt(freeChips.length);
      return freeChips[freeChipsPos].number;
    }();

    final chipScore = _random.nextInt(10) == 0 ? 4 : 2;
    final chips = board.chips.toList();
    final chip = chips[slotPos];
    chips[slotPos] = chip.upgrade(chipScore, identity: chip.identity + 1);
    return Board(board.size, board.score, chips);
  }
}
