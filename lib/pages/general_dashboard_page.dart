import 'package:club_lectura_app/models/dashboard.dart';
import 'package:club_lectura_app/pages/notificaciones_page.dart';
import 'package:club_lectura_app/theme/app_radius.dart';
import 'package:club_lectura_app/widgets/common/editar_progreso_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/app_page_route.dart';
import 'autor_libros_page.dart';
import '../navigation/book_detail_navigation.dart';

import '../models/club_membership.dart';
import '../models/general_dashboard.dart';
import '../models/libro.dart';
import '../models/libro_agrupado.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/club_service.dart';
import '../services/api_service.dart';
import '../services/general_dashboard_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/calendar_edit_fechas_sheet.dart';
import '../widgets/common/reading_cover_calendar.dart';
import '../widgets/common/optimized_network_image.dart';
import '../widgets/dashboard/monthly_reading_shelf.dart';
import '../widgets/dashboard/tbr_roulette_card.dart';
import 'clubs_page.dart';
import 'elegir_modo_page.dart';
import 'home_page.dart';
import 'explore_catalog_page.dart';
import 'detalle_libro_page.dart';
import 'monthly_reading_share_page.dart';
import 'nuevo_libro_page.dart';
import 'perfil_usuario_page.dart';
import 'sagas_page.dart';
import '../widgets/common/onboarding_tutorial.dart';
import '../widgets/common/screen_hint_banner.dart';
import '../widgets/libros/libro_acciones_rapidas.dart';
import 'mis_logros_page.dart';
import '../models/achievements/achievement.dart';
import '../services/achievement_service.dart';
import '../services/usuario_service.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';
import '../models/wishlist.dart';
import '../models/upcoming_release.dart';
import '../services/wishlist_service.dart';
import '../services/upcoming_releases_service.dart';
import 'wishlist_page.dart';
import 'upcoming_releases_page.dart';
import '../models/kit_lectura_seleccion.dart';
import '../services/kit_lectura_service.dart';
import 'kit_lectura_page.dart';

typedef DashboardQuickActions =
    Future<bool> Function({
      required String title,
      required String bookId,
      required String coverUrl,
      required String genre,
      required String author,
    });

class GeneralDashboardPage extends StatefulWidget {
  const GeneralDashboardPage({
    super.key,
    this.loadDashboard,
    this.quickActions,
  });

  final Future<GeneralDashboard> Function()? loadDashboard;
  final DashboardQuickActions? quickActions;

  @override
  State<GeneralDashboardPage> createState() => _GeneralDashboardPageState();
}

class _GeneralDashboardPageState extends State<GeneralDashboardPage> {
  late Future<GeneralDashboard> _future;
  // Se arranca en paralelo con el dashboard para evitar el layout-shift de logros.
  late Future<List<UserAchievement>> _achievementsFuture;
  late Future<List<UpcomingRelease>> _upcomingFuture;
  late Future<List<UpcomingRelease>> _newReleasesFuture;
  String? _openingClubId;
  bool _openingBook = false; // ← evita abrir dos fichas a la vez
  bool _openingNewBook = false;
  bool _savingProgress = false;
  bool _openingBookActions = false;
  final _scrollController = ScrollController();
  // _latestScrollController y _personalLibraryScrollController eliminados:
  // los carrouseles horizontales usan _HScrollGestureProxy, que no necesita
  // controller externo para preservar posición.
  // _trendingScrollController eliminado: _trending usa _HScrollGestureProxy.
  int _noLeidas = 0;

  @override
  void initState() {
    super.initState();
    _future = _loadDashboard();
    // Los logros se piden en paralelo: llegan aproximadamente igual que el
    // dashboard y no causan un salto de layout secundario.
    _achievementsFuture = ApiService().getAchievements();
    _upcomingFuture = _loadUpcomingPreview();
    _newReleasesFuture = _loadNewReleasesPreview();
    _checkOnboarding();
    _loadNotificaciones();
  }

  Future<void> _loadNotificaciones() async {
    try {
      final data = await ApiService().getNotificaciones();
      if (mounted) setState(() => _noLeidas = data.noLeidas);
    } catch (_) {}
  }

  Future<List<UpcomingRelease>> _loadUpcomingPreview() async {
    try {
      return await UpcomingReleasesService().load(limit: 6);
    } catch (_) {
      return const [];
    }
  }

