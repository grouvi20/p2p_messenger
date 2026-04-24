import 'package:flutter/material.dart';
import 'package:p2p_messenger/core/theme/app_theme.dart';

class AvatarWidget extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool showOnline;
  final bool isOnline;

  const AvatarWidget({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
    this.showOnline = false,
    this.isOnline = false,
  });

  Color _getColor(String name) {
    final colors = [
      const Color(0xFF5B8DEF),
      const Color(0xFF7C4DFF),
      const Color(0xFF00BFA5),
      const Color(0xFFFF6B6B),
      const Color(0xFFFFB74D),
      const Color(0xFF4DB6AC),
      const Color(0xFFBA68C8),
      const Color(0xFF4FC3F7),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getColor(name),
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null
              ? Center(
                  child: Text(
                    _getInitials(name),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
        if (showOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline
                    ? AppTheme.onlineColor
                    : Colors.grey,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
