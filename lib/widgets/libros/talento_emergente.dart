import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/libro_agrupado.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_card.dart';

/// Sello pequeño de los libros del programa «Talento emergente».
class SelloTalentoEmergente extends StatelessWidget {
  const SelloTalentoEmergente({super.key, this.compacto = false});

  final bool compacto;

  static const color = Color(0xFFB07A2A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacto ? 9 : 12,
        vertical: compacto ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '✨ Talento emergente',
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: compacto ? 11.5 : 12.5,
        ),
      ),
    );
  }
}

/// Tarjeta «De la autora»: su nota, el picante y los tropos que declara y el
/// enlace propio donde comprar o leer el libro. Solo aparece en libros con
/// sello de Talento emergente.
class TarjetaDeLaAutora extends StatelessWidget {
  const TarjetaDeLaAutora({super.key, required this.libro});

  final LibroAgrupado libro;

  Future<void> _abrirEnlace() async {
    var url = libro.enlaceAutora.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http')) url = 'https://$url';
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!libro.esTalentoEmergente) return const SizedBox.shrink();
    final nota = libro.notaAutora.trim();
    final tropos = libro.troposAutora;
    final picante = libro.picanteAutora;
    final enlace = libro.enlaceAutora.trim();
    if (nota.isEmpty && tropos.isEmpty && picante == null && enlace.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: ClubCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: SelloTalentoEmergente.color.withValues(alpha: 0.06),
        borderColor: SelloTalentoEmergente.color.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SelloTalentoEmergente(compacto: true),
            const SizedBox(height: AppSpacing.sm),
            Text('De la autora', style: AppTextStyles.section),
            if (nota.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '«$nota»',
                style: AppTextStyles.body.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            if (picante != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                picante == 0
                    ? '🌶️ Picante según la autora: sin escenas de contenido sexual'
                    : '🌶️ Picante según la autora: $picante de 5',
                style: AppTextStyles.bodySecondary,
              ),
            ],
            if (tropos.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final t in tropos)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(t, style: AppTextStyles.caption),
                    ),
                ],
              ),
            ],
            if (enlace.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _abrirEnlace,
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('Ver el libro de la autora'),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Enlace de la propia autora, no es de afiliado.',
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
