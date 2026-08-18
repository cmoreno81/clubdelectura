import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/general_dashboard.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../common/club_book_cover.dart';

enum _Phase { idle, spinning, result }

/// Modo de sorteo: ruleta (tragaperras) o tarro (papelito del frasquito).
enum _TbrMode { roulette, jar }

/// Ruleta del TBR — elige aleatoriamente un libro pendiente de la biblioteca
/// personal del usuario con una animación tipo tragaperras.
class TbrRouletteCard extends StatefulWidget {
  const TbrRouletteCard({
    super.key,
    required this.books,
    required this.onOpenBook,
  });

  /// Toda la biblioteca personal; la tarjeta filtra internamente los PENDIENTE.
  final List<PersonalLibraryBook> books;

  /// Callback cuando el usuario quiere abrir la ficha del libro sorteado.
  final void Function(PersonalLibraryBook) onOpenBook;

  @override
  State<TbrRouletteCard> createState() => _TbrRouletteCardState();
}

class _TbrRouletteCardState extends State<TbrRouletteCard>
    with SingleTickerProviderStateMixin {
  _Phase _phase = _Phase.idle;
  _TbrMode _mode = _TbrMode.roulette;
  int _spinIndex = 0;
  PersonalLibraryBook? _winner;
  Timer? _timer;

  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  List<PersonalLibraryBook> get _pendientes =>
      widget.books.where((b) => b.status == 'PENDIENTE').toList();

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _bounceAnim = CurvedAnimation(
      parent: _bounceCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bounceCtrl.dispose();
    super.dispose();
  }

  // ── Lógica de sorteo ─────────────────────────────────────────────────────

  void _spin() {
    _timer?.cancel();
    final pendientes = List<PersonalLibraryBook>.from(_pendientes)..shuffle();
    if (pendientes.isEmpty) return;

    final winner = pendientes[math.Random().nextInt(pendientes.length)];

    setState(() {
      _phase = _Phase.spinning;
      _spinIndex = 0;
    });

    _runStep(pendientes, winner, 0);
  }

  /// Llama a sí mismo recursivamente con un intervalo que va acelerando desde
  /// muy rápido hasta muy lento, creando el efecto de tragaperras que frena.
  void _runStep(
    List<PersonalLibraryBook> books,
    PersonalLibraryBook winner,
    int step,
  ) {
    const totalSteps = 32;
    final t = step / totalSteps; // 0 → 1
    // Easing cuadrático: 45 ms (rápido) → 520 ms (muy lento)
    final ms = (45 + (520 - 45) * t * t).round();

    _timer = Timer(Duration(milliseconds: ms), () {
      if (!mounted) return;

      if (step >= totalSteps - 1) {
        // Último tick: mostramos el ganador
        setState(() {
          _phase = _Phase.result;
          _winner = winner;
        });
        _bounceCtrl.forward(from: 0);
      } else {
        setState(() {
          _spinIndex = (_spinIndex + 1) % books.length;
        });
        _runStep(books, winner, step + 1);
      }
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _phase = _Phase.idle;
      _winner = null;
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pendientes = _pendientes;
    if (pendientes.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5A3470), Color(0xFFBE4D4A)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .30),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            // Círculos decorativos de fondo
            Positioned(
              top: -45,
              right: -35,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .07),
                ),
              ),
            ),
            Positioned(
              bottom: -55,
              left: -25,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .05),
                ),
              ),
            ),
            Positioned(
              top: 60,
              left: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: .04),
                ),
              ),
            ),
            // Contenido principal
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: switch (_phase) {
                  _Phase.idle => _Idle(
                      pendientes: pendientes,
                      mode: _mode,
                      onSpin: _spin,
                      onModeChanged: (m) =>
                          setState(() => _mode = m),
                    ),
                  _Phase.spinning => _mode == _TbrMode.jar
                      ? _JarSpinning(book: pendientes[_spinIndex % pendientes.length])
                      : _Spinning(
                          pendientes: pendientes,
                          currentIndex: _spinIndex,
                        ),
                  _Phase.result => _mode == _TbrMode.jar
                      ? _JarResultCard(
                          winner: _winner!,
                          onOpen: () => widget.onOpenBook(_winner!),
                          onReSpin: _spin,
                          onDismiss: _reset,
                        )
                      : _Result(
                          winner: _winner!,
                          bounceAnim: _bounceAnim,
                          mode: _mode,
                          onOpen: () => widget.onOpenBook(_winner!),
                          onReSpin: _spin,
                          onDismiss: _reset,
                        ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fase: Idle ───────────────────────────────────────────────────────────────

class _Idle extends StatelessWidget {
  const _Idle({
    required this.pendientes,
    required this.mode,
    required this.onSpin,
    required this.onModeChanged,
  });

  final List<PersonalLibraryBook> pendientes;
  final _TbrMode mode;
  final VoidCallback onSpin;
  final void Function(_TbrMode) onModeChanged;

  bool get _isJar => mode == _TbrMode.jar;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('idle_$mode'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Toggle ruleta / tarro ────────────────────────────────────────
        Row(
          children: [
            _ModeToggle(
              isJar: _isJar,
              onChanged: onModeChanged,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Icono centrado ────────────────────────────────────────────────
        Center(
          child: _isJar
              ? const _JarIdlePreview()
              : const Text('🎲', style: TextStyle(fontSize: 72)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '¿No te decides?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -.4,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tienes ${pendientes.length} '
          '${pendientes.length == 1 ? 'libro pendiente' : 'libros pendientes'}. '
          '${_isJar ? 'Mete la mano en el tarro y saca un papelito.' : 'Juega a la ruleta y deja que el destino elija.'}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .80),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _CoverStrip(books: pendientes),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onSpin,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -.2,
              ),
            ),
            icon: Text(
              _isJar ? '🫙' : '🎲',
              style: const TextStyle(fontSize: 18),
            ),
            label: Text(_isJar ? 'Sacar del tarro' : 'Girar la ruleta'),
          ),
        ),
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isJar, required this.onChanged});

  final bool isJar;
  final void Function(_TbrMode) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            emoji: '🎲',
            label: 'Ruleta',
            selected: !isJar,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(_TbrMode.roulette);
            },
          ),
          _ToggleOption(
            emoji: '🫙',
            label: 'Tarro',
            selected: isJar,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(_TbrMode.jar);
            },
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fase: Spinning ───────────────────────────────────────────────────────────

class _Spinning extends StatelessWidget {
  const _Spinning({required this.pendientes, required this.currentIndex});

  final List<PersonalLibraryBook> pendientes;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final current = pendientes[currentIndex % pendientes.length];
    return Column(
      key: const ValueKey('spinning'),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Eligiendo tu libro...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -.2,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 70),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: child,
            ),
            child: ClipRRect(
              key: ValueKey(current.id + currentIndex.toString()),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: ClubBookCover(
                title: current.title,
                imageUrl: current.coverUrl,
                width: 100,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _PulsingDots(),
      ],
    );
  }
}

