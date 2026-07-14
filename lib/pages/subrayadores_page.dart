import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';

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
                  children: colores
                      .map(
                        (c) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 28,
                          height: 90,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                      .toList(),
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

          const SizedBox(height: 30),

          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context, colores);
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text("Usar estos subrayadores"),
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
        child: ListTile(
          leading: Container(
            width: 28,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          title: Text(titulo, style: AppTextStyles.subtitle),
          subtitle: Text(descripcion),
        ),
      ),
    );
  }
}
