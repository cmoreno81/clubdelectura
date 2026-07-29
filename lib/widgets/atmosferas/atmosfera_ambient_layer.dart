import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/atmosferas/atmosfera_tipo.dart';

class AtmosferaAmbientLayer extends StatefulWidget {
  final Widget child;
  final AtmosferaLectura atmosfera;
  final Color color;
  final Color accentColor;
  final Color backgroundColor;
  final bool enabled;

  const AtmosferaAmbientLayer({
    super.key,
    required this.child,
    required this.atmosfera,
    required this.color,
    required this.accentColor,
    required this.backgroundColor,
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
      duration: const Duration(seconds: 10),
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
        oldWidget.color != widget.color ||
        oldWidget.accentColor != widget.accentColor ||
        oldWidget.backgroundColor != widget.backgroundColor) {
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
    final tieneAtmosfera = widget.atmosfera != AtmosferaLectura.neutra;

    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: widget.backgroundColor)),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _EditorialPaperPainter()),
          ),
        ),

        if (tieneAtmosfera)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withValues(alpha: 0.20),
                      widget.backgroundColor.withValues(alpha: 0.42),
                      widget.accentColor.withValues(alpha: 0.18),
                    ],
                    stops: const [0, 0.52, 1],
                  ),
                ),
              ),
            ),
          ),

        if (widget.enabled)
          Positioned.fill(
            child: IgnorePointer(
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
          ),

        widget.child,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _EditorialPaperPainter extends CustomPainter {
  const _EditorialPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paperRect = Offset.zero & size;
    canvas.drawRect(
      paperRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.18, -0.22),
          radius: 1.22,
          colors: [
            const Color(0xFFFFFBF2).withValues(alpha: .16),
            const Color(0xFF8D654A).withValues(alpha: .13),
          ],
          stops: const [.48, 1],
        ).createShader(paperRect),
    );

    final warmClouds = [
      (const Offset(.12, .18), 116.0, .065),
      (const Offset(.86, .36), 148.0, .05),
      (const Offset(.28, .78), 176.0, .046),
      (const Offset(.92, .9), 105.0, .055),
    ];
    for (final cloud in warmClouds) {
      final center = Offset(
        size.width * cloud.$1.dx,
        size.height * cloud.$1.dy,
      );
      final rect = Rect.fromCircle(center: center, radius: cloud.$2);
      canvas.drawCircle(
        center,
        cloud.$2,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFB98762).withValues(alpha: cloud.$3),
              Colors.transparent,
            ],
          ).createShader(rect),
      );
    }

    final fiber = Paint()
      ..color = const Color(0xFF705D4E).withValues(alpha: .1)
      ..strokeWidth = .72;
    for (var y = 13.0; y < size.height; y += 23) {
      final shift = ((y ~/ 23) % 5) * 9.0;
      canvas.drawLine(
        Offset(14 + shift, y),
        Offset(math.min(size.width - 12, 88 + shift), y + .8),
        fiber,
      );
      if (size.width > 220) {
        canvas.drawLine(
          Offset(size.width - 112 - shift, y + 9),
          Offset(size.width - 22 - shift, y + 8.2),
          fiber,
        );
      }
    }

    final ruledLine = Paint()
      ..color = const Color(0xFF7C6B88).withValues(alpha: .072)
      ..strokeWidth = .78;
    for (var y = 31.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(26, y), Offset(size.width, y), ruledLine);
    }

    final longFiber = Paint()
      ..color = const Color(0xFF9A7256).withValues(alpha: .065)
      ..strokeWidth = .52;
    for (var index = 0; index < 18; index++) {
      final y = ((index * 83.0) + 41) % math.max(size.height, 1.0);
      final x = ((index * 47.0) + 19) % math.max(size.width, 1.0);
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(size.width, x + 104 + (index % 4) * 18), y + 1.4),
        longFiber,
      );
    }

    final speck = Paint()
      ..color = const Color(0xFF6E513E).withValues(alpha: .12);
    final speckCount = math.min(210, (size.width * size.height / 3200).round());
    for (var index = 0; index < speckCount; index++) {
      final x =
          ((index * 73.37 + math.sin(index * 1.7) * 31).abs()) %
          math.max(size.width, 1.0);
      final y =
          ((index * 127.19 + math.cos(index * 2.1) * 47).abs()) %
          math.max(size.height, 1.0);
      final radius = .3 + (index % 4) * .14;
      canvas.drawCircle(Offset(x, y), radius, speck);
    }

    final margin = Paint()
      ..color = const Color(0xFFC75D4D).withValues(alpha: .34)
      ..strokeWidth = 1.25;
    canvas.drawLine(const Offset(11, 0), Offset(11, size.height), margin);
    canvas.drawLine(
      const Offset(14, 0),
      Offset(14, size.height),
      Paint()
        ..color = const Color(0xFF603B73).withValues(alpha: .1)
        ..strokeWidth = .9,
    );

    final edgePaint = Paint()
      ..color = const Color(0xFF74523E).withValues(alpha: .075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawRect(
      Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        _pintarDestellos(canvas, size);

      case AtmosferaLectura.magica:
        _pintarDestellos(canvas, size);
        _pintarConstelacion(canvas, size);

      case AtmosferaLectura.marina:
        _pintarOndas(canvas, size);
        _pintarDestellos(canvas, size);

      case AtmosferaLectura.bosque:
        _pintarHojas(canvas, size);
        _pintarRayosCalidos(canvas, size);

      case AtmosferaLectura.oscura:
        _pintarBruma(canvas, size);
        _pintarLluvia(canvas, size);

      case AtmosferaLectura.gotica:
        _pintarBruma(canvas, size);
        _pintarArcos(canvas, size);

      case AtmosferaLectura.misteriosa:
        _pintarBruma(canvas, size);
        _pintarConstelacion(canvas, size);

      case AtmosferaLectura.futurista:
        _pintarLineas(canvas, size);
        _pintarConstelacion(canvas, size);

      case AtmosferaLectura.epica:
        _pintarChispas(canvas, size);
        _pintarRayosCalidos(canvas, size);

      case AtmosferaLectura.acogedora:
        _pintarPolvoCalido(canvas, size);
        _pintarRayosCalidos(canvas, size);

      case AtmosferaLectura.historica:
        _pintarPolvoCalido(canvas, size);
        _pintarLineasManuscrito(canvas, size);

      case AtmosferaLectura.neutra:
        break;
    }
  }

  void _pintarPetalos(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.22);

    for (var i = 0; i < 25; i++) {
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
    for (var i = 0; i < 38; i++) {
      final x = _fraccion(i * 81.41) * size.width;
      final y = _fraccion(i * 39.73) * size.height;

      final pulso = (math.sin((progreso * math.pi * 2) + i * 0.8) + 1) / 2;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.07 + pulso * 0.20);

      canvas.drawCircle(Offset(x, y), 1.5 + pulso * 3.2, paint);

      if (i % 4 == 0) {
        final linePaint = Paint()
          ..color = color.withValues(alpha: 0.06 + pulso * 0.15)
          ..strokeWidth = 1;

        canvas.drawLine(Offset(x - 6, y), Offset(x + 6, y), linePaint);

        canvas.drawLine(Offset(x, y - 6), Offset(x, y + 6), linePaint);
      }
    }
  }

  void _pintarOndas(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (var fila = 0; fila < 8; fila++) {
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
    final paint = Paint()..color = color.withValues(alpha: 0.20);

    for (var i = 0; i < 24; i++) {
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
        ..color = color.withValues(alpha: 0.10 + (i % 3) * 0.025)
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
      ..color = color.withValues(alpha: 0.24)
      ..strokeWidth = 1.2;

    for (var i = 0; i < 28; i++) {
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
    for (var i = 0; i < 32; i++) {
      final fase = (progreso * (0.35 + (i % 5) * 0.06) + i * 0.12) % 1;
      final x = _fraccion(i * 45.73) * size.width;
      final y = size.height + 20 - fase * (size.height + 40);

      final paint = Paint()
        ..color = color.withValues(alpha: 0.10 + fase * 0.24);
      canvas.drawCircle(Offset(x, y), 1.5 + (i % 3), paint);
    }
  }

  void _pintarPolvoCalido(Canvas canvas, Size size) {
    for (var i = 0; i < 36; i++) {
      final x = _fraccion(i * 71.17) * size.width;
      final y = _fraccion(i * 37.91 + progreso * 20) * size.height;

      final pulso = (math.sin(progreso * math.pi * 2 + i * 0.6) + 1) / 2;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.08 + pulso * 0.18);
      canvas.drawCircle(Offset(x, y), 1.3 + pulso * 2.8, paint);
    }
  }

  void _pintarLluvia(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..strokeWidth = 1.5;
    for (var i = 0; i < 42; i++) {
      final x = _fraccion(i * 57.19) * size.width;
      final fase = (progreso * (0.7 + (i % 4) * 0.09) + i * 0.08) % 1;
      final y = fase * size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 7, y + 30), paint);
    }
  }

  void _pintarArcos(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (var i = 0; i < 4; i++) {
      final width = size.width * (0.24 + i * 0.08);
      final center = Offset(size.width * (0.15 + i * 0.25), size.height * 0.28);
      canvas.drawArc(
        Rect.fromCenter(center: center, width: width, height: width * 1.8),
        math.pi,
        math.pi,
        false,
        paint,
      );
    }
  }

  void _pintarConstelacion(Canvas canvas, Size size) {
    final points = <Offset>[];
    for (var i = 0; i < 12; i++) {
      points.add(
        Offset(
          _fraccion(i * 43.71) * size.width,
          _fraccion(i * 77.13) * size.height,
        ),
      );
    }
    final pulse = 0.15 + (math.sin(progreso * math.pi * 2) + 1) * 0.06;
    final line = Paint()
      ..color = color.withValues(alpha: pulse)
      ..strokeWidth = 0.9;
    final dot = Paint()..color = color.withValues(alpha: pulse + 0.06);
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 1.8 + (i % 3), dot);
      if (i > 0 && i % 3 != 0) canvas.drawLine(points[i - 1], points[i], line);
    }
  }

  void _pintarRayosCalidos(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.13)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 4; i++) {
      final drift = math.sin(progreso * math.pi * 2 + i) * 12;
      final path = Path()
        ..moveTo(size.width * (0.12 + i * 0.24) + drift, 0)
        ..lineTo(size.width * (0.30 + i * 0.24) + drift, 0)
        ..lineTo(size.width * (0.52 + i * 0.18), size.height)
        ..lineTo(size.width * (0.34 + i * 0.18), size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  void _pintarLineasManuscrito(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var row = 0; row < 12; row++) {
      final y = size.height * (0.08 + row * 0.075);
      final path = Path()..moveTo(size.width * 0.08, y);
      for (double x = size.width * 0.08; x < size.width * 0.92; x += 12) {
        path.lineTo(x, y + math.sin(x / 24 + row + progreso * 2) * 2);
      }
      canvas.drawPath(path, paint);
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
