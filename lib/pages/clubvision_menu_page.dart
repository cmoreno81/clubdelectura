import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';

import '../models/clubvision.dart';
import '../models/propuesta_lectura.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_button.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/error_view.dart';
import 'clubvision_votacion_page.dart';
import 'clubvision_como_votaron_page.dart';
import 'clubvision_gala_page.dart';
import 'clubvision_estadisticas_page.dart';
import 'clubvision_historial_page.dart';
import 'clubvision_mi_voto_page.dart';
import 'configurar_lectura_page.dart';
import 'lectura_page.dart';
import '../widgets/common/selector_libro_sheet.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';

class ClubvisionMenuPage extends StatefulWidget {
  const ClubvisionMenuPage({super.key, this.onBackToClub});

  final VoidCallback? onBackToClub;

  @override
  State<ClubvisionMenuPage> createState() => _ClubvisionMenuPageState();
}

class _ClubvisionMenuPageState extends State<ClubvisionMenuPage> {
  late Future<ClubvisionData> clubvisionFuture;
  bool _iniciandoBienvenida = false;

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

  Future<void> _iniciarBienvenida() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Iniciar Clubvisión de bienvenida'),
        content: const Text(
          'El club tendrá 48 horas para votar. Después se mostrará la gala y comenzará la lectura elegida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _iniciandoBienvenida = true);
    try {
      final result = await ApiService().iniciarClubvisionBienvenida();
      if (!mounted) return;
      final ok = result['ok'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Clubvisión de bienvenida iniciada'
                : (result['mensaje']?.toString() ?? 'No se ha podido iniciar'),
          ),
        ),
      );
      if (ok) await _refrescar();
    } finally {
      if (mounted) setState(() => _iniciandoBienvenida = false);
    }
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

                if ((club.estado == 'RESULTADOS' && club.ganador.isNotEmpty) ||
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

                const SizedBox(height: AppSpacing.md),

                _MenuCard(
                  icon: Icons.bar_chart_rounded,
                  color: const Color(0xFF4A6FBF),
                  title: 'Estadísticas',
                  subtitle: 'Gráficas y datos de todas las ediciones del club',
                  actionLabel: 'Ver estadísticas',
                  onTap: () {
                    Navigator.push(
                      context,
                      AppPageRoute(
                        builder: (_) => const ClubvisionEstadisticasPage(),
                      ),
                    );
                  },
                ),
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
        if (club.candidatas.length >= 5) {
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
        }
        return [
          _PropuestaVotacionCard(
            candidatasCount: club.candidatas.length,
            onActivada: _refrescar,
          ),
        ];

      case 'RESULTADOS':
        // Sin ganadora → mes sin candidatos suficientes, la Gala no aplica
        if (club.ganador.isEmpty) {
          return [const _SinGalaEsteMesCard()];
        }
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
        if (club.bienvenida.esAdmin) {
          return [
            _WelcomeClubvisionCard(
              eligibility: club.bienvenida,
              loading: _iniciandoBienvenida,
              onStart: club.bienvenida.disponible ? _iniciarBienvenida : null,
            ),
          ];
        }
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

// ── Propuesta de lectura (VOTACION con < 5 candidatos) ─────────

class _PropuestaVotacionCard extends StatefulWidget {
  final int candidatasCount;
  final Future<void> Function() onActivada;

  const _PropuestaVotacionCard({
    required this.candidatasCount,
    required this.onActivada,
  });

  @override
  State<_PropuestaVotacionCard> createState() => _PropuestaVotacionCardState();
}

class _PropuestaVotacionCardState extends State<_PropuestaVotacionCard> {
  late Future<PropuestaLectura?> _propuestaFuture;
  bool _accionando = false;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    _propuestaFuture = ApiService().getPropuestaLectura();
  }

  Future<void> _proponer() async {
    final controller = TextEditingController();
    final libro = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectorLibroSheet(controller: controller),
    );
    if (libro == null || libro.trim().isEmpty || !mounted) return;

    setState(() => _accionando = true);
    try {
      final result = await ApiService().crearPropuestaLectura(libro.trim());
      if (!mounted) return;
      if (result['ok'] == true) {
        setState(_recargar);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']?.toString() ?? 'No se pudo proponer'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _accionando = false);
    }
  }

  Future<void> _apoyar(String propuestaId) async {
    setState(() => _accionando = true);
    try {
      final result = await ApiService().apoyarPropuestaLectura(propuestaId);
      if (!mounted) return;
      if (result['activada'] == true) {
        await widget.onActivada();
      } else {
        setState(_recargar);
      }
    } finally {
      if (mounted) setState(() => _accionando = false);
    }
  }

  Future<void> _cancelar(String propuestaId) async {
    setState(() => _accionando = true);
    try {
      await ApiService().cancelarPropuestaLectura(propuestaId);
      if (!mounted) return;
      setState(_recargar);
    } finally {
      if (mounted) setState(() => _accionando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PropuestaLectura?>(
      future: _propuestaFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _PropuestaSkeletonCard();
        }

        final propuesta = snap.data;

        if (propuesta == null) {
          return _SinPropuestaCard(
            candidatasCount: widget.candidatasCount,
            accionando: _accionando,
            onProponer: _proponer,
          );
        }

        return _PropuestaActivaCard(
          propuesta: propuesta,
          accionando: _accionando,
          onApoyar: () => _apoyar(propuesta.id),
          onCancelar: () => _cancelar(propuesta.id),
        );
      },
    );
  }
}

class _SinPropuestaCard extends StatelessWidget {
  final int candidatasCount;
  final bool accionando;
  final VoidCallback onProponer;

