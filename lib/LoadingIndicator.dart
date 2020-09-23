import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: .75,
      widthFactor: 1.0,
      alignment: Alignment.topCenter,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
        ),
      ),
    );
  }
}
