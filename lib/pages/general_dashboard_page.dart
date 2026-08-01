import 'package:club_lectura_app/pages/notificaciones_page.dart';
import 'package:flutter/material.dart';

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
import '../widgets/common/reading_cover_calendar.dart';
import '../widgets/dashboard/monthly_reading_shelf.dart';
import 'clubs_page.dart';
import 'home_page.dart';
import 'explore_catalog_page.dart';
import 'detalle_libro_page.dart';
import 'monthly_reading_share_page.dart';
import 'perfil_usuario_page.dart';
import 'sagas_page.dart';
import '../widgets/common/onboarding_tutorial.dart';

class GeneralDashboardPage extends StatefulWidget {
  const GeneralDashboardPage({super.key});

  @override
  State<GeneralDashboardPage> createState() => _GeneralDashboardPageState();
}

class _GeneralDashboardPageState extends State<GeneralDashboardPage> {
  late Future<GeneralDashboard> _future;
  String? _openingClubId;
  Key _shelfKey = UniqueKey();
  final _scrollController = ScrollController();
  int _noLeidas = 0;

  @override
  void initState() {
    super.initState();
    _future = GeneralDashboardService().load();
    _checkOnboarding();
    _loadNotificaciones();
  }

  Future<void> _loadNotificaciones() async {
    try {
      final data = await ApiService().getNotificaciones();
      if (mounted) setState(() => _noLeidas = data.noLeidas);
    } catch (_) {}
  }

  Future<void> _abrirNotificaciones() async {
    await Navigator.push<void>(
      context,
      AppPageRoute(builder: (_) => const NotificacionesPage()),
    );
    _loadNotificaciones();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkOnboarding() async {
    final mostrar = await deberiaMostrarOnboarding();
    if (!mostrar || !mounted) return;
    // Pequeño delay para que la pantalla termine de renderizarse
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    await mostrarOnboardingTutorial(context);
  }

  Future<void> _reload() async {
    setState(() {
      _future = GeneralDashboardService().load();
      _shelfKey = UniqueKey();
    });
    await _future;
  }

  Future<void> _manageClubs() async {
    await Navigator.push<void>(
      context,
      AppPageRoute(builder: (_) => const ClubsPage()),
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

  Future<void> _openPersonalBook(
    PersonalLibraryBook book,
    String userName,
  ) async {
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
  }

  Future<void> _openMySeries() async {
    await Navigator.push<void>(
      context,
      AppPageRoute(builder: (_) => const SagasPage(showBackButton: true)),
    );
    if (mounted) await _reload();
  }

  Future<void> _openMyProfile(String userName) async {
    await Navigator.push<void>(
      context,
      AppPageRoute(builder: (_) => PerfilUsuarioPage(usuario: userName)),
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
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _DashboardError(onRetry: _reload);
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: CustomScrollView(
              controller: _scrollController,
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
                    // Campanita con badge de no leídas
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
                          'Lo nuevo que acaba de llegar a ClubReads',
                          Icons.new_releases_outlined,
                          action: TextButton(
                            onPressed: _exploreBooks,
                            child: const Text('Ver biblioteca'),
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
                      // La biblioteca anual se muestra en el perfil
                      // Aquí mostramos la estantería del mes
                      if (data.calendar.finishedBooks.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        MonthlyReadingShelf(
                          key: _shelfKey,
                          year: data.calendar.year,
                          month: data.calendar.month,
                          books: data.calendar.finishedBooks,
                          scrollController: _scrollController,
                          onBookTap: (book) => openBookDetail(
                            context,
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
                        // ── Separador visual "Comunidad global" ──
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
                          'Autoras del momento',
                          'Las más presentes en vuestras bibliotecas',
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
      onTap: () => _openMyProfile(data.userName),
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
                      ? '🔥 ${data.summary.monthStreak} ${data.summary.monthStreak == 1 ? 'mes' : 'meses'} manteniendo tu racha'
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
                          child: Text(
                            clubvisionReminder,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
        // Fila 1: Leyendo + Terminados
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
        // Fila 2: Este mes (título arriba) + Páginas (mes principal, histórico pequeño)
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
                // Título en negrita arriba
                const Text(
                  'Este mes',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
                // Número grande
                Text(
                  '${summary.finishedThisMonth}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                // Subtítulo descriptivo
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
                // Título arriba
                const Text(
                  'Páginas',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                // Páginas del mes (número principal)
                Text(
                  pagesMes > 0 ? '$pagesMes' : '0',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                // Total histórico en pequeño
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
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.local_library_rounded,
                color: AppColors.primary,
              ),
            ),
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
                    '${club.members} miembros · ${club.activeReadings} lecturas activas',
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
        colors: [AppColors.surfaceSoft, Color(0xFFFFF5EA)],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.group_add_outlined,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Crea un club o entra con una invitación',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: _manageClubs, child: const Text('Empezar')),
        ],
      ),
    );
  }

  Widget _currentBooks(List<GeneralBook> books) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final book = books[index];
          return SizedBox(
            width: 122,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => openBookDetail(
                context,
                title: book.title,
                bookId: book.id,
                coverUrl: book.coverUrl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClubBookCover(
                    title: book.title,
                    imageUrl: book.coverUrl,
                    width: 110,
                    height: 158,
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
        },
      ),
    );
  }

  Widget _personalLibrary(List<PersonalLibraryBook> books, String userName) {
    return SizedBox(
      height: 224,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final book = books[index];
          return SizedBox(
            width: 122,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openPersonalBook(book, userName),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClubBookCover(
                        title: book.title,
                        imageUrl: book.coverUrl,
                        width: 110,
                        height: 158,
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
        },
      ),
    );
  }

  Widget _latestAdditions(List<GeneralLatestBook> books) {
    return SizedBox(
      height: 218,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final book = books[index];
          return SizedBox(
            width: 112,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => openBookDetail(
                context,
                title: book.title,
                bookId: book.id,
                coverUrl: book.coverUrl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClubBookCover(
                        title: book.title,
                        imageUrl: book.coverUrl,
                        width: 108,
                        height: 158,
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
    return SizedBox(
      height: 154,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: series.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final item = series[index];
          return SizedBox(
            width: 260,
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: item.next == null
                    ? _openMySeries
                    : () => openBookDetail(
                        context,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
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
            ),
          );
        },
      ),
    );
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
            onBookTap: (reading) => _openCalendarBooks([reading.title]),
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
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final book = books[index];
          return SizedBox(
            width: 100,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => openBookDetail(
                context,
                title: book.title,
                bookId: book.id,
                coverUrl: book.coverUrl,
              ),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClubBookCover(
                        title: book.title,
                        imageUrl: book.coverUrl,
                        width: 92,
                        height: 132,
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

  Future<void> _openCalendarBooks(List<String> books) async {
    if (books.isEmpty) return;
    if (books.length == 1) {
      await openBookDetail(context, title: books.first);
      return;
    }
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            const ListTile(
              title: Text(
                'Libros de este día',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            for (final book in books)
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(book),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, book),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      await openBookDetail(context, title: selected);
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

  /// Avatar de fallback con iniciales y color derivado del nombre
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
    // Color derivado del hash del nombre para que sea consistente
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
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
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
                    child: author.photoUrl.isNotEmpty
                        ? Image.network(
                            author.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _authorInitials(author.nombre),
                          )
                        : _authorInitials(author.nombre),
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
