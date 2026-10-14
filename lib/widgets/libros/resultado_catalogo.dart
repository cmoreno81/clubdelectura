import 'package:flutter/material.dart';

import '../../models/catalog_book.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../common/optimized_network_image.dart';

/// Pastilla llamativa «En ClubReads»: el libro ya tiene ficha y gente leyéndolo.
class PastillaClubReads extends StatelessWidget {
  const PastillaClubReads({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'En ClubReads',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta discreta del origen de un resultado que aún NO está en ClubReads.
class EtiquetaFuenteExterna extends StatelessWidget {
  const EtiquetaFuenteExterna(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Tarjeta de un resultado de búsqueda. Los de ClubReads van destacados (borde y fondo de la
/// marca, pastilla llena y número de lectores) y los externos, neutros, para que la gente elija
/// primero lo que ya existe y no se creen fichas duplicadas.
class TarjetaResultadoCatalogo extends StatelessWidget {
  const TarjetaResultadoCatalogo({
    super.key,
    required this.book,
    required this.accion,
    required this.onTap,
    required this.onLongPress,
  });

  final CatalogBook book;

  /// Botón de añadir, indicador de «ya en tu biblioteca» o rueda de carga.
  final Widget accion;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  bool get _enClubReads => book.source == 'CLUBREADS';

  @override
  Widget build(BuildContext context) {
    final lectores = book.readers ?? 0;
    return Material(
      color: _enClubReads
          ? AppColors.primary.withValues(alpha: .06)
          : AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: _enClubReads
            ? BorderSide(
                color: AppColors.primary.withValues(alpha: .55),
                width: 1.5,
              )
            : const BorderSide(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 94,
                  child: OptimizedNetworkImage(
                    url: book.coverUrl,
                    width: 64,
                    height: 94,
                    fallback: Container(
                      color: AppColors.primary.withValues(alpha: .1),
                      child: const Icon(Icons.auto_stories_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.authorLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (_enClubReads) const PastillaClubReads(),
                        if (_enClubReads && lectores > 0)
                          Text(
                            lectores == 1 ? '1 lector' : '$lectores lectores',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (!_enClubReads)
                          EtiquetaFuenteExterna(book.sourceLabel),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              accion,
            ],
          ),
        ),
      ),
    );
  }
}

/// Cabecera de un grupo de resultados.
class CabeceraResultados extends StatelessWidget {
  const CabeceraResultados({
    super.key,
    required this.titulo,
    required this.subtitulo,
    this.destacada = false,
    this.total,
  });

  final String titulo;
  final String subtitulo;
  final bool destacada;
  final int? total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (destacada) ...[
                const Icon(
                  Icons.verified_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                total == null ? titulo : '$titulo ($total)',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: destacada ? 18 : 16,
                  color: destacada
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
