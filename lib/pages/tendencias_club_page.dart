import 'package:flutter/material.dart';

import '../models/tendencias_club.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/error_view.dart';
import 'perfil_usuario_page.dart';

class TendenciasClubPage extends StatefulWidget {
  const TendenciasClubPage({super.key});

  @override
  State<TendenciasClubPage> createState() => _TendenciasClubPageState();
}

class _TendenciasClubPageState extends State<TendenciasClubPage> {
  late Future<TendenciasClub> future;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    future = ApiService().getTendenciasClub();
  }

  Future<void> _refrescar() async {
    setState(_recargar);
    await future;
  }

  void _abrirPerfil(String usuario) {
    final nombre = usuario.trim();

    if (nombre.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PerfilUsuarioPage(usuario: nombre)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tendencias')),
      body: FutureBuilder<TendenciasClub>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorView(
              onRetry: () {
                setState(_recargar);
              },
            );
          }

          final data = snapshot.data!;

          final maxGenero = _max(data.generos);
          final maxLibro = _max(data.libros);

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
                _TendenciasHeader(data: data),

                if (data.generos.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),

                  const _SectionHeader(
                    icon: Icons.sell_outlined,
                    color: AppColors.success,
                    title: 'Géneros en tendencia',
                    subtitle: 'Las historias que más están atrapando al club',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  ClubCard(
                    elevated: false,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < data.generos.length;
                          index++
                        ) ...[
                          _GeneroItem(
                            posicion: index,
                            item: data.generos[index],
                            maximo: maxGenero,
                          ),

                          if (index < data.generos.length - 1)
                            const Divider(
                              height: 1,
                              indent: AppSpacing.md,
                              endIndent: AppSpacing.md,
                            ),
                        ],
                      ],
                    ),
                  ),
                ],

                if (data.libros.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),

                  const _SectionHeader(
                    icon: Icons.local_fire_department_outlined,
                    color: Color(0xFFE98325),
                    title: 'Libros que están ardiendo',
                    subtitle: 'Las lecturas que más coinciden entre lectoras',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  for (var index = 0; index < data.libros.length; index++) ...[
                    _LibroTendenciaCard(
                      posicion: index,
                      item: data.libros[index],
                      maximo: maxLibro,
                    ),

                    const SizedBox(height: AppSpacing.md),
                  ],
                ],

                if (data.lectoras.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),

                  const _SectionHeader(
                    icon: Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    title: 'Quién marca tendencia',
                    subtitle: 'Las lectoras con más historias entre manos',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  ClubCard(
                    elevated: false,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < data.lectoras.length;
                          index++
                        ) ...[
                          _LectoraTendenciaItem(
                            posicion: index,
                            nombre: data.lectoras[index].nombre,
                            total: data.lectoras[index].total,
                            onTap: () =>
                                _abrirPerfil(data.lectoras[index].nombre),
                          ),

                          if (index < data.lectoras.length - 1)
                            const Divider(
                              height: 1,
                              indent: AppSpacing.md,
                              endIndent: AppSpacing.md,
                            ),
                        ],
                      ],
                    ),
                  ),
                ],

                if (data.generos.isEmpty &&
                    data.libros.isEmpty &&
                    data.lectoras.isEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const _TendenciasVacias(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  int _max(List<TendenciaItem> items) {
    if (items.isEmpty) return 0;

    return items.map((item) => item.total).reduce((a, b) => a > b ? a : b);
  }
}

class _TendenciasHeader extends StatelessWidget {
  final TendenciasClub data;

  const _TendenciasHeader({required this.data});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF0FFF4), Color(0xFFEAF7F0)],
      ),
      borderColor: const Color(0xFFCDE8D5),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              color: Color(0xFFDDF2E4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: AppColors.success,
              size: 40,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Lo que está pasando',
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 29),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            data.titular.trim().isEmpty
                ? 'El club está repartido entre muchas historias.'
                : data.titular,
            textAlign: TextAlign.center,
            style: AppTextStyles.section.copyWith(
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),

          if (data.narrador.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),

            Text(
              data.narrador,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ClubChip(
                label:
                    '${data.totalLeyendo} ${data.totalLeyendo == 1 ? 'lectura activa' : 'lecturas activas'}',
                icon: Icons.auto_stories_outlined,
                variant: ClubChipVariant.success,
              ),

              if (data.generos.isNotEmpty)
                ClubChip(
                  label:
                      '${data.generos.length} ${data.generos.length == 1 ? 'género' : 'géneros'}',
                  icon: Icons.sell_outlined,
                  variant: ClubChipVariant.info,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SectionHeader({
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
            color: color.withValues(alpha: 0.13),
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

class _GeneroItem extends StatelessWidget {
  final int posicion;
  final TendenciaItem item;
  final int maximo;

  const _GeneroItem({
    required this.posicion,
    required this.item,
    required this.maximo,
  });

  @override
  Widget build(BuildContext context) {
    final progreso = maximo == 0 ? 0.0 : item.total / maximo;

    final destacado = posicion == 0;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: destacado
                      ? const Color(0xFFDDF2E4)
                      : AppColors.surfaceSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: destacado
                    ? const Icon(
                        Icons.trending_up_rounded,
                        color: AppColors.success,
                      )
                    : Text(
                        '${posicion + 1}',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nombre,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      item.total == 1 ? '1 lectora' : '${item.total} lectoras',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),

              Text(
                '${item.total}',
                style: AppTextStyles.section.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progreso.clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: AppColors.success.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibroTendenciaCard extends StatelessWidget {
  final int posicion;
  final TendenciaItem item;
  final int maximo;

  const _LibroTendenciaCard({
    required this.posicion,
    required this.item,
    required this.maximo,
  });

  @override
  Widget build(BuildContext context) {
    final progreso = maximo == 0 ? 0.0 : item.total / maximo;

    final primero = posicion == 0;

    return ClubCard(
      elevated: primero,
      padding: const EdgeInsets.all(AppSpacing.lg),
      gradient: primero
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8EC), Color(0xFFFFF0D8)],
            )
          : null,
      backgroundColor: primero ? null : AppColors.surface,
      borderColor: primero ? const Color(0xFFF1D7A8) : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primero
                      ? const Color(0xFFFFE6BD)
                      : const Color(0xFFFFF2E3),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  primero
                      ? Icons.local_fire_department_rounded
                      : Icons.auto_stories_outlined,
                  color: const Color(0xFFE98325),
                  size: 29,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Text(
                  item.nombre,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.section.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),

              if (primero)
                const ClubChip(
                  label: 'En llamas',
                  icon: Icons.local_fire_department_rounded,
                  variant: ClubChipVariant.warning,
                )
              else
                Text(
                  '#${posicion + 1}',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              ClubChip(
                label: item.total == 1 ? '1 lectora' : '${item.total} lectoras',
                icon: Icons.groups_2_outlined,
                variant: ClubChipVariant.info,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progreso.clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: const Color(0xFFE98325).withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFE98325),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LectoraTendenciaItem extends StatelessWidget {
  final int posicion;
  final String nombre;
  final int total;
  final VoidCallback onTap;

  const _LectoraTendenciaItem({
    required this.posicion,
    required this.nombre,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (posicion) {
      0 => const Color(0xFFE4B63F),
      1 => const Color(0xFF9AA3AF),
      2 => const Color(0xFFB77948),
      _ => AppColors.primary,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: posicion < 3
                  ? Text(switch (posicion) {
                      0 => '🥇',
                      1 => '🥈',
                      _ => '🥉',
                    }, style: const TextStyle(fontSize: 21))
                  : Text(
                      '${posicion + 1}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),

            const SizedBox(width: AppSpacing.sm),

            ClubAvatar(nombre: nombre, size: 50),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    total == 1 ? '1 lectura activa' : '$total lecturas activas',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            Text(
              '$total',
              style: AppTextStyles.section.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(width: AppSpacing.xs),

            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _TendenciasVacias extends StatelessWidget {
  const _TendenciasVacias();

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: AppColors.surfaceSoft,
      child: const Column(
        children: [
          Icon(
            Icons.query_stats_outlined,
            color: AppColors.textMuted,
            size: 40,
          ),

          SizedBox(height: AppSpacing.md),

          Text(
            'Todavía no hay una tendencia clara',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),

          SizedBox(height: AppSpacing.sm),

          Text(
            'Cuando el club empiece nuevas lecturas, aparecerán aquí los géneros, libros y lectoras más activos.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}
