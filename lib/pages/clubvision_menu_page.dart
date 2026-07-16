import 'package:flutter/material.dart';

import '../models/clubvision.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/error_view.dart';
import 'ClubVisionVotacionPage.dart';
import 'clubvision_como_votaron_page.dart';
import 'clubvision_gala_page.dart';
import 'clubvision_historial_page.dart';
import 'clubvision_mi_voto_page.dart';
import 'lectura_page.dart';

class ClubvisionMenuPage extends StatefulWidget {
  const ClubvisionMenuPage({super.key});

  @override
  State<ClubvisionMenuPage> createState() => _ClubvisionMenuPageState();
}

class _ClubvisionMenuPageState extends State<ClubvisionMenuPage> {
  late Future<ClubvisionData> clubvisionFuture;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    clubvisionFuture = ApiService().getClubvision();
  }

  Future<void> _refrescar() async {
    setState(_recargar);
    await clubvisionFuture;
  }

  Future<void> _abrirVotacion(ClubvisionData club) async {
    if (club.haVotado) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ClubvisionMiVotoPage()),
      );

      if (!mounted) return;
      setState(_recargar);
      return;
    }

    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClubvisionVotacionPage(idVotacion: club.idVotacion),
      ),
    );

    if (!mounted) return;

    if (actualizado == true) {
      setState(_recargar);
    }
  }

  Future<void> _abrirLectura(ClubvisionData club) async {
    if (club.ganador.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todavía no hay una lectura activa.')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LecturaPage(libro: club.ganador)),
    );

    if (!mounted) return;
    setState(_recargar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clubvisión')),
      body: FutureBuilder<ClubvisionData>(
        future: clubvisionFuture,
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

          final club = snapshot.data!;

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
                _ClubvisionHeader(club: club),

                const SizedBox(height: AppSpacing.xl),

                _SectionHeader(
                  icon: _estadoIcono(club.estado),
                  color: _estadoColor(club.estado),
                  title: 'Ahora en Clubvisión',
                  subtitle: _estadoDescripcion(club),
                ),

                const SizedBox(height: AppSpacing.md),

                ..._opcionesPrincipales(club),

                const SizedBox(height: AppSpacing.xl),

                const _SectionHeader(
                  icon: Icons.explore_outlined,
                  color: AppColors.info,
                  title: 'Explora Clubvisión',
                  subtitle: 'Consulta votaciones y ediciones anteriores',
                ),

                const SizedBox(height: AppSpacing.md),

                _MenuCard(
                  icon: Icons.history_rounded,
                  color: AppColors.info,
                  title: 'Historial',
                  subtitle: 'Revive todas las ediciones y sus ganadoras',
                  actionLabel: 'Ver ediciones',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClubvisionHistorialPage(),
                      ),
                    );
                  },
                ),

                if (club.estado == 'RESULTADOS' ||
                    club.estado == 'LECTURA') ...[
                  const SizedBox(height: AppSpacing.md),

                  _MenuCard(
                    icon: Icons.ballot_outlined,
                    color: AppColors.primary,
                    title: 'Cómo votaron',
                    subtitle: 'Descubre las puntuaciones de las lectoras',
                    actionLabel: 'Ver resultados',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ClubvisionComoVotaronPage(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _opcionesPrincipales(ClubvisionData club) {
    switch (club.estado?.trim().toUpperCase()) {
      case 'VOTACION':
        return [
          _MenuCard(
            icon: club.haVotado
                ? Icons.check_circle_outline_rounded
                : Icons.how_to_vote_outlined,
            color: club.haVotado ? AppColors.success : AppColors.primary,
            title: club.haVotado ? 'Mi voto' : 'Votación abierta',
            subtitle: club.haVotado
                ? 'Consulta la clasificación que enviaste'
                : 'Elige las cinco historias que prefieres',
            actionLabel: club.haVotado ? 'Consultar voto' : 'Votar ahora',
            badge: club.haVotado
                ? 'Voto registrado'
                : '${club.votosPendientes} pendientes',
            badgeVariant: club.haVotado
                ? ClubChipVariant.success
                : ClubChipVariant.warning,
            onTap: () => _abrirVotacion(club),
          ),
        ];

      case 'RESULTADOS':
        return [
          _MenuCard(
            icon: Icons.emoji_events_outlined,
            color: const Color(0xFFB48113),
            title: 'Gala Clubvisión',
            subtitle: 'Descubre la historia elegida por el club',
            actionLabel: 'Ver la gala',
            badge: 'Resultados disponibles',
            badgeVariant: ClubChipVariant.warning,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClubvisionGalaPage()),
              );
            },
          ),
        ];

      case 'LECTURA':
        return [
          _MenuCard(
            icon: Icons.auto_stories_outlined,
            color: AppColors.primary,
            title: club.ganador.isEmpty ? 'Lectura actual' : club.ganador,
            subtitle: 'Entra en los capítulos y comparte tus impresiones',
            actionLabel: 'Abrir lectura',
            badge: 'Lectura oficial',
            badgeVariant: ClubChipVariant.primary,
            onTap: () => _abrirLectura(club),
          ),
        ];

      default:
        return [const _EstadoEnEsperaCard()];
    }
  }

  IconData _estadoIcono(String? estado) {
    switch (estado?.trim().toUpperCase()) {
      case 'VOTACION':
        return Icons.how_to_vote_outlined;
      case 'RESULTADOS':
        return Icons.emoji_events_outlined;
      case 'LECTURA':
        return Icons.auto_stories_outlined;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  Color _estadoColor(String? estado) {
    switch (estado?.trim().toUpperCase()) {
      case 'VOTACION':
        return AppColors.primary;
      case 'RESULTADOS':
        return const Color(0xFFB48113);
      case 'LECTURA':
        return AppColors.info;
      default:
        return AppColors.textMuted;
    }
  }

  String _estadoDescripcion(ClubvisionData club) {
    switch (club.estado?.trim().toUpperCase()) {
      case 'VOTACION':
        return club.haVotado
            ? 'Tu voto ya está dentro de la urna'
            : 'Es el momento de elegir la próxima lectura';
      case 'RESULTADOS':
        return 'La votación ha terminado y ya hay ganadora';
      case 'LECTURA':
        return 'El club está disfrutando de la historia elegida';
      default:
        return 'Preparando la próxima edición';
    }
  }
}

class _ClubvisionHeader extends StatelessWidget {
  final ClubvisionData club;

  const _ClubvisionHeader({required this.club});

  @override
  Widget build(BuildContext context) {
    final estado = club.estado?.trim().toUpperCase() ?? '';

    final icon = switch (estado) {
      'VOTACION' => Icons.how_to_vote_rounded,
      'RESULTADOS' => Icons.emoji_events_rounded,
      'LECTURA' => Icons.auto_stories_rounded,
      _ => Icons.mic_none_rounded,
    };

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
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 38),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            club.titulo.trim().isEmpty ? 'Clubvisión' : club.titulo,
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 29),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            club.mensaje.trim().isEmpty
                ? 'Las lectoras deciden juntas la próxima aventura del club.'
                : club.mensaje,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(height: 1.45),
          ),

          if (estado == 'VOTACION') ...[
            const SizedBox(height: AppSpacing.lg),

            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: (club.porcentaje / 100).clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.72),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                ClubChip(
                  label: '${club.votosRecibidos} votos',
                  icon: Icons.how_to_vote_outlined,
                  variant: ClubChipVariant.primary,
                ),
                ClubChip(
                  label: '${club.votosPendientes} pendientes',
                  icon: Icons.schedule_rounded,
                  variant: ClubChipVariant.warning,
                ),
              ],
            ),
          ],

          if (estado == 'LECTURA' && club.ganador.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),

            ClubChip(
              label: club.ganador,
              icon: Icons.menu_book_outlined,
              variant: ClubChipVariant.primary,
            ),
          ],
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

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String actionLabel;
  final String? badge;
  final ClubChipVariant badgeVariant;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.badge,
    this.badgeVariant = ClubChipVariant.neutral,
  });

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: color.withValues(alpha: 0.20),
      backgroundColor: Color.lerp(color, Colors.white, 0.94),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(icon, color: color, size: 29),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      subtitle,
                      style: AppTextStyles.bodySecondary.copyWith(height: 1.4),
                    ),

                    if (badge != null) ...[
                      const SizedBox(height: AppSpacing.sm),

                      ClubChip(
                        label: badge!,
                        icon: Icons.auto_awesome_outlined,
                        variant: badgeVariant,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: color,
                  size: 21,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Icon(icon, size: 18, color: color),

              const SizedBox(width: AppSpacing.xs),

              Expanded(
                child: Text(
                  actionLabel,
                  style: AppTextStyles.body.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstadoEnEsperaCard extends StatelessWidget {
  const _EstadoEnEsperaCard();

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: AppColors.surfaceSoft,
      child: Column(
        children: [
          const Icon(
            Icons.hourglass_empty_rounded,
            color: AppColors.textMuted,
            size: 38,
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'La próxima edición está en camino',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),

          const SizedBox(height: AppSpacing.sm),

          const Text(
            'Muy pronto conoceremos las nuevas candidatas.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}
