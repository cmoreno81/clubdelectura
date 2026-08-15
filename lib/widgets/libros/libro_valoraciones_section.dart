import 'package:flutter/material.dart';

import '../../models/libro_finalizado.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_avatar.dart';
import '../common/club_card.dart';
import 'libro_section.dart';

class LibroValoracionesSection extends StatelessWidget {
  final List<LibroFinalizado> valoraciones;
  final double mediaValoracion;

  const LibroValoracionesSection({
    super.key,
    required this.valoraciones,
    required this.mediaValoracion,
  });

  @override
  Widget build(BuildContext context) {
    if (valoraciones.isEmpty) {
      return const SizedBox.shrink();
    }

    return LibroSection(
      icon: Icons.star_outline_rounded,
      color: AppColors.gold,
      title: 'Valoraciones',
      subtitle: valoraciones.length == 1
          ? 'Una persona ha valorado este libro'
          : '${valoraciones.length} personas han valorado este libro',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResumenValoraciones(
            media: mediaValoracion,
            total: valoraciones.length,
          ),

          const SizedBox(height: AppSpacing.lg),

          for (var index = 0; index < valoraciones.length; index++) ...[
            _ValoracionCard(valoracion: valoraciones[index]),

            if (index < valoraciones.length - 1)
              const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ResumenValoraciones extends StatelessWidget {
  final double media;
  final int total;

  const _ResumenValoraciones({required this.media, required this.total});

  @override
  Widget build(BuildContext context) {
    final mediaTexto = media > 0 ? media.toStringAsFixed(1) : '—';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9EA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1E2B3)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEDBA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Color(0xFFB48113),
              size: 30,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$mediaTexto / 5',
                  style: AppTextStyles.section.copyWith(
                    fontSize: 24,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  total == 1
                      ? '1 valoración del club'
                      : '$total valoraciones del club',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),

          _EstrellasCompactas(valoracion: media),
        ],
      ),
    );
  }
}

class _ValoracionCard extends StatefulWidget {
  final LibroFinalizado valoracion;

  const _ValoracionCard({required this.valoracion});

  @override
  State<_ValoracionCard> createState() => _ValoracionCardState();
}

class _ValoracionCardState extends State<_ValoracionCard> {
  bool resenaVisible = false;

  @override
  Widget build(BuildContext context) {
    final valoracion = widget.valoracion;
    final estrellas = _numeroEstrellas(valoracion.valoracion);
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClubAvatar(
                nombre: valoracion.usuario,
                imageUrl: valoracion.avatarUrl,
                size: 48,
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Text(
                  valoracion.usuario,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              _EstrellasCompactas(valoracion: estrellas),
            ],
          ),

          if (valoracion.resena.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: resenaVisible
                  ? Container(
                      key: const ValueKey('resena-visible'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.format_quote_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              valoracion.resena,
                              style: AppTextStyles.body.copyWith(
                                fontStyle: FontStyle.italic,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : InkWell(
                      key: const ValueKey('resena-oculta'),
                      onTap: () => setState(() => resenaVisible = true),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.midnight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              color: Colors.white,
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reflexión oculta',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Toca para revelar posibles spoilers.',
                                    style: TextStyle(color: Color(0xFFD9D4E5)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),

            Text(
              'Sin reseña escrita.',
              style: AppTextStyles.bodySecondary.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static double _numeroEstrellas(String valoracion) {
    final texto = valoracion.trim().replaceAll('⭐️', '⭐').replaceAll(',', '.');

    if (texto.isEmpty) {
      return 0;
    }

    if (texto == '😞') {
      return 0;
    }

    final numeroDirecto = double.tryParse(texto);

    if (numeroDirecto != null) {
      return (numeroDirecto * 2).round() / 2;
    }

    final estrellasCompletas = RegExp('⭐').allMatches(texto).length;

    final tieneMedia = texto.contains('½');

    final resultado = estrellasCompletas + (tieneMedia ? 0.5 : 0);

    return resultado.clamp(0, 5).toDouble();
  }
}

class _EstrellasCompactas extends StatelessWidget {
  final double valoracion;

  const _EstrellasCompactas({required this.valoracion});

  @override
  Widget build(BuildContext context) {
    final valor = ((valoracion.clamp(0, 5)).toDouble() * 2).round() / 2;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final inicioEstrella = index.toDouble();
        final valorDentro = valor - inicioEstrella;

        final IconData icono;

        if (valorDentro >= 1) {
          icono = Icons.star_rounded;
        } else if (valorDentro >= 0.5) {
          icono = Icons.star_half_rounded;
        } else {
          icono = Icons.star_border_rounded;
        }

        return Icon(icono, size: 19, color: const Color(0xFFB48113));
      }),
    );
  }
}
