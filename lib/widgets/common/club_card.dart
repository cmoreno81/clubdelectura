import 'package:flutter/material.dart';

import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

class ClubCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool elevated;
  final double? width;

  const ClubCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.elevated = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final fondo =
        backgroundColor ?? theme.cardTheme.color ?? colorScheme.surface;

    final borde =
        borderColor ??
        theme.dividerTheme.color ??
        colorScheme.outline.withValues(alpha: 0.55);

    const pageRadius = BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(12),
      bottomRight: Radius.circular(24),
      bottomLeft: Radius.circular(16),
    );
    final contenido = CustomPaint(
      foregroundPainter: gradient == null ? _PageDetailsPainter(borde) : null,
      child: Container(
        width: width,
        margin: margin,
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: gradient == null ? fondo : null,
          gradient: gradient,
          borderRadius: pageRadius,
          border: Border.all(color: borde, width: 1),
          boxShadow: elevated ? AppShadows.card : null,
        ),
        child: child,
      ),
    );

    if (onTap == null) {
      return contenido;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: pageRadius, child: contenido),
    );
  }
}

class _PageDetailsPainter extends CustomPainter {
  const _PageDetailsPainter(this.borderColor);

  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 48 || size.height < 38) return;
    final marginPaint = Paint()
      ..color = const Color(0xFF603B73).withValues(alpha: .16)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      const Offset(12, 16),
      Offset(12, size.height - 16),
      marginPaint,
    );

    final foldPath = Path()
      ..moveTo(size.width - 17, 0)
      ..lineTo(size.width, 17)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(
      foldPath,
      Paint()..color = borderColor.withValues(alpha: .42),
    );
  }

  @override
  bool shouldRepaint(covariant _PageDetailsPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}
