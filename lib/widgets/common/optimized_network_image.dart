import 'dart:convert';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Imagen pública de red dimensionada para evitar decodificar originales
/// innecesariamente grandes. No debe usarse con recursos autenticados.
class OptimizedNetworkImage extends StatelessWidget {
  const OptimizedNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.fallback,
    this.placeholder,
    this.highResolution = false,
  });

  final String? url;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? fallback;
  final Widget? placeholder;

  /// Conserva la URL y evita limitar la decodificación para vistas ampliables
  /// o imágenes destinadas a exportación.
  final bool highResolution;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = url?.trim() ?? '';
    if (trimmedUrl.isEmpty) return _fallback();

    // Data URIs (e.g. data:image/jpeg;base64,...) — no son URLs de red.
    // Las decodificamos directamente con Image.memory.
    if (trimmedUrl.startsWith('data:image/')) {
      final commaIdx = trimmedUrl.indexOf(',');
      if (commaIdx != -1) {
        try {
          final bytes = base64Decode(trimmedUrl.substring(commaIdx + 1));
          return Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => _fallback(),
          );
        } catch (_) {
          return _fallback();
        }
      }
      return _fallback();
    }

    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = highResolution
        ? null
        : cacheDimension(width, pixelRatio: pixelRatio);
    final cacheHeight = highResolution
        ? null
        : cacheDimension(height, pixelRatio: pixelRatio);
    final requestedUrl = highResolution
        ? trimmedUrl
        : cloudinaryThumbnailUrl(
            trimmedUrl,
            pixelWidth: cacheWidth,
            pixelHeight: cacheHeight,
          );

    return Image.network(
      requestedUrl,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : _placeholder(),
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _placeholder() =>
      placeholder ??
      const ColoredBox(
        color: AppColors.surfaceSoft,
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 22,
            color: AppColors.textMuted,
          ),
        ),
      );

  Widget _fallback() =>
      fallback ??
      const ColoredBox(
        color: AppColors.surfaceSoft,
        child: Center(child: Icon(Icons.image_not_supported_outlined)),
      );

  @visibleForTesting
  static int? cacheDimension(double logicalSize, {required double pixelRatio}) {
    if (!logicalSize.isFinite || logicalSize <= 0) return null;
    if (!pixelRatio.isFinite || pixelRatio <= 0) return null;
    return (logicalSize * pixelRatio).ceil().clamp(1, 4096);
  }

  @visibleForTesting
  static String cloudinaryThumbnailUrl(
    String source, {
    int? pixelWidth,
    int? pixelHeight,
  }) {
    final uri = Uri.tryParse(source);
    if (uri == null ||
        uri.scheme != 'https' ||
        !uri.host.toLowerCase().endsWith('cloudinary.com') ||
        !uri.path.contains('/upload/')) {
      return source;
    }

    final transformations = <String>['f_auto', 'q_auto'];
    if (pixelWidth != null) transformations.add('w_$pixelWidth');
    if (pixelHeight != null) transformations.add('h_$pixelHeight');
    transformations.add('c_fill');
    final path = uri.path.replaceFirst(
      '/upload/',
      '/upload/${transformations.join(',')}/',
    );
    return uri.replace(path: path).toString();
  }
}
