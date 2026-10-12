import 'package:flutter/material.dart';

import '../../services/talento_semana_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/genero_utils.dart';
import '../common/club_book_cover.dart';
import '../common/club_card.dart';
import '../libros/talento_emergente.dart';

/// Tarjeta de Inicio con el libro de Talento emergente de la semana. Si esta
/// semana no hay ninguno (o falla la carga) no ocupa nada.
class TalentoDeLaSemanaCard extends StatefulWidget {
  const TalentoDeLaSemanaCard({super.key, required this.onAbrir, this.cargar});

  /// Abre la ficha del libro.
  final void Function(TalentoDeLaSemana libro) onAbrir;

  /// Para pruebas: sustituye la carga real.
  final Future<TalentoDeLaSemana?> Function()? cargar;

  @override
  State<TalentoDeLaSemanaCard> createState() => _TalentoDeLaSemanaCardState();
}

class _TalentoDeLaSemanaCardState extends State<TalentoDeLaSemanaCard>
    with AutomaticKeepAliveClientMixin {
  TalentoDeLaSemana? _libro;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final libro = await (widget.cargar ?? TalentoSemanaService().cargar)();
      if (!mounted) return;
      setState(() => _libro = libro);
    } catch (_) {
      // Sin red o sin libro destacado: la tarjeta simplemente no sale.
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final libro = _libro;
    if (libro == null) return const SizedBox.shrink();

    final generos = libro.generos
        .map((g) => '${iconoGenero(g)} $g')
        .join('  ·  ');

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: ClubCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: SelloTalentoEmergente.color.withValues(alpha: 0.06),
        borderColor: SelloTalentoEmergente.color.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SelloTalentoEmergente(compacto: true),
                const Spacer(),
                Text('Talento de la semana', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () => widget.onAbrir(libro),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClubBookCover(
                    title: libro.titulo,
                    imageUrl: libro.coverUrl,
                    width: 88,
                    showShadow: true,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          libro.titulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.section,
                        ),
                        if (libro.autoria.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            libro.autoria,
                            style: AppTextStyles.bodySecondary.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (generos.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            generos,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        if (libro.nota.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            '«${libro.nota.trim()}»',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySecondary.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => widget.onAbrir(libro),
                child: const Text('Descubrir este libro'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