  const _SinPropuestaCard({
    required this.candidatasCount,
    required this.accionando,
    required this.onProponer,
  });

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: AppColors.primary.withValues(alpha: 0.20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Color.lerp(AppColors.primary, Colors.white, .9) ?? Colors.white,
        ],
      ),
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
                      AppColors.primary.withValues(alpha: .22),
                      AppColors.primary.withValues(alpha: .08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: .16),
                  ),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primary,
                  size: 29,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proponer lectura conjunta',
                      style: AppTextStyles.section.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'No hay suficientes candidatos para votar. '
                      'Poneos de acuerdo y proponed una lectura para el club.',
                      style: AppTextStyles.bodySecondary.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClubChip(
                      label: '$candidatasCount candidatos',
                      icon: Icons.auto_awesome_outlined,
                      variant: ClubChipVariant.info,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: accionando ? null : onProponer,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: accionando ? .05 : .1,
                ),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: AppColors.primary.withValues(
                      alpha: accionando ? .4 : 1,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Proponer un libro',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary.withValues(
                          alpha: accionando ? .4 : 1,
                        ),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (accionando)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                      size: 19,
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

class _PropuestaActivaCard extends StatelessWidget {
  final PropuestaLectura propuesta;
  final bool accionando;
  final VoidCallback onApoyar;
  final VoidCallback onCancelar;

  const _PropuestaActivaCard({
    required this.propuesta,
    required this.accionando,
    required this.onApoyar,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    final color = propuesta.estaCompleta
        ? AppColors.success
        : AppColors.primary;

    return ClubCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: color.withValues(alpha: 0.30),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Color.lerp(color, Colors.white, .88) ?? Colors.white,
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                  border: Border.all(color: color.withValues(alpha: .20)),
                ),
                child: Icon(Icons.groups_rounded, color: color, size: 29),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Propuesta del club',
                      style: AppTextStyles.section.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Propuesto por ${propuesta.proposedBy}',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Book title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: color.withValues(alpha: .15)),
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: color, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    propuesta.bookTitle,
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Apoyos progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${propuesta.apoyosCount} de ${propuesta.totalMiembros} '
                      '${propuesta.totalMiembros == 1 ? 'miembro apoya' : 'miembros apoyan'}',
                      style: AppTextStyles.bodySecondary.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: propuesta.totalMiembros > 0
                            ? propuesta.apoyosCount / propuesta.totalMiembros
                            : 0,
                        minHeight: 8,
                        backgroundColor: color.withValues(alpha: .15),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              ),
              if (propuesta.apoyos.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.md),
                _AvatarStack(apoyantes: propuesta.apoyos),
              ],
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Actions
          if (propuesta.yaApoye)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Ya has apoyado esta propuesta',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: accionando ? null : onApoyar,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: accionando ? .05 : .1,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.thumb_up_alt_rounded,
                      size: 18,
                      color: AppColors.primary.withValues(
                        alpha: accionando ? .4 : 1,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Apoyar esta propuesta',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary.withValues(
                            alpha: accionando ? .4 : 1,
                          ),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (accionando)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                        size: 19,
                      ),
                  ],
                ),
              ),
            ),

          if (propuesta.soyElProponente) ...[
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: accionando ? null : onCancelar,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.danger.withValues(alpha: .7),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Cancelar propuesta',
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: AppColors.danger.withValues(alpha: .7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<ApoyantesPropuesta> apoyantes;

  const _AvatarStack({required this.apoyantes});

  @override
  Widget build(BuildContext context) {
    const size = 32.0;
    const overlap = 10.0;
    final show = apoyantes.take(4).toList();
    final total = show.length * size - (show.length - 1) * overlap;

    return SizedBox(
      width: total,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < show.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  color: AppColors.primary.withValues(alpha: .15),
                ),
                child: ClipOval(
                  child: show[i].avatarUrl.isNotEmpty
                      ? Image.network(
                          show[i].avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 16,
                          color: AppColors.primary,
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PropuestaSkeletonCard extends StatelessWidget {
  const _PropuestaSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 140,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      height: 13,
                      width: 200,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: .07),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sin gala este mes (RESULTADOS sin candidatos) ────────────────

class _SinGalaEsteMesCard extends StatelessWidget {
  const _SinGalaEsteMesCard();

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: AppColors.surfaceSoft,
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: AppColors.textMuted,
            size: 38,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Este mes no hay Gala',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No hubo candidatos suficientes para abrir la votación. '
            'La próxima edición arrancará el mes que viene.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}

// ── Estado en espera ─────────────────────────────────────────────

class _WelcomeClubvisionCard extends StatelessWidget {
  const _WelcomeClubvisionCard({
    required this.eligibility,
    required this.loading,
    required this.onStart,
  });

  final ClubvisionWelcomeEligibility eligibility;
  final bool loading;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF8EFF9), Color(0xFFFFF6DF)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Clubvisión de bienvenida',
                  style: AppTextStyles.subtitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Vivid vuestra primera votación sin esperar al próximo mes.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ClubChip(
                label:
                    '${eligibility.miembros}/${eligibility.minimoMiembros} miembros',
                variant: eligibility.miembros >= eligibility.minimoMiembros
                    ? ClubChipVariant.success
                    : ClubChipVariant.warning,
              ),
              ClubChip(
                label:
                    '${eligibility.candidatas}/${eligibility.minimoCandidatas} candidatas',
                variant: eligibility.candidatas >= eligibility.minimoCandidatas
                    ? ClubChipVariant.success
                    : ClubChipVariant.warning,
              ),
            ],
          ),
          if (!eligibility.disponible && eligibility.motivo.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(eligibility.motivo, style: AppTextStyles.caption),
          ],
          const SizedBox(height: AppSpacing.lg),
          ClubButton(
            label: 'Iniciar bienvenida',
            icon: Icons.how_to_vote_outlined,
            loading: loading,
            onPressed: onStart,
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
