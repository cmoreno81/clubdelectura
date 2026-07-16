import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/atmosferas/atmosfera_tipo.dart';

class AtmosferaAmbientLayer extends StatefulWidget {
  final Widget child;
  final AtmosferaLectura atmosfera;
  final Color color;
  final bool enabled;

  const AtmosferaAmbientLayer({
    super.key,
    required this.child,
    required this.atmosfera,
    required this.color,
    this.enabled = true,
  });

  @override
  State<AtmosferaAmbientLayer> createState() => _AtmosferaAmbientLayerState();
}

class _AtmosferaAmbientLayerState extends State<AtmosferaAmbientLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );

    _actualizarAnimacion();
  }

  @override
  void didUpdateWidget(covariant AtmosferaAmbientLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.enabled != widget.enabled) {
      _actualizarAnimacion();
    }

    if (oldWidget.atmosfera != widget.atmosfera ||
        oldWidget.color != widget.color) {
      setState(() {});
    }
  }

  void _actualizarAnimacion() {
    if (widget.enabled) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,

        if (widget.enabled)
          IgnorePointer(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _AtmosferaPainter(
                      progreso: _controller.value,
                      atmosfera: widget.atmosfera,
                      color: widget.color,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _AtmosferaPainter extends CustomPainter {
  final double progreso;
  final AtmosferaLectura atmosfera;
  final Color color;

  const _AtmosferaPainter({
    required this.progreso,
    required this.atmosfera,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (atmosfera) {
      case AtmosferaLectura.romantica:
        _pintarPetalos(canvas, size);

      case AtmosferaLectura.magica:
        _pintarDestellos(canvas, size);

      case AtmosferaLectura.marina:
        _pintarOndas(canvas, size);

      case AtmosferaLectura.bosque:
        _pintarHojas(canvas, size);

      case AtmosferaLectura.oscura:
      case AtmosferaLectura.gotica:
      case AtmosferaLectura.misteriosa:
        _pintarBruma(canvas, size);

      case AtmosferaLectura.futurista:
        _pintarLineas(canvas, size);

      case AtmosferaLectura.epica:
        _pintarChispas(canvas, size);

      case AtmosferaLectura.acogedora:
      case AtmosferaLectura.historica:
        _pintarPolvoCalido(canvas, size);

      case AtmosferaLectura.neutra:
        break;
    }
  }

  void _pintarPetalos(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.075);

    for (var i = 0; i < 13; i++) {
      final velocidad = 0.45 + (i % 4) * 0.11;
      final fase = (progreso * velocidad + i * 0.113) % 1;

      final xBase = _fraccion(i * 53.17) * size.width;
      final oscilacion = math.sin((progreso * math.pi * 2) + i) * 24;
      final x = xBase + oscilacion;
      final y = -30 + fase * (size.height + 60);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progreso * math.pi * 2 + i);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: 8 + (i % 3) * 2,
          height: 15 + (i % 4) * 2,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  void _pintarDestellos(Canvas canvas, Size size) {
    for (var i = 0; i < 22; i++) {
      final x = _fraccion(i * 81.41) * size.width;
      final y = _fraccion(i * 39.73) * size.height;

      final pulso = (math.sin((progreso * math.pi * 2) + i * 0.8) + 1) / 2;

      final paint = Paint()..color = color.withValues(alpha: 0.025 + pulso * 0.09);

      canvas.drawCircle(Offset(x, y), 1.5 + pulso * 3.2, paint);

      if (i % 4 == 0) {
        final linePaint = Paint()
          ..color = color.withValues(alpha: 0.025 + pulso * 0.06)
          ..strokeWidth = 1;

        canvas.drawLine(Offset(x - 6, y), Offset(x + 6, y), linePaint);

        canvas.drawLine(Offset(x, y - 6), Offset(x, y + 6), linePaint);
      }
    }
  }

  void _pintarOndas(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (var fila = 0; fila < 5; fila++) {
      final path = Path();

      final yBase = size.height * (0.18 + fila * 0.17);
      final desplazamiento = progreso * size.width * 0.35;

      for (double x = -60; x <= size.width + 60; x += 8) {
        final y = yBase + math.sin((x + desplazamiento + fila * 40) / 42) * 8;

        if (x == -60) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  void _pintarHojas(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.065);

    for (var i = 0; i < 12; i++) {
      final fase = (progreso * (0.35 + (i % 3) * 0.1) + i * 0.16) % 1;

      final xBase = _fraccion(i * 67.27) * size.width;
      final x = xBase + math.sin(progreso * math.pi * 2 + i) * 30;
      final y = -25 + fase * (size.height + 50);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(i + progreso * 2);

      final path = Path()
        ..moveTo(0, -8)
        ..quadraticBezierTo(7, -3, 0, 9)
        ..quadraticBezierTo(-7, -3, 0, -8);

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  void _pintarBruma(Canvas canvas, Size size) {
    for (var i = 0; i < 7; i++) {
      final desplazamiento = ((progreso * (0.1 + i * 0.012)) + i * 0.19) % 1;

      final x = -size.width * 0.4 + desplazamiento * size.width * 1.8;
      final y = size.height * (0.12 + i * 0.13);

      final paint = Paint()
        ..color = color.withValues(alpha: 0.035 + (i % 3) * 0.012)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: size.width * 0.65,
          height: 90,
        ),
        paint,
      );
    }
  }

  void _pintarLineas(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.085)
      ..strokeWidth = 1.2;

    for (var i = 0; i < 15; i++) {
      final x = _fraccion(i * 91.31) * size.width;
      final fase = (progreso * (0.5 + (i % 4) * 0.08) + i * 0.09) % 1;
      final y = fase * size.height;

      canvas.drawLine(
        Offset(x, y),
        Offset(x + 15 + (i % 4) * 8, y - 28),
        paint,
      );
    }
  }

  void _pintarChispas(Canvas canvas, Size size) {
    for (var i = 0; i < 18; i++) {
      final fase = (progreso * (0.35 + (i % 5) * 0.06) + i * 0.12) % 1;
      final x = _fraccion(i * 45.73) * size.width;
      final y = size.height + 20 - fase * (size.height + 40);

      final paint = Paint()..color = color.withValues(alpha: 0.045 + fase * 0.11);
      canvas.drawCircle(Offset(x, y), 1.5 + (i % 3), paint);
    }
  }

  void _pintarPolvoCalido(Canvas canvas, Size size) {
    for (var i = 0; i < 20; i++) {
      final x = _fraccion(i * 71.17) * size.width;
      final y = _fraccion(i * 37.91 + progreso * 20) * size.height;

      final pulso = (math.sin(progreso * math.pi * 2 + i * 0.6) + 1) / 2;

      final paint = Paint()..color = color.withValues(alpha: 0.035 + pulso * 0.065);
      canvas.drawCircle(Offset(x, y), 1.3 + pulso * 2.8, paint);
    }
  }

  double _fraccion(double valor) {
    return valor - valor.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _AtmosferaPainter oldDelegate) {
    return oldDelegate.progreso != progreso ||
        oldDelegate.atmosfera != atmosfera ||
        oldDelegate.color != color;
  }
}
