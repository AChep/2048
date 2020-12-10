import 'package:meta/meta.dart';

@immutable
class Result {
  final int steps;
  final int time;
  final int size;
  final int score;
  final int highestOne;
  final bool isWin;
  final bool isSolved;

  Result({
    @required this.steps,
    @required this.time,
    @required this.size,
    @required this.score,
    @required this.highestOne,
    @required this.isWin,
    @required this.isSolved,
  });
}
