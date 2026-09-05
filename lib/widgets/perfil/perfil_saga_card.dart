import 'package:flutter/material.dart';
import '../common/onboarding_tutorial.dart';

import '../../models/perfil_usuario.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../common/club_book_cover.dart';
import '../common/club_card.dart';
import '../common/optimized_network_image.dart';

class PerfilSagaCard extends StatefulWidget {
  const PerfilSagaCard({
    super.key,
    required this.saga,
    this.onContinue,
    this.onCompleteCatalog,
    this.onGapTap,
    this.onEditVolume,
    this.onAddToLibrary,
    this.onEditSeries,
    this.onHideSeries,
    this.onReorderVolumes,
    this.onRemoveSeries,
  });

  final PerfilSaga saga;
  final ValueChanged<PerfilSagaVolumen>? onContinue;
  final VoidCallback? onCompleteCatalog;
  final ValueChanged<PerfilSagaVolumen>? onGapTap;
  final ValueChanged<PerfilSagaVolumen>? onEditVolume;

  /// Libro en ClubReads pero NO en la biblioteca del usuario
  final ValueChanged<PerfilSagaVolumen>? onAddToLibrary;

  final VoidCallback? onEditSeries;
  final VoidCallback? onHideSeries;
  final VoidCallback? onRemoveSeries;

  /// Llamado con la nueva lista ordenada de volúmenes (solo los que tienen bookId)
  final Future<void> Function(List<PerfilSagaVolumen> newOrder)?
  onReorderVolumes;

  @override
  State<PerfilSagaCard> createState() => _PerfilSagaCardState();
}

class _PerfilSagaCardState extends State<PerfilSagaCard> {
  bool _reordering = false;
  bool _saving = false;

  late List<PerfilSagaVolumen> _orderedVolumes;

  @override
  void initState() {
    super.initState();
    _orderedVolumes = _realVolumes();
  }

