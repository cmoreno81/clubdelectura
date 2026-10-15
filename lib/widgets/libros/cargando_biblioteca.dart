import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_shimmer.dart';

/// Pantalla de espera de la Biblioteca: tarjetas de relleno y un mensaje que
/// cambia con el tiempo para que nadie piense que se ha colgado.
///  · al principio: «Cargando tu biblioteca…»
///  · pasados [avisoLento]: «Está tardando más de lo normal…»
///  · pasados [avisoMuyLento]: ofrece «Reintentar».
class CargandoBiblioteca extends StatefulWidget {
  const CargandoBiblioteca({
    super.key,
    this.onReintentar,
    this.avisoLento = const Duration(seconds: 6),
    this.avisoMuyLento = const Duration(seconds: 20),
  });

  final VoidCallback? onReintentar;
  final Duration avisoLento;
  final Duration avisoMuyLento;

  @override
  State<CargandoBiblioteca> createState() => _CargandoBibliotecaState();
}

class _CargandoBibliotecaState extends State<CargandoBiblioteca> {
  int _fase = 0;
  Timer? _timerLento;
  Timer? _timerMuyLento;

  @override
  void initState() {
    super.initState();
    _timerLento = Timer(widget.avisoLento, () {
      if (mounted && _fase < 1) setState(() => _fase = 1);
    });
    _timerMuyLento = Timer(widget.avisoMuyLento, () {
      if (mounted) setState(() => _fase = 2);
    });
  }

  @override
  void dispose() {
    _timerLento?.cancel();
    _timerMuyLento?.cancel();
    super.dispose();
  }

  String get _titulo => switch (_fase) {
    0 => 'Cargando tu biblioteca…',
    1 => 'Está tardando más de lo normal…',
    _ => 'La conexión va lenta',
  };

  String? get _detalle => switch (_fase) {
    0 => null,
    1 => 'Sigue en marcha: enseguida aparecerán tus libros.',
    _ => 'Puedes esperar un poco más o volver a intentarlo.',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Semantics(
            liveRegion: true,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Column(
                key: ValueKey(_fase),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          _titulo,
                          key: const Key('cargando-biblioteca-titulo'),
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_detalle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _detalle!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                  if (_fase >= 2 && widget.onReintentar != null)
                    TextButton.icon(
                      key: const Key('cargando-biblioteca-reintentar'),
                      onPressed: widget.onReintentar,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Reintentar'),
                    ),
                ],
              ),
            ),
          ),
        ),
        const Expanded(child: BookListSkeleton()),
      ],
    );
  }
}
