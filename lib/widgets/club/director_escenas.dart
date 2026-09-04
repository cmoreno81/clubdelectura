import 'package:flutter/material.dart';

import '../../models/dashboard.dart';
import '../../models/estado_club.dart';
import '../../navigation/app_page_route.dart';
import '../../pages/configurar_lectura_page.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../lectura/fecha_relativa.dart';
import '../common/club_book_cover.dart';
import '../common/club_chip.dart';
import '../common/selector_libro_sheet.dart';
import 'escenas/escena_votacion.dart';

class DirectorEscenas {
  Widget construir({
    required EstadoClub estado,
    required Dashboard dashboard,
  }) {
    final esAdmin = dashboard.clubvision.esAdmin;
    final totalMiembros = dashboard.clubvision.totalUsuarios;

    switch (estado.contenido) {
      case ContenidoClub.preparando:
        return _preparando();

      case ContenidoClub.sinCandidatas:
        return _sinCandidatas(esAdmin: esAdmin, totalMiembros: totalMiembros);

      case ContenidoClub.candidatas:
        return EscenaVotacion(
          totalCandidatas: dashboard.clubvision.totalCandidatas,
          portadas: dashboard.clubvision.portadasCandidatas,
        );

      case ContenidoClub.ganador:
        // Si no hay ganadora (mes sin candidatos suficientes) no mostramos la Gala
        if (dashboard.clubvision.ganador.trim().isEmpty) {
          return _sinGalaEsteMes();
        }
        return _ganador(dashboard);

      case ContenidoClub.lectura:
        return _lectura(dashboard, esAdmin: esAdmin, totalMiembros: totalMiembros);
    }
  }

