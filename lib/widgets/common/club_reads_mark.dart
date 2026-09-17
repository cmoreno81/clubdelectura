import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// El icono de ClubReads (bocadillo de conversación + lomo de libro),
/// dibujado como vector — mismo diseño que `assets/icon.png`, pero sin el
/// fondo cuadrado, para poder colocarlo sobre cualquier superficie morada
/// (splash, cabeceras...).
class ClubReadsMark extends StatelessWidget {
  const ClubReadsMark({super.key, this.size = 72, this.color = AppColors.surface});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ClubReadsMarkPainter(color: color)),
    );
  }
}

class _ClubReadsMarkPainter extends CustomPainter {
  _ClubReadsMarkPainter({required this.color});

  final Color color;

  /// El diseño está trazado en un lienzo lógico de 200×200.
  static const _logicalSize = 200.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _logicalSize;
    canvas.scale(scale, scale);

    final bubble = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTRB(46, 58, 154, 138),
          const Radius.circular(12),
        ),
      );
    final tail = Path()
      ..moveTo(92, 138)
      ..lineTo(70, 158)
      ..lineTo(70, 138)
      ..close();

    final mark = Path.combine(PathOperation.union, bubble, tail);

    // Sombra suave + degradado vertical a crema, para dar algo de
    // profundidad — mismo tratamiento que `assets/icon.png`.
    canvas.drawShadow(mark, AppColors.primaryDark, 6, false);

    final gradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, Color.lerp(color, AppColors.primary, 0.1)!],
      ).createShader(const Rect.fromLTWH(0, 0, _logicalSize, _logicalSize));

    canvas.drawPath(mark, gradient);

    // Lomo: la línea central que separa el bocadillo en dos "páginas".
    canvas.drawLine(
      const Offset(100, 58),
      const Offset(100, 138),
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ClubReadsMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
