import 'dart:convert';
import 'dart:developer';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:fifteenpuzzle/data/board.dart';
import 'package:fifteenpuzzle/data/result.dart';
import 'package:fifteenpuzzle/domain/game.dart';
import 'package:fifteenpuzzle/utils/serializable.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GamePresenterWidget extends StatefulWidget {
  static const SUPPORTED_SIZES = [3, 4, 5];

  final Widget child;

  final Function(Result) onSolve;

  GamePresenterWidget({@required this.child, this.onSolve});

  static GamePresenterWidgetState of(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_InheritedStateContainer)
            as _InheritedStateContainer)
        .data;
  }

  @override
  GamePresenterWidgetState createState() => GamePresenterWidgetState();
}

class GamePresenterWidgetState extends State<GamePresenterWidget>
    with WidgetsBindingObserver {
  static const TIME_STOPPED = 0;

  static final _SALSA_KEY = encrypt.Key.fromUtf8('3531662080279914');
  static final _SALSA_IV = encrypt.IV.fromUtf8('84bgee3v');

  static const _KEY_STATE = 'state';

  /// Encrypter to protected saved states of the game and
  /// make hacking a lil bit harder.
  final _encrypter = encrypt.Encrypter(encrypt.Salsa20(_SALSA_KEY));

  final Game game = Game.instance;

  Board board;

  int get score => board?.score ?? 0;

  int steps;

  int time;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    board = null;
    steps = null;
    time = TIME_STOPPED;

    _loadState();
  }

  void _loadState() async {
    dynamic jsonMap;
    try {
      final prefs = await SharedPreferences.getInstance();

      final encrypted =
          encrypt.Encrypted.fromBase64(prefs.getString(_KEY_STATE) ?? '');
      final plainText = _encrypter.decrypt(encrypted, iv: _SALSA_IV);

      jsonMap = json.decode(plainText);
    } catch (FormatException) {
      jsonMap = Map<String, dynamic>();
    }

    int elapsedTime;
    int time;
    int steps;
    Board board;

    try {
      final deserializer = MapSerializeInput(map: jsonMap);
      const boardFactory = BoardDeserializableFactory();
      elapsedTime = deserializer.readInt();
      time = deserializer.readInt();
      steps = deserializer.readInt();
      board = deserializer.readDeserializable(boardFactory);
    } catch (Exception) {}

    final now = DateTime.now().millisecondsSinceEpoch;
    if ( // validate time
        time == null ||
            time < 0 ||
            time > now ||
            time > 0 && elapsedTime > now - time ||
            // validate steps
            steps == null ||
            steps < 0 ||
            // validate board
            board == null) {
      time = TIME_STOPPED;
      steps = 0;
      // Initialize empty board.
      const size = 4;
      board = _createShowcaseBoard(size);
    }

    setState(() {
      this.time = time;
      this.steps = steps;
      this.board = board;
    });
  }

  Board _createShowcaseBoard(int size) => Board.createLoose(size);

  Board _createBoard(int size) => game.spawnMany(Board.createEmpty(size), 2);

  void playStop() {
    if (isPlaying()) {
      stop();
    } else {
      play();
    }
  }

  void play() {
    assert(board != null);

    final now = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      time = now;
      steps = 0;
      board = _createBoard(board.size);
    });
  }

  void stop() {
    setState(() {
      time = TIME_STOPPED;
      steps = 0;
    });
  }

  bool isPlaying() => time != TIME_STOPPED;

  void resize(int size) {
    setState(() {
      time = TIME_STOPPED;
      steps = 0;
      board = _createShowcaseBoard(size);
    });
  }

  void swipe({@required Point<int> point}) {
    assert(board != null);
    assert(point != null);

    setState(() {
      final result = game.swipe(board, point: point);
      if (!result.item1) {
        // hasn't changed
        return;
      }
      board = result.item2;

      if (isPlaying()) {
        // Increment the amount of steps.
        steps = steps + 1;

        // Stop if a user has solved the
        // board.
        if (board.isEnded()) {
          final highestOne = board.highestOne();
          final isSolved = board.isSolved();
          final isWin = highestOne >= 128 * pow(2, board.size);
          final now = DateTime.now().millisecondsSinceEpoch;
          final result = Result(
            steps: steps,
            time: now - time,
            size: board.size,
            score: board.score,
            highestOne: highestOne,
            isSolved: isSolved,
            isWin: isWin,
          );

          widget.onSolve?.call(result);

          stop();
        }
      }
    });
  }

  /// Resets the board, keeping the `isPlaying` state
  /// the same.
  void reset() {
    setState(() {
      int timeFuture;
      if (isPlaying()) {
        final now = DateTime.now().millisecondsSinceEpoch;
        timeFuture = now;
      } else {
        timeFuture = TIME_STOPPED;
      }

      var boardFuture;
      if (isPlaying()) {
        boardFuture = _createBoard(board.size);
      } else {
        boardFuture = _createBoard(board.size);
      }

      time = timeFuture;
      steps = 0;
      board = boardFuture;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        try {
          _saveState();
        } on Exception {}
        break;
      default:
        break;
    }
  }

  void _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final serializer = MapSerializeOutput();

    if (board == null) {
      // Clear the current state, loading this will recreate
      // the board.
      prefs.setString(_KEY_STATE, null);
      return;
    }

    // Write the delta of time, so user can not close the app, change
    // time and go back so easily.
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedTime = now - time;

    serializer.writeInt(elapsedTime);
    serializer.writeInt(time);
    serializer.writeInt(steps);
    serializer.writeSerializable(board);

    final plainText = serializer.toJsonString();
    final encryptedText = _encrypter.encrypt(plainText, iv: _SALSA_IV).base64;
    prefs.setString(_KEY_STATE, encryptedText);
  }

  @override
  Widget build(BuildContext context) {
    return new _InheritedStateContainer(
      data: this,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class _InheritedStateContainer extends InheritedWidget {
  final GamePresenterWidgetState data;

  _InheritedStateContainer({
    Key key,
    @required this.data,
    @required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedStateContainer old) => true;
}
