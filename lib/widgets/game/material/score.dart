import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Widget shows the current score of
/// a game.
class GameScoreWidget extends StatelessWidget {
  final int score;

  GameScoreWidget({@required this.score});

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(4.0)),
    );
    return Material(
      shape: shape,
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.0),
        child: Text(
          '$score',
          style: Theme.of(context).textTheme.headline6.copyWith(
                fontSize: 42.0,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
