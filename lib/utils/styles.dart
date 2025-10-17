import 'package:flutter/material.dart';
import 'colors.dart';

ButtonStyle defaultButtonStyle({
  Color? backgroundColor = kSecondaryColor,
  double borderRadius = 4.0,
  Size minimumSize = const Size(100, 45),
}) {
  return ElevatedButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
    ),
    backgroundColor: backgroundColor,
    minimumSize: minimumSize,
);
}