// ── Fase: Spinning (Tarro) ────────────────────────────────────────────────────

/// Animación modo tarro: el tarro se agita con papelitos flotando dentro.
class _JarSpinning extends StatefulWidget {
  const _JarSpinning({required this.book});
  final PersonalLibraryBook book;

  @override
  State<_JarSpinning> createState() => _JarSpinningState();
}

class _JarSpinningState extends State<_JarSpinning>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _wobble;

  // Propiedades fijas para cada papelito (posición base, tamaño, color)
  static final List<(double dx, double dy, double w, double h, Color color)> _paperProps = [
    (-16, -38, 17, 28, Color(0xFFFFF8E7)),
    (4,   -44, 14, 24, Color(0xFFFFEDD5)),
    (20,  -34, 16, 26, Color(0xFFFFFBEE)),
    (-6,  -40, 13, 20, Color(0xFFFFF3CD)),
    (26,  -30, 12, 22, Color(0xFFFFE9B8)),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _wobble = Tween<double>(begin: -0.10, end: 0.10).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('jar_spinning'),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Revolviendo el tarro...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -.2,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final t = _ctrl.value;
              return SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Papelitos que asoman del tarro
                    ..._paperProps.asMap().entries.map((e) {
                      final i = e.key;
                      final p = e.value;
                      final phase = (t + i * 0.18) % 1.0;
                      final dy = math.sin(phase * math.pi * 2) * 5.0;
                      final rot = math.sin(phase * math.pi * 2 + i) * 0.22;
                      return Positioned(
                        bottom: 52 + p.$2.abs() + dy,
                        left: 55 + p.$1 - p.$3 / 2,
                        child: Transform.rotate(
                          angle: rot,
                          child: _TinyPaper(
                            width: p.$3,
                            height: p.$4,
                            color: p.$5,
                          ),
                        ),
                      );
                    }),
                    // Tarro con wobble
                    Positioned(
                      bottom: 0,
                      child: Transform.rotate(
                        angle: _wobble.value,
                        child: const Text('🫙', style: TextStyle(fontSize: 72)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const _PulsingDots(),
      ],
    );
  }
}

