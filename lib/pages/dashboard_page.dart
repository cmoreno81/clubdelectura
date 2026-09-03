import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

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
import '../widgets/dashboard/club_books_of_year_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/common/club_empty_state.dart';
import '../widgets/common/club_section_title.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/optimized_network_image.dart';
import '../widgets/error_view.dart';
import '../widgets/info_card.dart';
import 'mood_club_page.dart';
import 'perfil_usuario_page.dart';
import '../models/perfil_usuario.dart';
import 'ranking_page.dart';
import 'tendencias_club_page.dart';
import 'club_book_of_year_page.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';
import '../widgets/common/reaction_details_sheet.dart';
import '../models/personalidad_miembro.dart';
import 'personalidad_lectora_page.dart';
import '../models/wishlist.dart';
import '../models/general_dashboard.dart';
import '../services/general_dashboard_service.dart';
import '../services/wishlist_service.dart';
import 'club_wishlist_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.clubName,
    this.clubId,
    this.esPersonal = false,
    this.controller,
    this.loadData,
    this.initialUser,
    this.profilePageBuilder,
    this.loadCheckinHistory,
  });

  final String clubName;

  /// ID del club activo. Si se proporciona, las notificaciones de "Actividad
  /// del club" se filtran para mostrar solo las de este club.
  final String? clubId;
  final bool esPersonal;
  final DashboardPageController? controller;
  final Future<DashboardViewData> Function()? loadData;
  final AuthUser? initialUser;
  final Widget Function(String userName)? profilePageBuilder;
  final Future<Map<String, dynamic>> Function()? loadCheckinHistory;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class DashboardPageController {
  Future<void> Function()? _refresh;

  Future<void> refresh() => _refresh?.call() ?? Future<void>.value();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<DashboardViewData> dashboardFuture;
  /// Datos ampliados del usuario (estantería anual, biblioteca personal, etc.).
  /// Solo se carga en modo personal.
  late Future<GeneralDashboard?> _generalFuture;
  final Map<String, ValueNotifier<LecturaAhoraItem>> _reactionNotifiers = {};
  final Set<String> _reactingProgressIds = {};

  String? usuarioActual;
  String avatarUrlActual = '';
  bool _headerLoading = true;

  /// Se incrementa en cada recarga para forzar que _FavoritosClubCard se recree.
  int _favoritosKey = 0;

  @override
  void initState() {
    super.initState();
    final sessionUser = widget.initialUser ?? AuthSessionService.instance.user;
    usuarioActual = sessionUser?.nombre.trim();
    avatarUrlActual = sessionUser?.avatarUrl.trim() ?? '';
    widget.controller?._refresh = _recargar;
    dashboardFuture = _cargarDashboard();
    if (widget.esPersonal) {
      _generalFuture = GeneralDashboardService()
          .load()
          .then<GeneralDashboard?>((d) => d)
          .catchError((_) => null);
    } else {
      _generalFuture = Future.value(null);
      unawaited(NotificacionesService.instance.cargar());
    }
  }

  Future<void> _abrirNotificaciones() async {
    final notif = await mostrarNotificacionesSheet(
      context,
      titulo: 'Actividad del club',
      filtro: (n) {
        const tipos = {
          'LIBRO_TERMINADO',
          'LIBRO_EMPEZADO',
          'LIBRO_NUEVO_BIBLIOTECA',
          'NUEVA_MIEMBRO',
          'CLUB_BOOK_OF_YEAR',
        };
        if (!tipos.contains(n.tipo)) return false;
        final clubId = widget.clubId;
        if (clubId != null && clubId.isNotEmpty) {
          return n.clubId == null || n.clubId == clubId;
        }
        return true;
      },
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
      if (v.isNotEmpty) {
        bookTitle = v;
        break;
      }
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
      case 'CLUB_BOOK_OF_YEAR':
        if (widget.esPersonal) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Esta edición pertenece a un club social.'),
            ),
          );
          return;
        }
        final year = int.tryParse(extra['year']?.toString() ?? '');
        await Navigator.push<void>(
          context,
          AppPageRoute(builder: (_) => ClubBookOfYearPage(initialYear: year)),
        );
        if (mounted) await _recargar();
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
      if (widget.esPersonal) {
        _generalFuture = GeneralDashboardService()
            .load()
            .then<GeneralDashboard?>((d) => d)
            .catchError((_) => null);
      }
      _favoritosKey++;
    });

    await dashboardFuture;
  }

  void _abrirPerfil(String usuario, {String? profileUserId}) {
    final limpio = usuario.trim();

    if (limpio.isEmpty) return;

    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) =>
            widget.profilePageBuilder?.call(limpio) ??
            PerfilUsuarioPage(usuario: limpio, profileUserId: profileUserId),
      ),
    );
  }

  Future<void> _abrirMiPerfil({bool scrollToSeguimiento = false}) async {
    final nombre = usuarioActual?.trim() ?? '';
    final userId = AuthSessionService.instance.user?.id.trim() ?? '';
    if (nombre.isEmpty) return;
    await Navigator.push<void>(
      context,
      AppPageRoute(
        builder: (_) =>
            scrollToSeguimiento
                ? PerfilUsuarioPage(
                    usuario: nombre,
                    profileUserId: userId.isEmpty ? null : userId,
                    scrollToSeguimiento: true,
                  )
                : widget.profilePageBuilder?.call(nombre) ??
                    PerfilUsuarioPage(
                      usuario: nombre,
                      profileUserId: userId.isEmpty ? null : userId,
                    ),
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
            ganador: data.clubvision.ganador,
          );

          return RefreshIndicator(
            onRefresh: _recargar,
            // Solo activar cuando el usuario arrastra activamente con el dedo
            // (dragDetails != null). Los flings y bounces que sobrepasan el
            // tope tienen dragDetails == null y no deben disparar el refresh.
            notificationPredicate: (notification) {
              if (notification.depth != 0) return false;
              if (notification is ScrollUpdateNotification) {
                if (notification.dragDetails == null) return false;
                if ((notification.dragDetails!.delta.dy) < 0) return false;
              }
              return true;
            },
            child: widget.esPersonal
                ? FutureBuilder<GeneralDashboard?>(
                    future: _generalFuture,
                    builder: (context, genSnap) {
                      return _personalDashboardScrollView(
                        data: data,
                        viewData: viewData,
                        general: genSnap.data,
                      );
                    },
                  )
                : SingleChildScrollView(
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
                    title: widget.esPersonal
                        ? 'Tu actividad de lectura'
                        : 'Así está el club',
                    subtitle: widget.esPersonal
                        ? 'Tu mes en números'
                        : 'El pulso lector de este mes',
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
                              gradientColors: const [
                                Color(0xFFD63070),
                                Color(0xFFE8607A),
                              ],
                              onTap: () => Navigator.push(
                                context,
                                AppPageRoute(
                                  builder: (_) => const MoodClubPage(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _PulsoTendenciaCard(
                              title: 'Tendencia',
                              value: data.tendencia,
                              icon: Icons.trending_up_rounded,
                              gradientColors: const [
                                Color(0xFF1F7A55),
                                Color(0xFF39A876),
                              ],
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

                    const SizedBox(height: AppSpacing.md),
                    const _ClubWishlistCard(),

                    if (data.rankingAfinidad.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _AffinityCard(
                        miembros: data.rankingAfinidad,
                        miAvatarUrl: avatarUrlActual,
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),
                    _FavoritosClubCard(key: ValueKey(_favoritosKey)),
                    const SizedBox(height: AppSpacing.md),
                    ClubBooksOfYearCard(
                      key: ValueKey('book-of-year-$_favoritosKey'),
                      currentUserName: usuarioActual,
                      currentUserId: AuthSessionService.instance.user?.id,
                    ),

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
                    esPersonal: widget.esPersonal,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  RachaLectoraCard(
                    key: ValueKey('reading-streak-$_favoritosKey'),
                    loadHistory: widget.loadCheckinHistory,
                    onTap: () => _abrirMiPerfil(scrollToSeguimiento: true),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  ClubSectionTitle(
                    title: 'Leyendo ahora',
                    subtitle: widget.esPersonal
                        ? 'Tus lecturas activas'
                        : 'Qué tienen entre manos los miembros',
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
                          : 'Cuando alguien empiece un libro, aparecerá aquí.',
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                      ),
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

                  // ── Personalidades — sección más estática, al final ───────
                  if (!widget.esPersonal) ...[
                    const SizedBox(height: AppSpacing.md),
                    const _PersonalidadesClubCard(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Dashboard personal ────────────────────────────────────────────────────

  Widget _personalDashboardScrollView({
    required Dashboard data,
    required DashboardViewData viewData,
    GeneralDashboard? general,
  }) {
    final year = DateTime.now().year;
    final yearBooks = general?.yearShelf ?? const [];
    final personalLib = general?.personalLibrary ?? const [];
    final currentBooks = data.leyendoAhora;
    final highPriority = personalLib
        .where((b) => b.isHighPriority && b.status == 'PENDIENTE')
        .take(5)
        .toList();

    // Género favorito: el más frecuente en la biblioteca personal
    final genreCounts = <String, int>{};
    for (final b in personalLib) {
      if (b.genre.isNotEmpty && b.genre != 'Sin género') {
        genreCounts[b.genre] = (genreCounts[b.genre] ?? 0) + 1;
      }
    }
    final favoriteGenre = genreCounts.entries.isEmpty
        ? null
        : genreCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    return SingleChildScrollView(
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
          // ── 1. Leyendo ahora ──────────────────────────────────────────────
          if (currentBooks.isNotEmpty) ...[
            ClubSectionTitle(
              title: 'Leyendo ahora',
              subtitle: 'Tu lectura activa',
              icon: Icons.menu_book_rounded,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...currentBooks.map(
              (u) => _lectoraLeyendoCard(
                nombre: u.usuario,
                lecturas: u.lecturas,
                total: u.total,
                avatarUrl: u.avatarUrl,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── 2. Mi año en libros ───────────────────────────────────────────
          _PersonalYearShelfCard(
            year: year,
            books: yearBooks,
            favoriteGenre: favoriteGenre,
            totalLibrary: general?.summary.enEstanteria ?? personalLib.length,
          ),

          // ── 3. Sagas en curso ─────────────────────────────────────────────
          if ((general?.openSeries ?? []).isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            ClubSectionTitle(
              title: 'Sagas en curso',
              subtitle: 'Tu progreso en cada serie',
              icon: Icons.auto_stories_rounded,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
            _PersonalOpenSeriesShelf(series: general!.openSeries),
          ],

          const SizedBox(height: AppSpacing.md),

          // ── 4. Reto lector + racha ────────────────────────────────────────
          _LogrosClubCard(esPersonal: true),
          const SizedBox(height: AppSpacing.sm),
          _AchievementsClubCard(esPersonal: true),
          const SizedBox(height: AppSpacing.sm),
          RachaLectoraCard(
            key: ValueKey('reading-streak-$_favoritosKey'),
            loadHistory: widget.loadCheckinHistory,
            onTap: () => _abrirMiPerfil(scrollToSeguimiento: true),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── 5. Stats del mes ──────────────────────────────────────────────
          _estadisticasMes(
            actividad: data.resumen.actividadMes,
            valoracion: data.resumen.valoracionMedia,
            esPersonal: true,
          ),

          // ── 6. Próximas lecturas (alta prioridad) ─────────────────────────
          if (highPriority.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            ClubSectionTitle(
              title: 'Próximas lecturas',
              subtitle: 'Las que tienes marcadas como prioritarias',
              icon: Icons.bookmark_rounded,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
            _PersonalPriorityShelf(books: highPriority),
          ],

          // ── Si no tiene nada leyendo: estado vacío ────────────────────────
          if (currentBooks.isEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            ClubEmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Aún no tienes lecturas activas',
              message: 'Ve a Libros y empieza una nueva lectura.',
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            ),
          ],
        ],
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
      padding: EdgeInsets.zero,
      borderColor: AppColors.primaryLight,
      onTap: () => _abrirRanking(initialTab: 1),
      child: Column(
        children: [
          // ── Cabecera morada con gradiente ────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(23),
                topRight: Radius.circular(11),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 26)),
                const SizedBox(height: 4),
                const Text(
                  'Ranking del club',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  participantes.isEmpty
                      ? '¿Quién lo conseguirá este mes?'
                      : 'El podio lector de este mes',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ── Podio ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
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
                          onTap: () =>
                              _abrirPerfil(participantes.first.nombre),
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
          ),

          // ── Enlace ranking completo ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
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
          ),
        ],
      ),
    );
  }

  Widget _estadisticasMes({
    required int actividad,
    required String valoracion,
    bool esPersonal = false,
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
            onTap: esPersonal ? null : () => _abrirRanking(initialTab: 1),
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: InfoCard(
            title: esPersonal ? 'Mi media' : 'Media del club',
            value: valoracion == '0' ? 'Sin datos' : '$valoracion / 5',
            icon: Icons.star_outline_rounded,
            variant: InfoCardVariant.gold,
            compact: true,
            onTap: esPersonal ? null : () => _abrirRanking(initialTab: 2),
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
                  onReactionDetails: () => ReactionDetailsSheet.show(
                    context,
                    targetType: 'PROGRESS',
                    targetId: lectura.libraryId,
                  ),
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

  final Set<String> _savingProgressIds = <String>{};

  Future<void> _editarProgreso(String usuario, LecturaAhoraItem lectura) async {
    final progressId = lectura.libraryId.isNotEmpty
        ? lectura.libraryId
        : lectura.bookId;
    if (_savingProgressIds.contains(progressId)) return;
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
    if (_savingProgressIds.contains(progressId)) return;

    setState(() => _savingProgressIds.add(progressId));
    try {
      final guardado = await ApiService().actualizarProgresoLectura(
        usuario: usuario,
        libro: lectura.titulo,
        progreso: resultado.progreso,
        comentario: resultado.comentario,
        paginaActual: resultado.paginaActual,
        paginasTotales: resultado.paginasTotales,
      );
      if (!mounted) return;
      if (!guardado.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              guardado.mensaje.isNotEmpty
                  ? guardado.mensaje
                  : 'No se ha podido guardar el progreso.',
            ),
          ),
        );
        return;
      }
      if (resultado.paginaActual != null &&
          guardado.paginaActual != resultado.paginaActual) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El servidor devolvió una página diferente.'),
          ),
        );
      }
      await _recargar();
    } finally {
      if (mounted) setState(() => _savingProgressIds.remove(progressId));
    }
  }

  Future<void> _reaccionarProgreso(LecturaAhoraItem lectura) async {
    if (lectura.libraryId.isEmpty ||
        _reactingProgressIds.contains(lectura.libraryId)) {
      return;
    }
    final reaccion = await showModalBottomSheet<ReaccionComentario>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final bottomPad = MediaQuery.viewPaddingOf(context).bottom;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + bottomPad,
          ),
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
        );
      },
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
  final VoidCallback onReactionDetails;

  const _LecturaProgresoCard({
    super.key,
    required this.lectura,
    required this.editable,
    required this.onEditar,
    required this.onBookTap,
    required this.onReact,
    required this.onReactionDetails,
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
                          ActionChip(
                            tooltip: 'Ver quién ha reaccionado',
                            onPressed: onReactionDetails,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
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
          Icon(
            Icons.emoji_events_rounded,
            color: color.withValues(alpha: .35),
            size: 18,
          )
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
            border: Border.all(color: color.withValues(alpha: .28), width: 1.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
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
              // Emoji protagonista sin cuadrado contenedor
              const Text('👥', style: TextStyle(fontSize: 30)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compañeros de lectura',
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
// ─────────────────────────────────────────────
// Anillo de progreso circular (reto lector)
// ─────────────────────────────────────────────
class _RingProgress extends StatelessWidget {
  const _RingProgress({
    required this.value,
    required this.size,
    this.strokeWidth = 8,
    this.color = Colors.white,
    this.trackColor,
  });

  final double value; // 0.0 – 1.0
  final double size;
  final double strokeWidth;
  final Color color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RingPainter(
        value: value.clamp(0.0, 1.0),
        strokeWidth: strokeWidth,
        color: color,
        trackColor: trackColor ?? color.withValues(alpha: .2),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final arc = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5707963267948966, // -π/2 (top)
      6.283185307179586 * value, // 2π * value
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color;
}

// ─────────────────────────────────────────────
// Card: Reto lector
// ─────────────────────────────────────────────
class _LogrosClubCard extends StatefulWidget {
  const _LogrosClubCard({this.esPersonal = false});
  final bool esPersonal;

  @override
  State<_LogrosClubCard> createState() => _LogrosClubCardState();
}

class _LogrosClubCardState extends State<_LogrosClubCard> {
  late final Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService()
        .getClubChallenges()
        .then<Map<String, dynamic>?>((d) => d)
        .catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (context, snap) {
        int? myTarget;
        int myRead = 0;
        if (snap.hasData && snap.data != null) {
          final d = snap.data!;
          if (widget.esPersonal) {
            // Personal: buscar el registro propio (isMe: true) o el primero
            final challenges =
                (d['challenges'] as List<dynamic>? ?? []);
            final myChallenge = challenges
                    .cast<Map>()
                    .firstWhere(
                      (c) => c['isMe'] == true,
                      orElse: () => challenges.isNotEmpty
                          ? Map<String, dynamic>.from(
                              challenges.first as Map)
                          : <String, dynamic>{},
                    )
                    as Map<String, dynamic>;
            myTarget = myChallenge['target'] != null
                ? (myChallenge['target'] as num).toInt()
                : null;
            myRead = (myChallenge['read'] as num? ?? 0).toInt();
          } else {
            // Club: mostrar el reto colectivo
            final clubTarget = d['clubTarget'];
            final clubTotal = d['clubTotal'];
            final clubTargetNum = clubTarget as num?;
            myTarget = clubTargetNum != null && clubTargetNum > 0
                ? clubTargetNum.toInt()
                : null;
            myRead = (clubTotal as num? ?? 0).toInt();
          }
        }

        final hasData = snap.hasData && myTarget != null;
        final target = myTarget ?? 1;
        final progress =
            hasData ? (myRead / target).clamp(0.0, 1.0) : 0.0;
        final pct = (progress * 100).round();
        final faltan = hasData ? target - myRead : 0;
        final completado = hasData && faltan <= 0;

        return GestureDetector(
          onTap: () => Navigator.push<void>(
            context,
            AppPageRoute(builder: (_) => const ClubChallengePage()),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C3CE1), Color(0xFF3B7BF6)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // — Izquierda: textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🔥',
                              style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            widget.esPersonal
                                ? 'Mi reto lector $year'
                                : 'Reto colectivo $year',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$myRead',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            if (hasData)
                              TextSpan(
                                text: ' / $target',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasData
                            ? (completado
                                ? '¡Reto completado! 🎉'
                                : 'Faltan $faltan libro${faltan == 1 ? '' : 's'}')
                            : 'Libros leídos',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // — Derecha: anillo de progreso
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _RingProgress(
                      value: progress,
                      size: 80,
                      strokeWidth: 9,
                      color: Colors.white,
                      trackColor: Colors.white.withValues(alpha: .18),
                    ),
                    Text(
                      hasData ? '$pct%' : '—',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Card: Mis logros
// ─────────────────────────────────────────────
class _AchievementsClubCard extends StatefulWidget {
  const _AchievementsClubCard({this.esPersonal = false});
  final bool esPersonal;

  @override
  State<_AchievementsClubCard> createState() => _AchievementsClubCardState();
}

class _AchievementsClubCardState extends State<_AchievementsClubCard> {
  late final Future<Map<String, dynamic>?> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService()
        .getRecentClubAchievements()
        .then<Map<String, dynamic>?>((d) => d)
        .catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _future,
      builder: (context, snap) {
        // Últimos logros (máx 4 emojis visibles)
        // Cada item de `achievements` tiene achievementIcon/achievementTitle directamente
        final recientes = snap.hasData
            ? (snap.data!['achievements'] as List<dynamic>? ?? [])
                .take(4)
                .map((e) {
                  final m = Map<String, dynamic>.from(e as Map);
                  return <String, dynamic>{
                    'icon': m['achievementIcon']?.toString() ?? '🏅',
                    'title': m['achievementTitle']?.toString() ?? '',
                  };
                })
                .toList()
            : <Map<String, dynamic>>[];

        // Total logros: para personal = total del primer (único) ranking entry;
        // para club = suma de todos los miembros
        int myTotal = 0;
        if (snap.hasData) {
          final ranking =
              snap.data!['ranking'] as List<dynamic>? ?? [];
          if (widget.esPersonal && ranking.isNotEmpty) {
            // En personal solo hay un entry (el propio usuario)
            final me = Map<String, dynamic>.from(ranking.first as Map);
            myTotal = (me['total'] as num? ?? 0).toInt();
          } else {
            // En club: suma de todos los miembros del ranking
            myTotal = ranking.fold<int>(0, (sum, e) {
              final m = Map<String, dynamic>.from(e as Map);
              return sum + ((m['total'] as num?)?.toInt() ?? 0);
            });
          }
        }

        final hayLogros = recientes.isNotEmpty;

        return GestureDetector(
          onTap: () => Navigator.push<void>(
            context,
            AppPageRoute(
              builder: (_) =>
                  ClubLogrosPage(esPersonal: widget.esPersonal),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFD4960A), Color(0xFFE8B84B)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // — Cabecera
                Row(
                  children: [
                    const Text('🏆',
                        style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      widget.esPersonal
                          ? 'Mis logros'
                          : 'Logros del club',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .2,
                      ),
                    ),
                    const Spacer(),
                    if (myTotal > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .25),
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          '$myTotal desbloqueado${myTotal == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 14),
                // — Emojis de logros o placeholder
                if (hayLogros)
                  Row(
                    children: [
                      for (final logro in recientes) ...[
                        _LogroBadge(
                          emoji: logro['icon']?.toString() ?? '🏅',
                          titulo: logro['title']?.toString() ?? '',
                        ),
                        if (logro != recientes.last)
                          const SizedBox(width: 10),
                      ],
                    ],
                  )
                else ...[
                  Row(
                    children: [
                      for (final placeholder in ['🏅', '📚', '⭐', '🎯']) ...[
                        _LogroBadge(
                          emoji: placeholder,
                          titulo: '',
                          dimmed: true,
                        ),
                        if (placeholder != '🎯')
                          const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Completa retos para desbloquear logros',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LogroBadge extends StatelessWidget {
  const _LogroBadge({
    required this.emoji,
    required this.titulo,
    this.dimmed = false,
  });

  final String emoji;
  final String titulo;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: dimmed
                ? Colors.white.withValues(alpha: .15)
                : Colors.white.withValues(alpha: .28),
            shape: BoxShape.circle,
            border: dimmed
                ? Border.all(
                    color: Colors.white.withValues(alpha: .2), width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            emoji,
            style: TextStyle(
              fontSize: 26,
              color: dimmed
                  ? Colors.white.withValues(alpha: .35)
                  : null,
            ),
          ),
        ),
        if (titulo.isNotEmpty) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: 56,
            child: Text(
              titulo,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Racha lectora — check-ins diarios confirmados por el backend
// ─────────────────────────────────────────────────────────────────────────────

class RachaLectoraCard extends StatefulWidget {
  const RachaLectoraCard({super.key, this.loadHistory, this.onTap});

  final Future<Map<String, dynamic>> Function()? loadHistory;
  final VoidCallback? onTap;

  @override
  State<RachaLectoraCard> createState() => _RachaLectoraCardState();
}

class _RachaLectoraCardState extends State<RachaLectoraCard> {
  late final Future<Map<String, dynamic>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture =
        widget.loadHistory?.call() ?? ApiService().getHistorialCheckin(dias: 7);
  }

  Future<void> _irASeguimiento(BuildContext context) async {
    final usuario = AuthSessionService.instance.user?.nombre ?? '';
    if (usuario.isEmpty) return;
    await Navigator.push<void>(
      context,
      AppPageRoute(
        builder: (_) => PerfilUsuarioPage(
          usuario: usuario,
          profileUserId: AuthSessionService.instance.user?.id,
          scrollToSeguimiento: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _historyFuture,
      builder: (context, snap) {
        final racha = (snap.data?['streak'] as num?)?.toInt() ?? 0;
        final checkedToday = snap.data?['checkedToday'] == true;
        return _RachaLectoraTile(
          racha: racha,
          checkedToday: checkedToday,
          onTap: widget.onTap ?? () => _irASeguimiento(context),
        );
      },
    );
  }
}

class _RachaLectoraTile extends StatelessWidget {
  const _RachaLectoraTile({
    required this.racha,
    required this.checkedToday,
    this.onTap,
  });

  final int racha;
  final bool checkedToday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (emoji, mensaje, color) = checkedToday
        ? _datos(racha)
        : ('📖', 'Marca que has leído hoy', AppColors.textSecondary);

    // ── Racha activa (≥3 días): tarjeta con gradiente flamígero ─────────────
    if (checkedToday && racha >= 3) {
      final gradientColors = racha >= 30
          ? [const Color(0xFFAA7A00), const Color(0xFFD4A800)] // dorado
          : racha >= 14
              ? [const Color(0xFFB82400), const Color(0xFFE85020)] // rojo coral
              : [const Color(0xFFD84B00), const Color(0xFFFF7040)]; // naranja llama

      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(24),
              bottomLeft: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withValues(alpha: .35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // ── Número de días protagonista ────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Text(
                      '$racha',
                      key: ValueKey(racha),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                  Text(
                    racha == 1 ? 'día' : 'días',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: AppSpacing.md),

              // ── Etiqueta + mensaje ─────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RACHA DE LECTURA',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mensaje,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Emoji grande ───────────────────────────────────────────
              Text(emoji, style: const TextStyle(fontSize: 38)),
            ],
          ),
        ),
      );
    }

    // ── Racha baja o sin check-in: ClubCard neutra ───────────────────────────
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
                    'Racha de lectura',
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
    required this.gradientColors,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;
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
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.88, end: 1.12).animate(
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.gradientColors,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: ícono animado + título + flecha
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Icon(widget.icon, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: Colors.white60,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Valor — texto destacado
            Text(
              widget.value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta "Favoritos del club"
// ─────────────────────────────────────────────────────────────────────────────

class _FavoritosClubCard extends StatefulWidget {
  const _FavoritosClubCard({super.key});

  @override
  State<_FavoritosClubCard> createState() => _FavoritosClubCardState();
}

class _FavoritosClubCardState extends State<_FavoritosClubCard> {
  List<MiembroFavoritos>? _miembros;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await ApiService().getFavoritosDelClub();
      if (!mounted) return;
      setState(() {
        _miembros = lista;
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _verFavoritos(MiembroFavoritos miembro) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FavoritosDeUsuarioSheet(miembro: miembro),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ocultar si no hay nadie con favoritos (incluida la usuaria actual)
    if (!_cargando && (_miembros == null || _miembros!.isEmpty)) {
      return const SizedBox.shrink();
    }
    // También ocultar si la única entrada soy yo y no tengo favoritos
    if (!_cargando &&
        _miembros!.length == 1 &&
        _miembros!.first.esTu &&
        _miembros!.first.favoritos.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClubCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera con degradado rosa suave
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7D0E0), Color(0xFFFFEDF5)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(23),
                topRight: Radius.circular(11),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                const Text('❤️', style: TextStyle(fontSize: 26)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Favoritos del club',
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFAD2F5A),
                        ),
                      ),
                      Text(
                        'Los 5 libros favoritos de los miembros',
                        style: AppTextStyles.caption.copyWith(
                          color: const Color(0xFFAD2F5A).withValues(alpha: .6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

          if (_cargando)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: CircularProgressIndicator(),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _miembros!
                    .map(
                      (m) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: _FavoritosMiembroTile(
                          miembro: m,
                          onTap: () => _verFavoritos(m),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            ],       // cierra inner Column children
          ),         // cierra inner Column
        ),           // cierra Padding
        const SizedBox(height: AppSpacing.sm),
      ],             // cierra outer Column children
    ),               // cierra outer Column
  );                 // cierra ClubCard
  }
}

class _FavoritosMiembroTile extends StatelessWidget {
  const _FavoritosMiembroTile({required this.miembro, required this.onTap});

  final MiembroFavoritos miembro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClubAvatar(
                nombre: miembro.nombre,
                imageUrl: miembro.avatarUrl,
                size: 52,
              ),
              // Miniatura del primer favorito
              if (miembro.favoritos.isNotEmpty)
                Positioned(
                  bottom: -4,
                  right: -6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child:
                        miembro.favoritos.first.coverUrl != null &&
                            miembro.favoritos.first.coverUrl!.isNotEmpty
                        ? OptimizedNetworkImage(
                            url: miembro.favoritos.first.coverUrl,
                            width: 22,
                            height: 32,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 22,
                            height: 32,
                            color: const Color(0xFFD4537E),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            miembro.esTu ? 'Tú' : miembro.nombre,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FavoritosDeUsuarioSheet extends StatelessWidget {
  const _FavoritosDeUsuarioSheet({required this.miembro});
  final MiembroFavoritos miembro;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Row(
                children: [
                  ClubAvatar(
                    nombre: miembro.nombre,
                    imageUrl: miembro.avatarUrl,
                    size: 36,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          miembro.esTu
                              ? 'Tus favoritos'
                              : 'Favoritos de ${miembro.nombre}',
                          style: AppTextStyles.section,
                        ),
                        Text(
                          '${miembro.favoritos.length} libro${miembro.favoritos.length == 1 ? '' : 's'}',
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
              Row(
                children: [
                  for (var i = 0; i < 5; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 4 ? 8 : 0),
                        child: i < miembro.favoritos.length
                            ? _MiniPortada(
                                libro: miembro.favoritos[i],
                                onTap: () {
                                  final libro = miembro.favoritos[i];
                                  Navigator.pop(context);
                                  openBookDetail(
                                    context,
                                    title: libro.title,
                                    bookId: libro.bookId,
                                    coverUrl: libro.coverUrl ?? '',
                                    genre: libro.genreName,
                                  );
                                },
                              )
                            : const _MiniSlotVacio(),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Navegar al perfil
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_outline_rounded, size: 18),
                  label: Text('Ver perfil de ${miembro.nombre}'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push<void>(
                      context,
                      AppPageRoute(
                        builder: (_) => PerfilUsuarioPage(
                          usuario: miembro.nombre,
                          profileUserId: miembro.userId.isEmpty
                              ? null
                              : miembro.userId,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPortada extends StatelessWidget {
  const _MiniPortada({required this.libro, this.onTap});
  final LibroFavorito libro;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: libro.coverUrl != null && libro.coverUrl!.isNotEmpty
                    ? OptimizedNetworkImage(
                        url: libro.coverUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: cs.surfaceContainerHighest,
                        child: Center(
                          child: Text(
                            libro.title.isNotEmpty
                                ? libro.title[0].toUpperCase()
                                : '?',
                            style: AppTextStyles.section.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Positioned(
              bottom: 3,
              right: 3,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4537E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          libro.title,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),  // Column
    );  // GestureDetector
  }
}

class _MiniSlotVacio extends StatelessWidget {
  const _MiniSlotVacio();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border, width: 1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PersonalidadesClubCard
// ─────────────────────────────────────────────────────────────────────────────

class _PersonalidadesClubCard extends StatefulWidget {
  const _PersonalidadesClubCard();

  @override
  State<_PersonalidadesClubCard> createState() => _PersonalidadesClubCardState();
}

class _PersonalidadesClubCardState extends State<_PersonalidadesClubCard> {
  late Future<List<PersonalidadMiembro>> _future;

  @override
  void initState() {
    super.initState();
    _future = _syncAndLoad();
  }

  /// Si hay un resultado guardado en local (quiz hecho antes de que el campo
  /// existiera en el servidor), lo re-sube antes de pedir la lista del club.
  Future<List<PersonalidadMiembro>> _syncAndLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('quiz_personalidad_result');
      if (saved != null && saved.isNotEmpty) {
        await ApiService().guardarPersonalidadLectora(saved);
      }
    } catch (_) {
      // Fallo silencioso — la carga del club continúa igual
    }
    return ApiService().getPersonalidadesClub();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PersonalidadMiembro>>(
      future: _future,
      builder: (context, snap) {
        // Nada que mostrar mientras carga o si hay error silencioso
        if (snap.connectionState != ConnectionState.done) return const SizedBox.shrink();
        final miembros = snap.data ?? [];
        if (miembros.isEmpty) return const _SinPersonalidadesYet();
        return _PersonalidadesContent(miembros: miembros);
      },
    );
  }
}

/// Teaser para cuando nadie ha hecho el quiz aún — anima a ser el primero.
class _SinPersonalidadesYet extends StatelessWidget {
  const _SinPersonalidadesYet();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push<void>(
        context,
        AppPageRoute(builder: (_) => const PersonalidadLectoraPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E1A4A), Color(0xFF5E3A7A), Color(0xFF9E5FBF)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            const Text('🧬', style: TextStyle(fontSize: 28)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personalidades del club',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sé la primera en descubrir tu arquetipo lector',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: .70),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista con las personalidades de los miembros que han completado el quiz.
class _PersonalidadesContent extends StatelessWidget {
  const _PersonalidadesContent({required this.miembros});
  final List<PersonalidadMiembro> miembros;

  @override
  Widget build(BuildContext context) {
    // Agrupar por arquetipo para el resumen
    final conteo = <String, int>{};
    for (final m in miembros) {
      conteo[m.arquetipo] = (conteo[m.arquetipo] ?? 0) + 1;
    }
    final masComun = conteo.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final ejemplar = miembros.first; // para el color del gradiente

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabecera ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Text('🧬', style: TextStyle(fontSize: 20)),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Personalidades del club',
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '${miembros.length} ${miembros.length == 1 ? 'lectora' : 'lectoras'}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Arquetipo más común del club ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(ejemplar.colores.start),
                    Color(ejemplar.colores.end),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Text(
                    PersonalidadMiembro(
                      usuario: '',
                      avatarUrl: '',
                      arquetipo: masComun.key,
                    ).emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Arquetipo del club',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .70),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          PersonalidadMiembro(
                            usuario: '',
                            avatarUrl: '',
                            arquetipo: masComun.key,
                          ).nombreArquetipo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '×${masComun.value}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .80),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Lista horizontal de miembros ──────────────────────────────────
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              itemCount: miembros.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) => _MiembroPersonalidadChip(miembro: miembros[i]),
            ),
          ),

          // ── CTA si el usuario aún no ha hecho el quiz ────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: GestureDetector(
              onTap: () => Navigator.push<void>(
                context,
                AppPageRoute(builder: (_) => const PersonalidadLectoraPage()),
              ),
              child: Text(
                '¿Cuál es el tuyo? Hacer el quiz →',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiembroPersonalidadChip extends StatelessWidget {
  const _MiembroPersonalidadChip({required this.miembro});
  final PersonalidadMiembro miembro;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(miembro.colores.start).withValues(alpha: .15),
            Color(miembro.colores.end).withValues(alpha: .08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Color(miembro.colores.end).withValues(alpha: .30),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          ClubAvatar(
            nombre: miembro.usuario,
            imageUrl: miembro.avatarUrl.isEmpty ? null : miembro.avatarUrl,
            size: 34,
          ),
          const SizedBox(height: 3),
          // Emoji arquetipo
          Text(miembro.emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 2),
          // Nombre de usuario
          Text(
            miembro.usuario,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Club wishlist card (entre Compañeros y Personalidades) ───────────────────

class _ClubWishlistCard extends StatefulWidget {
  const _ClubWishlistCard();

  @override
  State<_ClubWishlistCard> createState() => _ClubWishlistCardState();
}

class _ClubWishlistCardState extends State<_ClubWishlistCard> {
  late Future<ClubWishlistData> _future;

  @override
  void initState() {
    super.initState();
    _future = WishlistService().getClubWishlist();
  }

  void _openWishlist() {
    Navigator.push<void>(
      context,
      AppPageRoute(builder: (_) => const ClubWishlistPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ClubWishlistData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return ClubShimmer(
            width: double.infinity,
            height: 96,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          );
        }

        // Si error o sin datos, no mostramos nada para no estorbar
        if (snap.hasError || snap.data == null) return const SizedBox.shrink();

        final data = snap.data!;

        // Si nadie tiene ítems en el club, no mostrar el widget
        if (data.items.isEmpty) return const SizedBox.shrink();

        // Mostrar hasta 3 libros más deseados por el club
        final preview = data.items.take(3).toList();

        return GestureDetector(
          onTap: _openWishlist,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7B4E92), Color(0xFF40254F)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: .30),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cabecera ───────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('🛍️', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lo que quiere el club',
                            style: AppTextStyles.subtitle.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${data.membersWithWishlist} miembro${data.membersWithWishlist != 1 ? 's' : ''} · ${data.totalItems} libro${data.totalItems != 1 ? 's' : ''}',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: .75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: .70),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // ── Lista de libros con quién los quiere ──────────────────
                ...preview.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        // Portada real; si falta, el componente conserva un
                        // fallback de libro legible.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: ClubBookCover(
                            title: group.title,
                            imageUrl: group.coverUrl ?? '',
                            width: 28,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Título
                        Expanded(
                          child: Text(
                            group.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Nombres de quién lo quiere (hasta 2 + "y N más")
                        _MemberNames(members: group.members),
                      ],
                    ),
                  ),
                ),

                // ── Pie ────────────────────────────────────────────────────
                Text(
                  data.items.length > 3
                      ? '+${data.items.length - 3} más · Ver todo →'
                      : 'Ver lista completa →',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: .80),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Nombres de miembros para la wishlist del club ────────────────────────────

class _MemberNames extends StatelessWidget {
  const _MemberNames({required this.members});
  final List<ClubWishlistMember> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    // Mostrar hasta 2 nombres, luego "y N más"
    final shown = members.take(2).map((m) => m.name.split(' ').first).toList();
    final extra = members.length - shown.length;

    final label = extra > 0
        ? '${shown.join(', ')} +$extra'
        : shown.join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Widgets exclusivos del dashboard personal
// ═══════════════════════════════════════════════════════════════════════════

/// Card "Mi año en libros": estantería de portadas + total + género favorito.
class _PersonalYearShelfCard extends StatelessWidget {
  const _PersonalYearShelfCard({
    required this.year,
    required this.books,
    required this.favoriteGenre,
    required this.totalLibrary,
  });

  final int year;
  final List<YearShelfBook> books;
  final String? favoriteGenre;
  final int totalLibrary;

  @override
  Widget build(BuildContext context) {
    final count = books.length;
    final covers = books
        .where((b) => b.coverUrl.isNotEmpty)
        .take(12)
        .toList();

    return ClubCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi año en libros',
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$year · $count leído${count == 1 ? '' : 's'}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Contador grande
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  '$count',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),

          if (covers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            // Estantería horizontal de portadas
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: covers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final book = covers[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: ClubBookCover(
                      imageUrl: book.coverUrl,
                      title: book.title,
                      width: 65,
                      height: 100,
                      showShadow: false,
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              count == 0
                  ? 'Aún no has terminado ningún libro este año. ¡A por ello!'
                  : 'Termina tu primer libro para ver tu estantería.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          if (favoriteGenre != null || totalLibrary > 0) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (favoriteGenre != null) ...[
                  const Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Género favorito: $favoriteGenre',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (totalLibrary > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.library_books_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$totalLibrary en mi estantería',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Shelf horizontal de sagas en curso con progreso visual.
class _PersonalOpenSeriesShelf extends StatelessWidget {
  const _PersonalOpenSeriesShelf({required this.series});

  final List<GeneralOpenSeries> series;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 192,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: series.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final saga = series[index];
          final remaining = saga.total > 0 ? saga.total - saga.read : 0;
          return SizedBox(
            width: 130,
            child: ClubCard(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Portada
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: ClubBookCover(
                      imageUrl: saga.next?.coverUrl.isNotEmpty == true
                          ? saga.next!.coverUrl
                          : saga.coverUrl,
                      title: saga.name,
                      width: double.infinity,
                      height: 90,
                      showShadow: false,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Nombre de la saga
                  Text(
                    saga.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Progreso: X de Y leídos
                  Text(
                    saga.total > 0
                        ? '${saga.read} de ${saga.total} leído${saga.read == 1 ? '' : 's'}'
                        : '${saga.read} leído${saga.read == 1 ? '' : 's'}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Barra de progreso
                  if (saga.total > 0) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: LinearProgressIndicator(
                        value: saga.progress.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Siguiente / faltan
                    if (remaining > 0)
                      Text(
                        saga.next != null
                            ? 'Sig: ${saga.next!.title}'
                            : 'Faltan $remaining',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shelf horizontal de libros pendientes de alta prioridad.
class _PersonalPriorityShelf extends StatelessWidget {
  const _PersonalPriorityShelf({required this.books});

  final List<PersonalLibraryBook> books;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final book = books[index];
          return SizedBox(
            width: 82,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: ClubBookCover(
                    imageUrl: book.coverUrl,
                    title: book.title,
                    width: 82,
                    height: 110,
                    showShadow: false,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
