import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class GamerHeader extends StatelessWidget implements PreferredSizeWidget {
  final String username;
  final int level;
  final VoidCallback? onCreatePost;

  const GamerHeader({
    super.key,
    required this.username,
    required this.level,
    this.onCreatePost,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0A0A0B),
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0x22FFFFFF),
                  Color(0x2200FFFF),
                  Color(0x228000FF),
                ],
              ),
              border: Border.all(
                  color: Colors.cyanAccent.withOpacity(0.4), width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Center(
              child: ClipOval(
                child: SvgPicture.asset(
                  'assets/logo.svg',
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  colorFilter:
                      const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'GamerFlick',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: onCreatePost,
          icon: const Icon(Icons.add, color: Colors.white),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Row(
            children: [
              Text(
                username,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(width: 4),
              Text(
                'Level $level',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
