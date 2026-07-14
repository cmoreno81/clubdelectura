import 'package:flutter/material.dart';

import '../models/lectura_activa.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/ui/club_metric.dart';
import 'configurar_lectura_page.dart';
import 'lectura_page.dart';

class LecturasPage extends StatefulWidget {
  const LecturasPage({super.key});

  @override
  State<LecturasPage> createState() => _LecturasPageState();
}

class _LecturasPageState extends State<LecturasPage> {
  late Future<List<LecturaActiva>> future;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    future = ApiService().getLecturasActivas();
  }

  Future<void> _refrescar() async {
    setState(_recargar);
    await future;
  }

  Future<void> _abrirLectura(LecturaActiva lectura) async {
    if (!lectura.configurada) {
      final creado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ConfigurarLecturaPage(libro: lectura.libro),
        ),
      );

      if (!mounted) return;

      if (creado == true) {
        setState(_recargar);
      }

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LecturaPage(libro: lectura.libro, coverUrl: lectura.coverUrl),
      ),
    );

    if (!mounted) return;

    setState(_recargar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lecturas')),
      body: FutureBuilder<List<LecturaActiva>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorLecturas(
              onRetry: () {
                setState(_recargar);
              },
            );
          }

          final lecturas = snapshot.data ?? const <LecturaActiva>[];

          if (lecturas.isEmpty) {
            return _LecturasVacias(onRefresh: _refrescar);
          }

          final oficiales = lecturas
              .where((lectura) => lectura.esOficial && lectura.configurada)
              .toList();

          final compartidas = lecturas
              .where((lectura) => !lectura.esOficial && lectura.configurada)
              .toList();

          final pendientes = lecturas
              .where((lectura) => !lectura.configurada)
              .toList();

          final mayorNumeroComentarios = lecturas.fold<int>(0, (
            mayor,
            lectura,
          ) {
            return lectura.comentarios > mayor ? lectura.comentarios : mayor;
          });

          bool esMasComentada(LecturaActiva lectura) {
            return mayorNumeroComentarios > 0 &&
                lectura.comentarios == mayorNumeroComentarios;
          }

          return RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                110,
              ),
              children: [
                _CabeceraLecturas(total: lecturas.length),

                const SizedBox(height: AppSpacing.xl),

                if (oficiales.isNotEmpty) ...[
                  const _SectionTitle(
                    icon: Icons.emoji_events_outlined,
                    color: AppColors.primary,
                    title: 'Lectura oficial',
                    subtitle: 'La historia elegida por el club',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  for (final lectura in oficiales) ...[
                    _LecturaCard(
                      lectura: lectura,
                      destacada: true,
                      masComentada: esMasComentada(lectura),
                      onTap: () => _abrirLectura(lectura),
                    ),

                    const SizedBox(height: AppSpacing.md),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                ],

                if (compartidas.isNotEmpty) ...[
                  const _SectionTitle(
                    icon: Icons.groups_2_outlined,
                    color: AppColors.info,
                    title: 'Lecturas compartidas',
                    subtitle: 'Historias que coinciden entre lectoras',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  for (final lectura in compartidas) ...[
                    _LecturaCard(
                      lectura: lectura,
                      masComentada: esMasComentada(lectura),
                      onTap: () => _abrirLectura(lectura),
                    ),

                    const SizedBox(height: AppSpacing.md),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                ],

                if (pendientes.isNotEmpty) ...[
                  const _SectionTitle(
                    icon: Icons.settings_outlined,
                    color: Color(0xFFB48113),
                    title: 'Pendientes de configurar',
                    subtitle: 'Estas lecturas todavía necesitan capítulos',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  for (final lectura in pendientes) ...[
                    _LecturaCard(
                      lectura: lectura,
                      onTap: () => _abrirLectura(lectura),
                    ),

                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CabeceraLecturas extends StatelessWidget {
  final int total;

  const _CabeceraLecturas({required this.total});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceSoft, Color(0xFFF1E8FF)],
      ),
      borderColor: AppColors.primaryLight,
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Lecturas del club',
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 29),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            total == 1
                ? 'Una historia está reuniendo al club alrededor de sus páginas.'
                : '$total historias están reuniendo al club alrededor de sus páginas.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(icon, color: color, size: 27),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.section.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                subtitle,
                style: AppTextStyles.bodySecondary.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LecturaCard extends StatelessWidget {
  final LecturaActiva lectura;
  final VoidCallback onTap;
  final bool destacada;
  final bool masComentada;

  const _LecturaCard({
    required this.lectura,
    required this.onTap,
    this.destacada = false,
    this.masComentada = false,
  });

  @override
  Widget build(BuildContext context) {
    final tieneActividad = lectura.ultimaActividad.trim().isNotEmpty;

    final colorPrincipal = destacada
        ? AppColors.primary
        : lectura.configurada
        ? AppColors.info
        : const Color(0xFFB48113);

    return ClubCard(
      elevated: destacada,
      padding: const EdgeInsets.all(AppSpacing.md),
      gradient: destacada
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8F3FF), Color(0xFFF1E8FF)],
            )
          : null,
      borderColor: destacada
          ? AppColors.primaryLight
          : lectura.configurada
          ? AppColors.border
          : const Color(0xFFF1E2B3),
      backgroundColor: lectura.configurada
          ? AppColors.surface
          : const Color(0xFFFFFBF0),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'book-${lectura.libro}',
                child: ClubBookCover(
                  title: lectura.libro,
                  imageUrl: lectura.coverUrl,
                  width: destacada ? 104 : 92,
                  showShadow: true,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lectura.libro,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: destacada ? 21 : 20,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (!lectura.configurada)
                          const ClubChip(
                            label: 'Pendiente',
                            icon: Icons.settings_outlined,
                            variant: ClubChipVariant.warning,
                          )
                        else if (lectura.esOficial)
                          const ClubChip(
                            label: 'Lectura oficial',
                            icon: Icons.emoji_events_outlined,
                            variant: ClubChipVariant.primary,
                          )
                        else
                          const ClubChip(
                            label: 'Compartida',
                            icon: Icons.groups_2_outlined,
                            variant: ClubChipVariant.info,
                          ),

                        if (masComentada)
                          const ClubChip(
                            label: 'Debate activo',
                            icon: Icons.local_fire_department_outlined,
                            variant: ClubChipVariant.danger,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right_rounded, color: colorPrincipal),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ClubMetric(
                icon: Icons.people_outline_rounded,
                value: '${lectura.lectoras}',
                label: lectura.lectoras == 1 ? 'lectora' : 'lectoras',
                variant: ClubMetricVariant.info,
                compact: true,
              ),

              ClubMetric(
                icon: Icons.chat_bubble_outline_rounded,
                value: '${lectura.comentarios}',
                label: lectura.comentarios == 1 ? 'comentario' : 'comentarios',
                variant: ClubMetricVariant.primary,
                compact: true,
              ),
            ],
          ),

          if (tieneActividad) ...[
            const SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(destacada ? 0.68 : 1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 17,
                    color: AppColors.textMuted,
                  ),

                  const SizedBox(width: AppSpacing.xs),

                  Expanded(
                    child: Text(
                      lectura.ultimaActividad,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (lectura.configurada) ...[
            const SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Todavía no hay comentarios. ¿Quién rompe el hielo?',
                style: AppTextStyles.caption.copyWith(height: 1.3),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Icon(
                lectura.configurada
                    ? Icons.auto_stories_outlined
                    : Icons.settings_outlined,
                size: 18,
                color: colorPrincipal,
              ),

              const SizedBox(width: AppSpacing.xs),

              Expanded(
                child: Text(
                  lectura.configurada ? 'Abrir lectura' : 'Configurar lectura',
                  style: AppTextStyles.body.copyWith(
                    color: colorPrincipal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Icon(Icons.chevron_right_rounded, color: colorPrincipal),
            ],
          ),
        ],
      ),
    );
  }
}

class _LecturasVacias extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _LecturasVacias({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_stories_outlined,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Todavía no hay lecturas compartidas',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.section,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    const Text(
                      'Cuando el club empiece una historia, aparecerá aquí.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorLecturas extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorLecturas({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: AppColors.textMuted,
            ),

            const SizedBox(height: AppSpacing.md),

            const Text(
              'No hemos podido cargar las lecturas.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.md),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
