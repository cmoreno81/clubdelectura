import 'dart:async';

import 'package:club_lectura_app/widgets/common/editar_progreso_dialog.dart';
import 'package:flutter/material.dart';

import '../models/notificacion.dart';
import '../navigation/app_page_route.dart';
import '../services/notificaciones_service.dart';
import '../navigation/book_detail_navigation.dart';
import '../widgets/common/notificaciones_sheet.dart';
import 'afinidad_detalle_page.dart';
import 'club_challenge_page.dart';
import 'club_logros_page.dart';
import '../dev/dev_settings.dart';
import '../models/dashboard_view_data.dart';
import '../models/dashboard.dart';
import '../services/reading_streak_service.dart';
import '../models/auth_session.dart';
import '../models/ranking_item.dart';
import '../models/reaccion_comentario.dart';
import '../services/api_service.dart';
import '../services/auth_session_service.dart';
import '../services/club_dashboard_service.dart';
import '../services/club_narrador.dart';
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
import '../widgets/common/optimized_network_image.dart';
import '../widgets/error_view.dart';
import '../widgets/info_card.dart';
import 'mood_club_page.dart';
import 'perfil_usuario_page.dart';
import 'ranking_page.dart';
import 'tendencias_club_page.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.clubName,
    this.esPersonal = false,
    this.controller,
    this.loadData,
    this.initialUser,
    this.profilePageBuilder,
  });

  final String clubName;
  final bool esPersonal;
  final DashboardPageController? controller;
  final Future<DashboardViewData> Function()? loadData;
  final AuthUser? initialUser;
  final Widget Function(String userName)? profilePageBuilder;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class DashboardPageController {
  Future<void> Function()? _refresh;

  Future<void> refresh() => _refresh?.call() ?? Future<void>.value();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<DashboardViewData> dashboardFuture;
  final Map<String, ValueNotifier<LecturaAhoraItem>> _reactionNotifiers = {};
  final Set<String> _reactingProgressIds = {};

  String? usuarioActual;
  String avatarUrlActual = '';
  bool _headerLoading = true;

  @override
  void initState() {
    super.initState();
    final sessionUser = widget.initialUser ?? AuthSessionService.instance.user;
    usuarioActual = sessionUser?.nombre.trim();
    avatarUrlActual = sessionUser?.avatarUrl.trim() ?? '';
    widget.controller?._refresh = _recargar;
    dashboardFuture = _cargarDashboard();
    // Carga inicial de notificaciones en el servicio compartido
    unawaited(NotificacionesService.instance.cargar());
  }

  Future<void> _abrirNotificaciones() async {
    final notif = await mostrarNotificacionesSheet(
      context,
      titulo: 'Actividad del club',
      filtro:
          (n) =>
              n.tipo == 'LIBRO_TERMINADO' ||
              n.tipo == 'LIBRO_EMPEZADO' ||
              n.tipo == 'LIBRO_NUEVO_BIBLIOTECA' ||
              n.tipo == 'NUEVA_MIEMBRO',
    );

    // Refrescar el servicio tras cerrar el sheet
    unawaited(NotificacionesService.instance.cargar());

    if (notif == null || !mounted) return;
    await _navegarDesdeNotificacion(notif);
  }

  Future<void> _navegarDesdeNotificacion(Notificacion n) async {
    final extra = n.extra ?? const <String, dynamic>{};
    String bookTitle = '';
    for (final key in const ['bookTitle', 'titulo', 'libro']) {
      final v = extra[key]?.toString().trim() ?? '';
      if (v.isNotEmpty) { bookTitle = v; break; }
    }
    if (bookTitle.isEmpty) {
      final match = RegExp(r'["«"]([^""»"]+)["»"]').firstMatch(n.mensaje);
      bookTitle = match?.group(1)?.trim() ?? '';
    }

    if (!mounted) return;

    switch (n.tipo) {
      case 'LIBRO_TERMINADO':
      case 'LIBRO_EMPEZADO':
      case 'LIBRO_NUEVO_BIBLIOTECA':
        if (bookTitle.isNotEmpty) {
          await openBookDetail(
            context,
            title: bookTitle,
            bookId: n.bookId?.trim() ?? '',
          );
        }
      default:
        break;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._refresh == _recargar) {
      widget.controller?._refresh = null;
    }
    for (final notifier in _reactionNotifiers.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  Future<DashboardViewData> _cargarDashboard() async {
    late final DashboardViewData viewData;
    try {
      viewData =
          await (widget.loadData?.call() ?? ClubDashboardService().load());
    } finally {
      _headerLoading = false;
    }
    for (final member in viewData.dashboard.leyendoAhora) {
      for (final reading in member.lecturas) {
        _reactionNotifiers[reading.libraryId]?.value = reading;
      }
    }
    final dashboardName = viewData.dashboard.usuarioActual.trim();
    final dashboardAvatar = viewData.dashboard.avatarUrlActual.trim();
    if (dashboardName.isNotEmpty) usuarioActual = dashboardName;
    if (dashboardAvatar.isNotEmpty) avatarUrlActual = dashboardAvatar;
    return viewData;
  }

  Future<void> _recargar() async {
    setState(() {
      dashboardFuture = _cargarDashboard();
    });

    await dashboardFuture;
  }

  void _abrirPerfil(String usuario) {
    final limpio = usuario.trim();

    if (limpio.isEmpty) return;

    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) =>
            widget.profilePageBuilder?.call(limpio) ??
            PerfilUsuarioPage(usuario: limpio),
      ),
    );
  }

  Future<void> _abrirMiPerfil() async {
    final nombre = usuarioActual?.trim() ?? '';
    if (nombre.isEmpty) return;
    await Navigator.push<void>(
      context,
      AppPageRoute(
        builder: (_) =>
            widget.profilePageBuilder?.call(nombre) ??
            PerfilUsuarioPage(usuario: nombre),
      ),
    );
    if (mounted) await _recargar();
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
          if (!widget.esPersonal)
          ListenableBuilder(
            listenable: NotificacionesService.instance,
            builder: (context, _) {
              final n = NotificacionesService.instance.noLeidasClub;
              return IconButton(
                tooltip: 'Actividad del club',
                onPressed: _abrirNotificaciones,
                icon: Badge(
                  isLabelVisible: n > 0,
                  label: Text(n < 10 ? '$n' : '9+'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: ClubAvatar(
              nombre: usuarioActual ?? '',
              imageUrl: avatarUrlActual,
              size: 46,
              neutralWhenUnnamed: _headerLoading,
              onTap: _abrirMiPerfil,
            ),
          ),
        ],
      ),

      body: FutureBuilder<DashboardViewData>(
        future: dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const DashboardSkeleton();
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
                  if (!widget.esPersonal) ...[
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
                  ],

                  ClubSectionTitle(
                    title: widget.esPersonal ? 'Tu actividad lectora' : 'Así está el club',
                    subtitle: widget.esPersonal ? 'Tu mes en números' : 'El pulso lector de este mes',
                    icon: Icons.auto_awesome_rounded,
                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // ── Logros / reto — adaptado según modo ──
                  _LogrosClubCard(esPersonal: widget.esPersonal),
                  const SizedBox(height: AppSpacing.sm),
                  _AchievementsClubCard(esPersonal: widget.esPersonal),

                  if (!widget.esPersonal) ...[
                  const SizedBox(height: AppSpacing.md),

                  IntrinsicHeight(
                   child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _PulsoTendenciaCard(
                          title: 'Pulso del club',
                          value: data.mood,
                          icon: Icons.psychology_alt_outlined,
                          foreground: const Color(0xFFD95781),
                          background: const Color(0xFFFFF4F7),
                          border: const Color(0xFFF5D8E1),
                          onTap: () => Navigator.push(
                            context,
                            AppPageRoute(builder: (_) => const MoodClubPage()),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _PulsoTendenciaCard(
                          title: 'Tendencia',
                          value: data.tendencia,
                          icon: Icons.trending_up_rounded,
                          foreground: const Color(0xFF3D7358),
                          background: const Color(0xFFF0F7F4),
                          border: const Color(0xFFB8D9C5),
                          onTap: () => Navigator.push(
                            context,
                            AppPageRoute(
                              builder: (_) => const TendenciasClubPage(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ),

                  if (data.rankingAfinidad.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _AffinityCard(
                      miembros: data.rankingAfinidad,
                      miAvatarUrl: avatarUrlActual,
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
                  ], // fin if (!widget.esPersonal)

                  const SizedBox(height: AppSpacing.lg),

                  _estadisticasMes(
                    actividad: data.resumen.actividadMes,
                    valoracion: data.resumen.valoracionMedia,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  const _RachaLectoraCard(),

                  const SizedBox(height: AppSpacing.lg),

                  ClubSectionTitle(
                    title: 'Leyendo ahora',
                    subtitle: widget.esPersonal
                        ? 'Tus lecturas activas'
                        : 'Qué tienen entre manos las lectoras',
                    icon: Icons.menu_book_rounded,
                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  if (data.leyendoAhora.isEmpty)
                    ClubEmptyState(
                      icon: Icons.menu_book_outlined,
                      title: widget.esPersonal
                          ? 'Aún no tienes lecturas activas'
                          : 'El club está entre lecturas',
                      message: widget.esPersonal
                          ? 'Ve a Libros y empieza una nueva lectura.'
                          : 'Cuando alguna lectora empiece un libro, aparecerá aquí.',
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
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
                ? '¿Quién lo conseguirá este mes?'
                : 'El podio lector de este mes',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Podio — siempre muestra 3 puestos; los vacíos animan a participar
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
                    : const _PodioPuestoVacio(
                        posicion: 2,
                        altura: 44,
                        color: Color(0xFF9AA3AD),
                      ),
              ),

              const SizedBox(width: AppSpacing.xs),

              Expanded(
                child: participantes.isNotEmpty
                    ? _PodioPuesto(
                        item: participantes.first,
                        posicion: 1,
                        altura: 60,
                        color: AppColors.gold,
                        destacado: true,
                        onTap: () => _abrirPerfil(participantes.first.nombre),
                      )
                    : const _PodioPuestoVacio(
                        posicion: 1,
                        altura: 60,
                        color: AppColors.gold,
                        destacado: true,
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
                    : const _PodioPuestoVacio(
                        posicion: 3,
                        altura: 36,
                        color: Color(0xFFB77A4A),
                      ),
              ),
            ],
          ),
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
            variant: InfoCardVariant.coral,
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
              ValueListenableBuilder<LecturaAhoraItem>(
                valueListenable: _reactionNotifier(lecturas[index]),
                builder: (context, lectura, _) => _LecturaProgresoCard(
                  key: ValueKey('progress-${lectura.libraryId}'),
                  lectura: lectura,
                  editable:
                      usuarioActual?.trim().toLowerCase() ==
                      nombre.trim().toLowerCase(),
                  onEditar: () => _editarProgreso(nombre, lectura),
                  onBookTap: () => openBookDetail(
                    context,
                    title: lectura.titulo,
                    bookId: lectura.bookId,
                    coverUrl: lectura.coverUrl,
                  ),
                  onReact: () => _reaccionarProgreso(lectura),
                ),
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
    _reactingProgressIds.add(lectura.libraryId);
    _reactionNotifier(lectura).value = optimistic;
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
      _reactionNotifier(lectura).value = _withReactionState(
        previous,
        reactions: {
          for (final item in ReaccionComentario.values)
            item: (rawReactions[item.apiValue] as num?)?.toInt() ?? 0,
        },
        myReaction: ReaccionComentarioDatos.fromApi(
          result['miReaccion']?.toString(),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _reactionNotifier(lectura).value = previous;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido guardar la reacción.')),
      );
    } finally {
      _reactingProgressIds.remove(lectura.libraryId);
    }
  }

  LecturaAhoraItem _effectiveReading(LecturaAhoraItem reading) =>
      _reactionNotifiers[reading.libraryId]?.value ?? reading;

  ValueNotifier<LecturaAhoraItem> _reactionNotifier(LecturaAhoraItem reading) =>
      _reactionNotifiers.putIfAbsent(
        reading.libraryId,
        () => ValueNotifier<LecturaAhoraItem>(reading),
      );

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
    super.key,
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
// Puesto vacío del podio (inicio de mes / sin datos)
// ─────────────────────────────────────────────

class _PodioPuestoVacio extends StatelessWidget {
  final int posicion;
  final double altura;
  final Color color;
  final bool destacado;

  const _PodioPuestoVacio({
    required this.posicion,
    required this.altura,
    required this.color,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Copa o espacio arriba (igual que _PodioPuesto)
        if (destacado)
          Icon(Icons.emoji_events_rounded, color: color.withValues(alpha: .35), size: 18)
        else
          const SizedBox(height: 18),

        const SizedBox(height: AppSpacing.xxs),

        // Avatar placeholder — círculo punteado
        Container(
          width: destacado ? 52 : 46,
          height: destacado ? 52 : 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: .45),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            color: color.withValues(alpha: .07),
          ),
          child: Center(
            child: Text(
              '?',
              style: TextStyle(
                fontSize: destacado ? 22 : 18,
                fontWeight: FontWeight.w900,
                color: color.withValues(alpha: .4),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xxs),

        Text(
          'Libre',
          maxLines: 1,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),

        Text(
          '–',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),

        const SizedBox(height: AppSpacing.xxs),

        // Bloque del podio — translúcido y con patrón de puntos
        Container(
          height: altura,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .14),
            border: Border.all(
              color: color.withValues(alpha: .28),
              width: 1.5,
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(14),
            ),
          ),
          child: Text(
            '$posicion',
            style: AppTextStyles.title.copyWith(
              color: color.withValues(alpha: .4),
              fontSize: destacado ? 25 : 21,
            ),
          ),
        ),
      ],
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
                child: OptimizedNetworkImage(
                  url: miembro.avatarUrl,
                  width: size,
                  height: size,
                  fallback: _initials(),
                ),
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
  const _LogrosClubCard({this.esPersonal = false});

  final bool esPersonal;

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
                  esPersonal
                      ? 'Tu progreso lector este año'
                      : 'Ve el progreso de todas las lectoras',
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

// Card de ranking de logros del club
// ─────────────────────────────────────────────
class _AchievementsClubCard extends StatelessWidget {
  const _AchievementsClubCard({this.esPersonal = false});

  final bool esPersonal;

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF8E5), Color(0xFFFFEDD5)],
      ),
      borderColor: AppColors.gold.withValues(alpha: .3),
      onTap: () => Navigator.push<void>(
        context,
        AppPageRoute(builder: (_) => const ClubLogrosPage()),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.gold,
              size: 27,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esPersonal ? 'Mis logros' : 'Logros del club',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  esPersonal
                      ? 'Tus logros desbloqueados este año'
                      : 'Ranking y últimos logros desbloqueados',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Racha lectora — días consecutivos abriendo la app
// ─────────────────────────────────────────────────────────────────────────────

class _RachaLectoraCard extends StatefulWidget {
  const _RachaLectoraCard();

  @override
  State<_RachaLectoraCard> createState() => _RachaLectoraCardState();
}

class _RachaLectoraCardState extends State<_RachaLectoraCard> {
  late final Future<int> _rachaFuture;

  @override
  void initState() {
    super.initState();
    // Registra la visita de hoy y obtiene el total actualizado
    _rachaFuture = ReadingStreakService.registrarVisita();
  }

  Future<void> _irASeguimiento(BuildContext context) async {
    final usuario = AuthSessionService.instance.user?.nombre ?? '';
    if (usuario.isEmpty) return;
    await Navigator.push<void>(
      context,
      AppPageRoute(
        builder: (_) => PerfilUsuarioPage(
          usuario: usuario,
          scrollToSeguimiento: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _rachaFuture,
      builder: (context, snap) {
        final racha = snap.data ?? 0;
        return _RachaLectoraTile(
          racha: racha,
          onTap: () => _irASeguimiento(context),
        );
      },
    );
  }
}

class _RachaLectoraTile extends StatelessWidget {
  const _RachaLectoraTile({required this.racha, this.onTap});

  final int racha;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (emoji, mensaje, color) = _datos(racha);

    return GestureDetector(
      onTap: onTap,
      child: ClubCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      borderColor: color.withValues(alpha: 0.35),
      child: Row(
        children: [
          // ── Icono de llama ──────────────────────────────────────────────
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // ── Texto central ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Racha lectora',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  mensaje,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // ── Contador de días ────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Column(
              key: ValueKey(racha),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$racha',
                  style: AppTextStyles.section.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Text(
                  racha == 1 ? 'día' : 'días',
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // ── Chevron de navegación ───────────────────────────────────────
          if (onTap != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ],
      ),
    ),
    );
  }

  static (String emoji, String mensaje, Color color) _datos(int racha) {
    if (racha >= 30) {
      return ('🏆', '¡Racha legendaria!', AppColors.gold);
    } else if (racha >= 14) {
      return ('🔥', '¡Imparable!', AppColors.inkCoral);
    } else if (racha >= 7) {
      return ('⚡', '¡Una semana seguida!', AppColors.inkCoral);
    } else if (racha >= 3) {
      return ('🔥', '¡En racha!', AppColors.inkCoral);
    } else if (racha == 2) {
      return ('📖', '¡Dos días seguidos!', AppColors.inkCoral);
    } else {
      return ('📖', 'Sigue leyendo cada día', AppColors.textSecondary);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta compacta: Pulso del club / Tendencia
// Muestra el título con claridad arriba, el valor debajo con wrap completo,
// y un ícono decorativo a la derecha con animación de pulso opcional.
// ─────────────────────────────────────────────────────────────────────────────

class _PulsoTendenciaCard extends StatefulWidget {
  const _PulsoTendenciaCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.border,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color foreground;
  final Color background;
  final Color border;
  final VoidCallback? onTap;

  @override
  State<_PulsoTendenciaCard> createState() => _PulsoTendenciaCardState();
}

class _PulsoTendenciaCardState extends State<_PulsoTendenciaCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: widget.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: widget.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: ícono animado + título
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Icon(
                    widget.icon,
                    color: widget.foreground,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTextStyles.caption.copyWith(
                      color: widget.foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: widget.foreground.withValues(alpha: 0.6),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // Valor — texto completo, sin truncar
            Text(
              widget.value,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
