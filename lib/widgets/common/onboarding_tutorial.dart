import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

// ─────────────────────────────────────────────
// Clave para SharedPreferences
// ─────────────────────────────────────────────
const _kOnboardingDone = 'onboarding_v1_done';

// ─────────────────────────────────────────────
// Datos de cada paso del tutorial
// ─────────────────────────────────────────────
class _TutorialStep {
  const _TutorialStep({
    required this.emoji,
    required this.titulo,
    required this.descripcion,
    this.detalle,
  });

  final String emoji;
  final String titulo;
  final String descripcion;
  final String? detalle;
}

const List<_TutorialStep> _pasos = [
  _TutorialStep(
    emoji: '📚',
    titulo: '¡Te damos la bienvenida a ClubReads!',
    descripcion:
        'Tu espacio para leer, ya sea en compañía o en solitario. '
        'Este recorrido breve te muestra lo necesario para empezar.',
  ),
  _TutorialStep(
    emoji: '🔀',
    titulo: 'Uso personal y clubes',
    descripcion:
        'Puedes usar tu espacio personal sin pertenecer a un club y, si quieres, '
        'crear o unirte a uno o varios clubes.',
    detalle:
        'Tu biblioteca, progreso y Perfil son personales. Las lecturas grupales, '
        'Clubvisión y las conversaciones solo aparecen dentro de los clubes.',
  ),
  _TutorialStep(
    emoji: '🌌',
    titulo: 'Mi universo lector',
    descripcion:
        'El dashboard global reúne tus lecturas actuales, calendario, '
        'estanterías, sagas y accesos a tu biblioteca y tus clubes.',
  ),
  _TutorialStep(
    emoji: '➕',
    titulo: 'Explora y añade libros',
    descripcion:
        'Explora el catálogo compartido para añadir un libro a tu biblioteca. '
        'Dentro de un club también puedes usar el botón + de la pestaña “Libros”.',
    detalle:
        'En “Novedades” y “Próximos lanzamientos” del dashboard puedes guardar '
        'libros en tu lista de deseos pulsando el icono de carrito 🛒 sobre la portada.',
  ),
  _TutorialStep(
    emoji: '📖',
    titulo: 'Estados, progreso y relecturas',
    descripcion:
        'Marca cada libro como pendiente, leyendo, pausado, terminado, '
        'abandonado o en relectura, y actualiza sus páginas cuando quieras.',
    detalle:
        'Cada relectura conserva su propio periodo y no sustituye la lectura original.',
  ),
  _TutorialStep(
    emoji: '✨',
    titulo: 'Kit de lectura',
    descripcion:
        'Cada libro tiene su propio kit: paleta de colores, subrayadores '
        'estilo Mildliner, atmósfera de lectura, playlist y story para compartir.',
    detalle:
        'El kit tiene 6 secciones y una barra de progreso. Accede desde la ficha del '
        'libro. Si tienes atmósfera preparada, verás un banner directamente en la ficha.',
  ),
  _TutorialStep(
    emoji: '👤',
    titulo: 'Tu Perfil lector',
    descripcion:
        'El Perfil se organiza en Resumen, Historial, Favoritos, Meses lectores, '
        'Logros y Más.',
    detalle:
        'Historial reúne Cronología y Libros. Favoritos reúne tus cinco favoritos, '
        'Mi libro del año y Wrapped.',
  ),
  _TutorialStep(
    emoji: '🔥',
    titulo: 'Seguimiento de lectura',
    descripcion:
        'Haz check-in de forma explícita para marcar que has leído hoy y consulta '
        'tu racha y mapa de actividad.',
    detalle:
        'Abrir ClubReads no crea actividad. Wrapped está en Perfil → Favoritos '
        'y permanece bloqueado fuera de su periodo disponible.',
  ),
  _TutorialStep(
    emoji: '🏛️',
    titulo: 'Lee en comunidad',
    descripcion:
        'En un club puedes participar en lecturas grupales, comentar capítulos, '
        'guardar citas, reaccionar y votar en Clubvisión.',
    detalle: 'Estas funciones son opcionales y requieren pertenecer a un club.',
  ),
  _TutorialStep(
    emoji: '⚙️',
    titulo: 'Ayuda siempre disponible',
    descripcion:
        'En tu perfil → sección "Más" encontrarás el botón de Ayuda '
        'con explicaciones detalladas y actualizadas.',
    detalle: 'Desde Ayuda puedes volver a abrir este tutorial cuando quieras.',
  ),
];

