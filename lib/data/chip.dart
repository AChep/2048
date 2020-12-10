import 'dart:math';

import 'package:fifteenpuzzle/utils/serializable.dart';
import 'package:meta/meta.dart';

import 'point.dart';

@immutable
class Chip implements Serializable {
  /// Unique identifier of a chip, starts
  /// from a zero.
  final int number;

  final int identity;

  final int score;

  final Point<int> currentPoint;

  const Chip(
    this.number,
    this.identity,
    this.score,
    this.currentPoint,
  );

  Chip move(Point<int> point) => Chip(number, identity, score, point);

  Chip upgrade(int score, {int identity}) => Chip(
        number,
        identity ?? this.identity,
        score,
        currentPoint,
      );

  @override
  void serialize(SerializeOutput output) {
    output.writeInt(number);
    output.writeInt(identity);
    output.writeInt(score);
    output.writeSerializable(PointSerializableWrapper(currentPoint));
  }
}

class ChipDeserializableFactory extends DeserializableHelper<Chip> {
  const ChipDeserializableFactory() : super();

  @override
  Chip deserialize(SerializeInput input) {
    final pd = PointDeserializableFactory();

    final number = input.readInt();
    final identity = input.readInt();
    final score = input.readInt();
    final point = input.readDeserializable(pd);
    return Chip(number, identity, score, point);
  }
}
