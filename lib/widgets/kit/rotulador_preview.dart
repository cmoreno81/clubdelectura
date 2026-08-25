import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Mildliner-style dual-tip marker — el subrayador icónico de BookTok.
///
/// En horizontal: punta plana (chisel) a la izquierda, tapa redonda a la
/// derecha, ventana blanca central (donde en el producto real va el logotipo).
/// En vertical (por defecto): el mismo marcador girado 90°.
class RotuladorPreview extends StatelessWidget {
  final Color color;
  final bool vertical;
  final double length;
  final double thickness;

  const RotuladorPreview({
    super.key,
    required this.color,
    this.vertical = true,
    this.length = 92,
    this.thickness = 28,
  });

  @override
  Widget build(BuildContext context) {
    // Siempre renderizamos horizontal; si es vertical lo rotamos.
    final marker = SizedBox(
      width: vertical ? thickness : length,
      height: vertical ? length : thickness,
      child: CustomPaint(
        size: Size(vertical ? thickness : length, vertical ? length : thickness),
        painter: _MildlinerPainter(color: color, vertical: vertical),
      ),
    );

    return marker;
  }
}

class _MildlinerPainter extends CustomPainter {
  final Color color;
  final bool vertical;

  const _MildlinerPainter({required this.color, required this.vertical});

  @override
  void paint(Canvas canvas, Size size) {
    if (vertical) {
      // Rotar 90° en sentido antihorario para dibujar el mismo marcador
      canvas.save();
      canvas.translate(0, size.height);
      canvas.rotate(-math.pi / 2);
      _paintHorizontal(canvas, Size(size.height, size.width));
      canvas.restore();
    } else {
      _paintHorizontal(canvas, size);
    }
  }

  void _paintHorizontal(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = h / 2;

    // Colores derivados
    final bodyColor = Color.lerp(color, Colors.white, 0.52)!;
    final capColor = color;
    final tipColor = Color.lerp(color, Colors.black, 0.22)!;
    final borderColor = Color.lerp(color, Colors.black, 0.15)!;

    // Longitudes proporcionales
    final tipLen = h * 0.55; // punta chisel
    final capLen = h * 0.90; // tapa redonda derecha
    final bodyStart = tipLen;
    final bodyEnd = w - capLen * 0.5;

    // ── Sombra suave ──────────────────────────────────────────────────────
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        bodyStart,
        h * 0.08,
        bodyEnd + capLen * 0.5,
        h + 2,
        topRight: Radius.circular(r),
        bottomRight: Radius.circular(r),
        topLeft: Radius.circular(3),
        bottomLeft: Radius.circular(3),
      ),
      shadowPaint,
    );

    // ── Cuerpo principal ──────────────────────────────────────────────────
    final bodyRect = RRect.fromLTRBAndCorners(
      bodyStart,
      0,
      bodyEnd,
      h,
      topRight: Radius.circular(2),
      bottomRight: Radius.circular(2),
      topLeft: Radius.circular(3),
      bottomLeft: Radius.circular(3),
    );
    canvas.drawRRect(bodyRect, Paint()..color = bodyColor);
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = borderColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // ── Ventana blanca central (logotipo Mildliner) ───────────────────────
    final windowW = (bodyEnd - bodyStart) * 0.34;
    final windowX = bodyStart + (bodyEnd - bodyStart - windowW) / 2;
    final windowRect = RRect.fromLTRBR(
      windowX,
      h * 0.12,
      windowX + windowW,
      h * 0.88,
      Radius.circular(2.5),
    );
    canvas.drawRRect(
      windowRect,
      Paint()..color = Colors.white.withValues(alpha: 0.82),
    );
    // Línea de color dentro de la ventana (simula la franja de color del Mildliner)
    canvas.drawRRect(
      RRect.fromLTRBR(
        windowX + windowW * 0.2,
        h * 0.3,
        windowX + windowW * 0.8,
        h * 0.7,
        Radius.circular(1.5),
      ),
      Paint()..color = color.withValues(alpha: 0.55),
    );

    // ── Reflejo/brillo superior ───────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromLTRBR(
        bodyStart + 4,
        h * 0.08,
        bodyEnd - 4,
        h * 0.32,
        Radius.circular(2),
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );

    // ── Tapa redonda derecha ──────────────────────────────────────────────
    final capCenter = Offset(w - r, r);
    canvas.drawCircle(capCenter, r - 0.5, Paint()..color = capColor);
    canvas.drawCircle(
      capCenter,
      r - 0.5,
      Paint()
        ..color = borderColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    // Reflejo en la tapa
    canvas.drawCircle(
      Offset(w - r * 1.35, r * 0.55),
      r * 0.28,
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // ── Punta chisel (izquierda) — forma trapezoidal ──────────────────────
    final tipPath = Path()
      ..moveTo(0, h * 0.5) // ápice de la punta (izquierda)
      ..lineTo(tipLen, 0) // esquina superior
      ..lineTo(bodyStart + 1, 0) // unión con el cuerpo (arriba)
      ..lineTo(bodyStart + 1, h) // unión con el cuerpo (abajo)
      ..lineTo(tipLen, h) // esquina inferior
      ..close();
    canvas.drawPath(tipPath, Paint()..color = tipColor);
    // Borde de la punta
    canvas.drawPath(
      tipPath,
      Paint()
        ..color = borderColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
    // Bisel / brillo en la punta
    final bevelPath = Path()
      ..moveTo(0, h * 0.5)
      ..lineTo(tipLen * 0.65, h * 0.14)
      ..lineTo(tipLen * 0.65, h * 0.4)
      ..close();
    canvas.drawPath(
      bevelPath,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(_MildlinerPainter old) =>
      old.color != color || old.vertical != vertical;
}
