import 'package:flutter/material.dart';

const kTextFieldDecoration = InputDecoration(
  hintText: 'Comment Text',
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.orangeAccent, width: 2.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.orangeAccent, width: 3.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
);
