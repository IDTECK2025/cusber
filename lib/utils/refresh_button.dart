import 'package:flutter/material.dart';

Widget RefreshButton(bool isDesktop, bool isTablet, {VoidCallback? onTap}) {
  return InkWell(
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    overlayColor: MaterialStateProperty.all(Colors.transparent),
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isDesktop || isTablet ? 10 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.refresh, size: 16, color: Color(0xFF6B7280)),
          if (isDesktop || isTablet) SizedBox(width: 8),
          if (isDesktop || isTablet)
            Text(
              'Refresh',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    ),
  );
}
