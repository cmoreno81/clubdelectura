import 'package:flutter/material.dart';

import '../../models/amistad.dart';
import '../../models/reaccion_comentario.dart';
import '../../services/api_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Reacciones al progreso de lectura de una amistad: lo que ya han puesto
/// otras personas y un botón para reaccionar tú (o quitar tu reacción).
class ReaccionesProgreso extends StatefulWidget {
  const ReaccionesProgreso({super.key, required this.lectura, this.reaccionar});

  final LecturaAmistad lectura;

  /// Para pruebas: sustituye la llamada al servidor. Devuelve el estado final
  /// o `null` si falló.
  final Future<LecturaAmistad?> Function(
    LecturaAmistad lectura,
    ReaccionComentario reaccion,
  )?
  reaccionar;

  @override
  State<ReaccionesProgreso> createState() => _ReaccionesProgresoState();
}

class _ReaccionesProgresoState extends State<ReaccionesProgreso> {
  late LecturaAmistad _lectura = widget.lectura;
  bool _guardando = false;

  @override
  void didUpdateWidget(covariant ReaccionesProgreso oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lectura.libraryId != widget.lectura.libraryId) {
      _lectura = widget.lectura;
    }
  }

  Future<ReaccionComentario?> _elegir() =>
      showModalBottomSheet<ReaccionComentario>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (context) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reaccionar a su lectura', style: AppTextStyles.section),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final r in ReaccionComentario.values)
                    ActionChip(
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      label: Text('${r.emoji}  ${r.titulo}'),
                      onPressed: () => Navigator.pop(context, r),
                    ),
                ],
              ),
            ],
          ),
        ),
      );

  /// Cambio local inmediato mientras se guarda (si repites tu reacción, se quita).
  LecturaAmistad _local(LecturaAmistad l, ReaccionComentario r) {
    final cuentas = Map<ReaccionComentario, int>.from(l.reacciones);
    final anterior = l.miReaccion;
    if (anterior != null) cuentas[anterior] = (cuentas[anterior] ?? 1) - 1;
    final nueva = anterior == r ? null : r;
    if (nueva != null) cuentas[nueva] = (cuentas[nueva] ?? 0) + 1;
    return l.conReaccion(reacciones: cuentas, miReaccion: nueva);
  }

  Future<LecturaAmistad?> _guardar(
    LecturaAmistad l,
    ReaccionComentario r,
  ) async {
    final result = await ApiService().toggleProgressReaction(
      libraryId: l.libraryId,
      reaccion: r.apiValue,
    );
    if (result['ok'] != true) return null;
    final crudas = result['reacciones'] as Map? ?? const {};
    return l.conReaccion(
      reacciones: {
        for (final item in ReaccionComentario.values)
          item: (crudas[item.apiValue] as num?)?.toInt() ?? 0,
      },
      miReaccion: ReaccionComentarioDatos.fromApi(
        result['miReaccion']?.toString(),
      ),
    );
  }

  Future<void> _reaccionar() async {
    if (_guardando || _lectura.libraryId.isEmpty) return;
    final reaccion = await _elegir();
    if (reaccion == null || !mounted) return;
    final anterior = _lectura;
    setState(() {
      _guardando = true;
      _lectura = _local(anterior, reaccion);
    });
    LecturaAmistad? guardada;
    try {
      guardada = await (widget.reaccionar ?? _guardar)(anterior, reaccion);
    } catch (_) {
      guardada = null;
    }
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _lectura = guardada ?? anterior;
    });
    if (guardada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido guardar la reacción.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final entry in _lectura.reacciones.entries)
          if (entry.value > 0)
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text('${entry.key.emoji} ${entry.value}'),
            ),
        TextButton.icon(
          onPressed: _lectura.libraryId.isEmpty ? null : _reaccionar,
          icon: _lectura.miReaccion == null
              ? const Icon(Icons.add_reaction_outlined, size: 19)
              : Text(
                  _lectura.miReaccion!.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
          label: const Text('Reaccionar'),
        ),
      ],
    );
  }
}
