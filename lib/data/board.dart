import 'dart:collection';
import 'dart:math';

import 'package:twopowereleven/data/point.dart';
import 'package:twopowereleven/utils/serializable.dart';
import 'package:meta/meta.dart';

import 'chip.dart';

@immutable
class Board extends Serializable {
  /// Width and height of a board, for
  /// example 4x4.
  final int size;

  final int score;

  final List<Chip> chips;

  Board(this.size, this.score, this.chips);

  factory Board.createComplete(int size) =>
      Board.create(size, (n) => pow(2, n + 1));

  factory Board.createEmpty(int size) => Board.create(size, (n) => 0);

  factory Board.createLoose(int size) => Board.createComplete(size);

  factory Board.create(int size, int Function(int) factory) {
    final chips = List<Chip>.generate(size * size, (n) {
      final point = Point(n % size, n ~/ size);
      return Chip(n, 0, factory(n), point);
    });
    return Board(size, 0, chips);
  }

  int highestOne() {
    var score = 0;
    for (var chip in chips) {
      if (chip.score > score) score = chip.score;
    }
    return score;
  }

  /// Returns `true` if all of the [chips] are in their
  /// target positions.
  bool isSolved() {
    final set = LinkedHashSet();
    for (var chip in chips) {
      if (set.contains(chip.score)) return false;
      set.add(chip.score);
    }
    return true;
  }

  bool isEnded() {
    for (var chip in chips) {
      if (chip.score <= 0) return false;
    }

    List<List<Chip>> matrix = List.generate(size, (i) {
      return List.generate(size, (j) {
        return null;
      });
    });

    chips.forEach((chip) {
      matrix[chip.currentPoint.x][chip.currentPoint.y] = chip;
    });

    bool isTweenNeighbor(Chip chip, int x, int y) =>
        chip.score == _getOrNull(matrix, x, y)?.score;

    bool hasTweenNeighbors(int x, int y) {
      final chip = matrix[x][y];
      return isTweenNeighbor(chip, x + 1, y) ||
          isTweenNeighbor(chip, x - 1, y) ||
          isTweenNeighbor(chip, x, y + 1) ||
          isTweenNeighbor(chip, x, y - 1);
    }

    for (var x = 0; x < size; x++) {
      for (var y = 0; y < size; y++) {
        if (hasTweenNeighbors(x, y)) return false;
      }
    }

    return true;
  }

  Chip _getOrNull(List<List<Chip>> matrix, int x, int y) {
    if (x < 0 || x >= size || y < 0 || y >= size) return null;
    return matrix[x][y];
  }

  @override
  void serialize(SerializeOutput output) {
    output.writeInt(size);
    output.writeInt(score);

    for (final chip in chips) {
      output.writeSerializable(chip);
    }
  }
}

class BoardDeserializableFactory extends DeserializableHelper<Board> {
  const BoardDeserializableFactory() : super();

  @override
  Board deserialize(SerializeInput input) {
    final size = input.readInt();
    final score = input.readInt();
    if (size == null || score == null) {
      return null;
    }

    const chipFactory = ChipDeserializableFactory();

    final chips = List<Chip>();
    for (var i = 0; i < size * size; i++) {
      final chip = input.readDeserializable(chipFactory);
      if (chip == null) {
        return null;
      }

      chips.add(chip);
    }

    // TODO: Verify if the loaded data is valid
    return Board(size, score, chips);
  }
}
