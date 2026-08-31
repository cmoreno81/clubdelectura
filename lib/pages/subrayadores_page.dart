import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import '../widgets/kit/rotulador_preview.dart';

class SubrayadoresPage extends StatelessWidget {
  final String libro;
  final String coverUrl;
  final List<Color> colores;

  const SubrayadoresPage({
    super.key,
    required this.libro,
    required this.coverUrl,
    required this.colores,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Subrayadores")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          40,
        ),
        children: [
          ClubCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            gradient: const LinearGradient(
              colors: [AppColors.surfaceSoft, Color(0xFFF7F3FF)],
            ),
            borderColor: AppColors.primaryLight,
            child: Column(
              children: [
                ClubBookCover(
                  title: libro,
                  imageUrl: coverUrl,
                  width: 145,
                  showShadow: true,
                ),

                const SizedBox(height: 24),

                Text(
                  libro,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(fontSize: 28),
                ),

                const SizedBox(height: 10),

                Text(
                  "Una propuesta para subrayar esta historia",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary,
                ),

                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(colores.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Transform.rotate(
                        angle: (index - 2) * 0.035,
                        child: RotuladorPreview(color: colores[index]),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Text(
            "Propuesta de uso",
            style: AppTextStyles.title.copyWith(fontSize: 28),
          ),

          const SizedBox(height: 18),

          _Categoria(
            color: colores[0],
            titulo: "Momentos favoritos",
            descripcion: "Escenas que quieres volver a leer.",
          ),

          _Categoria(
            color: colores[1],
            titulo: "Teorías",
            descripcion: "Ideas, sospechas y predicciones.",
          ),

          _Categoria(
            color: colores[2],
            titulo: "Citas",
            descripcion: "Frases que merecen quedarse contigo.",
          ),

          _Categoria(
            color: colores[3],
            titulo: "Personajes",
            descripcion: "Detalles importantes del mundo.",
          ),

          _Categoria(
            color: colores[4],
            titulo: "Impacto",
            descripcion: "Momentos que te dejaron sin respiración.",
          ),

          const SizedBox(height: 24),

          // ── Nota: uso en lecturas conjuntas ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFB8D0FF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💬', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'También en las lecturas conjuntas',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF3058C7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Estos colores estarán disponibles al escribir comentarios en los capítulos del libro. '
                        'Elige una categoría para que tu nota quede marcada con su color — '
                        'muy útil para que el club identifique de un vistazo si compartes una teoría, un personaje o un momento especial.',
                        style: AppTextStyles.bodySecondary.copyWith(
                          color: const Color(0xFF3058C7).withValues(alpha: .85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context, colores);
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Usar estos subrayadores"),
          ),

          const SizedBox(height: AppSpacing.xl),

          // ── Referencia de marca ──────────────────────────────────────────
          ClubCard(
            elevated: false,
            borderColor: const Color(0xFFE49A24).withValues(alpha: 0.28),
            backgroundColor: const Color(0xFFFFF8EC),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RotuladorPreview(
                        color: const Color(0xFFD4A1C7),
                        vertical: false,
                        length: 52,
                        thickness: 16,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      RotuladorPreview(
                        color: const Color(0xFF89B4C2),
                        vertical: false,
                        length: 52,
                        thickness: 16,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      RotuladorPreview(
                        color: const Color(0xFFA8C89A),
                        vertical: false,
                        length: 52,
                        thickness: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '¿Los quieres en físico?',
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Los Zebra Mildliner son el subrayador favorito de BookTok — punta dual (ancha + fina), 40 tonos pastel y sin manchar el papel fino. Los más usados en anotaciones de libros.',
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse(
                        'https://www.amazon.es/s?k=zebra+mildliner',
                      ),
                      mode: LaunchMode.externalApplication,
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Buscar Zebra Mildliner'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB07A1A),
                      side: const BorderSide(
                        color: Color(0xFFE49A24),
                        width: 1.2,
                      ),
                    ),
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

class _Categoria extends StatelessWidget {
  final Color color;
  final String titulo;
  final String descripcion;

  const _Categoria({
    required this.color,
    required this.titulo,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClubCard(
        elevated: false,
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            leading: RotuladorPreview(color: color, length: 68, thickness: 23),
            title: Text(titulo, style: AppTextStyles.subtitle),
            subtitle: Text(descripcion),
          ),
        ),
      ),
    );
  }
}
