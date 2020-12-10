import 'package:fifteenpuzzle/data/chip.dart';
import 'package:flutter/material.dart' hide Chip;

class ChipWidget extends StatelessWidget {
  final Chip chip;

  final Color backgroundColor;

  final double opacity;

  final double fontSize;

  final double size;

  final bool showNumber;

  ChipWidget(
    this.chip,
    this.backgroundColor,
    this.opacity,
    this.fontSize, {
    @required this.size,
    this.showNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = size < 150;

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(isCompact ? 4.0 : 8.0)),
    );

    var color = Theme.of(context).cardColor;
    color = Color.alphaBlend(backgroundColor, color);

    return Opacity(
      opacity: this.opacity,
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 2.0 : 4.0),
        child: Material(
          shape: shape,
          color: color,
          elevation: 1,
          child: showNumber
              ? Center(
                  child: Text(
                    '${chip.score}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
