import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Mensaje dentro de una hoja inferior. Un SnackBar saldría por detrás de la hoja y no se
/// vería; este aviso aparece arriba del contenido y se quita solo a los 5 segundos.
mixin AvisoEnHojaState<T extends StatefulWidget> on State<T> {
  String? avisoTexto;
  Timer? _avisoTimer;

  void avisar(String texto) {
    _avisoTimer?.cancel();
    setState(() => avisoTexto = texto);
    _avisoTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => avisoTexto = null);
    });
  }

  void cancelarAviso() => _avisoTimer?.cancel();
}

class AvisoEnHoja extends StatelessWidget {
  const AvisoEnHoja({super.key, required this.texto});

  final String? texto;

  @override
  Widget build(BuildContext context) {
    final t = texto;
    if (t == null || t.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        liveRegion: true,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: cs.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            t,
            style: TextStyle(color: cs.onSecondaryContainer, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
