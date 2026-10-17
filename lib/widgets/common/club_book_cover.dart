import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import 'optimized_network_image.dart';
import 'portada_sin_imagen.dart';

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
  final bool highResolution;

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
    this.highResolution = false,
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
        child: _buildCoverContent(width: width, height: resolvedHeight),
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

  Widget _buildCoverContent({required double width, required double height}) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (hasImage) {
      return OptimizedNetworkImage(
        url: imageUrl,
        width: width,
        height: height,
        fit: fit,
        highResolution: highResolution,
        fallback: _placeholder(),
        placeholder: Container(
          color: AppColors.surfaceSoft,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_outlined,
            size: 28,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    return _placeholder();
  }

  Widget _placeholder() => PortadaSinImagen(title: title);
}
