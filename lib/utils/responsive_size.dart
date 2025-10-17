import 'package:flutter/material.dart';

class ResponsiveSize {
  final double? mobile;
  final double? tablet;
  final double? desktop;

  const ResponsiveSize({this.mobile, this.tablet, this.desktop});

  double of(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    if (width >= 1000) {
      return desktop ?? tablet ?? mobile ?? 14;
    } else if (width >= 400) {
      return tablet ?? mobile ?? 14;
    } else {
      return mobile ?? 14;
    }
  }
}
