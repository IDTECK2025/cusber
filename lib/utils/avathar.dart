import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final Color color;

  const Avatar({
    Key? key,
    required this.name,
    this.size = 16,
    this.color = Colors.white
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size,
      backgroundColor: _getAvatarColor(name),
      child: Text(
        name.isNotEmpty
            ? name.split(' ').map((n) => n[0]).take(2).join().toUpperCase()
            : '?',
        style: TextStyle(
          color: color ,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.6,
        ),
      ),
    );
  }
}
