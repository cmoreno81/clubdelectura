import 'package:flutter/material.dart';

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
    return SizedBox(
      width: vertical ? thickness : length,
      height: vertical ? length : thickness,
      child: vertical ? _vertical() : _horizontal(),
    );
  }

  Widget _vertical() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(top: 9, bottom: 7, left: 2, right: 2, child: _cuerpo()),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: length * 0.28,
          child: _tapa(vertical: true),
        ),
        Positioned(
          left: thickness * 0.18,
          right: thickness * 0.18,
          bottom: 0,
          height: 12,
          child: ClipPath(
            clipper: const _PuntaVerticalClipper(),
            child: Container(color: Color.lerp(color, Colors.black, 0.28)),
          ),
        ),
        Positioned(
          top: length * 0.49,
          left: 3,
          right: 3,
          height: 13,
          child: _banda(),
        ),
      ],
    );
  }

  Widget _horizontal() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(left: 8, right: 8, top: 2, bottom: 2, child: _cuerpo()),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: length * 0.28,
          child: _tapa(vertical: false),
        ),
        Positioned(
          left: 0,
          top: thickness * 0.18,
          bottom: thickness * 0.18,
          width: 13,
          child: ClipPath(
            clipper: const _PuntaHorizontalClipper(),
            child: Container(color: Color.lerp(color, Colors.black, 0.28)),
          ),
        ),
        Positioned(
          left: length * 0.46,
          top: 3,
          bottom: 3,
          width: 14,
          child: _banda(),
        ),
      ],
    );
  }

  Widget _cuerpo() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.lerp(color, Colors.white, 0.62),
        borderRadius: BorderRadius.circular(thickness * 0.28),
        border: Border.all(color: Color.lerp(color, Colors.black, 0.18)!),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(1, 2)),
        ],
      ),
    );
  }

  Widget _tapa({required bool vertical}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: vertical
            ? BorderRadius.circular(thickness * 0.34)
            : BorderRadius.circular(thickness * 0.3),
        border: Border.all(color: Color.lerp(color, Colors.black, 0.2)!),
      ),
      child: Align(
        alignment: vertical ? Alignment.topCenter : Alignment.centerRight,
        child: Container(
          width: vertical ? thickness * 0.48 : 3,
          height: vertical ? 3 : thickness * 0.48,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _banda() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _PuntaVerticalClipper extends CustomClipper<Path> {
  const _PuntaVerticalClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width * 0.72, size.height)
    ..lineTo(size.width * 0.18, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _PuntaHorizontalClipper extends CustomClipper<Path> {
  const _PuntaHorizontalClipper();

  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height * 0.72)
    ..lineTo(0, size.height * 0.18)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
