import 'package:fifteenpuzzle/data/result.dart';
import 'package:fifteenpuzzle/links.dart';
import 'package:fifteenpuzzle/play_games.dart';
import 'package:fifteenpuzzle/widgets/game/format.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';

class GameVictoryDialog extends StatelessWidget {
  final Result result;

  final String Function(int) timeFormatter;

  GameVictoryDialog({
    @required this.result,
    this.timeFormatter: formatElapsedTime,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormatted = timeFormatter(result.time);
    final phrase = result.isSolved
        ? "solved"
        : result.isWin
        ? "successfully completed"
        : "tried to complete";
    final actions = <Widget>[
      new FlatButton(
        child: new Text("Share"),
        onPressed: () {
          Share.share("I have $phrase the Game of 2048's "
              "${result.size}x${result.size} mode in $timeFormatted, reaching "
              "as high as block ${result.highestOne} with "
              "${result.steps} steps / ${result.score} score! Check it out: $URL_REPOSITORY");
        },
      ),
      new FlatButton(
        child: new Text("Close"),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
    ];

    if (PlayGamesContainer.of(context).isSupported) {
      actions.insert(
        0,
        new FlatButton(
          child: new Text("Leaderboard"),
          onPressed: () {
            final playGames = PlayGamesContainer.of(context);
            playGames.showLeaderboard(
              key: PlayGames.getLeaderboardOfSize(result.size),
            );
          },
        ),
      );
    }

    return AlertDialog(
      title: Center(
        child: Text(
          result.isSolved
              ? "You are amazing!"
              : result.isWin
                  ? "Congratulations!"
                  : "Oh snap!",
          style: Theme.of(context).textTheme.headline6,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
              "You've $phrase the ${result.size}x${result.size} game, reaching as high as block ${result.highestOne}."),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Time:',
                    style: Theme.of(context).textTheme.caption,
                  ),
                  Text(
                    timeFormatted,
                    style: Theme.of(context).textTheme.headline5.copyWith(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Score:',
                    style: Theme.of(context).textTheme.caption,
                  ),
                  Text(
                    '${result.score}',
                    style: Theme.of(context).textTheme.headline5.copyWith(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Steps:',
                    style: Theme.of(context).textTheme.caption,
                  ),
                  Text(
                    '${result.steps}',
                    style: Theme.of(context).textTheme.headline5.copyWith(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: actions,
    );
  }
}
