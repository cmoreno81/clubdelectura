import 'dart:math';

import 'package:flutter/material.dart';

import '../../common/club_book_cover.dart';

class EscenaVotacion extends StatefulWidget {
  const EscenaVotacion({
    super.key,
    required this.totalCandidatas,
    this.portadas = const [],
  });

  final int totalCandidatas;
  final List<String> portadas;

  @override
  State<EscenaVotacion> createState() => _EscenaVotacionState();
}

class _EscenaVotacionState extends State<EscenaVotacion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Posiciones y rotaciones fijas por portada (seeded por índice → siempre iguales)
  late final List<_CoverData> _covers;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _covers = _buildCovers();
  }

  List<_CoverData> _buildCovers() {
    final portadas = widget.portadas.toList();
    if (portadas.isEmpty) return [];

    final rng = Random(42); // seed fijo → layout siempre igual
    final result = <_CoverData>[];

    // Distribuimos en un área de 300×200 con superposición
    for (var i = 0; i < portadas.length; i++) {
      result.add(
        _CoverData(
          url: portadas[i],
          // dx: -110..110, dy: -60..60
          dx: (rng.nextDouble() * 340 - 170),
          dy: (rng.nextDouble() * 200 - 100),
          angle: (rng.nextDouble() * 40 - 20) * pi / 180,
          delay: i * 0.07,
          scale: 0.65 + rng.nextDouble() * 0.45,
        ),
      );
    }
    return result;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Collage animado ──
        if (_covers.isNotEmpty)
          SizedBox(
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < _covers.length; i++)
                  _AnimatedCover(
                    data: _covers[i],
                    controller: _ctrl,
                    zIndex: i,
                  ),
              ],
            ),
          ),

        if (_covers.isNotEmpty) const SizedBox(height: 20),

        // ── Texto ──
        Text(
          '${widget.totalCandidatas} historias esperan convertirse\n'
          'en la próxima lectura del club.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.35,
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Cada voto acerca el desenlace.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _CoverData {
  const _CoverData({
    required this.url,
    required this.dx,
    required this.dy,
    required this.angle,
    required this.delay,
    required this.scale,
  });

  final String url;
  final double dx;
  final double dy;
  final double angle;
  final double delay; // 0..1
  final double scale;
}

class _AnimatedCover extends StatelessWidget {
  const _AnimatedCover({
    required this.data,
    required this.controller,
    required this.zIndex,
  });

  final _CoverData data;
  final AnimationController controller;
  final int zIndex;

  @override
  Widget build(BuildContext context) {
    // Cada portada entra con un pequeño delay
    final begin = data.delay.clamp(0.0, 0.85);
    final end = (begin + 0.4).clamp(0.0, 1.0);

    final anim = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (_, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..translateByDouble(data.dx, data.dy + (1 - anim.value) * 60, 0, 1)
          ..rotateZ(data.angle)
          ..scaleByDouble(
            data.scale * anim.value.clamp(0.0, 1.0),
            data.scale * anim.value.clamp(0.0, 1.0),
            1,
            1,
          ),
        child: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClubBookCover(
          title: '',
          imageUrl: data.url,
          width: 58,
          height: 86,
          borderRadius: BorderRadius.circular(8),
          showShadow: false,
        ),
      ),
    );
  }
}