  Future<List<UpcomingRelease>> _loadNewReleasesPreview() async {
    try {
      return await UpcomingReleasesService().loadNew(limit: 6);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _abrirNotificaciones() async {
    await Navigator.push<void>(
      context,
      AppPageRoute(builder: (_) => const NotificacionesPage()),
    );
    _loadNotificaciones();
  }

  Future<void> _actualizarProgreso(GeneralBook book) async {
    if (_savingProgress) return;
    final lectura = LecturaAhoraItem(
      libraryId: '',
      bookId: book.id,
      titulo: book.title,
      coverUrl: book.coverUrl,
      progreso: book.progress,
      paginaActual: book.currentPage,
      paginasTotales: book.pages,
      comentario: '',
      actualizadoEn: null,
      reacciones: {},
      miReaccion: null,
    );

    final resultado =
        await showDialog<
          ({
            int progreso,
            int? paginaActual,
            int? paginasTotales,
            String comentario,
          })
        >(
          context: context,
          builder: (_) => EditarProgresoDialog(lectura: lectura),
        );
    if (resultado == null || !mounted) return;
    if (_savingProgress) return;

    final usuario = (await UsuarioService().obtenerUsuario()) ?? '';

    if (!mounted || _savingProgress) return;

    setState(() => _savingProgress = true);
    try {
      final guardado = await ApiService().actualizarProgresoLectura(
        usuario: usuario,
        libro: book.title,
        progreso: resultado.progreso,
        comentario: resultado.comentario,
        paginaActual: resultado.paginaActual,
        paginasTotales: book.pages,
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
      await _reload();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _savingProgress = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkOnboarding() async {
    final mostrar = await deberiaMostrarOnboarding();
    if (!mostrar || !mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await mostrarOnboardingTutorial(context);
  }

  Future<void> _reload() async {
    final refresh = _loadDashboard();
    final achievementsRefresh = ApiService().getAchievements();
    final upcomingRefresh = _loadUpcomingPreview();
    final newReleasesRefresh = _loadNewReleasesPreview();
    try {
      final data = await refresh;
      if (!mounted) return;
      setState(() {
        _future = Future.value(data);
        _achievementsFuture = achievementsRefresh;
        _upcomingFuture = upcomingRefresh;
        _newReleasesFuture = newReleasesRefresh;
      });
    } catch (error, stack) {
      debugPrint('[dashboard] _reload falló: $error\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido actualizar el panel.')),
      );
    }
  }

  Future<GeneralDashboard> _loadDashboard() =>
      widget.loadDashboard?.call() ?? GeneralDashboardService().load();

  Future<void> _addBook() async {
    if (_openingNewBook) return;
    setState(() => _openingNewBook = true);
    try {
      final creado = await Navigator.push<bool>(
        context,
        AppPageRoute(builder: (_) => const NuevoLibroPage()),
      );
      if (creado == true && mounted) await _reload();
    } finally {
      if (mounted) setState(() => _openingNewBook = false);
    }
  }

  Future<void> _manageClubs() async {
    await Navigator.push<void>(
      context,
      AppPageRoute(builder: (_) => const ClubsPage()),
    );
    if (mounted) await _reload();
  }

  Future<void> _elegirModo() async {
    await Navigator.push<void>(
      context,
      AppPageRoute(builder: (_) => const ElegirModoPage()),
    );
    if (mounted) await _reload();
  }

  Future<void> _exploreBooks() async {
    await Navigator.push<void>(
      context,
      AppPageRoute(builder: (_) => const ExploreCatalogPage()),
    );
    if (mounted) await _reload();
  }

  // ── Apertura de ficha de libro con protección anti-doble-tap ─────────────
  Future<void> _openBook({
    required String title,
    String bookId = '',
    String coverUrl = '',
    String genre = '',
  }) async {
    if (_openingBook) return;
    setState(() => _openingBook = true);
    try {
      await openBookDetail(
        context,
        title: title,
        bookId: bookId,
        coverUrl: coverUrl,
        genre: genre,
      );
      if (mounted) await _reload();
    } finally {
      if (mounted) setState(() => _openingBook = false);
    }
  }

  Future<void> _openCatalogBook({
    required String title,
    String bookId = '',
    String coverUrl = '',
    String genre = '',
    bool forceFullDetail = false,
  }) async {
    if (_openingBook) return;
    setState(() => _openingBook = true);
    try {
      final changed = await openCatalogBookDetail(
        context,
        title: title,
        bookId: bookId,
        coverUrl: coverUrl,
        genre: genre,
        forceFullDetail: forceFullDetail,
        // Dashboard global: usar stats de toda la comunidad, no solo del usuario
        globalStats: true,
      );
      if (changed && mounted) await _reload();
    } finally {
      if (mounted) setState(() => _openingBook = false);
    }
  }

  Future<void> _openQuickActions({
    required String title,
    required String bookId,
    required String coverUrl,
    required String genre,
    String author = '',
  }) async {
    if (_openingBookActions) return;
    _openingBookActions = true;
    HapticFeedback.mediumImpact();
    try {
      final changed = widget.quickActions != null
          ? await widget.quickActions!(
              title: title,
              bookId: bookId,
              coverUrl: coverUrl,
              genre: genre,
              author: author,
            )
          : await mostrarAccionesRapidasLibro(
              context,
              bookId: bookId,
              titulo: title,
              autor: author,
              genero: genre,
              coverUrl: coverUrl,
              // "Ver ficha completa" desde pulsación larga → siempre DetalleLibroPage
              abrirFicha: (_) => _openCatalogBook(
                title: title,
                bookId: bookId,
                coverUrl: coverUrl,
                genre: genre,
                forceFullDetail: true,
              ),
            );
      if (changed && mounted) await _reload();
    } finally {
      _openingBookActions = false;
    }
  }
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _openPersonalBook(
    PersonalLibraryBook book,
    String userName,
  ) async {
    if (_openingBook) return;
    setState(() => _openingBook = true);
    try {
      final registro = Libro.fromJson({
        'bookId': book.id,
        'usuario': userName,
        'libro': book.title,
        'genero': book.genre,
        'prioridad': book.priority,
        'formato': book.format,
        'estado': book.status,
        'yaLoTengo': true,
        'coverUrl': book.coverUrl,
      });
      await Navigator.push<void>(
        context,
        AppPageRoute(
          builder: (_) => DetalleLibroPage(
            libro: LibroAgrupado(
              libro: book.title,
              genero: book.genre,
              registros: [registro],
              finalizados: const [],
              yaLoTengo: true,
              coverUrl: book.coverUrl,
            ),
          ),
        ),
      );
      if (mounted) await _reload();
    } finally {
      if (mounted) setState(() => _openingBook = false);
    }
  }

  Future<void> _openMySeries() async {
    await Navigator.push<void>(
      context,
      AppPageRoute(builder: (_) => const SagasPage(showBackButton: true)),
    );
    if (mounted) await _reload();
  }

  Future<void> _openMyProfile(String userName, String userId) async {
    await Navigator.push<void>(
      context,
      AppPageRoute(
        builder: (_) => PerfilUsuarioPage(
          usuario: userName,
          profileUserId: userId.isEmpty ? null : userId,
        ),
      ),
    );
    if (mounted) await _reload();
  }

  Future<void> _openClub(GeneralClub club) async {
    if (_openingClubId != null) return;
    setState(() => _openingClubId = club.id);
    try {
      if (!club.active) await ClubService().selectClub(club.id);
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        AppPageRoute(
          builder: (_) => HomePage(
            club: ClubMembership(
              id: club.id,
              nombre: club.name,
              slug: '',
              rol: club.role,
              activo: true,
              descripcion: club.description,
              avatarUrl: club.avatarUrl,
              tipo: club.esPersonal ? TipoClub.personal : TipoClub.social,
            ),
          ),
        ),
      );
      if (mounted) await _reload();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _openingClubId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder<GeneralDashboard>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done &&
              !snapshot.hasData) {
            return const DashboardSkeleton();
          }
          if (snapshot.hasError) {
            return _DashboardError(onRetry: _reload);
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            // El indicador nativo ya distingue un arrastre real de un fling.
            // Limitarlo al borde evita que capture el gesto de vuelta hacia
            // arriba cuando empieza sobre una sección intermedia del panel.
            triggerMode: RefreshIndicatorTriggerMode.onEdge,
            child: CustomScrollView(
              controller: _scrollController,
              // cacheExtent grande para que ninguna sección del dashboard salga
              // del cache del viewport. Sin esto, secciones como _ReleasesPreview
              // o _LogrosDashboardSection se desmontan al alejarse y, al remontar,
              // muestran un frame de skeleton que genera una scrollOffsetCorrection
              // que empuja la posición de vuelta — el usuario no puede subir.
              cacheExtent: 4000,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.background,
                  surfaceTintColor: Colors.transparent,
                  scrolledUnderElevation: 0,
                  shape: const Border(
                    bottom: BorderSide(color: AppColors.paperLine, width: .8),
                  ),
                  title: const Text('Mi universo lector'),
                  actions: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          tooltip: 'Notificaciones',
                          onPressed: _abrirNotificaciones,
                          icon: const Icon(Icons.notifications_outlined),
                        ),
                        if (_noLeidas > 0)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.danger,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _noLeidas > 9 ? '9+' : '$_noLeidas',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      tooltip: 'Explorar libros',
                      onPressed: _exploreBooks,
                      icon: const Icon(Icons.travel_explore_rounded),
                    ),
                    IconButton(
                      tooltip: 'Cerrar sesión',
                      onPressed: () => AuthService().logout(),
                      icon: const Icon(Icons.logout_rounded),
                    ),
                  ],
                ),
                // ── Tutorial primera visita ──
                SliverToBoxAdapter(
                  child: ScreenHintBanner(
                    featureKey: 'hint_dashboard_v4',
                    titulo: 'Tu universo lector de un vistazo',
                    tips: const [
                      ScreenHintTip(
                        '📊',
                        'Aquí ves tu resumen de lecturas del mes y el año',
                      ),
                      ScreenHintTip(
                        '📖',
                        'Pulsa el botón + (abajo a la derecha) para añadir un libro a tu biblioteca',
                      ),
                      ScreenHintTip(
                        '🧭',
                        'Usa el icono de exploración (arriba) para descubrir libros del catálogo',
                      ),
                      ScreenHintTip(
                        '📚',
                        'Pulsa una portada para ver el detalle · Mantén pulsado para acciones rápidas según el estado del libro',
                      ),
                      ScreenHintTip(
                        '🎲',
                        'La Ruleta del TBR elige un libro pendiente al azar · Cambia a modo 🫙 Tarro para una experiencia más artesanal',
                      ),
                    ],
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.xxxl,
                  ),
                  sliver: SliverList.list(
                    children: [
                      _hero(data),
                      const SizedBox(height: AppSpacing.sm),
                      _metrics(data),
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        child: ListTile(
                          onTap: _exploreBooks,
                          leading: const CircleAvatar(
                            child: Icon(Icons.auto_stories_outlined),
                          ),
                          title: const Text(
                            'Explorar la biblioteca',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: const Text(
                            'Busca nuevas lecturas y añádelas a tu espacio',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded),
                        ),
                      ),
                      if (data.latestAdditions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _sectionTitle(
                          'Últimas incorporaciones',
                          'Los últimos libros añadidos por la comunidad',
                          Icons.new_releases_outlined,
                          action: TextButton.icon(
                            key: const Key('add_book_latest_additions'),
                            onPressed: _openingNewBook ? null : _addBook,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Añadir libro'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _latestAdditions(data.latestAdditions),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      _sectionTitle(
                        'Tus clubes',
                        data.clubs.isEmpty
                            ? 'Tu próxima historia puede empezar aquí'
                            : 'Entra en uno o cambia de comunidad',
                        Icons.groups_2_outlined,
                        action: TextButton(
                          onPressed: _manageClubs,
                          child: const Text('Gestionar'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (data.clubs.isEmpty)
                        _emptyClubs()
                      else
                        ...data.clubs.map(_clubCard),

                      const SizedBox(height: AppSpacing.xl),
                      _ReleasesPreview(
                        future: _newReleasesFuture,
                        mode: ReleaseCatalogMode.newReleases,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _ReleasesPreview(
                        future: _upcomingFuture,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _WishlistPreviewSection(userName: data.userName),

                      const SizedBox(height: AppSpacing.xl),
                      _LogrosDashboardSection(
                        userName: data.userName,
                        future: _achievementsFuture,
                      ),

                      if (data.calendar.finishedBooks.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        MonthlyReadingShelf(
                          key: ValueKey(
                            'monthly-${data.calendar.year}-${data.calendar.month}',
                          ),
                          year: data.calendar.year,
                          month: data.calendar.month,
                          books: data.calendar.finishedBooks,
                          scrollController: _scrollController,
                          onBookTap: (book) => _openBook(
                            title: book.title,
                            bookId: book.bookId,
                            coverUrl: book.coverUrl,
                          ),
                        ),
                      ],
                      if (data.currentBooks.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _sectionTitle(
                          'Leyendo ahora',
                          'Tus historias, estés en el club que estés',
                          Icons.auto_stories_outlined,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _currentBooks(data.currentBooks),
                      ],
                      if (data.openSeries.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _sectionTitle(
                          'Continúa tus sagas',
                          'Universos que ya has empezado',
                          Icons.view_week_outlined,
                          action: TextButton(
                            onPressed: _openMySeries,
                            child: const Text('Ver todas'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _openSeries(data.openSeries),
                      ],

                      if (data.personalLibrary.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _sectionTitle(
                          'Tu próxima lectura',
                          'Tu biblioteca, con las prioridades altas primero',
                          Icons.bookmarks_outlined,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _personalLibrary(data.personalLibrary, data.userName),
                        const SizedBox(height: AppSpacing.md),
                        TbrRouletteCard(
                          books: data.personalLibrary,
                          onOpenBook: (book) =>
                              _openPersonalBook(book, data.userName),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      _sectionTitle(
                        'Tu mes lector',
                        'Las portadas recorren los días que estuviste leyendo',
                        Icons.calendar_month_outlined,
                        action: TextButton.icon(
                          onPressed: () => Navigator.push<void>(
                            context,
                            AppPageRoute(
                              builder: (_) => MonthlyReadingSharePage(
                                calendar: data.calendar,
                                userName: data.userName,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.ios_share_rounded, size: 18),
                          label: const Text('Compartir'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _calendar(data.calendar),
                      if (data.trending.isNotEmpty ||
                          data.trendingAuthors.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _communityDivider(),
                      ],
                      if (data.trending.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _sectionTitle(
                          'Se están leyendo mucho',
                          'Tendencias de toda la comunidad',
                          Icons.local_fire_department_outlined,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _trending(data.trending),
                      ],
                      if (data.trendingAuthors.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _sectionTitle(
                          'Autores del momento',
                          'Los más presentes en vuestras bibliotecas',
                          Icons.people_outline_rounded,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _trendingAuthors(data.trendingAuthors),
                      ],
                      if (data.community.formats.total > 0) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _sectionTitle(
                          'Cómo lee la comunidad',
                          'Formatos guardados en las bibliotecas personales',
                          Icons.donut_large_rounded,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _communityFormats(data.community.formats),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      _community(data.community),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _hero(GeneralDashboard data) {
    final clubvisionReminder = data.clubvisionNotice?.message;
    return ClubCard(
      onTap: () => _openMyProfile(data.userName, data.userId),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.primaryDark, AppColors.primary, AppColors.inkCoral],
        stops: [0, .66, 1],
      ),
      borderColor: Colors.transparent,
      child: Row(
        children: [
          ClubAvatar(nombre: data.userName, imageUrl: data.avatarUrl, size: 64),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${data.userName.split(' ').first}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.summary.monthStreak > 0
                      ? '🔥 ${data.summary.monthStreak} ${data.summary.monthStreak == 1 ? 'mes' : 'meses'} seguidos con libros terminados'
                      : 'Tu próxima lectura empieza hoy',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (clubvisionReminder != null &&
                    clubvisionReminder.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .24),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.mic_rounded,
                          color: Color(0xFFFFD979),
                          size: 17,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Builder(builder: (context) {
                            const base = TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            );
                            final parts = data.clubvisionNotice?.messageParts;
                            if (parts?.clubName != null) {
                              return RichText(
                                text: TextSpan(
                                  style: base,
                                  children: [
                                    TextSpan(text: parts!.prefix),
                                    TextSpan(
                                      text: '«${parts.clubName}»',
                                      style: base.copyWith(
                                        color: const Color(0xFFFFD979),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    if (parts.suffix.isNotEmpty)
                                      TextSpan(text: parts.suffix),
                                  ],
                                ),
                              );
                            }
                            return Text(clubvisionReminder, style: base);
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white,
            size: 25,
          ),
        ],
      ),
    );
  }

  Widget _metrics(GeneralDashboard data) {
    final summary = data.summary;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.menu_book_rounded,
                color: AppColors.info,
                title: 'Leyendo',
                value: '${summary.reading}',
                subtitle: '',
                context: context,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _metricCard(
                icon: Icons.check_rounded,
                color: AppColors.success,
                title: 'Terminados',
                value: '${summary.finished}',
                subtitle: 'en total',
                context: context,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _metricCardMes(
                summary: summary,
                pages: data.pagesReadThisMonth,
                context: context,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _metricCardPaginas(
                summary: summary,
                pagesMes: data.pagesReadThisMonth,
                context: context,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _metricCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
    required BuildContext context,
  }) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .14),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCardMes({
    required GeneralSummary summary,
    required int pages,
    required BuildContext context,
  }) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.warning.withValues(alpha: .14),
            child: const Icon(Icons.bolt_rounded, color: AppColors.warning),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Este mes',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
                Text(
                  '${summary.finishedThisMonth}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  summary.finishedThisMonth == 1
                      ? 'libro terminado'
                      : 'libros terminados',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCardPaginas({
    required GeneralSummary summary,
    required int pagesMes,
    required BuildContext context,
  }) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: .14),
            child: const Icon(Icons.bookmark_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Páginas',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  pagesMes > 0 ? '$pagesMes' : '0',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${summary.pagesRead} en total',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _clubCard(GeneralClub club) {
    final busy = _openingClubId == club.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClubCard(
        onTap: () => _openClub(club),
        child: Row(
          children: [
            ClubAvatar(nombre: club.name, imageUrl: club.avatarUrl, size: 72),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          club.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (club.active) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 17,
                          color: AppColors.success,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    club.esPersonal
                        ? 'Tu espacio lector personal'
                        : '${club.members} miembros · ${club.activeReadings} lecturas activas',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            busy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }

  Widget _emptyClubs() {
    return ClubCard(
      elevated: false,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceSoft, Color(0xFFFFF5EA)],
      ),
      child: Column(
        children: [
          const Text('📚', style: TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            '¿Cómo quieres leer?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Lee en solitario o únete a una comunidad',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _elegirModo,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Elegir mi modo'),
          ),
        ],
      ),
    );
  }

  Widget _currentBooks(List<GeneralBook> books) {
    return Column(
      children: [
        for (final book in books)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _CurrentBookCard(
              book: book,
              onTap: () => _openBook(
                title: book.title,
                bookId: book.id,
                coverUrl: book.coverUrl,
              ),
              onUpdateProgress: () => _actualizarProgreso(book),
              onLongPress: () => _openQuickActions(
                title: book.title,
                bookId: book.id,
                coverUrl: book.coverUrl,
                genre: book.genre,
              ),
            ),
          ),
      ],
    );
  }

  Widget _personalLibraryBookCard(PersonalLibraryBook book, String userName) {
    return SizedBox(
      width: 122,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openPersonalBook(book, userName),
        onLongPress: () => _openQuickActions(
          title: book.title,
          bookId: book.id,
          coverUrl: book.coverUrl,
          genre: book.genre,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Semantics(
                  hint: 'Mantén pulsado para abrir acciones rápidas',
                  child: ClubBookCover(
                    title: book.title,
                    imageUrl: book.coverUrl,
                    width: 110,
                    height: 158,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: book.isHighPriority
                          ? AppColors.warning
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      book.priority,
                      style: TextStyle(
                        color: book.isHighPriority
                            ? AppColors.midnight
                            : AppColors.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _personalLibrary(List<PersonalLibraryBook> books, String userName) {
    const cardWidth = 122.0;
    const gap = AppSpacing.md;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalContent =
            books.length * cardWidth + (books.length - 1) * gap;

        // Si caben todos sin scroll: Row (sin competencia de gestos).
        if (totalContent <= constraints.maxWidth) {
          return SizedBox(
            height: 224,
            child: Row(
              children: [
                for (var i = 0; i < books.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  _personalLibraryBookCard(books[i], userName),
                ],
              ],
            ),
          );
        }

        // No caben: ListView horizontal protegido contra robo del gesto vertical.
        return _HScrollGestureProxy(
          height: 224,
          child: (physics, controller) => ListView.separated(
            controller: controller,
            scrollDirection: Axis.horizontal,
            physics: physics,
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(width: gap),
            itemBuilder: (_, index) =>
                _personalLibraryBookCard(books[index], userName),
          ),
        );
      },
    );
  }

  Widget _latestAdditions(List<GeneralLatestBook> books) {
    return _HScrollGestureProxy(
      height: 218,
      child: (physics, controller) => ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: physics,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final book = books[index];
          return SizedBox(
            width: 112,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openCatalogBook(
                title: book.title,
                bookId: book.id,
                coverUrl: book.coverUrl,
              ),
              onLongPress: () => _openQuickActions(
                title: book.title,
                bookId: book.id,
                coverUrl: book.coverUrl,
                genre: book.genre,
                author: book.author,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Semantics(
                        hint: 'Mantén pulsado para abrir acciones rápidas',
                        child: ClubBookCover(
                          title: book.title,
                          imageUrl: book.coverUrl,
                          width: 108,
                          height: 158,
                        ),
                      ),
                      Positioned(
                        right: -2,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.inkCoral,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'NUEVO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  if (book.author.isNotEmpty)
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _openSeries(List<GeneralOpenSeries> series) {
    // Un ListView horizontal —aunque tenga ClampingScrollPhysics— compite con
    // el CustomScrollView padre y puede absorber gestos verticales hacia arriba
    // cuando está en la posición 0 de scroll. La solución es evitar el ListView
    // siempre que el contenido quepa sin necesidad de scroll horizontal.
    // Ancho de cada tarjeta + separador:
    const cardWidth = 260.0;
    const gap = AppSpacing.md;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final totalContent =
            series.length * cardWidth + (series.length - 1) * gap;

        if (totalContent <= available) {
          // Caben todas sin scroll: Row simple, sin competencia de gestos.
          return SizedBox(
            height: 154,
            child: Row(
              children: [
                for (var i = 0; i < series.length; i++) ...[
                  if (i > 0) const SizedBox(width: gap),
                  SizedBox(
                    width: series.length == 1 ? available : cardWidth,
                    child: _openSeriesCard(
                      series[i],
                      fullWidth: series.length == 1,
                      cardWidth: series.length == 1 ? available : cardWidth,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        // No caben: ListView horizontal protegido contra robo del gesto vertical.
        return _HScrollGestureProxy(
          height: 154,
          child: (physics, controller) => ListView.separated(
            controller: controller,
            scrollDirection: Axis.horizontal,
            physics: physics,
            itemCount: series.length,
            separatorBuilder: (_, _) => const SizedBox(width: gap),
            itemBuilder: (context, index) =>
                _openSeriesCard(series[index], fullWidth: false),
          ),
        );
      },
    );
  }

  Widget _openSeriesCard(
    GeneralOpenSeries item, {
    required bool fullWidth,
    double? cardWidth,
  }) {
    final card = Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: item.next == null
            ? _openMySeries
            : () => _openBook(
                title: item.next!.title,
                bookId: item.next!.id,
                coverUrl: item.next!.coverUrl,
              ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ClubBookCover(
                title: item.next?.title ?? item.name,
                imageUrl: item.next?.coverUrl.trim().isNotEmpty == true
                    ? item.next!.coverUrl
                    : item.coverUrl,
                width: 62,
                height: 92,
                showShadow: false,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: item.progress.clamp(0, 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.read} de ${item.total} leídos',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (item.next != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Siguiente: ${item.next!.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (fullWidth) return SizedBox(width: cardWidth, height: 154, child: card);
    return SizedBox(width: 260, height: 154, child: card);
  }

  Widget _calendar(ReadingCalendar calendar) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReadingCoverCalendar(
            calendar: calendar,
            onBookTap: (reading) => _editarFechasCalendario(reading),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  calendar.readings.isEmpty
                      ? 'Cuando registres las fechas de una lectura, su portada recorrerá esos días.'
                      : 'Cada portada marca los días de lectura. Si coinciden varios libros, el día se divide entre ellos.',
                  style: AppTextStyles.caption.copyWith(height: 1.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trending(List<TrendingBook> books) {
    return _HScrollGestureProxy(
      height: 190,
      child: (physics, controller) => ListView.separated(
        controller: controller,
        key: const PageStorageKey('dashboard-trending-books'),
        scrollDirection: Axis.horizontal,
        physics: physics,
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final book = books[index];
          return SizedBox(
            width: 100,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openCatalogBook(
                title: book.title,
                bookId: book.id,
                coverUrl: book.coverUrl,
              ),
              onLongPress: () => _openQuickActions(
                title: book.title,
                bookId: book.id,
                coverUrl: book.coverUrl,
                genre: '',
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Semantics(
                        hint: 'Mantén pulsado para abrir acciones rápidas',
                        child: ClubBookCover(
                          title: book.title,
                          imageUrl: book.coverUrl,
                          width: 92,
                          height: 132,
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.warning,
                          child: Text(
                            '${book.readers}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

  Future<void> _editarFechasCalendario(MonthlyReadingSpan reading) async {
    final usuario = await UsuarioService().obtenerUsuario();
    if (usuario == null || usuario.trim().isEmpty || !mounted) return;
    final actualizado = await showCalendarEditFechasSheet(
      context,
      reading: reading,
      usuario: usuario,
    );
    if (actualizado && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fechas de lectura actualizadas')),
      );
      _reload();
    }
  }

  Widget _community(CommunitySummary community) {
    return ClubCard(
      elevated: false,
      backgroundColor: AppColors.midnight,
      borderColor: Colors.transparent,
      child: Column(
        children: [
          const Text(
            'La comunidad en una página',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _communityMetric('${community.clubs}', 'clubes'),
              _communityMetric('${community.readers}', 'lectores'),
              _communityMetric('${community.activeReadings}', 'leyendo'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _communityFormats(CommunityReadingFormats formats) {
    return ClubCard(
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _formatBar(
            icon: '📖',
            label: 'Físico',
            value: formats.physical,
            total: formats.total,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          _formatBar(
            icon: '📱',
            label: 'Digital',
            value: formats.digital,
            total: formats.total,
            color: AppColors.info,
          ),
          const SizedBox(height: AppSpacing.md),
          _formatBar(
            icon: '🎧',
            label: 'Audiolibro',
            value: formats.audiobook,
            total: formats.total,
            color: const Color(0xFFE36A8D),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${formats.total} ${formats.total == 1 ? 'libro con formato' : 'libros con formato'} en toda la comunidad',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatBar({
    required String icon,
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final percentage = total == 0 ? 0.0 : value / total;
    return Column(
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${(percentage * 100).round()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 9,
            value: percentage,
            color: color,
            backgroundColor: color.withValues(alpha: .12),
          ),
        ),
      ],
    );
  }

  Widget _communityMetric(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _authorInitials(String nombre) {
    final palabras = nombre
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    final iniciales = palabras.length >= 2
        ? '${palabras[0][0]}${palabras[1][0]}'.toUpperCase()
        : nombre.isNotEmpty
        ? nombre[0].toUpperCase()
        : '?';
    final colors = [
      const Color(0xFF7C3AED),
      const Color(0xFF2563EB),
      const Color(0xFFDB2777),
      const Color(0xFF059669),
      const Color(0xFFD97706),
      const Color(0xFFDC2626),
      const Color(0xFF0891B2),
    ];
    final color = colors[nombre.hashCode.abs() % colors.length];
    return Container(
      color: color.withValues(alpha: .15),
      alignment: Alignment.center,
      child: Text(
        iniciales,
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _communityDivider() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.public_rounded, color: Colors.white, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Toda la comunidad',
                  style: AppTextStyles.subtitle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Lo que se mueve en ClubReads',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: .75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trendingAuthors(List<TrendingAuthor> authors) {
    return _HScrollGestureProxy(
      height: 150,
      child: (physics, controller) => ListView.separated(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: physics,
        itemCount: authors.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final author = authors[index];
          return GestureDetector(
            onTap: () => Navigator.push<void>(
              context,
              AppPageRoute(
                builder: (_) => AutorLibrosPage(
                  autorId: author.id,
                  nombre: author.nombre,
                  photoUrl: author.photoUrl,
                ),
              ),
            ),
            child: SizedBox(
              width: 80,
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryLight,
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: OptimizedNetworkImage(
                      url: author.photoUrl,
                      width: 72,
                      height: 72,
                      fallback: _authorInitials(author.nombre),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    author.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${author.libros} libros',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
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

  Widget _sectionTitle(
    String title,
    String subtitle,
    IconData icon, {
    Widget? action,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48),
            const SizedBox(height: 12),
            const Text('No hemos podido cargar tu espacio lector.'),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _LogrosDashboardSection extends StatelessWidget {
  const _LogrosDashboardSection({required this.userName, required this.future});
  final String userName;
  final Future<List<UserAchievement>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserAchievement>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _LogrosSkeleton();
        }
        final achievements = snapshot.data ?? const [];
        if (achievements.isEmpty) return const SizedBox.shrink();

        final unlocked = achievements.where((a) => a.unlocked).length;
        final total = achievements.length;
        final pct = total > 0 ? unlocked / total : 0.0;

        final rarityOrder = {'legendary': 0, 'epic': 1, 'rare': 2, 'common': 3};
        final recent = [...achievements.where((a) => a.unlocked)]
          ..sort(
            (a, b) => (rarityOrder[a.rarity] ?? 3).compareTo(
              rarityOrder[b.rarity] ?? 3,
            ),
          );
        final shown = recent.take(6).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 20)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tus logros ${DateTime.now().year}',
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$unlocked de $total desbloqueados',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push<void>(
                    context,
                    AppPageRoute(builder: (_) => const MisLogrosPage()),
                  ),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 5,
                backgroundColor: AppColors.primaryLight,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  '¡Empieza a leer para desbloquear logros este año!',
                  style: AppTextStyles.bodySecondary,
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.9,
                ),
                itemCount: shown.length,
                itemBuilder: (context, i) =>
                    _LogroMiniTile(achievement: shown[i]),
              ),
          ],
        );
      },
    );
  }
}

/// Placeholder de logros con las mismas dimensiones que la sección cargada.
/// Evita el layout-shift mientras el future de achievements está en vuelo.
class _LogrosSkeleton extends StatelessWidget {
  static BorderRadius _r(double r) => BorderRadius.circular(r);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClubShimmer(width: 24, height: 24, borderRadius: _r(4)),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClubShimmer(width: 140, height: 14, borderRadius: _r(4)),
                  const SizedBox(height: 4),
                  ClubShimmer(width: 100, height: 11, borderRadius: _r(4)),
                ],
              ),
            ),
            ClubShimmer(width: 60, height: 28, borderRadius: _r(8)),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ClubShimmer(width: double.infinity, height: 6, borderRadius: _r(3)),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.9,
          ),
          itemCount: 6,
          itemBuilder: (_, i) => ClubShimmer(
            width: double.infinity,
            height: double.infinity,
            borderRadius: _r(AppRadius.md),
          ),
        ),
      ],
    );
  }
}

class _LogroMiniTile extends StatelessWidget {
  const _LogroMiniTile({required this.achievement});
  final UserAchievement achievement;

  Color get _color => switch (achievement.rarity) {
    'legendary' => AppColors.gold, // dorado — cálido, especial
    'epic' => AppColors.primary, // ciruela — color principal de la app
    'rare' => AppColors.info, // azul apagado — discreto
    _ => AppColors.textSecondary, // marrón grisáceo — común
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Tooltip(
      message: '${achievement.title}\n${achievement.description}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: .22), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(achievement.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color.withValues(alpha: .75),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                AchievementService.rarityLabels[achievement.rarity] ?? '',
                style: TextStyle(
                  fontSize: 8,
                  color: color.withValues(alpha: .75),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentBookCard extends StatelessWidget {
  const _CurrentBookCard({
    required this.book,
    required this.onTap,
    required this.onUpdateProgress,
    this.onLongPress,
  });

  final GeneralBook book;
  final VoidCallback onTap;
  final VoidCallback onUpdateProgress;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final pct =
        book.currentPage != null && book.pages != null && book.pages! > 0
        ? book.currentPage! / book.pages!
        : book.progress / 100.0;
    final pctClamped = pct.clamp(0.0, 1.0);
    final hasPageInfo =
        book.currentPage != null && book.pages != null && book.pages! > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border.withValues(alpha: .5)),
          ),
          child: Row(
            children: [
              ClubBookCover(
                title: book.title,
                imageUrl: book.coverUrl,
                width: 52,
                height: 76,
                showShadow: false,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pctClamped,
                        minHeight: 6,
                        backgroundColor: AppColors.primaryLight,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasPageInfo
                          ? 'Pág. ${book.currentPage} de ${book.pages} · '
                                '${(pctClamped * 100).round()}%'
                          : '${book.progress}%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Actualizar progreso',
                onPressed: onUpdateProgress,
                icon: const Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widget de acceso rápido a Mis adquisiciones ──────────────────────────────

class _WishlistPreviewSection extends StatefulWidget {
  const _WishlistPreviewSection({required this.userName});
  final String userName;

  @override
  State<_WishlistPreviewSection> createState() =>
      _WishlistPreviewSectionState();
}

class _WishlistPreviewSectionState extends State<_WishlistPreviewSection>
    with AutomaticKeepAliveClientMixin {
  late Future<WishlistData> _future;

  // Evita que SliverList desmonte este widget cuando sale del viewport.
  // Sin keepAlive, al remontar se relanza la future desde skeleton (80 px),
  // la corrección de scrollOffset lleva la posición hacia arriba y, en cuanto
  // la future resuelve y la sección crece de nuevo, el scroll vuelve al punto
  // original — el usuario no puede subir a pesar de que pos > 0.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _future = WishlistService().getWishlist();
  }

  void _openWishlist() {
    Navigator.push<void>(
      context,
      AppPageRoute(builder: (_) => const WishlistPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // requerido por AutomaticKeepAliveClientMixin
    return FutureBuilder<WishlistData>(
      future: _future,
      builder: (context, snap) {
        // Skeleton mientras carga
        if (snap.connectionState == ConnectionState.waiting) {
          return ClubShimmer(
            width: double.infinity,
            height: 80,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          );
        }

        // Si no hay datos o hay error, mostramos el acceso rápido vacío
        final data = snap.data ?? WishlistData.empty;

        if (data.totalItems == 0) {
          // Empty-state compacto: invitación a añadir
          return GestureDetector(
            onTap: _openWishlist,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7B4E92), Color(0xFF40254F)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🛍️', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu lista de deseos',
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Libros que quieres leer o comprar',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: .80),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.white.withValues(alpha: .80),
                  ),
                ],
              ),
            ),
          );
        }

        return WishlistSummaryCard(data: data, onTap: _openWishlist);
      },
    );
  }
}

class _ReleasesPreview extends StatelessWidget {
  const _ReleasesPreview({
    required this.future,
    this.mode = ReleaseCatalogMode.upcoming,
  });

  final Future<List<UpcomingRelease>> future;
  final ReleaseCatalogMode mode;

  void _open(BuildContext context) => Navigator.push<void>(
    context,
    AppPageRoute(builder: (_) => UpcomingReleasesPage(mode: mode)),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<List<UpcomingRelease>>(
    future: future,
    builder: (context, snapshot) {
      final books = snapshot.data ?? const [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                child: Icon(
                  mode == ReleaseCatalogMode.newReleases
                      ? Icons.auto_awesome_outlined
                      : Icons.event_available_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode == ReleaseCatalogMode.newReleases
                          ? 'Novedades disponibles'
                          : 'Próximos lanzamientos',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      mode == ReleaseCatalogMode.newReleases
                          ? 'Libros de ficción que ya están en librerías'
                          : 'Novedades que están a punto de llegar',
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _open(context),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (snapshot.connectionState != ConnectionState.done)
            const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (snapshot.hasError)
            ClubCard(
              child: InkWell(
                onTap: () => _open(context),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off_outlined),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text('No hemos podido cargar esta sección'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (books.isEmpty)
            ClubCard(
              child: InkWell(
                onTap: () => _open(context),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.event_busy_outlined),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text('Todavía no hay libros disponibles'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            _HScrollGestureProxy(
              height: 205,
              child: (physics, controller) => ListView.separated(
                controller: controller,
                key: PageStorageKey(
                  mode == ReleaseCatalogMode.newReleases
                      ? 'dashboard-new-releases'
                      : 'dashboard-upcoming-releases',
                ),
                scrollDirection: Axis.horizontal,
                physics: physics,
                itemCount: books.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, index) {
                  final book = books[index];
                  return InkWell(
                    onTap: () => _open(context),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: SizedBox(
                      width: 112,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClubBookCover(
                                title: book.title,
                                imageUrl: book.coverUrl ?? '',
                                width: 104,
                                height: 152,
                              ),
                              if (book.isInWishlist || book.isInLibrary)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      book.isInLibrary
                                          ? Icons.check
                                          : Icons.favorite,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _HScrollGestureProxy
//
// Envuelve un ListView horizontal para evitar que su HorizontalDragGestureRecognizer
// robe gestos verticales del CustomScrollView padre.
//
// Mecanismo (v6 — Listener solo horizontal):
//   – El ListView siempre usa NeverScrollableScrollPhysics → no registra
//     reconocedores en el arena de gestos; elimina la competencia horizontal.
//   – Un Listener de puntero crudo detecta la dirección del swipe.
//   – Gesto horizontal → mueve el carrusel directamente vía _controller.
//   – Gesto vertical   → el Listener NO interviene; el arena lo resuelve con
//     el VerticalDragGestureRecognizer del CustomScrollView sin interferencia.
//     Esto evita el doble-scroll que causaba v5 (Listener + arena scrollando
//     simultáneamente a velocidad doble y luego reventando).
// ─────────────────────────────────────────────────────────────────────────────
class _HScrollGestureProxy extends StatefulWidget {
  const _HScrollGestureProxy({
    required this.height,
    required this.child,
  });

  final double height;

  /// Recibe las físicas fijas (siempre NeverScrollable) y el ScrollController
  /// que el ListView debe usar para que el proxy pueda moverlo.
  final Widget Function(ScrollPhysics physics, ScrollController controller) child;

  @override
  State<_HScrollGestureProxy> createState() => _HScrollGestureProxyState();
}

class _HScrollGestureProxyState extends State<_HScrollGestureProxy> {
  // Umbral de movimiento (px) antes de decidir el eje del gesto.
  static const _kDirectionSlop = 8.0;
  // Deceleración (px/s²) para el fling del carrusel.
  static const _kDeceleration = 3500.0;

  final _controller = ScrollController();

  // Estado del puntero activo.
  int? _activePointer;
  double? _startX;
  double? _startY;
  double? _scrollAtStart;
  bool? _isHorizontal; // null = aún sin decidir

  // Velocidad horizontal (para fling del carrusel).
  double _prevLocalX = 0;
  int _prevTimestampUs = 0;
  double _velocityPxPerSec = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent e) {
    if (_activePointer != null) return;
    _activePointer = e.pointer;
    _startX = e.localPosition.dx;
    _startY = e.localPosition.dy;
    _scrollAtStart = _controller.hasClients ? _controller.position.pixels : 0.0;
    _isHorizontal = null;
    _prevLocalX = e.localPosition.dx;
    _prevTimestampUs = e.timeStamp.inMicroseconds;
    _velocityPxPerSec = 0;

    // Detener cualquier animación de fling en curso en el carrusel.
    if (_controller.hasClients) {
      try {
        _controller.position.hold(() {});
      } catch (_) {}
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (e.pointer != _activePointer) return;
    final sx = _startX;
    final sy = _startY;
    if (sx == null || sy == null) return;

    final dx = e.localPosition.dx - sx;
    final dy = e.localPosition.dy - sy;

    // Determinar el eje una sola vez, tras superar el umbral.
    // Sesgo 1.7×: el dedo debe moverse un 70 % más en X que en Y para
    // activar el carrusel; de lo contrario, se deja pasar al arena vertical.
    if (_isHorizontal == null) {
      if (dx.abs() < _kDirectionSlop && dy.abs() < _kDirectionSlop) return;
      _isHorizontal = dx.abs() > dy.abs() * 1.7;
    }

    // Gesto vertical → no intervenimos; el CustomScrollView lo maneja.
    if (_isHorizontal != true) return;

    // Actualizar velocidad instantánea para el fling posterior.
    final nowUs = e.timeStamp.inMicroseconds;
    final dtUs = nowUs - _prevTimestampUs;
    if (dtUs > 0 && dtUs < 100_000) {
      final instantV = (e.localPosition.dx - _prevLocalX) / (dtUs / 1e6);
      _velocityPxPerSec = 0.6 * instantV + 0.4 * _velocityPxPerSec;
    }
    _prevLocalX = e.localPosition.dx;
    _prevTimestampUs = nowUs;

    if (!_controller.hasClients) return;
    final newPixels = (_scrollAtStart! - dx).clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );
    _controller.jumpTo(newPixels);
  }

  void _onPointerUp(PointerUpEvent e) {
    if (e.pointer != _activePointer) return;
    if (_isHorizontal == true) _applyFling();
    _reset();
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (e.pointer != _activePointer) return;
    _reset();
  }

  void _applyFling() {
    if (!_controller.hasClients) return;
    final v = _velocityPxPerSec;
    if (v.abs() < 80) return;
    final a = _kDeceleration;
    final distance = v.sign * v * v / (2 * a);
    final target = (_controller.position.pixels - distance).clamp(
      _controller.position.minScrollExtent,
      _controller.position.maxScrollExtent,
    );
    final durationMs = ((v.abs() / a) * 1000).clamp(80, 500).toInt();
    _controller.animateTo(
      target,
      duration: Duration(milliseconds: durationMs),
      curve: Curves.decelerate,
    );
  }

  void _reset() {
    _activePointer = null;
    _startX = null;
    _startY = null;
    _isHorizontal = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // translucent: el Listener recibe los eventos Y el hit-testing continúa
      // hacia los ancestros, lo que permite que el VerticalDragGestureRecognizer
      // del CustomScrollView entre en el arena sin interferencia.
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: SizedBox(
        height: widget.height,
        child: widget.child(const NeverScrollableScrollPhysics(), _controller),
      ),
    );
  }
}

// ── Feature 1: widget "Mi sesión de hoy" en el dashboard ──────────────────
//
// Se muestra bajo "Leyendo ahora" solo cuando el libro activo tiene
// kit de lectura con atmósfera configurada. Se carga a sí mismo.
class _KitSesionWidget extends StatefulWidget {
  final String bookId;
  final String bookTitle;
  final String coverUrl;
  final VoidCallback onTap;

  const _KitSesionWidget({
    required this.bookId,
    required this.bookTitle,
    required this.coverUrl,
    required this.onTap,
  });

  @override
  State<_KitSesionWidget> createState() => _KitSesionWidgetState();
}

class _KitSesionWidgetState extends State<_KitSesionWidget> {
  KitLecturaSeleccion? _kit;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(_KitSesionWidget old) {
    super.didUpdateWidget(old);
    if (old.bookId != widget.bookId) _cargar();
  }

  Future<void> _cargar() async {
    if (widget.bookId.isEmpty) return;
    final kit = await KitLecturaService().obtener(widget.bookId);
    if (!mounted) return;
    setState(() => _kit = kit);
  }

  @override
  Widget build(BuildContext context) {
    final kit = _kit;
    // Si no hay kit con atmósfera, no mostramos nada
    if (kit == null || !kit.tieneAtmosfera) return const SizedBox.shrink();

    final icono = kit.atmosferaIcono.trim().isEmpty ? '✨' : kit.atmosferaIcono;
    final titulo = kit.atmosferaTitulo.trim().isEmpty
        ? 'Tu atmósfera de lectura'
        : kit.atmosferaTitulo;

    // Detalles del rincón: luz, bebida, snack, música — los que están configurados
    final detalles = <String>[
      if (kit.luz.trim().isNotEmpty) kit.luz,
      if (kit.bebida.trim().isNotEmpty) kit.bebida,
      if (kit.snack.trim().isNotEmpty) kit.snack,
    ].take(3).join(' · ');

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: GestureDetector(
        onTap: () => Navigator.push<void>(
          context,
          AppPageRoute(
            builder: (_) => KitLecturaPage(
              bookId: widget.bookId,
              libro: widget.bookTitle,
              coverUrl: widget.coverUrl,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Emoji grande de atmósfera
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(icono, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Info de la sesión
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    if (detalles.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        detalles,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      widget.bookTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Dots de paleta (si tiene)
              if (kit.tienePaleta)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: kit.paleta
                          .take(3)
                          .map((hex) {
                            final limpio = hex.replaceAll('#', '').trim();
                            final color = Color(
                              int.parse('FF$limpio', radix: 16),
                            );
                            return Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.2,
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary.withValues(alpha: 0.5),
                      size: 18,
                    ),
                  ],
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
