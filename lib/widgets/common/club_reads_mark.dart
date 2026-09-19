import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// El icono de ClubReads (bocadillo de conversación + lomo de libro),
/// dibujado como vector — mismo diseño que `assets/icon.png`, pero sin el
/// fondo cuadrado, para poder colocarlo sobre cualquier superficie morada
/// (splash, cabeceras...).
///
/// Con [animate] (por defecto activado), las dos "páginas" se abren desde
/// el lomo central como las tapas de un libro, con un pequeño rebote al
/// asentarse — un gesto que tiene sentido para una app de lectura.
class ClubReadsMark extends StatefulWidget {
  const ClubReadsMark({
    super.key,
    this.size = 72,
    this.color = AppColors.surface,
    this.animate = true,
  });

  final double size;
  final Color color;
  final bool animate;

  @override
  State<ClubReadsMark> createState() => _ClubReadsMarkState();
}

class _ClubReadsMarkState extends State<ClubReadsMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    // easeOutBack hace que cada mitad se pase un poco del centro antes de
    // asentarse — el "encaje" que pedía, en vez de un deslizamiento seco.
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) => CustomPaint(
          painter: _ClubReadsMarkPainter(
            color: widget.color,
            progress: _progress.value,
          ),
        ),
      ),
    );
  }
}

class _ClubReadsMarkPainter extends CustomPainter {
  _ClubReadsMarkPainter({required this.color, required this.progress});

  final Color color;

  /// 0 = las dos "tapas" están cerradas sobre el lomo (de canto, casi
  /// invisibles). 1 = abiertas del todo, en su posición final. Con la
  /// curva easeOutBack puede pasar brevemente de 1 (el rebote al asentarse).
  final double progress;

  /// El diseño está trazado en un lienzo lógico de 200×200.
  static const _logicalSize = 200.0;

  /// Línea del lomo: eje sobre el que giran ambas mitades.
  static const _hingeX = 100.0;

  /// Ángulo máximo de cierre (no llega a π/2 para que la sombra no
  /// degenere sobre un trazo de ancho cero).
  static const _maxAngle = math.pi / 2.2;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _logicalSize;
    canvas.scale(scale, scale);

    // Mitad izquierda: la "página" con el piquito de bocadillo.
    final leftHalf = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          const Rect.fromLTRB(46, 58, 100, 138),
          topLeft: const Radius.circular(12),
          bottomLeft: const Radius.circular(12),
        ),
      );
    final tail = Path()
      ..moveTo(92, 138)
      ..lineTo(70, 158)
      ..lineTo(70, 138)
      ..close();
    final left = Path.combine(PathOperation.union, leftHalf, tail);

    // Mitad derecha: la otra "página".
    final right = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          const Rect.fromLTRB(100, 58, 154, 138),
          topRight: const Radius.circular(12),
          bottomRight: const Radius.circular(12),
        ),
      );

    final gradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, Color.lerp(color, AppColors.primary, 0.1)!],
      ).createShader(const Rect.fromLTWH(0, 0, _logicalSize, _logicalSize));

    // (1 - progress) va de 1 (cerrado) a 0 (abierto); con el rebote de
    // easeOutBack puede colarse un pelín por debajo de 0, así que la tapa
    // se pasa levemente de su sitio antes de asentarse.
    final t = (1 - progress).clamp(-0.25, 1.0);
    final angle = _maxAngle * t;

    void drawHalf(Path path, double rotation) {
      canvas.save();
      canvas.translate(_hingeX, 0);
      final matrix = Matrix4.identity()
        ..setEntry(3, 2, 0.0025)
        ..rotateY(rotation);
      canvas.transform(matrix.storage);
      canvas.translate(-_hingeX, 0);
      // Sombra suave + degradado vertical a crema, para dar algo de
      // profundidad — mismo tratamiento que `assets/icon.png`.
      canvas.drawShadow(path, AppColors.primaryDark, 6, false);
      canvas.drawPath(path, gradient);
      canvas.restore();
    }

    drawHalf(left, angle);
    drawHalf(right, -angle);

    // Lomo: la línea central que separa el bocadillo en dos "páginas".
    // Con las tapas cerradas queda tapado por ellas; solo se lee según se
    // van abriendo.
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
      oldDelegate.color != color || oldDelegate.progress != progress;
}
