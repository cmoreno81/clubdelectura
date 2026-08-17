import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

// ──────────────────────────────────────────────────────────────────
// Modelo de tip
// ──────────────────────────────────────────────────────────────────

class ScreenHintTip {
  const ScreenHintTip(this.emoji, this.texto);
  final String emoji;
  final String texto;
}

// ──────────────────────────────────────────────────────────────────
// ScreenHintBanner
//
// Muestra un banner desplegable la primera vez que el usuario
// visita una pantalla. Desaparece permanentemente al pulsar
// "Entendido" y se puede cerrar temporalmente con la ×.
//
// Uso:
//   body: Column(children: [
//     ScreenHintBanner(
//       featureKey: 'hint_libros_v1',
//       titulo: 'Tu biblioteca',
//       tips: [ ScreenHintTip('📌', 'Pulsa para ver detalles'), ... ],
//     ),
//     Expanded(child: _buildContent()),
//   ]),
// ──────────────────────────────────────────────────────────────────

class ScreenHintBanner extends StatefulWidget {
  const ScreenHintBanner({
    super.key,
    required this.featureKey,
    required this.titulo,
    required this.tips,
  });

  final String featureKey;
  final String titulo;
  final List<ScreenHintTip> tips;

  @override
  State<ScreenHintBanner> createState() => _ScreenHintBannerState();
}

class _ScreenHintBannerState extends State<ScreenHintBanner>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  late final AnimationController _ctrl;
  late final Animation<double> _heightFactor;
  late final Animation<double> _fade;

  static const _prefix = 'screen_hint_v1_';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _heightFactor = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _checkShouldShow();
  }

  Future<void> _checkShouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('$_prefix${widget.featureKey}') ?? false;
    if (dismissed || !mounted) return;
    setState(() => _visible = true);
    _ctrl.forward();
  }

  Future<void> _dismiss({required bool permanent}) async {
    await _ctrl.reverse();
    if (!mounted) return;
    setState(() => _visible = false);
    if (permanent) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefix${widget.featureKey}', true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return SizeTransition(
      sizeFactor: _heightFactor,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _fade,
        child: _BannerContent(
          titulo: widget.titulo,
          tips: widget.tips,
          onDismiss: () => _dismiss(permanent: true),
          onClose: () => _dismiss(permanent: false),
        ),
      ),
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({
    required this.titulo,
    required this.tips,
    required this.onDismiss,
    required this.onClose,
  });

  final String titulo;
  final List<ScreenHintTip> tips;
  final VoidCallback onDismiss;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEDE7FF),
            Color(0xFFF5F0FF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryLight,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    titulo,
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                // Cerrar temporalmente
                GestureDetector(
                  onTap: onClose,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xs),

            // Tips
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(top: 4, left: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tip.emoji, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tip.texto,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Botón entendido
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Entendido ✓',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
