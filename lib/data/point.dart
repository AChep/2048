import 'dart:math';

import 'package:fifteenpuzzle/utils/serializable.dart';

class PointSerializableWrapper extends Point<int> implements Serializable {
  PointSerializableWrapper(Point<int> point) : super(point.x, point.y);

  @override
  void serialize(SerializeOutput output) {
    assert(x != null);
    assert(y != null);
    output.writeInt(x);
    output.writeInt(y);
  }
}

class PointDeserializableFactory extends DeserializableHelper<Point<int>> {
  const PointDeserializableFactory() : super();

  @override
  Point<int> deserialize(SerializeInput input) {
    final x = input.readInt();
    final y = input.readInt();
    assert(x != null);
    assert(y != null);
    return Point(x, y);
  }
}