  Widget _sinCandidatas({required bool esAdmin, required int totalMiembros}) {
    // Clubs pequeños (≤5 miembros) o admin pueden configurar lectura directamente
    final esClubPequeno = totalMiembros > 0 && totalMiembros <= 5;
    final mostrarPropuesta = esClubPequeno || esAdmin;

    return Builder(
      builder: (context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .6),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.library_books_outlined,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Sin libros candidatos este mes',
              style: AppTextStyles.section.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              esClubPequeno
                  ? 'En clubes pequeños podéis proponer una lectura directamente, '
                    'sin necesidad de votar.'
                  : 'Para que Clubvisión se abra, al menos dos miembros del club deben '
                    'tener el mismo libro en estado "En mi estantería".',
              style: AppTextStyles.bodySecondary.copyWith(height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (mostrarPropuesta) ...[
              _BotonConfigurarLectura(
                etiqueta: esClubPequeno
                    ? 'Proponer lectura'
                    : 'Configurar lectura',
                icono: esClubPequeno
                    ? Icons.menu_book_rounded
                    : Icons.settings_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (!esClubPequeno) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.tips_and_updates_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Añade libros pendientes y comenta los que te interesan',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _preparando() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
            size: 30,
          ),

          SizedBox(height: AppSpacing.sm),

          Text(
            'La próxima lectura',
            textAlign: TextAlign.center,
            style: AppTextStyles.section,
          ),

          SizedBox(height: AppSpacing.xs),

          Text(
            'Muy pronto conoceremos los libros candidatos.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }

  Widget _ganador(Dashboard dashboard) {
    final totalVotos = dashboard.clubvision.votosRecibidos;
    final totalMiembros = dashboard.clubvision.totalUsuarios;
    final participacion = totalMiembros > 0
        ? (totalVotos / totalMiembros * 100).round()
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8E6), Color(0xFFFFF0C0)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: const Color(0xFFE4B63F).withValues(alpha: .5),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _statItem('$totalVotos', 'votos recibidos', Icons.how_to_vote_outlined)),
          Container(
            width: 1,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            color: const Color(0xFFE4B63F).withValues(alpha: .4),
          ),
          Expanded(child: _statItem('$participacion%', '', Icons.people_outline_rounded)),
          Container(
            width: 1,
            height: 44,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            color: const Color(0xFFE4B63F).withValues(alpha: .4),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded, color: Color(0xFFB48113), size: 18),
                const SizedBox(height: 4),
                Text(
                  '¡Descubre el ganador!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: const Color(0xFF7A5A00),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFFB48113), size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.title.copyWith(
            fontSize: 22,
            color: const Color(0xFF5A3E00),
            fontWeight: FontWeight.w900,
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: const Color(0xFF9A7A20),
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }

  Widget _lectura(Dashboard dashboard, {required bool esAdmin, required int totalMiembros}) {
    final lectura = dashboard.lecturaActual;
    // Sin lectura oficial — cada lectora va a su ritmo
    if (lectura.titulo.trim().isEmpty) {
      final esClubPequeno = totalMiembros > 0 && totalMiembros <= 5;
      final mostrarBoton = esClubPequeno || esAdmin;

      // Calcular el libro más leído entre los miembros del club
      final conteo = <String, ({LecturaAhoraItem item, int lectores})>{};
      for (final miembro in dashboard.leyendoAhora) {
        for (final item in miembro.lecturas) {
          if (item.titulo.trim().isEmpty) continue;
          final key = item.bookId.isNotEmpty ? item.bookId : item.titulo;
          final prev = conteo[key];
          conteo[key] = (item: item, lectores: (prev?.lectores ?? 0) + 1);
        }
      }
      // Libro con más lectores, al menos 1
      final masLeido = conteo.values.isEmpty
          ? null
          : conteo.values.reduce((a, b) => a.lectores >= b.lectores ? a : b);

      return Builder(
        builder: (context) => Column(
          children: [
            // ── Libro más leído del club ────────────────────────────────
            if (masLeido != null) ...[
              _LibroMasLeidoCard(
                item: masLeido.item,
                lectores: masLeido.lectores,
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Explicación: sin Clubvisión activo ──────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.mic_none_rounded,
                    color: AppColors.textMuted,
                    size: 32,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Clubvisión en pausa',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.section.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    esClubPequeno
                        ? 'No hay edición de Clubvisión activa. '
                          'Podéis proponer una lectura directamente.'
                        : 'No hay edición de Clubvisión activa este mes. '
                          'Mientras tanto, cada miembro lee a su ritmo.',
                    style: AppTextStyles.bodySecondary.copyWith(height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  if (mostrarBoton) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _BotonConfigurarLectura(
                      etiqueta: esClubPequeno ? 'Proponer lectura' : 'Configurar lectura',
                      icono: esClubPequeno ? Icons.menu_book_rounded : Icons.settings_rounded,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .88),
            const Color(0xFFEDE3FF).withValues(alpha: .82),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primary.withValues(alpha: .14)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClubBookCover(
                title: lectura.titulo,
                imageUrl: lectura.coverUrl,
                width: 105,
                showShadow: true,
                heroTag: 'lectura-actual-${lectura.titulo}',
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EL LIBRO DEL CLUB',
                      style: TextStyle(
                        color: AppColors.inkCoral,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      lectura.titulo,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.section.copyWith(
                        fontSize: 20,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        ClubChip(
                          label: '${lectura.totalLeyendo} leyendo',
                          icon: Icons.people_outline_rounded,
                          variant: ClubChipVariant.info,
                        ),
                        ClubChip(
                          label: '${lectura.totalFinalizado} terminaron',
                          icon: Icons.check_circle_outline_rounded,
                          variant: ClubChipVariant.success,
                        ),
                        if (lectura.comentarios > 0)
                          ClubChip(
                            label: '${lectura.comentarios} comentarios',
                            icon: Icons.chat_bubble_outline_rounded,
                            variant: ClubChipVariant.primary,
                          ),
                        if (lectura.likes > 0)
                          ClubChip(
                            label: '${lectura.likes} reacciones',
                            icon: Icons.favorite_border_rounded,
                            variant: ClubChipVariant.danger,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (lectura.ultimaActividad?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .64),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      FechaRelativa.formato(lectura.ultimaActividad),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined, size: 18, color: Colors.white),
                SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    'Entrar al rincón de lectura',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sinGalaEsteMes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: AppColors.textMuted,
            size: 36,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Este mes no hay Gala',
            textAlign: TextAlign.center,
            style: AppTextStyles.section.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No hubo candidatos suficientes para votar. '
            'La próxima edición arrancará el mes que viene.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Botón + bottom sheet para proponer / configurar una lectura directamente
// ─────────────────────────────────────────────

class _BotonConfigurarLectura extends StatelessWidget {
  const _BotonConfigurarLectura({
    required this.etiqueta,
    required this.icono,
  });

  final String etiqueta;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _mostrarSelector(context),
        icon: Icon(icono, size: 18),
        label: Text(etiqueta),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: .6)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: AppTextStyles.subtitle.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarSelector(BuildContext context) async {
    final controller = TextEditingController();
    final resultado = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => SelectorLibroSheet(controller: controller),
    );

    if (resultado != null && resultado.trim().isNotEmpty && context.mounted) {
      await Navigator.push(
        context,
        AppPageRoute(
          builder: (_) => ConfigurarLecturaPage(
            libro: resultado.trim(),
            tipo: 'OFICIAL',
          ),
        ),
      );
    }
  }
}


// ── Tarjeta: libro más leído del club este mes ────────────────────────────────

class _LibroMasLeidoCard extends StatelessWidget {
  const _LibroMasLeidoCard({required this.item, required this.lectores});

  final LecturaAhoraItem item;
  final int lectores;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF5C7A6B); // verde musgo suave, lector libre
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: .92),
            const Color(0xFFE8F0EC).withValues(alpha: .75),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: accent.withValues(alpha: .18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Portada
          if (item.coverUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: ClubBookCover(
                title: item.titulo,
                imageUrl: item.coverUrl,
                width: 52,
                height: 76,
              ),
            )
          else
            Container(
              width: 52,
              height: 76,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.auto_stories_outlined, color: accent, size: 26),
            ),

          const SizedBox(width: AppSpacing.md),

          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClubChip(
                  label: lectores == 1
                      ? '1 miembro leyendo'
                      : '$lectores miembros leyendo',
                  variant: ClubChipVariant.neutral,
                  icon: Icons.people_alt_outlined,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
