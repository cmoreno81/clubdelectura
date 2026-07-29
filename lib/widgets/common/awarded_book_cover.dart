import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import 'club_book_cover.dart';

class AwardedBookCover extends StatelessWidget {
  final String title;
  final String imageUrl;
  final int position;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const AwardedBookCover({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.position,
    required this.width,
    required this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (position) {
      1 => const Color(0xFFE4B63F),
      2 => const Color(0xFF9AA3AF),
      3 => const Color(0xFFB77948),
      _ => const Color(0xFF7146A0),
    };
    final icon = switch (position) {
      1 => Icons.emoji_events_rounded,
      2 => Icons.workspace_premium_rounded,
      3 => Icons.workspace_premium_outlined,
      _ => Icons.star_rounded,
    };

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClubBookCover(
              title: title,
              imageUrl: imageUrl,
              width: width,
              height: height,
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: onTap,
            ),
          ),
          Positioned(
            left: -7,
            top: -7,
            child: Container(
              width: position == 1 ? 36 : 31,
              height: position == 1 ? 36 : 31,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: .3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: position == 1 ? 20 : 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
