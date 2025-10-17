import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final Color color;

  const Avatar({
    super.key,
    required this.name,
    this.size = 16,
    this.color = Colors.white,
  });

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFFBDAC67), // Light Gold
      const Color(0xFFFBBF24), // Amber Gold
      const Color(0xFFEAB308), // Classic Gold
      const Color(0xFFCA8A04), // Dark Gold
      const Color(0xFFB45309), // Bronze
      const Color(0xFF78350F), // Deep Brown/Antique
    ];
    return colors[name.hashCode % colors.length];
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) {
      return '?';
    }

    // Split by space and filter out empty strings
    final nameParts =
        name.trim().split(' ').where((part) => part.isNotEmpty).toList();

    if (nameParts.isEmpty) {
      return '?';
    }

    // Take first letter of first two words
    String initials = '';
    for (int i = 0; i < nameParts.length && i < 2; i++) {
      if (nameParts[i].isNotEmpty) {
        initials += nameParts[i][0];
      }
    }

    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size,
      backgroundColor: _getAvatarColor(name),
      child: Text(
        _getInitials(name),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.6,
        ),
      ),
    );
  }
}
