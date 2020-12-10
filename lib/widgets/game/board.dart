import 'dart:math';

import 'package:fifteenpuzzle/data/board.dart';
import 'package:fifteenpuzzle/data/chip.dart';
import 'package:fifteenpuzzle/widgets/game/chip.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter/widgets.dart';
import 'package:swipe_gesture_recognizer/swipe_gesture_recognizer.dart';

class BoardWidget extends StatefulWidget {
  final Board board;

  final double size;

  final bool showNumbers;

  final Function(Point<int>) onSwipe;

  final bool isSpeedRunModeEnabled;

  BoardWidget({
    Key key,
    @required this.board,
    @required this.size,
    this.showNumbers = true,
    this.isSpeedRunModeEnabled = false,
    this.onSwipe,
  }) : super(key: key);

  @override
  _BoardWidgetState createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget>
    with TickerProviderStateMixin {
  static const _ANIM_COLOR_BACKGROUND_TAG = "color_background";
  static const _ANIM_MOVE_TAG = "move";
  static const _ANIM_SCALE_TAG = "scale";
  static const _ANIM_OPACITY_TAG = "opacity";

  static const num _ANIM_DURATION_MULTIPLIER_NORMAL = 1.0;
  static const num _ANIM_DURATION_MULTIPLIER_SPEED_RUN = 0.6;

  static const int _ANIM_DURATION_BLINK_HALF = 200;
  static const int _ANIM_DURATION_MOVE = 200;
  static const int _ANIM_DURATION_COLOR_BACKGROUND = 200;

  List<_Chip> chips;

  bool _isSpeedRunModeEnabled;

  /// Applies normal/speed run duration modifiers */
  int _applyAnimationMultiplier(int duration) {
    if (_isSpeedRunModeEnabled) {
      return (duration.toDouble() * _ANIM_DURATION_MULTIPLIER_SPEED_RUN)
          .toInt();
    } else
      return (duration.toDouble() * _ANIM_DURATION_MULTIPLIER_NORMAL).toInt();
  }

  @override
  void initState() {
    super.initState();
    _isSpeedRunModeEnabled = widget.isSpeedRunModeEnabled;
    _performSetBoard(
      newBoard: widget.board,
    );
  }

  @override
  void didUpdateWidget(BoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      _isSpeedRunModeEnabled = widget.isSpeedRunModeEnabled;
    });
    _performSetBoard(
      newBoard: widget.board,
      oldBoard: oldWidget.board,
    );
  }

  void _performSetPrevBoard() =>
      _performSetBoard(newBoard: widget.board, oldBoard: widget.board);

  void _performSetBoard({final Board newBoard, final Board oldBoard}) {
    if (newBoard == null) {
      setState(() {
        // Dispose current animations. This is not necessary, but good
        // to do.
        chips?.forEach((chip) {
          chip.animations.values.forEach((controller) => controller.dispose());
        });

        chips = null;
      });
      return;
    }

    final board = newBoard;
    if (chips == null || board.chips.length != oldBoard.chips.length) {
      // The size of the board has been changed...
      // rebuild everything!
      setState(() {
        void _changeTo(int length) {
          for (var i = 0; i < length; i++) {
            final chip = board.chips[i];
            final extra = chips[i];

            final wasCurrentPoint = extra.currentPoint;
            extra.currentPoint = chip.currentPoint;
            _onChipChangePosition(chip, wasCurrentPoint, chip.currentPoint);

            // Change the color of the chip.
            final color = _getColorFor(score: chip.score);
            _startColorBackgroundAnimation(
              chip,
              from: extra.backgroundColor,
              to: color,
            );

            final opacity = _getOpacityFor(score: chip.score);
            _startOpacityAnimation(chip, from: extra.opacity, to: opacity);
          }
        }

        if (chips != null) {
          if (chips.length > board.chips.length) {
            // Remove a few chips with a smooth animation.
            chips = chips.sublist(0, board.chips.length);
            _changeTo(board.chips.length);
            return;
          } else {
            // chips length < new chips length
            final delta = board.chips.length - chips.length;
            final newChips = List.generate(delta, (index) {
              final chip = board.chips[chips.length + index];
              final x = chip.currentPoint.x / board.size;
              final y = chip.currentPoint.y / board.size;
              final scale = 0.0; // will be scaled by the animation
              final opacity = _getOpacityFor(score: chip.score);
              final color = _getColorFor(score: chip.score);
              return _Chip(
                chip.identity,
                x,
                y,
                chip.currentPoint,
                scale: scale,
                opacity: opacity,
                backgroundColor: color,
              );
            });

            chips = chips + newChips;

            for (var i = oldBoard.chips.length; i < board.chips.length; i++) {
              _startAppearAnimation(board.chips[i]);
            }

            _changeTo(oldBoard.chips.length);
            return;
          }
        }

        // Create our extras
        chips = board.chips.map((chip) {
          final x = chip.currentPoint.x / board.size;
          final y = chip.currentPoint.y / board.size;
          final opacity = _getOpacityFor(score: chip.score);
          final color = _getColorFor(score: chip.score);
          return _Chip(
            chip.identity,
            x,
            y,
            chip.currentPoint,
            opacity: opacity,
            backgroundColor: color,
          );
        }).toList(growable: false);
      });
      return;
    }

    for (var chip in board.chips) {
      final extra = chips[chip.number];
      if (extra.currentPoint != chip.currentPoint) {
        // The chip has been moved somewhere...
        // animate the change!
        final wasIdentity = extra.identity;
        final wasCurrentPoint = extra.currentPoint;
        extra.currentPoint = chip.currentPoint;
        final preferBlink = wasIdentity != chip.identity || chip.score == 0;
        _onChipChangePosition(
          chip,
          wasCurrentPoint,
          chip.currentPoint,
          preferBlink: preferBlink,
        );
      }

      extra.identity = chip.identity;

      // Animate the color change!
      if (chip.score > 0) {
        final color = _getColorFor(score: chip.score);
        final wasIdentity = extra.identity;
        if (wasIdentity != chip.identity) {
          if (extra.backgroundColor != color)
            setState(() {
              extra.backgroundColor = color;
            });
        } else {
          _startColorBackgroundAnimation(chip,
              from: extra.backgroundColor, to: color);
        }
      }
      final opacity = _getOpacityFor(score: chip.score);
      _startOpacityAnimation(chip, from: extra.opacity, to: opacity);
    }
  }

  /// Returns the color corresponding to the
  /// chip's score.
  Color _getColorFor({@required int score}) {
    final values = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096];
    final index = values.indexWhere((v) => v >= score);

    if (index == -1) {
      return Colors.black12;
    }

    final hue = 360.0 * sqrt(index.toDouble() / values.length.toDouble());
    return HSLColor.fromAHSL(1, hue, 0.7, 0.5).toColor();
  }

  double _getOpacityFor({@required int score}) {
    if (score <= 0) {
      return 0.0;
    } else {
      return 1.0;
    }
  }

  // ---- Change the size of the board ----

  void _startAppearAnimation(Chip chip) {
    final duration = Duration(
        milliseconds: _applyAnimationMultiplier(_ANIM_DURATION_BLINK_HALF));
    final curve = Curves.easeIn;

    final controller = AnimationController(
      duration: duration,
      vsync: this,
    );

    final target = chips[chip.number];
    final animation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );
    animation.addListener(() {
      final scale = cos(animation.value * 2.0 * pi) / 2.0 + 0.5;
      setState(() {
        target.scale = scale;
      });
    });

    _addAnimation(chip, _ANIM_SCALE_TAG, controller);
    controller
        .forward()
        .then<void>((_) => _disposeAnimation(chip, _ANIM_SCALE_TAG));
  }

  void _startColorBackgroundAnimation(Chip chip, {Color from, Color to}) {
    final duration = Duration(
        milliseconds:
            _applyAnimationMultiplier(_ANIM_DURATION_COLOR_BACKGROUND));
    final curve = Curves.easeIn;

    final controller = AnimationController(
      duration: duration,
      vsync: this,
    );

    final target = chips[chip.number];
    final animation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );
    animation.addListener(() {
      final scale = cos(animation.value * 2.0 * pi) / 2.0 + 0.5;
      final color = Color.alphaBlend(from.withOpacity(1.0 - scale), to);
      setState(() {
        target.backgroundColor = color;
      });
    });

    _addAnimation(chip, _ANIM_COLOR_BACKGROUND_TAG, controller);
    controller
        .forward()
        .then<void>((_) => _disposeAnimation(chip, _ANIM_COLOR_BACKGROUND_TAG));
  }

  void _startOpacityAnimation(Chip chip, {double from, double to}) {
    final duration = Duration(
        milliseconds:
            _applyAnimationMultiplier(_ANIM_DURATION_COLOR_BACKGROUND));
    final curve = Curves.easeIn;

    final controller = AnimationController(
      duration: duration,
      vsync: this,
    );

    final target = chips[chip.number];
    final animation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );
    animation.addListener(() {
      final opacity = from * (1.0 - animation.value) + to * animation.value;
      setState(() {
        target.opacity = opacity;
      });
    });

    _addAnimation(chip, _ANIM_OPACITY_TAG, controller);
    controller
        .forward()
        .then<void>((_) => _disposeAnimation(chip, _ANIM_OPACITY_TAG));
  }

  // ---- Shuffle the chips ----

  void _onChipChangePosition(
    Chip chip,
    Point<int> from,
    Point<int> to, {
    bool preferBlink,
  }) {
    if (from.x != to.x && from.y != to.y || preferBlink) {
      // Chip can not be physically moved this way, play
      // the blink animation along with move animation.
      _startBlinkAnimation(chip, to);
    } else {
      _startMoveAnimation(chip, to);
    }
  }

  void _startMoveAnimation(Chip chip, Point<int> point) {
    final controller = AnimationController(
      duration: Duration(
          milliseconds: _applyAnimationMultiplier(_ANIM_DURATION_MOVE)),
      vsync: this,
    );

    final target = chips[chip.number];
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutQuad,
    );

    final board = widget.board;
    final oldX = target.x * board.size;
    final oldY = target.y * board.size;
    animation.addListener(() {
      // Calculate current point
      // of the chip.
      final x = (oldX * (1.0 - animation.value) + point.x * animation.value) /
          board.size;
      final y = (oldY * (1.0 - animation.value) + point.y * animation.value) /
          board.size;

      setState(() {
        target.x = x;
        target.y = y;
      });
    });

    // Start and dispose the animation
    // after its finish.
    _addAnimation(chip, _ANIM_MOVE_TAG, controller);
    controller
        .forward()
        .then<void>((_) => _disposeAnimation(chip, _ANIM_MOVE_TAG));
  }

  void _startBlinkAnimation(Chip chip, Point<int> point) {
    final duration = Duration(
        milliseconds: _applyAnimationMultiplier(_ANIM_DURATION_BLINK_HALF) * 2);
    final curve = Curves.easeInOut;

    void _startScaleAnimation(Chip chip, Point<int> point) {
      final controller = AnimationController(
        duration: duration,
        vsync: this,
      );

      final target = chips[chip.number];
      final animation = CurvedAnimation(
        parent: controller,
        curve: curve,
      );
      animation.addListener(() {
        final scale = cos(animation.value * 2.0 * pi) / 2.0 + 0.5;
        setState(() {
          target.scale = scale;
        });
      });

      _addAnimation(chip, _ANIM_SCALE_TAG, controller);
      controller
          .forward()
          .then<void>((_) => _disposeAnimation(chip, _ANIM_SCALE_TAG));
    }

    void _startMoveAnimation(Chip chip, Point<int> point) {
      final controller = AnimationController(
        duration: duration,
        vsync: this,
      );

      final target = chips[chip.number];
      final animation = CurvedAnimation(
        parent: controller,
        curve: curve,
      );

      final board = widget.board;
      var wasHalfwayOrMore = false;
      animation.addListener(() {
        final isHalfwayOrMore = animation.value >= 0.5;
        if (isHalfwayOrMore != wasHalfwayOrMore) {
          wasHalfwayOrMore = isHalfwayOrMore;

          final x = point.x.toDouble() / board.size;
          final y = point.y.toDouble() / board.size;
          setState(() {
            target.x = x;
            target.y = y;
          });
        }
      });

      _addAnimation(chip, _ANIM_MOVE_TAG, controller);
      controller
          .forward()
          .then<void>((_) => _disposeAnimation(chip, _ANIM_MOVE_TAG));
    }

    _startScaleAnimation(chip, point);
    _startMoveAnimation(chip, point);
  }

  void _addAnimation(
    Chip chip,
    String tag,
    AnimationController controller,
  ) {
    final map = chips[chip.number].animations;

    // Replace previous animation.
    map[tag]?.dispose();
    map[tag] = controller;
  }

  void _disposeAnimation(
    Chip chip,
    String tag,
  ) {
    final map = chips[chip.number].animations;
    map.remove(tag)?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.board;
    if (board == null || widget.board.chips.length == 0) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: Text('Empty board'),
        ),
      );
    }
    final chips = board.chips.map(_buildChipWidget).toList();
    final boardStack = Stack(children: chips);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: widget.onSwipe != null
          ? SwipeGestureRecognizer(
              child: boardStack,
              onSwipeLeft: () {
                widget.onSwipe(Point(-1, 0));
              },
              onSwipeRight: () {
                widget.onSwipe(Point(1, 0));
              },
              onSwipeUp: () {
                widget.onSwipe(Point(0, -1));
              },
              onSwipeDown: () {
                widget.onSwipe(Point(0, 1));
              },
            )
          : null,
    );
  }

  Widget _buildChipWidget(Chip chip) {
    final board = widget.board;
    final extra = chips[chip.number];

    // Calculate the colors.
    final backgroundColor = extra.backgroundColor.withOpacity(1);

    final chipSize = widget.size / board.size;
    return Positioned(
      width: chipSize,
      height: chipSize,
      left: extra.x * widget.size,
      top: extra.y * widget.size,
      child: Transform.scale(
        scale: extra.scale,
        child: ChipWidget(
          chip,
          backgroundColor,
          extra.opacity,
          chipSize / 3,
          showNumber: widget.showNumbers && chip.score > 0,
          size: widget.size,
        ),
      ),
    );
  }
}

class _Chip {
  int identity;

  double x = 0;
  double y = 0;

  /// Current X and Y scale of the chip, used for a
  /// blink animation.
  double scale = 1;

  double opacity = 1;

  Color backgroundColor = Colors.white.withOpacity(0.0);

  Map<String, AnimationController> animations = Map();

  Point<int> currentPoint;

  _Chip(
    this.identity,
    this.x,
    this.y,
    this.currentPoint, {
    this.opacity: 1,
    this.scale: 1,
    this.backgroundColor,
  });
}
