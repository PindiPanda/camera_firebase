import 'package:flutter/material.dart';

class CircleButton extends StatelessWidget {
  final IconData iconData;
  final Color color = Colors.deepOrange;
  final double height = 50;
  final Function onPressed;

  CircleButton({this.iconData, @required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      height: height,
      shape: CircleBorder(),
      color: color,
      child: Icon(
        iconData,
      ),
      onPressed: onPressed,
    );
  }
}