// ─────────────────────────────────────────────
// Función pública para mostrar el tutorial
// ─────────────────────────────────────────────
Future<bool> deberiaMostrarOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_kOnboardingDone) ?? false);
}

Future<void> marcarOnboardingCompletado() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kOnboardingDone, true);
}

/// Muestra el tutorial en pantalla completa como ruta de diálogo.
/// Llama esto justo después de que el usuario inicia sesión por primera vez.
Future<void> mostrarOnboardingTutorial(BuildContext context) async {
  await Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: .65),
      pageBuilder: (_, _, _) => const _OnboardingOverlay(),
      transitionsBuilder: (_, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
  await marcarOnboardingCompletado();
}

// ─────────────────────────────────────────────
// Overlay principal del tutorial
// ─────────────────────────────────────────────
class _OnboardingOverlay extends StatefulWidget {
  const _OnboardingOverlay();

  @override
  State<_OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<_OnboardingOverlay>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  late final AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _buildAnimations();
    _animCtrl.forward();
  }

  void _buildAnimations() {
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, .06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  Future<void> _goTo(int index) async {
    await _animCtrl.reverse();
    setState(() => _step = index);
    _animCtrl.forward();
  }

  Future<void> _next() async {
    if (_step < _pasos.length - 1) {
      await _goTo(_step + 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _prev() async {
    if (_step > 0) await _goTo(_step - 1);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paso = _pasos[_step];
    final esUltimo = _step == _pasos.length - 1;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  elevation: 0,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Indicador de progreso ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_pasos.length, (i) {
                              final activo = i == _step;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: activo ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: activo
                                      ? AppColors.primary
                                      : AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // ── Emoji grande ──
                          Text(
                            paso.emoji,
                            style: const TextStyle(fontSize: 56),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // ── Título ──
                          Text(
                            paso.titulo,
                            style: AppTextStyles.title.copyWith(
                              fontSize: 20,
                              color: AppColors.primaryDark,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          // ── Descripción ──
                          Text(
                            paso.descripcion,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          // ── Detalle (caja diferenciada) ──
                          if (paso.detalle != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '💡',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      paso.detalle!,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primaryDark,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: AppSpacing.xl),

                          // ── Botones ──
                          Row(
                            children: [
                              if (_step > 0) ...[
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _prev,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: const Text('Anterior'),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                              ],
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  onPressed: _next,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: Text(
                                    esUltimo
                                        ? '¡Empezar a leer! 🎉'
                                        : 'Siguiente',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // ── Saltar (solo si no es el último paso) ──
                          if (!esUltimo) ...[
                            const SizedBox(height: AppSpacing.sm),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Saltar tutorial',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════
// FEATURE DISCOVERY — Tooltips de descubrimiento
// ═════════════════════════════════════════════
//
// Se muestran UNA SOLA VEZ por clave, justo después de que el usuario
// termina el tutorial principal.
//
// Uso:
//   FeatureTooltip(
//     featureKey: 'ft_add_book',
//     message: 'Pulsa aquí para añadir un libro',
//     icon: Icons.add_rounded,
//     child: MiBoton(),
//   )
//
// Para resetear todos los tooltips (útil en desarrollo):
//   await FeatureTooltipStore.reset();

const _kTooltipPrefix = 'feature_tooltip_v1_';

class FeatureTooltipStore {
  /// Devuelve true si este tooltip nunca se ha mostrado.
  static Future<bool> deberiaMostrar(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('$_kTooltipPrefix$featureKey') ?? false);
  }

  /// Marca el tooltip como ya mostrado.
  static Future<void> marcarMostrado(String featureKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kTooltipPrefix$featureKey', true);
  }

  /// Resetea todos los tooltips (útil para desarrollo / botón "Volver a ver").
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(_kTooltipPrefix))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}

// ─────────────────────────────────────────────
// Widget FeatureTooltip
// ─────────────────────────────────────────────

class FeatureTooltip extends StatefulWidget {
  const FeatureTooltip({
    super.key,
    required this.featureKey,
    required this.message,
    required this.child,
    this.icon,
    this.position = FeatureTooltipPosition.below,
    this.align = FeatureTooltipAlign.start,
  });

  final String featureKey;
  final String message;
  final Widget child;
  final IconData? icon;
  final FeatureTooltipPosition position;
  /// Horizontal alignment of the bubble relative to the target widget.
  /// [start] = bubble starts at target's left edge (default).
  /// [end]   = bubble ends at target's right edge (use near right screen edge).
  final FeatureTooltipAlign align;

  @override
  State<FeatureTooltip> createState() => _FeatureTooltipState();
}

enum FeatureTooltipPosition { above, below }
enum FeatureTooltipAlign { start, end }

class _FeatureTooltipState extends State<FeatureTooltip>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  OverlayEntry? _entry;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: widget.position == FeatureTooltipPosition.below
          ? const Offset(0, -0.15)
          : const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    _check();
  }

  Future<void> _check() async {
    final onboardingDone = !(await deberiaMostrarOnboarding());
    if (!onboardingDone) return;

    final mostrar = await FeatureTooltipStore.deberiaMostrar(widget.featureKey);
    if (!mostrar || !mounted) return;

    // Pequeño delay para que la UI esté completamente renderizada
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    _showOverlay();
    _ctrl.forward();
    await FeatureTooltipStore.marcarMostrado(widget.featureKey);

    // Auto-cierra tras 5 segundos
    await Future<void>.delayed(const Duration(seconds: 5));
    if (mounted) _dismiss();
  }

  void _showOverlay() {
    final isAbove = widget.position == FeatureTooltipPosition.above;
    final isEnd = widget.align == FeatureTooltipAlign.end;
    // Offset vertical respecto al borde del target: encima o debajo
    final followerOffset = isAbove
        ? const Offset(0, -8)   // justo encima, la burbuja crece hacia arriba
        : const Offset(0, 0);   // alineado con el borde inferior del target

    // Alineación horizontal: start = izquierda del target, end = derecha del target
    final hTarget = isEnd ? Alignment.centerRight : Alignment.centerLeft;
    final targetAnchor = isAbove
        ? Alignment(hTarget.x, -1.0)   // borde superior
        : Alignment(hTarget.x, 1.0);   // borde inferior
    final followerAnchor = isAbove
        ? Alignment(hTarget.x, 1.0)    // pie de burbuja
        : Alignment(hTarget.x, -1.0);  // cabeza de burbuja

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        // Cubrimos toda la pantalla para poder usar CompositedTransformFollower
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
        child: IgnorePointer(
          // Solo el bubble es interactivo; el resto ignora eventos
          ignoring: false,
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: targetAnchor,
                followerAnchor: followerAnchor,
                offset: followerOffset,
                child: _TooltipBubble(
                  message: widget.message,
                  icon: widget.icon,
                  position: widget.position,
                  fade: _fade,
                  slide: _slide,
                  onDismiss: _dismiss,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  Future<void> _dismiss() async {
    if (_entry == null) return;
    await _ctrl.reverse();
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────
// Burbuja del tooltip
// ─────────────────────────────────────────────

class _TooltipBubble extends StatelessWidget {
  const _TooltipBubble({
    required this.message,
    required this.icon,
    required this.position,
    required this.fade,
    required this.slide,
    required this.onDismiss,
  });

  final String message;
  final IconData? icon;
  final FeatureTooltipPosition position;
  final Animation<double> fade;
  final Animation<Offset> slide;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    const bubbleColor = AppColors.primaryDark;
    const arrowSize = 8.0;
    const radius = 12.0;

    final bubble = GestureDetector(
      onTap: onDismiss,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );

    // Triángulo apuntando hacia el widget hijo
    final arrow = CustomPaint(
      size: const Size(arrowSize * 2, arrowSize),
      painter: _ArrowPainter(
        color: bubbleColor,
        pointUp: position == FeatureTooltipPosition.above,
      ),
    );

    // La flecha señala hacia el widget: si el bubble está arriba, la flecha
    // apunta hacia abajo (pointUp: false); si está abajo, apunta arriba.
    final column = position == FeatureTooltipPosition.below
        ? Column(mainAxisSize: MainAxisSize.min, children: [arrow, bubble])
        : Column(mainAxisSize: MainAxisSize.min, children: [bubble, arrow]);

    // El posicionamiento ya lo gestiona CompositedTransformFollower en el
    // Overlay; aquí solo aplicamos la animación.
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: column),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color, required this.pointUp});
  final Color color;
  final bool pointUp;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (pointUp) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.color != color;
}