// ── Resultado modo tarro: papel sacado con letra manuscrita ───────────────────

class _JarResultCard extends StatefulWidget {
  const _JarResultCard({
    required this.winner,
    required this.onOpen,
    required this.onReSpin,
    required this.onDismiss,
  });

  final PersonalLibraryBook winner;
  final VoidCallback onOpen;
  final VoidCallback onReSpin;
  final VoidCallback onDismiss;

  @override
  State<_JarResultCard> createState() => _JarResultCardState();
}

class _JarResultCardState extends State<_JarResultCard>
    with TickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final AnimationController _contentCtrl;

  late final Animation<Offset> _slideAnim;
  late final Animation<double> _slideOpacity;
  late final Animation<double> _rotateAnim;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
    _slideOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: const Interval(0, 0.55)));
    _rotateAnim = Tween<double>(begin: 0.05, end: -0.015)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutBack));
    _contentFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));

    HapticFeedback.mediumImpact();
    _slideCtrl.forward();
    Future.delayed(const Duration(milliseconds: 420), () {
      if (mounted) _contentCtrl.forward();
    });
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('jar_result'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cabecera
        Row(
          children: [
            const Expanded(
              child: Text(
                '🫙 ¡Has sacado...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            GestureDetector(
              onTap: widget.onDismiss,
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withValues(alpha: .60),
                size: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // El papelito
        SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _slideOpacity,
            child: AnimatedBuilder(
              animation: _rotateAnim,
              builder: (_, child) => Transform.rotate(
                angle: _rotateAnim.value,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
              child: _PaperSlip(
                winner: widget.winner,
                contentFade: _contentFade,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),
        // Botones
        Row(
          children: [
            Expanded(
              flex: 3,
              child: FilledButton(
                onPressed: widget.onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                child: const Text('Ver ficha →'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: widget.onReSpin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: .45)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                child: const Text('Otra vez 🫙'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Papelito de papel rayado con el título en estilo caligráfico.
class _PaperSlip extends StatelessWidget {
  const _PaperSlip({required this.winner, required this.contentFade});

  final PersonalLibraryBook winner;
  final Animation<double> contentFade;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .28),
            blurRadius: 14,
            offset: const Offset(2, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: .10),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CustomPaint(
          painter: _RuledPaperPainter(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            child: FadeTransition(
              opacity: contentFade,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '✦ tu próximo libro',
                    style: TextStyle(
                      color: const Color(0xFFB5651D).withValues(alpha: .75),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    winner.title,
                    style: const TextStyle(
                      color: Color(0xFF1A237E),
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                      letterSpacing: -.2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (winner.genre.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      '— ${winner.genre}',
                      style: const TextStyle(
                        color: Color(0xFF6D4C41),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Text(
                    '✦   ✦   ✦',
                    style: TextStyle(
                      color: Color(0xFFBB8B4A),
                      fontSize: 10,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dibuja líneas de papel rayado y margen rojo vertical.
class _RuledPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFD4C5A0).withValues(alpha: .55)
      ..strokeWidth = 0.8;
    final marginPaint = Paint()
      ..color = const Color(0xFFE8A0A0).withValues(alpha: .50)
      ..strokeWidth = 0.9;

    // Línea de margen vertical
    canvas.drawLine(const Offset(38, 0), Offset(38, size.height), marginPaint);

    // Líneas horizontales de papel rayado
    var y = 32.0;
    while (y < size.height - 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      y += 24.0;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Fase: Result ─────────────────────────────────────────────────────────────

class _Result extends StatelessWidget {
  const _Result({
    required this.winner,
    required this.bounceAnim,
    required this.mode,
    required this.onOpen,
    required this.onReSpin,
    required this.onDismiss,
  });

  final PersonalLibraryBook winner;
  final Animation<double> bounceAnim;
  final _TbrMode mode;
  final VoidCallback onOpen;
  final VoidCallback onReSpin;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('result'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera con botón de cerrar
        Row(
          children: [
            const Expanded(
              child: Text(
                '✨ ¡Tu próximo libro es...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withValues(alpha: .60),
                size: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Portada + info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScaleTransition(
              scale: bounceAnim,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: ClubBookCover(
                  title: winner.title,
                  imageUrl: winner.coverUrl,
                  width: 88,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    winner.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.3,
                      height: 1.25,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (winner.genre.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      winner.genre,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .70),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Botones
        Row(
          children: [
            Expanded(
              flex: 3,
              child: FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                child: const Text('Ver ficha →'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: onReSpin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: .45)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                child: Text(
                  mode == _TbrMode.jar ? 'Otra vez 🫙' : 'Otra vez 🎲',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Subwidgets ────────────────────────────────────────────────────────────────

/// Tira de portadas pequeñas con opacidad decreciente hacia la derecha.
class _CoverStrip extends StatelessWidget {
  const _CoverStrip({required this.books});

  final List<PersonalLibraryBook> books;

  @override
  Widget build(BuildContext context) {
    final shown = books.take(6).toList();
    return Row(
      children: shown.asMap().entries.map((e) {
        final i = e.key;
        final opacity = (0.75 - i * 0.10).clamp(0.15, 1.0);
        return Padding(
          padding: EdgeInsets.only(right: i < shown.length - 1 ? 6 : 0),
          child: Opacity(
            opacity: opacity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: ClubBookCover(
                title: e.value.title,
                imageUrl: e.value.coverUrl,
                width: 42,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Jar idle preview ─────────────────────────────────────────────────────────

/// Tarro con papelitos que asoman suavemente en el estado idle.
class _JarIdlePreview extends StatefulWidget {
  const _JarIdlePreview();

  @override
  State<_JarIdlePreview> createState() => _JarIdlePreviewState();
}

class _JarIdlePreviewState extends State<_JarIdlePreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // offset-x, base-y, ancho, alto, color, desfase de fase
  static const _papers = [
    (-18.0, -42.0, 19.0, 33.0, Color(0xFFFFF8E7), 0.0),
    (10.0,  -50.0, 17.0, 28.0, Color(0xFFFFEDD5), 0.35),
    (28.0,  -36.0, 18.0, 30.0, Color(0xFFFFFBEE), 0.65),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final t = _ctrl.value;
          return Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // Papelitos
              ..._papers.map((p) {
                final phase = (t + p.$6) % 1.0;
                final dy = math.sin(phase * math.pi * 2) * 4.5;
                final rot = math.sin(phase * math.pi * 2) * 0.12 * (p.$1 < 0 ? -1 : 1);
                return Positioned(
                  bottom: 56 + p.$2.abs() + dy,
                  left: 55 + p.$1 - p.$3 / 2,
                  child: Transform.rotate(
                    angle: rot,
                    child: _TinyPaper(width: p.$3, height: p.$4, color: p.$5),
                  ),
                );
              }),
              // Tarro
              const Positioned(
                bottom: 0,
                child: Text('🫙', style: TextStyle(fontSize: 64)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Papelito miniatura con líneas de papel rayado.
class _TinyPaper extends StatelessWidget {
  const _TinyPaper({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 2),
        child: Column(
          children: List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Container(
                height: 1,
                color: const Color(0xFFBBAA88).withValues(alpha: .5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cuatro puntos que pulsan en ola con una animación sin fin.
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (i) {
          final delay = i / 4.0;
          final phase = (_ctrl.value - delay) % 1.0;
          final v = math.sin(phase * math.pi * 2);
          final opacity = ((v + 1) / 2).clamp(0.15, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
