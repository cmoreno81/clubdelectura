import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Botón de check-in lector diario.
///
/// Si [checkedToday] es true muestra el estado "ya leíste hoy" con la racha.
/// En caso contrario muestra el CTA para marcar el check-in.
/// Llama a [onCheckinDone] (si se proporciona) con el nuevo valor de racha.
class CheckinButton extends StatefulWidget {
  const CheckinButton({
    super.key,
    required this.checkedToday,
    required this.streak,
    this.onCheckinDone,
    this.doCheckin,
  });

  final bool checkedToday;
  final int streak;
  final void Function(int newStreak)? onCheckinDone;
  final Future<Map<String, dynamic>> Function()? doCheckin;

  @override
  State<CheckinButton> createState() => _CheckinButtonState();
}

class _CheckinButtonState extends State<CheckinButton>
    with SingleTickerProviderStateMixin {
  late bool _checked = widget.checkedToday;
  late int _streak = widget.streak;
  bool _busy = false;

  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.18,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _hacerCheckin() async {
    if (_busy || _checked) return;
    setState(() => _busy = true);
    try {
      final data = await (widget.doCheckin?.call() ?? ApiService().doCheckin());
      final nuevoStreak = (data['streak'] as num?)?.toInt() ?? _streak;
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _checked = true;
        _streak = nuevoStreak;
        _busy = false;
      });
      _ctrl.forward(from: 0);
      widget.onCheckinDone?.call(nuevoStreak);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: _checked
          ? _DoneCard(streak: _streak)
          : _CTA(busy: _busy, onTap: _hacerCheckin),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DoneCard extends StatelessWidget {
  const _DoneCard({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .08),
        border: Border.all(color: AppColors.primary.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          // Icono de llama animado
          const Text('🔥', style: TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Ya leíste hoy!',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (streak > 0)
                  Text(
                    streak == 1
                        ? 'Llevas 1 día de racha'
                        : 'Llevas $streak días de racha',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _CTA extends StatelessWidget {
  const _CTA({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 26)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¿Has leído hoy?', style: AppTextStyles.subtitle),
                    Text(
                      'Registra tu check-in diario',
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    '¡Sí!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
