import 'package:flutter/cupertino.dart';

class ResponsiveText extends StatelessWidget {
  final String text;
  final FontWeight? fontWeight;
  final Color? color;
  final double? mobile;
  final double? tablet;
  final double? desktop;

  // All Text widget fields
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  const ResponsiveText(
      this.text, {
        super.key,
        this.fontWeight,
        this.color,
        this.mobile,
        this.tablet,
        this.desktop,
        this.style,
        this.strutStyle,
        this.textAlign,
        this.textDirection,
        this.locale,
        this.softWrap,
        this.overflow,
        this.textScaleFactor,
        this.textScaler,
        this.maxLines,
        this.semanticsLabel,
        this.textWidthBasis,
        this.textHeightBehavior,
        this.selectionColor,
      });

  double _getFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 400 && mobile != null) {
      return mobile!;
    } else if (width >= 400 && width < 1000 && tablet != null) {
      return tablet!;
    } else if (width >= 1000 && desktop != null) {
      // 👉 use desktop first if available
      return desktop!;
    }

    // fallback to style.fontSize or default
    return style?.fontSize ?? 14;
  }


  @override
  Widget build(BuildContext context) {
    final fontSize = _getFontSize(context);

    return Text(
      text,
      style: style?.copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ) ??
          TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}
