import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';

import '../models/clubvision.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/error_view.dart';
import 'clubvision_votacion_page.dart';
import 'clubvision_como_votaron_page.dart';
import 'clubvision_gala_page.dart';
import 'clubvision_historial_page.dart';
import 'clubvision_mi_voto_page.dart';
import 'configurar_lectura_page.dart';
import 'lectura_page.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';

class ClubvisionMenuPage extends StatefulWidget {
  const ClubvisionMenuPage({super.key, this.onBackToClub});

  final VoidCallback? onBackToClub;

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
        AppPageRoute(builder: (_) => const ClubvisionMiVotoPage()),
      );

      if (!mounted) return;
      setState(_recargar);
      return;
    }

    final actualizado = await Navigator.push<bool>(
      context,
      AppPageRoute(
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

    if (!club.lecturaConfigurada) {
      await Navigator.push<bool>(
        context,
        AppPageRoute(
          builder: (_) =>
              ConfigurarLecturaPage(libro: club.ganador, tipo: 'OFICIAL'),
        ),
      );

      if (!mounted) return;
      setState(_recargar);
      return;
    }

    await Navigator.push(
      context,
      AppPageRoute(builder: (_) => LecturaPage(libro: club.ganador)),
    );

    if (!mounted) return;
    setState(_recargar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.onBackToClub == null,
        leading: widget.onBackToClub == null
            ? null
            : IconButton(
                tooltip: 'Volver a El Club',
                onPressed: widget.onBackToClub,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
        title: const Text('Clubvisión'),
      ),
      body: FutureBuilder<ClubvisionData>(
        future: clubvisionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CardListSkeleton();
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

                const SizedBox(height: AppSpacing.md),

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
                  subtitle: 'Revive todas las ediciones y sus libros ganadores',
                  actionLabel: 'Ver ediciones',
                  onTap: () {
                    Navigator.push(
                      context,
                      AppPageRoute(
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
                    subtitle: 'Descubre las puntuaciones de los miembros',
                    actionLabel: 'Ver resultados',
                    onTap: () {
                      Navigator.push(
                        context,
                        AppPageRoute(
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
                AppPageRoute(builder: (_) => const ClubvisionGalaPage()),
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
        return 'La votación ha terminado y ya hay libro ganador';
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

    return ClubCard(
      elevated: true,
      padding: EdgeInsets.zero,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF25162F), Color(0xFF5E347C), Color(0xFF8C527E)],
      ),
      borderColor: const Color(0xFFD9B56D),
      child: Stack(
        children: [
          Positioned(
            top: -38,
            right: -24,
            child: Transform.rotate(
              angle: -.18,
              child: Container(
                width: 132,
                height: 190,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: .18),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.elliptical(80, 25),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 16,
            child: Icon(
              Icons.mic_rounded,
              size: 88,
              color: Colors.white.withValues(alpha: .08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFF0CE82),
                      size: 17,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'CLUBVISIÓN · GALA LITERARIA',
                      style: TextStyle(
                        color: Color(0xFFF0CE82),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.45,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  club.titulo.trim().isEmpty ? 'Clubvisión' : club.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.7,
                  ),
                ),
                if (estado != 'LECTURA') ...[
                  const SizedBox(height: 7),
                  Text(
                    club.mensaje.trim().isEmpty
                        ? 'La próxima lectura la decide el club'
                        : club.mensaje,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .78),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _ClubvisionCycle(estado: estado),
                if (estado == 'VOTACION') ...[
                  const SizedBox(height: AppSpacing.lg),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: (club.porcentaje / 100).clamp(0.0, 1.0),
                      minHeight: 9,
                      backgroundColor: Colors.white.withValues(alpha: .18),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFF0CE82),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${club.votosRecibidos} votos dentro · '
                    '${club.votosPendientes} pendientes',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .82),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (estado == 'LECTURA' && club.ganador.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              club.ganador,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubvisionCycle extends StatelessWidget {
  const _ClubvisionCycle({required this.estado});

  final String estado;

  @override
  Widget build(BuildContext context) {
    final activeIndex = switch (estado) {
      'VOTACION' => 0,
      'RESULTADOS' => 1,
      'LECTURA' => 2,
      _ => -1,
    };
    const steps = [
      (Icons.how_to_vote_outlined, 'Votación'),
      (Icons.emoji_events_outlined, 'Gala'),
      (Icons.auto_stories_outlined, 'Lectura'),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 58,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      width: index == activeIndex ? 52 : 34,
                      height: index == activeIndex ? 52 : 34,
                      decoration: BoxDecoration(
                        color: index <= activeIndex
                            ? const Color(0xFFF0CE82)
                            : Colors.white.withValues(alpha: .10),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: index == activeIndex
                              ? Colors.white
                              : index < activeIndex
                              ? const Color(0xFFF0CE82)
                              : Colors.white.withValues(alpha: .28),
                          width: index == activeIndex ? 3 : 1,
                        ),
                        boxShadow: index == activeIndex
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFF0CE82,
                                  ).withValues(alpha: .48),
                                  blurRadius: 18,
                                  spreadRadius: 3,
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: .20),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        steps[index].$1,
                        size: index == activeIndex ? 26 : 17,
                        color: index <= activeIndex
                            ? const Color(0xFF432552)
                            : Colors.white.withValues(alpha: .62),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: index == activeIndex
                        ? const Color(0xFFF0CE82)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    steps[index].$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: index == activeIndex
                          ? const Color(0xFF432552)
                          : Colors.white.withValues(alpha: .62),
                      fontSize: index == activeIndex ? 11 : 10,
                      fontWeight: index == activeIndex
                          ? FontWeight.w900
                          : FontWeight.w600,
                    ),
                  ),
                ),
                if (index == activeIndex) ...[
                  const SizedBox(height: 4),
                  Text(
                    'AHORA',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .86),
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (index < steps.length - 1)
            SizedBox(
              width: 28,
              height: 58,
              child: Center(
                child: Container(
                  height: 2,
                  color: index < activeIndex
                      ? const Color(0xFFF0CE82)
                      : Colors.white.withValues(alpha: .28),
                ),
              ),
            ),
        ],
      ],
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
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: color.withValues(alpha: 0.20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Color.lerp(color, Colors.white, .9) ?? Colors.white,
        ],
      ),
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: .22),
                      color.withValues(alpha: .08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: color.withValues(alpha: .16)),
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
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    actionLabel,
                    style: AppTextStyles.body.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: color, size: 19),
              ],
            ),
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

          Text(
            'Muy pronto conoceremos los nuevos libros candidatos.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}