  @override
  void didUpdateWidget(PerfilSagaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_reordering) {
      _orderedVolumes = _realVolumes();
    }
  }

  List<PerfilSagaVolumen> _realVolumes() =>
      widget.saga.volumenes.where((v) => v.bookId.isNotEmpty).toList();

  PerfilSaga get saga => widget.saga;

  void _toggleReorder() {
    setState(() {
      _reordering = !_reordering;
      if (!_reordering) _orderedVolumes = _realVolumes();
    });
  }

  Future<void> _saveOrder() async {
    if (widget.onReorderVolumes == null) return;
    setState(() => _saving = true);
    try {
      await widget.onReorderVolumes!(_orderedVolumes);
      if (mounted) setState(() => _reordering = false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = saga.completada
        ? const Color(0xFFD39B24)
        : saga.alDia
        ? AppColors.success
        : saga.pendiente
        ? AppColors.warning
        : AppColors.primary;
    final estado = saga.completada
        ? 'Completada'
        : saga.alDia
        ? 'Al día'
        : saga.pendiente
        ? 'Pendiente'
        : 'En curso';

    return ClubCard(
      elevated: false,
      borderColor: accent.withValues(alpha: .32),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, accent.withValues(alpha: .08)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      saga.nombre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      saga.totalSaga > saga.totalConocidos
                          ? '${saga.totalConocidos} publicados'
                                ' · ${saga.leidos} leídos'
                                ' · ${saga.totalSaga} previstos'
                          : '${saga.totalConocidos} publicados'
                                ' · ${saga.leidos} leídos',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      estado,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.onReorderVolumes != null &&
                          _orderedVolumes.length >= 2)
                        IconButton(
                          tooltip: _reordering
                              ? 'Cancelar reordenar'
                              : 'Reordenar volúmenes',
                          visualDensity: VisualDensity.compact,
                          onPressed: _toggleReorder,
                          icon: Icon(
                            _reordering
                                ? Icons.close_rounded
                                : Icons.swap_vert_rounded,
                            size: 19,
                            color: _reordering
                                ? AppColors.danger
                                : AppColors.textSecondary,
                          ),
                        ),
                      if (widget.onEditSeries != null)
                        IconButton(
                          tooltip: 'Editar datos de la saga',
                          visualDensity: VisualDensity.compact,
                          onPressed: widget.onEditSeries,
                          icon: const Icon(Icons.edit_outlined, size: 19),
                        ),
                      if (widget.onHideSeries != null)
                        IconButton(
                          tooltip: 'Ocultar saga',
                          visualDensity: VisualDensity.compact,
                          onPressed: widget.onHideSeries,
                          icon: const Icon(
                            Icons.visibility_off_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                      // Justo antes o después del icono de ocultar:
                      if (widget.onRemoveSeries != null)
                        IconButton(
                          tooltip: 'Eliminar saga',
                          visualDensity: VisualDensity.compact,
                          onPressed: widget.onRemoveSeries,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: AppColors.danger,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Volúmenes: modo normal o modo reordenar ──
          if (_reordering)
            _ReorderableVolumeList(
              volumes: _orderedVolumes,
              saving: _saving,
              accent: accent,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  final item = _orderedVolumes.removeAt(oldIndex);
                  _orderedVolumes.insert(newIndex, item);
                });
              },
              onSave: _saveOrder,
            )
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (var index = 0; index < saga.totalSaga; index++)
                  Builder(
                    key: ValueKey(index),
                    builder: (_) {
                      final vol = _volumeAt(index + 1);

                      // Caso 1: hueco real (no en ClubReads, o marcado especial)
                      // Un volumen con bookId real y estado NO_ANADIDO NO es hueco:
                      // está en el catálogo pero aún no está en la biblioteca.
                      final esHueco =
                          vol == null ||
                          vol.bookId.isEmpty ||
                          vol.esLeidoExterno ||
                          vol.esOmitido;

                      // Caso 2: en ClubReads pero NO en mi biblioteca
                      final enClubReadsNoEnBiblioteca =
                          vol != null &&
                          vol.bookId.isNotEmpty &&
                          vol.esNoAnadido;

                      VoidCallback? tapCallback;
                      if (vol != null &&
                          !esHueco &&
                          !enClubReadsNoEnBiblioteca) {
                        // Tiene estado → editar volumen
                        if (widget.onEditVolume != null) {
                          tapCallback = () => widget.onEditVolume!(vol);
                        }
                      } else if (enClubReadsNoEnBiblioteca) {
                        // Está en ClubReads pero no en mi biblioteca → añadir
                        if (widget.onAddToLibrary != null) {
                          tapCallback = () => widget.onAddToLibrary!(vol);
                        }
                      } else if (esHueco) {
                        // No en ClubReads → gap tap (override o completar)
                        if (widget.onGapTap != null) {
                          final gap =
                              vol ??
                              PerfilSagaVolumen(
                                bookId: '',
                                titulo: 'Tomo ${index + 1}',
                                numero: '${index + 1}',
                                posicion: index + 1,
                                coverUrl: '',
                                estado: 'NO_ANADIDO',
                              );
                          tapCallback = () => widget.onGapTap!(gap);
                        }
                      }

                      return _VolumeSquare(
                        index: index,
                        volume: vol,
                        enClubReadsNoEnBiblioteca: enClubReadsNoEnBiblioteca,
                        onTap: tapCallback,
                      );
                    },
                  ),
              ],
            ),

          // ── Completar saga ──
          if (!_reordering && widget.onCompleteCatalog != null) ...[
            const SizedBox(height: AppSpacing.md),
            FeatureTooltip(
              featureKey: 'ft_complete_saga',
              message: 'Añade de golpe todos los tomos que aún no tienes en tu biblioteca',
              icon: Icons.auto_awesome_rounded,
              position: FeatureTooltipPosition.above,
              child: OutlinedButton.icon(
                onPressed: widget.onCompleteCatalog,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Completar saga'),
              ),
            ),
          ],

          // ── Siguiente para continuar ──
          if (!_reordering && saga.siguiente != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: widget.onContinue == null
                    ? null
                    : () => widget.onContinue!(saga.siguiente!),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .82),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: accent.withValues(alpha: .18)),
                  ),
                  child: Row(
                    children: [
                      ClubBookCover(
                        title: saga.siguiente!.titulo,
                        imageUrl: saga.siguiente!.coverUrl,
                        width: 44,
                        height: 64,
                        showShadow: false,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              saga.siguiente!.estado == 'LEYENDO'
                                  ? 'Leyendo ahora'
                                  : 'Siguiente para continuar',
                              style: TextStyle(
                                color: accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              saga.siguiente!.titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.onContinue != null)
                        Icon(Icons.arrow_forward_rounded, color: accent),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  PerfilSagaVolumen? _volumeAt(int position) {
    for (final volume in saga.volumenes) {
      if (volume.posicion == position) return volume;
    }
    return null;
  }
}

// ─── Lista reordenable ───────────────────────────────────────────

class _ReorderableVolumeList extends StatelessWidget {
  const _ReorderableVolumeList({
    required this.volumes,
    required this.saving,
    required this.accent,
    required this.onReorder,
    required this.onSave,
  });

  final List<PerfilSagaVolumen> volumes;
  final bool saving;
  final Color accent;
  final void Function(int oldIndex, int newIndex) onReorder;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: .5),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                size: 16,
                color: AppColors.primaryDark,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Arrastra los tomos para cambiar el orden visual. '
                  'No afecta a tus fechas ni valoraciones.',
                  style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: volumes.length,
          onReorderItem: onReorder,
          proxyDecorator: (child, index, animation) => Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: child,
          ),
          itemBuilder: (context, index) {
            final vol = volumes[index];
            final status = vol.estado;
            final read = status == 'LEIDO' || status == 'LEIDO_EXTERNO';
            final reading = status == 'LEYENDO';
            final color = read
                ? AppColors.primary
                : reading
                ? AppColors.info
                : status == 'OMITIDO'
                ? AppColors.textMuted
                : AppColors.textSecondary;

            return Container(
              key: ValueKey(vol.bookId),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: color.withValues(alpha: .25)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.md - 1),
                      bottomLeft: Radius.circular(AppRadius.md - 1),
                    ),
                    child: SizedBox(
                      width: 36,
                      height: 52,
                      child: OptimizedNetworkImage(
                        url: vol.coverUrl,
                        width: 36,
                        height: 52,
                        fallback: _placeholder(color, '${index + 1}'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      vol.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(saving ? 'Guardando…' : 'Guardar orden'),
          ),
        ),
      ],
    );
  }

  Widget _placeholder(Color color, String number) {
    return Container(
      color: color.withValues(alpha: .1),
      alignment: Alignment.center,
      child: Text(
        number,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: color,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ─── Cuadrado de volumen (modo normal) ──────────────────────────

class _VolumeSquare extends StatelessWidget {
  const _VolumeSquare({
    required this.index,
    required this.volume,
    required this.enClubReadsNoEnBiblioteca,
    this.onTap,
  });

  final int index;
  final PerfilSagaVolumen? volume;
  final bool enClubReadsNoEnBiblioteca;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = volume?.estado ?? 'DESCONOCIDO';
    final read = status == 'LEIDO';
    final reading = status == 'LEYENDO';
    final pending = status == 'PENDIENTE';
    final leidoExterno = status == 'LEIDO_EXTERNO';
    final omitido = status == 'OMITIDO';

    final color = read || leidoExterno
        ? AppColors.primary
        : reading
        ? AppColors.info
        : pending
        ? AppColors.warning
        : omitido
        ? AppColors.textMuted
        : enClubReadsNoEnBiblioteca
        ? AppColors.primary.withValues(alpha: .4)
        : AppColors.textSecondary;

    final number = volume?.posicion != null
        ? '${volume!.posicion}'
        : volume?.numero.isNotEmpty == true
        ? volume!.numero
        : '${index + 1}';

    String tooltipMsg;
    if (volume == null) {
      tooltipMsg = 'Volumen ${index + 1} aún no registrado';
    } else if (enClubReadsNoEnBiblioteca) {
      tooltipMsg = '${volume!.titulo} · Pulsa para añadir a tu biblioteca';
    } else {
      tooltipMsg = '${volume!.titulo} · Volumen $number';
    }

    return Tooltip(
      message: tooltipMsg,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 48,
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Portada
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: OptimizedNetworkImage(
                    url: volume?.coverUrl,
                    width: 48,
                    height: 72,
                    fallback: _coverPlaceholder(color, number),
                  ),
                ),
              ),
              // Borde
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: color,
                      width: reading ? 2.5 : 1.5,
                    ),
                  ),
                ),
              ),
              // Indicador de estado — esquina inferior derecha
              if (read || leidoExterno)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: _statusBadge(
                    color: color,
                    icon: Icons.check_rounded,
                    iconSize: 11,
                  ),
                ),
              if (reading)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: _statusBadge(
                    color: color,
                    icon: Icons.menu_book_rounded,
                    iconSize: 10,
                  ),
                ),
              if (pending)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: _statusBadge(
                    color: color,
                    icon: Icons.bookmark_rounded,
                    iconSize: 10,
                  ),
                ),
              // Indicador especial — esquina superior derecha. Con fondo de
              // color (como el resto de _statusBadge) en vez de un icono
              // suelto: sobre portadas con mucho color, un icono sin fondo
              // se pierde y no se distingue bien.
              if (omitido)
                Positioned(
                  top: 2,
                  right: 2,
                  child: _statusBadge(
                    color: color,
                    icon: Icons.block_rounded,
                    iconSize: 11,
                  ),
                ),
              if (leidoExterno)
                Positioned(
                  top: 2,
                  right: 2,
                  child: _statusBadge(
                    color: color,
                    icon: Icons.history_edu_rounded,
                    iconSize: 11,
                  ),
                ),
              // En ClubReads pero no en mi biblioteca → icono de añadir
              if (enClubReadsNoEnBiblioteca)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge({
    required Color color,
    required IconData icon,
    required double iconSize,
  }) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }

  Widget _coverPlaceholder(Color color, String number) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        number,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 16,
          color: color,
        ),
      ),
    );
  }
}
