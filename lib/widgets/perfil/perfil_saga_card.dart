import 'package:flutter/material.dart';
import '../common/onboarding_tutorial.dart';

import '../../models/perfil_usuario.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../common/club_book_cover.dart';
import '../common/club_card.dart';

class PerfilSagaCard extends StatelessWidget {
  const PerfilSagaCard({
    super.key,
    required this.saga,
    this.onContinue,
    this.onCompleteCatalog,
    this.onGapTap,
    this.onEditVolume,
    this.onEditSeries,
  });

  final PerfilSaga saga;
  final ValueChanged<PerfilSagaVolumen>? onContinue;
  final VoidCallback? onCompleteCatalog;
  final ValueChanged<PerfilSagaVolumen>? onGapTap;
  final ValueChanged<PerfilSagaVolumen>? onEditVolume;
  final VoidCallback? onEditSeries;

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
                  if (onEditSeries != null)
                    IconButton(
                      tooltip: 'Editar datos de la saga',
                      visualDensity: VisualDensity.compact,
                      onPressed: onEditSeries,
                      icon: const Icon(Icons.edit_outlined, size: 19),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (var index = 0; index < saga.totalSaga; index++)
                Builder(
                  key: ValueKey(index),
                  builder: (_) {
                    final vol = _volumeAt(index + 1);
                    final esHueco =
                        vol == null ||
                        vol.esNoAnadido ||
                        vol.esLeidoExterno ||
                        vol.esOmitido;
                    return _VolumeSquare(
                      index: index,
                      volume: vol,
                      onTap: vol != null && !esHueco && onEditVolume != null
                          ? () => onEditVolume!(vol)
                          : esHueco && onGapTap != null
                          ? () {
                              // Creamos un volumen virtual para el hueco
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
                              onGapTap!(gap);
                            }
                          : null,
                    );
                  },
                ),
            ],
          ),
          if (onCompleteCatalog != null) ...[
            const SizedBox(height: AppSpacing.md),
            FeatureTooltip(
              featureKey: 'ft_complete_saga',
              message: 'Busca los tomos que te faltan en el catálogo',
              icon: Icons.auto_awesome_rounded,
              position: FeatureTooltipPosition.above,
              child: OutlinedButton.icon(
                onPressed: onCompleteCatalog,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Completar saga'),
              ),
            ),
          ],
          if (saga.siguiente != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: onContinue == null
                    ? null
                    : () => onContinue!(saga.siguiente!),
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
                      if (onContinue != null)
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

class _VolumeSquare extends StatelessWidget {
  const _VolumeSquare({required this.index, required this.volume, this.onTap});

  final int index;
  final PerfilSagaVolumen? volume;
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
        : AppColors.textSecondary;

    final number = volume?.posicion != null
        ? '${volume!.posicion}'
        : volume?.numero.isNotEmpty == true
        ? volume!.numero
        : '${index + 1}';
    return Tooltip(
      message: volume == null
          ? 'Volumen ${index + 1} aún no registrado'
          : '${volume!.titulo} · Volumen $number',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 48,
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: volume?.coverUrl.isNotEmpty == true
                      ? Image.network(
                          volume!.coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _coverPlaceholder(color, number),
                        )
                      : _coverPlaceholder(color, number),
                ),
              ),
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
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              if (read || reading || leidoExterno || omitido)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      color: omitido ? AppColors.textMuted : color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      read
                          ? Icons.check_rounded
                          : reading
                          ? Icons.auto_stories_rounded
                          : leidoExterno
                          ? Icons.history_edu_rounded
                          : Icons.block_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              // Borde discontinuo para LEIDO_EXTERNO
              if (leidoExterno)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: .5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder(Color color, String number) => Container(
    color: color.withValues(alpha: .1),
    alignment: Alignment.center,
    child: Text(
      number,
      style: TextStyle(color: color, fontWeight: FontWeight.w900),
    ),
  );
}
