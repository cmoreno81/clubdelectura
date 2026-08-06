import 'package:club_lectura_app/widgets/common/editar_progreso_dialog.dart';
import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../navigation/book_detail_navigation.dart';
import 'afinidad_detalle_page.dart';
import 'club_challenge_page.dart';
import '../dev/dev_settings.dart';
import '../models/dashboard_view_data.dart';
import '../models/dashboard.dart';
import '../models/ranking_item.dart';
import '../models/reaccion_comentario.dart';
import '../services/api_service.dart';
import '../services/club_narrador.dart';
import '../services/usuario_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../widgets/club/clubvision_card.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/common/club_empty_state.dart';
import '../widgets/common/club_section_title.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/error_view.dart';
import '../widgets/info_card.dart';
import 'mood_club_page.dart';
import 'perfil_usuario_page.dart';
import 'ranking_page.dart';
import 'tendencias_club_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.clubName});

  final String clubName;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<DashboardViewData> dashboardFuture;
  final Map<String, LecturaAhoraItem> _reactionOverrides = {};
  final Set<String> _reactingProgressIds = {};

  String? usuarioActual;
  String avatarUrlActual = '';

  @override
  void initState() {
    super.initState();

    dashboardFuture = _cargarDashboard();
    _cargarUsuarioActual();
  }

  @override
  void reassemble() {
    super.reassemble();

    // En desarrollo, un hot reload puede conservar un DashboardViewData
    // anterior que todavía no incluía el top 3. Volvemos a pedirlo para que
    // el podio se reconstruya completo sin necesitar reiniciar la app.
    dashboardFuture = _cargarDashboard();
  }

  Future<DashboardViewData> _cargarDashboard() async {
    final dashboardFuture = ApiService().getDashboard();
    final clubvisionFuture = ApiService().getClubvision();
    final topLectorasFuture = ApiService().getTopLectorasMes();

    final dashboard = await dashboardFuture;
    final clubvision = await clubvisionFuture;
    List<RankingItem> topLectoras;

    try {
      topLectoras = await topLectorasFuture;
    } catch (_) {
      topLectoras = const [];
    }

    return DashboardViewData(
      dashboard: dashboard,
      haVotado: clubvision.haVotado,
      topLectoras: topLectoras,
    );
  }

  Future<void> _cargarUsuarioActual() async {
    final usuario = await UsuarioService().obtenerUsuario();
    final nombre = usuario?.trim() ?? '';

    if (!mounted) return;

    if (nombre.isEmpty) {
      setState(() {
        usuarioActual = '';
        avatarUrlActual = '';
      });

      return;
    }

    try {
      final perfil = await ApiService().getPerfilUsuario(nombre);

      if (!mounted) return;

      setState(() {
        usuarioActual = nombre;
        avatarUrlActual = perfil.avatarUrl;
      });
    } catch (error) {
      debugPrint('No se pudo cargar el avatar del dashboard: $error');

      if (!mounted) return;

      setState(() {
        usuarioActual = nombre;
        avatarUrlActual = '';
      });
    }
  }

  Future<void> _recargar() async {
    setState(() {
      _reactionOverrides.clear();
      dashboardFuture = _cargarDashboard();
    });

    await dashboardFuture;
  }

  void _abrirPerfil(String usuario) {
    final limpio = usuario.trim();

    if (limpio.isEmpty) return;

    Navigator.push(
      context,
      AppPageRoute(builder: (_) => PerfilUsuarioPage(usuario: limpio)),
    );
  }

  void _abrirRanking({int initialTab = 0}) {
    Navigator.push(
      context,
      AppPageRoute(builder: (_) => RankingPage(initialTab: initialTab)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Row(
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.primary,
              size: 28,
            ),

            const SizedBox(width: AppSpacing.xs),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.clubName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'ClubReads',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: ClubAvatar(
              nombre: usuarioActual ?? '',
              imageUrl: avatarUrlActual,
              size: 46,
              onTap: () async {
                final nombre = usuarioActual?.trim() ?? '';

                if (nombre.isEmpty) return;

                await Navigator.push(
                  context,
                  AppPageRoute(
                    builder: (_) => PerfilUsuarioPage(usuario: nombre),
                  ),
                );

                if (!mounted) return;

                // Recargamos por si la usuaria cambió su foto en el perfil.
                await _cargarUsuarioActual();
              },
            ),
          ),
        ],
      ),

      body: FutureBuilder<DashboardViewData>(
        future: dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(onRetry: _recargar);
          }

          final viewData = snapshot.data!;
          final data = viewData.dashboard;

          final estadoClub = ClubNarrador().narrar(
            estado: DevSettings.estadoForzado ?? data.clubvision.estado,
          );

          return RefreshIndicator(
            onRefresh: _recargar,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                110,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _podioLectoras(
                    lectoras: viewData.topLectoras ?? const [],
                    usuarioMes: data.resumen.usuarioMes,
                    librosUsuarioMes: data.resumen.librosUsuarioMes,
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  if (data.clubvision.estado.toUpperCase() != 'SIN_DATOS')
                    ClubvisionCard(
                      dashboard: data,
                      estadoClub: estadoClub,
                      haVotado: viewData.haVotado,
                      onActualizar: _recargar,
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  const ClubSectionTitle(
                    title: 'Así está el club',
                    subtitle: 'El pulso lector de este mes',
                    icon: Icons.auto_awesome_rounded,
                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Logros del club — primera card de la sección ──
                  _LogrosClubCard(),

                  const SizedBox(height: AppSpacing.md),

                  InfoCard(
                    title: 'Pulso del club',
                    value: data.mood,
                    icon: Icons.psychology_alt_outlined,
                    variant: InfoCardVariant.blush,
                    pulseIcon: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        AppPageRoute(builder: (_) => const MoodClubPage()),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),

                  InfoCard(
                    title: 'Tendencia',
                    value: data.tendencia,
                    icon: Icons.trending_up_rounded,
                    variant: InfoCardVariant.sage,
                    pulseIcon: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        AppPageRoute(
                          builder: (_) => const TendenciasClubPage(),
                        ),
                      );
                    },
                  ),

                  if (data.rankingAfinidad.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _AffinityCard(
                      miembros: data.rankingAfinidad,
                      miAvatarUrl: avatarUrlActual ?? '',
                    ),
                  ],

                  if (data.libroMes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),

                    InfoCard(
                      title: 'Libro del mes',
                      value:
                          '${data.libroMes.first.libro}\n'
                          '${data.libroMes.first.puntos} puntos',
                      icon: Icons.workspace_premium_outlined,
                      variant: InfoCardVariant.primary,
                      onTap: () => openBookDetail(
                        context,
                        title: data.libroMes.first.libro,
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  _estadisticasMes(
                    actividad: data.resumen.actividadMes,
                    valoracion: data.resumen.valoracionMedia,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  const ClubSectionTitle(
                    title: 'Leyendo ahora',
                    subtitle: 'Qué tienen entre manos las lectoras',
                    icon: Icons.menu_book_rounded,
                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  if (data.leyendoAhora.isEmpty)
                    const ClubEmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'El club está entre lecturas',
                      message:
                          'Cuando alguna lectora empiece un libro, aparecerá aquí.',
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    )
                  else
                    ...data.leyendoAhora.map(
                      (usuario) => _lectoraLeyendoCard(
                        nombre: usuario.usuario,
                        lecturas: usuario.lecturas,
                        total: usuario.total,
                        avatarUrl: usuario.avatarUrl,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _podioLectoras({
    required List<RankingItem> lectoras,
    required String usuarioMes,
    required int librosUsuarioMes,
  }) {
    final participantes = lectoras.isNotEmpty
        ? lectoras
        : usuarioMes.trim().isNotEmpty
        ? [RankingItem(nombre: usuarioMes, total: librosUsuarioMes)]
        : const <RankingItem>[];

    return ClubCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceSoft, Color(0xFFF0E5FF)],
      ),
      borderColor: AppColors.primaryLight,
      onTap: () => _abrirRanking(initialTab: 1),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 28,
                color: AppColors.gold,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Ranking del club',
                style: AppTextStyles.section.copyWith(fontSize: 20),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxs),

          Text(
            participantes.isEmpty
                ? 'Descubre las clasificaciones y favoritos del club'
                : 'El podio lector de este mes',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),

          if (participantes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: participantes.length > 1
                      ? _PodioPuesto(
                          item: participantes[1],
                          posicion: 2,
                          altura: 44,
                          color: const Color(0xFF9AA3AD),
                          onTap: () => _abrirPerfil(participantes[1].nombre),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(width: AppSpacing.xs),

                Expanded(
                  child: _PodioPuesto(
                    item: participantes.first,
                    posicion: 1,
                    altura: 60,
                    color: AppColors.gold,
                    destacado: true,
                    onTap: () => _abrirPerfil(participantes.first.nombre),
                  ),
                ),

                const SizedBox(width: AppSpacing.xs),

                Expanded(
                  child: participantes.length > 2
                      ? _PodioPuesto(
                          item: participantes[2],
                          posicion: 3,
                          altura: 36,
                          color: const Color(0xFFB77A4A),
                          onTap: () => _abrirPerfil(participantes[2].nombre),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Abrir ranking completo',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 17,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _estadisticasMes({
    required int actividad,
    required String valoracion,
  }) {
    return Row(
      children: [
        Expanded(
          child: InfoCard(
            title: 'Este mes',
            value: '$actividad ${actividad == 1 ? 'libro' : 'libros'}',
            icon: Icons.local_fire_department_outlined,
            variant: InfoCardVariant.warning,
            compact: true,
            onTap: () {
              _abrirRanking(initialTab: 1);
            },
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: InfoCard(
            title: 'Media del club',
            value: valoracion == '0' ? 'Sin datos' : '$valoracion / 5',
            icon: Icons.star_outline_rounded,
            variant: InfoCardVariant.gold,
            compact: true,
            onTap: () {
              _abrirRanking(initialTab: 2);
            },
          ),
        ),
      ],
    );
  }

  Widget _lectoraLeyendoCard({
    required String nombre,
    required List<LecturaAhoraItem> lecturas,
    required int total,
    required String avatarUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ClubCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        elevated: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => _abrirPerfil(nombre),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Row(
                children: [
                  ClubAvatar(nombre: nombre, imageUrl: avatarUrl, size: 48),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      nombre,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ClubChip(
                    label: '$total ${total == 1 ? 'lectura' : 'lecturas'}',
                    icon: Icons.menu_book_outlined,
                    variant: ClubChipVariant.info,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < lecturas.length; index++) ...[
              _LecturaProgresoCard(
                lectura: _effectiveReading(lecturas[index]),
                editable:
                    usuarioActual?.trim().toLowerCase() ==
                    nombre.trim().toLowerCase(),
                onEditar: () =>
                    _editarProgreso(nombre, _effectiveReading(lecturas[index])),
                onBookTap: () => openBookDetail(
                  context,
                  title: lecturas[index].titulo,
                  bookId: lecturas[index].bookId,
                  coverUrl: lecturas[index].coverUrl,
                ),
                onReact: () =>
                    _reaccionarProgreso(_effectiveReading(lecturas[index])),
              ),
              if (index < lecturas.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editarProgreso(String usuario, LecturaAhoraItem lectura) async {
    final resultado =
        await showDialog<
          ({
            int progreso,
            String comentario,
            int? paginaActual,
            int? paginasTotales,
          })
        >(
          context: context,
          builder: (_) => EditarProgresoDialog(lectura: lectura),
        );
    if (resultado == null) return;

    final ok = await ApiService().actualizarProgresoLectura(
      usuario: usuario,
      libro: lectura.titulo,
      progreso: resultado.progreso,
      comentario: resultado.comentario,
      paginaActual: resultado.paginaActual,
      paginasTotales: resultado.paginasTotales,
    );
    if (!mounted) return;
    if (ok) {
      await _recargar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido guardar el progreso.')),
      );
    }
  }

  Future<void> _reaccionarProgreso(LecturaAhoraItem lectura) async {
    if (lectura.libraryId.isEmpty ||
        _reactingProgressIds.contains(lectura.libraryId)) {
      return;
    }
    final reaccion = await showModalBottomSheet<ReaccionComentario>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reaccionar a esta impresión', style: AppTextStyles.section),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: ReaccionComentario.values
                    .map(
                      (item) => ActionChip(
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 5,
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.emoji,
                              strutStyle: const StrutStyle(
                                fontSize: 21,
                                height: 1.25,
                                forceStrutHeight: true,
                              ),
                              style: const TextStyle(
                                fontSize: 21,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(item.titulo),
                          ],
                        ),
                        onPressed: () => Navigator.pop(context, item),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (reaccion == null || !mounted) return;
    final previous = _effectiveReading(lectura);
    final optimistic = _toggleLocalReaction(previous, reaccion);
    setState(() {
      _reactingProgressIds.add(lectura.libraryId);
      _reactionOverrides[lectura.libraryId] = optimistic;
    });
    try {
      final result = await ApiService().toggleProgressReaction(
        libraryId: lectura.libraryId,
        reaccion: reaccion.apiValue,
      );
      if (!mounted) return;
      if (result['ok'] != true) {
        throw StateError('No se ha podido guardar la reacción');
      }
      final rawReactions = result['reacciones'] as Map? ?? const {};
      setState(() {
        _reactionOverrides[lectura.libraryId] = _withReactionState(
          previous,
          reactions: {
            for (final item in ReaccionComentario.values)
              item: (rawReactions[item.apiValue] as num?)?.toInt() ?? 0,
          },
          myReaction: ReaccionComentarioDatos.fromApi(
            result['miReaccion']?.toString(),
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _reactionOverrides[lectura.libraryId] = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido guardar la reacción.')),
      );
    } finally {
      if (mounted) {
        setState(() => _reactingProgressIds.remove(lectura.libraryId));
      }
    }
  }

  LecturaAhoraItem _effectiveReading(LecturaAhoraItem reading) =>
      _reactionOverrides[reading.libraryId] ?? reading;

  LecturaAhoraItem _toggleLocalReaction(
    LecturaAhoraItem reading,
    ReaccionComentario selected,
  ) {
    final reactions = Map<ReaccionComentario, int>.from(reading.reacciones);
    final current = reading.miReaccion;
    if (current != null) {
      reactions[current] = ((reactions[current] ?? 0) - 1).clamp(0, 1 << 31);
    }
    final next = current == selected ? null : selected;
    if (next != null) {
      reactions[next] = (reactions[next] ?? 0) + 1;
    }
    return _withReactionState(reading, reactions: reactions, myReaction: next);
  }

  LecturaAhoraItem _withReactionState(
    LecturaAhoraItem reading, {
    required Map<ReaccionComentario, int> reactions,
    required ReaccionComentario? myReaction,
  }) {
    return LecturaAhoraItem(
      libraryId: reading.libraryId,
      bookId: reading.bookId,
      titulo: reading.titulo,
      coverUrl: reading.coverUrl,
      progreso: reading.progreso,
      paginaActual: reading.paginaActual,
      paginasTotales: reading.paginasTotales,
      comentario: reading.comentario,
      actualizadoEn: reading.actualizadoEn,
      reacciones: reactions,
      miReaccion: myReaction,
    );
  }
}

class _LecturaProgresoCard extends StatelessWidget {
  final LecturaAhoraItem lectura;
  final bool editable;
  final VoidCallback onEditar;
  final VoidCallback onBookTap;
  final VoidCallback onReact;

  const _LecturaProgresoCard({
    required this.lectura,
    required this.editable,
    required this.onEditar,
    required this.onBookTap,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            onTap: onBookTap,
            child: ClubBookCover(
              title: lectura.titulo,
              imageUrl: lectura.coverUrl,
              width: 52,
              showShadow: false,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        onTap: onBookTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            lectura.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (editable)
                      IconButton(
                        tooltip: 'Actualizar progreso',
                        visualDensity: VisualDensity.compact,
                        onPressed: onEditar,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: lectura.progreso / 100,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      lectura.paginaActual != null &&
                              lectura.paginasTotales != null
                          ? 'Pág. ${lectura.paginaActual} de '
                                '${lectura.paginasTotales} · '
                                '${lectura.progreso}%'
                          : '${lectura.progreso}%',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (lectura.comentario.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '“${lectura.comentario}”',
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final entry in lectura.reacciones.entries)
                        if (entry.value > 0)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            label: Text(
                              '${entry.key.emoji} ${entry.value}',
                              style: const TextStyle(height: 1.35),
                            ),
                          ),
                      TextButton.icon(
                        onPressed: lectura.libraryId.isEmpty ? null : onReact,
                        icon: lectura.miReaccion == null
                            ? const Icon(Icons.add_reaction_outlined, size: 19)
                            : SizedBox.square(
                                dimension: 24,
                                child: Center(
                                  child: Text(
                                    lectura.miReaccion!.emoji,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ),
                        label: const Text('Reaccionar'),
                      ),
                    ],
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

class _PodioPuesto extends StatelessWidget {
  final RankingItem item;
  final int posicion;
  final double altura;
  final Color color;
  final bool destacado;
  final VoidCallback onTap;

  const _PodioPuesto({
    required this.item,
    required this.posicion,
    required this.altura,
    required this.color,
    required this.onTap,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Puesto $posicion, ${item.nombre}, ${item.total} libros',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (destacado)
              Icon(Icons.emoji_events_rounded, color: color, size: 18)
            else
              const SizedBox(height: 18),

            const SizedBox(height: AppSpacing.xxs),

            ClubAvatar(
              nombre: item.nombre,
              imageUrl: item.avatarUrl,
              size: destacado ? 52 : 46,
            ),
            const SizedBox(height: AppSpacing.xxs),

            Text(
              item.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),

            Text(
              '${item.total} ${item.total == 1 ? 'libro' : 'libros'}',
              maxLines: 1,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: AppSpacing.xxs),

            Container(
              height: altura,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.88),
                    color.withValues(alpha: 0.58),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Text(
                '$posicion',
                style: AppTextStyles.title.copyWith(
                  color: Colors.white,
                  fontSize: destacado ? 25 : 21,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Ranking de afinidad anual
// ─────────────────────────────────────────────

class _AffinityCard extends StatelessWidget {
  const _AffinityCard({required this.miembros, required this.miAvatarUrl});
  final List<AffinityMember> miembros;
  final String miAvatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0E5FF), Color(0xFFE8F4FF)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primaryLight),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compañeras de lectura',
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Más libros en común este año',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Podio de avatares
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < miembros.length && i < 5; i++)
                Builder(
                  key: ValueKey(miembros[i].id),
                  builder: (_) {
                    final miembro = miembros[i];
                    return _AffinityMemberTile(
                      miembro: miembro,
                      posicion: i,
                      onTap: () => Navigator.push<void>(
                        context,
                        AppPageRoute(
                          builder: (_) => AfinidadDetallePage(
                            miembroId: miembro.id,
                            nombre: miembro.nombre,
                            avatarUrl: miembro.avatarUrl,
                            librosComunes: miembro.librosComunes,
                            miAvatarUrl: miAvatarUrl,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AffinityMemberTile extends StatelessWidget {
  const _AffinityMemberTile({
    required this.miembro,
    required this.posicion,
    required this.onTap,
  });

  final AffinityMember miembro;
  final int posicion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Primera posición: avatar más grande
    final size = posicion == 0
        ? 62.0
        : posicion <= 2
        ? 52.0
        : 44.0;
    final medalColors = [
      const Color(0xFFE4B63F), // oro
      const Color(0xFF9AA3AF), // plata
      const Color(0xFFB77948), // bronce
    ];
    final medalColor = posicion < 3 ? medalColors[posicion] : AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar con borde de color según posición
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: medalColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: medalColor.withValues(alpha: .3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: miembro.avatarUrl.isNotEmpty
                    ? Image.network(
                        miembro.avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initials(),
                      )
                    : _initials(),
              ),
              // Medalla en esquina inferior derecha
              if (posicion < 3)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: medalColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${posicion + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          // Nombre corto
          SizedBox(
            width: size + 4,
            child: Text(
              miembro.nombre.split(' ').first, // solo primer nombre
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                fontWeight: posicion == 0 ? FontWeight.w800 : FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 11,
              ),
            ),
          ),

          // Libros en común
          Text(
            '${miembro.librosComunes} 📚',
            style: AppTextStyles.caption.copyWith(
              color: medalColor,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ), // Column
    ); // GestureDetector
  }

  Widget _initials() => Container(
    color: AppColors.primaryLight,
    alignment: Alignment.center,
    child: Text(
      miembro.nombre.isNotEmpty ? miembro.nombre[0].toUpperCase() : '?',
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w800,
        fontSize: 18,
      ),
    ),
  );
}

// ─────────────────────────────────────────────
// Card de logros del club
// ─────────────────────────────────────────────
class _LogrosClubCard extends StatelessWidget {
  const _LogrosClubCard();

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF0E5FF), Color(0xFFE8F4FF)],
      ),
      borderColor: AppColors.primary.withValues(alpha: .2),
      onTap: () => Navigator.push<void>(
        context,
        AppPageRoute(builder: (_) => const ClubChallengePage()),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.primary,
              size: 27,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reto lector ${DateTime.now().year}',
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Ve el progreso de todas las lectoras',
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ],
      ),
    );
  }
}
