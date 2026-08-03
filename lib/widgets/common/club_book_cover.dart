import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text_styles.dart';

class ClubBookCover extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final double width;
  final double? height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final String? heroTag;
  final bool showShadow;
  final BoxFit fit;

  const ClubBookCover({
    super.key,
    required this.title,
    this.imageUrl,
    this.width = 120,
    this.height,
    this.borderRadius,
    this.onTap,
    this.heroTag,
    this.showShadow = true,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedHeight = height ?? width * 1.5;
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.lg);

    Widget cover = Container(
      width: width,
      height: resolvedHeight,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: showShadow ? AppShadows.card : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: _buildCoverContent(
          width: width,
          height: resolvedHeight,
          pixelRatio: MediaQuery.devicePixelRatioOf(context),
        ),
      ),
    );

    if (heroTag != null && heroTag!.trim().isNotEmpty) {
      cover = Hero(tag: heroTag!, child: cover);
    }

    if (onTap != null) {
      cover = Material(
        color: Colors.transparent,
        child: InkWell(borderRadius: radius, onTap: onTap, child: cover),
      );
    }

    return cover;
  }

  Widget _buildCoverContent({
    required double width,
    required double height,
    required double pixelRatio,
  }) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (hasImage) {
      return Image.network(
        imageUrl!,
        width: width,
        height: height,
        cacheWidth: (width * pixelRatio).round(),
        cacheHeight: (height * pixelRatio).round(),
        fit: fit,
        errorBuilder: (_, _, _) {
          return _placeholder();
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return Container(
            color: AppColors.surfaceSoft,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.surfaceSoft],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Align(
            alignment: Alignment.topRight,
            child: Icon(
              Icons.auto_stories_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),

          const Align(
            alignment: Alignment.bottomCenter,
            child: Icon(
              Icons.bookmark_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
