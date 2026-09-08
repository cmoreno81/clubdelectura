import 'package:flutter/material.dart';

import '../../models/libro_finalizado.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/idioma_utils.dart';
import '../common/club_avatar.dart';
import '../common/club_card.dart';
import '../common/club_chip.dart';
import '../common/club_rating_selector.dart';
import '../common/club_rating_stars.dart';

/// Tarjeta "Tú" para un libro que ya terminaste: permite editar la
/// valoración, el picante y el idioma sin cambiar el estado de lectura ni
/// crear una relectura — a diferencia de "Otra vuelta", que sí crea un
/// registro nuevo.
class MiFichaLecturaCard extends StatefulWidget {
  const MiFichaLecturaCard({
    super.key,
    required this.finalizado,
    required this.onCambiado,
  });

  final LibroFinalizado finalizado;
  final VoidCallback onCambiado;

  @override
  State<MiFichaLecturaCard> createState() => _MiFichaLecturaCardState();
}

class _MiFichaLecturaCardState extends State<MiFichaLecturaCard> {
  late double _valoracion;
  late int? _picante;
  bool _guardandoValoracion = false;
  bool _guardandoPicante = false;
  bool _guardandoIdioma = false;

  @override
  void initState() {
    super.initState();
    _valoracion = ClubRatingStars.parseValoracion(widget.finalizado.valoracion);
    _picante = _parsePicante(widget.finalizado.picante);
  }

  @override
  void didUpdateWidget(covariant MiFichaLecturaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.finalizado.valoracion != widget.finalizado.valoracion) {
      _valoracion = ClubRatingStars.parseValoracion(widget.finalizado.valoracion);
    }
    if (oldWidget.finalizado.picante != widget.finalizado.picante) {
      _picante = _parsePicante(widget.finalizado.picante);
    }
  }

  static int? _parsePicante(String valor) {
    final nivel = '🌶️'.allMatches(valor).length;
    return nivel > 0 ? nivel : null;
  }

  Future<void> _guardarValoracion(double nueva) async {
    final anterior = _valoracion;
    setState(() {
      _valoracion = nueva;
      _guardandoValoracion = true;
    });
    try {
      final ok = await ApiService().actualizarValoracionLibro(
        bookId: widget.finalizado.bookId,
        valoracion: nueva.toString(),
      );
      if (!mounted) return;
      if (ok) {
        widget.onCambiado();
      } else {
        setState(() => _valoracion = anterior);
        _avisarError();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _valoracion = anterior);
      _avisarError();
    } finally {
      if (mounted) setState(() => _guardandoValoracion = false);
    }
  }

  Future<void> _guardarPicante(int? nuevo) async {
    final anterior = _picante;
    setState(() {
      _picante = nuevo;
      _guardandoPicante = true;
    });
    try {
      final ok = await ApiService().actualizarValoracionLibro(
        bookId: widget.finalizado.bookId,
        picante: nuevo?.toString() ?? '',
      );
      if (!mounted) return;
      if (ok) {
        widget.onCambiado();
      } else {
        setState(() => _picante = anterior);
        _avisarError();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _picante = anterior);
      _avisarError();
    } finally {
      if (mounted) setState(() => _guardandoPicante = false);
    }
  }

  Future<void> _elegirIdioma() async {
    final seleccionado = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Idioma de "${widget.finalizado.libro}"',
                  style: AppTextStyles.section,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'El idioma en el que TÚ leíste tu copia, si difiere del '
                  'de la ficha.',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final codigo in idiomasSoportados)
                        ListTile(
                          leading: Text(
                            banderaIdioma(codigo),
                            style: const TextStyle(fontSize: 22),
                          ),
                          title: Text(nombreIdioma(codigo)),
                          trailing: codigo == widget.finalizado.idioma
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => Navigator.pop(sheetContext, codigo),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (seleccionado == null || !mounted) return;

    setState(() => _guardandoIdioma = true);
    try {
      final resultado = await ApiService().actualizarIdiomaLibro(
        bookId: widget.finalizado.bookId,
        idioma: seleccionado,
      );
      if (!mounted) return;
      if (resultado['ok'] == true) {
        widget.onCambiado();
      } else {
        _avisarError();
      }
    } catch (_) {
      if (!mounted) return;
      _avisarError();
    } finally {
      if (mounted) setState(() => _guardandoIdioma = false);
    }
  }

  void _avisarError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se ha podido guardar el cambio')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppColors.surfaceSoft,
      borderColor: AppColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClubAvatar(
                nombre: widget.finalizado.usuario,
                imageUrl: widget.finalizado.avatarUrl,
                size: 48,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.finalizado.usuario,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        const ClubChip(
                          label: 'Tú',
                          icon: Icons.person_rounded,
                          variant: ClubChipVariant.primary,
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: ClubChip(
                        label: 'Historia terminada',
                        icon: Icons.check_circle_rounded,
                        variant: ClubChipVariant.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Mi valoración',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              ClubRatingSelector(
                valoracion: _valoracion,
                enabled: !_guardandoValoracion,
                starSize: 30,
                itemWidth: 34,
                onChanged: _guardarValoracion,
              ),
              if (_guardandoValoracion) ...[
                const SizedBox(width: AppSpacing.sm),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            '🌶️ Picante',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              for (var nivel = 1; nivel <= 5; nivel++)
                GestureDetector(
                  onTap: _guardandoPicante
                      ? null
                      : () => _guardarPicante(_picante == nivel ? null : nivel),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Text(
                      '🌶️',
                      style: TextStyle(
                        fontSize: 26,
                        color: _picante != null && nivel <= _picante!
                            ? null
                            : Colors.black.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                ),
              if (_guardandoPicante) ...[
                const SizedBox(width: AppSpacing.sm),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Idioma que leí',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _guardandoIdioma ? null : _elegirIdioma,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    banderaIdioma(widget.finalizado.idioma),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    widget.finalizado.idioma.isEmpty
                        ? 'Sin especificar'
                        : nombreIdioma(widget.finalizado.idioma),
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (_guardandoIdioma)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
