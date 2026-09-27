import 'package:flutter/material.dart';

import '../models/achievements/achievement.dart';
import '../models/dashboard.dart' show LecturaAhoraItem;
import '../models/estadisticas_personales.dart';
import '../models/general_dashboard.dart';
import '../navigation/app_page_route.dart';
import '../navigation/book_detail_navigation.dart';
import '../services/api_service.dart';
import '../services/general_dashboard_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/wrapped_availability.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_section_title.dart';
import '../widgets/common/editar_progreso_dialog.dart';
import '../widgets/common/floating_nav_bar.dart' show kFloatingNavClearance;
import '../widgets/dashboard/bingo_lector_card.dart';
import '../widgets/profile/book_of_year_preview.dart';
import 'perfil_usuario_page.dart'
    show
        CheckinSection,
        FavoritosShelf,
        LibroSeleccionable,
        PerfilUsuarioPage;
import '../widgets/common/club_avatar.dart';
import 'personalidad_lectora_page.dart';
import 'share_reader_card_page.dart';
import 'wrapped_page.dart';

/// "Mi espacio": el rincón de la cuenta personal — qué haces hoy (leyendo
/// ahora, racha y check-in, sagas en curso) y cómo celebras tu año (bingo,
/// quiz, Wrapped, libro del año). Las estadísticas y gráficas en profundidad
/// viven en la pestaña hermana "Mis estadísticas" (`mi_estadisticas_page.dart`).
class MiEspacioPage extends StatefulWidget {
  const MiEspacioPage({super.key});

  @override
  State<MiEspacioPage> createState() => _MiEspacioPageState();
}

class _MiEspacioPageState extends State<MiEspacioPage>
    with TickerProviderStateMixin {
  late Future<_PageData> _future;

  late final AnimationController _streakCtrl;
  late final Animation<double> _streakPulse;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _streakCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _streakPulse = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _streakCtrl, curve: Curves.easeInOut));
  }

  Future<_PageData> _load() async {
    final dashboard = GeneralDashboardService().load();
    final achievements = ApiService().getAchievements();
    // El género favorito es un extra decorativo de "Mi año en libros": si el
    // endpoint falla, la tarjeta simplemente no lo muestra.
    final generoFavorito = ApiService()
        .getEstadisticasPersonales()
        .then((json) => EstadisticasPersonales.fromJson(json).generos)
        .then((generos) => generos.isNotEmpty ? generos.first.nombre : null)
        .catchError((_) => null);
    final results = await Future.wait([dashboard, achievements, generoFavorito]);
    return _PageData(
      dashboard: results[0] as GeneralDashboard,
      achievements: results[1] as List<UserAchievement>,
      generoFavorito: results[2] as String?,
    );
  }

  @override
  void dispose() {
    _streakCtrl.dispose();
    super.dispose();
  }

  Future<void> _editarProgreso(GeneralBook book) async {
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
          builder: (_) => EditarProgresoDialog(
            lectura: LecturaAhoraItem(
              libraryId: book.id,
              bookId: book.id,
              titulo: book.title,
              coverUrl: book.coverUrl,
              progreso: book.progress,
              paginaActual: book.currentPage,
              paginasTotales: book.pages,
              comentario: book.note,
              actualizadoEn: null,
              reacciones: const {},
              miReaccion: null,
            ),
          ),
        );
    if (resultado == null || !mounted) return;
    final userName = (await _future).dashboard.userName;
    final guardado = await ApiService().actualizarProgresoLectura(
      usuario: userName,
      libro: book.title,
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
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: const Color(0xFFF5EDE0),
        foregroundColor: AppColors.primaryDark,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryDark, size: 22),
        actionsIconTheme: const IconThemeData(
          color: AppColors.primaryDark,
          size: 22,
        ),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFCDB8A0), width: 1.0),
        ),
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '✦  C L U B R E A D S  ✦',
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Mi espacio lector',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryDark,
                letterSpacing: -0.3,
                height: 1.15,
              ),
            ),
          ],
        ),
        actions: [
          FutureBuilder<_PageData>(
            future: _future,
            builder: (context, snapshot) {
              final dashboard = snapshot.data?.dashboard;
              if (dashboard == null) return const SizedBox(width: 46);
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: ClubAvatar(
                  nombre: dashboard.userName,
                  imageUrl: dashboard.avatarUrl,
                  size: 46,
                  onTap: () => Navigator.push<void>(
                    context,
                    AppPageRoute(
                      builder: (_) => PerfilUsuarioPage(
                        usuario: dashboard.userName,
                        profileUserId: dashboard.userId.isEmpty
                            ? null
                            : dashboard.userId,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<_PageData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _ErrorView(onRetry: () => setState(() => _future = _load()));
          }
          return _Content(
            data: snapshot.data!,
            streakPulse: _streakPulse,
            onEditarProgreso: _editarProgreso,
            onVerWrapped: () => Navigator.push<void>(
              context,
              AppPageRoute(
                builder: (_) =>
                    WrappedPage(anio: WrappedAvailability().wrappedYear),
              ),
            ),
            onOpenQuiz: () => Navigator.push<void>(
              context,
              AppPageRoute(
                builder: (_) => const PersonalidadLectoraPage(),
              ),
            ),
            onShareCard: () {
              final d = snapshot.data!;
              final summary = d.dashboard.summary;
              Navigator.push<void>(
                context,
                AppPageRoute(
                  builder: (_) => ShareReaderCardPage(
                    data: ReaderCardData(
                      userName: d.dashboard.userName,
                      // Libros terminados en el año en curso (no histórico)
                      booksFinished: d.dashboard.yearShelf.length,
                      booksReading: summary.reading,
                      monthStreak: summary.monthStreak,
                      pagesRead: summary.pagesRead,
                      coverUrls: d.dashboard.personalLibrary
                          .where((b) => b.coverUrl.trim().isNotEmpty)
                          .take(4)
                          .map((b) => b.coverUrl)
                          .toList(),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PageData {
  const _PageData({
    required this.dashboard,
    required this.achievements,
    this.generoFavorito,
  });
  final GeneralDashboard dashboard;
  final List<UserAchievement> achievements;
  final String? generoFavorito;
}

/// Todos los libros de la cuenta (leyendo, terminados este año, biblioteca
/// pendiente) que se pueden elegir como favorito, para el selector de
/// "Libros favoritos" — deduplicados por bookId.
List<LibroSeleccionable> _librosSeleccionables(GeneralDashboard dashboard) {
  final porId = <String, LibroSeleccionable>{};
  for (final book in dashboard.currentBooks) {
    porId[book.id] = LibroSeleccionable(
      bookId: book.id,
      title: book.title,
      coverUrl: book.coverUrl,
    );
  }
  for (final book in dashboard.yearShelf) {
    porId[book.bookId] = LibroSeleccionable(
      bookId: book.bookId,
      title: book.title,
      coverUrl: book.coverUrl,
    );
  }
  for (final book in dashboard.personalLibrary) {
    porId[book.id] = LibroSeleccionable(
      bookId: book.id,
      title: book.title,
      coverUrl: book.coverUrl,
    );
  }
  return porId.values.toList(growable: false);
}

// ────────────────────────────────────────────────────────────────────────────
// _Content — toda la UI una vez cargado
// ────────────────────────────────────────────────────────────────────────────

class _Content extends StatelessWidget {
  const _Content({
    required this.data,
    required this.streakPulse,
    required this.onEditarProgreso,
    required this.onVerWrapped,
    required this.onOpenQuiz,
    required this.onShareCard,
  });

  final _PageData data;
  final Animation<double> streakPulse;
  final ValueChanged<GeneralBook> onEditarProgreso;
  final VoidCallback onVerWrapped;
  final VoidCallback onOpenQuiz;
  final VoidCallback onShareCard;

  @override
  Widget build(BuildContext context) {
    final summary = data.dashboard.summary;
    final achievements = data.achievements;
    final unlockedCount = achievements.where((a) => a.unlocked).length;
    final total = achievements.length;
    final currentBooks = data.dashboard.currentBooks;
    final openSeries = data.dashboard.openSeries;

    return RefreshIndicator(
      onRefresh: () async {},
      child: CustomScrollView(
        slivers: [
          // ── Racha — sección propia, ya no fusionada con la cabecera ───────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _RachaCard(
                summary: summary,
                streakPulse: streakPulse,
                userName: data.dashboard.userName,
              ),
            ),
          ),

          // ── Leyendo ahora ──────────────────────────────────────────────────
          if (currentBooks.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _SectionLabel('Hoy'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    for (final book in currentBooks)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _LeyendoAhoraCard(
                          book: book,
                          onTap: () => openBookDetail(
                            context,
                            title: book.title,
                            bookId: book.id,
                            coverUrl: book.coverUrl,
                          ),
                          onEditar: () => onEditarProgreso(book),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],

          // ── Racha + check-in (fusionados) ───────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              currentBooks.isEmpty ? AppSpacing.md : AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            sliver: const SliverToBoxAdapter(child: CheckinSection()),
          ),

          // ── Mi año en libros ─────────────────────────────────────────────
          if (data.dashboard.yearShelf.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _MiAnioEnLibrosCard(
                  anio: DateTime.now().year,
                  libros: data.dashboard.yearShelf,
                  generoFavorito: data.generoFavorito,
                  enEstanteria: summary.enEstanteria,
                ),
              ),
            ),

          // ── Sagas en curso ───────────────────────────────────────────────
          if (openSeries.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(child: _SectionLabel('Sagas en curso')),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                0,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 168,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    itemCount: openSeries.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final saga = openSeries[index];
                      return _SagaCard(
                        item: saga,
                        onTap: saga.next == null
                            ? null
                            : () => openBookDetail(
                                context,
                                title: saga.next!.title,
                                bookId: saga.next!.id,
                                coverUrl: saga.next!.coverUrl,
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],

          // ── Celebra tu año ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(child: _SectionLabel('Celebra tu año')),
          ),

          // ── Bingo lector ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: const BingoLectorSection(),
              ),
            ),
          ),

          // ── Libros favoritos — sección propia, no una tarjeta de enlace ────
          // Mismo formato de título que "Mi libro del año" (ClubSectionTitle
          // con icono), para que las dos secciones se vean homogéneas.
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: ClubSectionTitle(
                title: 'Libros favoritos',
                subtitle: 'Tus 5 favoritos de siempre',
                icon: Icons.favorite_rounded,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: FavoritosShelf(
                favoritos: const [],
                esMiPerfil: true,
                onOpen: (libro) => openBookDetail(
                  context,
                  title: libro.title,
                  bookId: libro.bookId,
                  coverUrl: libro.coverUrl ?? '',
                  genre: libro.genreName,
                ),
                todosLosLibros: _librosSeleccionables(data.dashboard),
              ),
            ),
          ),

          // ── Mi libro del año — sección propia (incluye su propio título) ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: BookOfYearPreview(
                profile: data.dashboard.userName,
                profileUserId: data.dashboard.userId.isEmpty
                    ? null
                    : data.dashboard.userId,
                editable: true,
              ),
            ),
          ),

          // ── Quiz de personalidad ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _QuizCta(onTap: onOpenQuiz),
            ),
          ),

          // ── Tarjeta compartible ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _ShareCardCta(onTap: onShareCard),
            ),
          ),

          // ── Wrapped anual (al fondo: sigue bloqueado hasta noviembre) ──────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: MiEspacioWrappedCta(onTap: onVerWrapped),
            ),
          ),

          // ── Motivación ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              kFloatingNavClearance,
            ),
            sliver: SliverToBoxAdapter(
              child: _MotivationalCta(
                unlocked: unlockedCount,
                total: total,
                reading: summary.reading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _WrappedCta
// ────────────────────────────────────────────────────────────────────────────

class MiEspacioWrappedCta extends StatelessWidget {
  const MiEspacioWrappedCta({super.key, required this.onTap, this.date});
  final VoidCallback onTap;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final availability = WrappedAvailability(date);
    final year = availability.wrappedYear;
    if (!availability.isAvailable) {
      final days = availability.daysUntilNovember;
      return Container(
        key: const Key('wrapped_individual_locked'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F3A5F), Color(0xFF2E6F6E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            const Text('🎁', style: TextStyle(fontSize: 36)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wrapped $year',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Disponible en $days ${days == 1 ? 'día' : 'días'} · llega en noviembre',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .80),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.lock_outline_rounded,
              color: Colors.white.withValues(alpha: .70),
              size: 18,
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      key: const Key('wrapped_individual_available'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C3FF5), Color(0xFF1DB954)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 36)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tu Wrapped $year',
                    style: AppTextStyles.subtitle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tu año en libros, de un vistazo.',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _RachaCard — sección propia debajo de la cabecera (antes fusionada con ella)
// ────────────────────────────────────────────────────────────────────────────

class _RachaCard extends StatelessWidget {
  const _RachaCard({
    required this.summary,
    required this.streakPulse,
    required this.userName,
  });

  final GeneralSummary summary;
  final Animation<double> streakPulse;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final firstName = userName.split(' ').first;
    final streak = summary.monthStreak;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            Color(0xFF7B3F8F),
            AppColors.inkCoral,
          ],
          stops: [0, .55, 1],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Fondo decorativo
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: .07,
              child: Icon(
                Icons.auto_stories_rounded,
                size: 140,
                color: Colors.white,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (streak > 0) ...[
                ScaleTransition(
                  scale: streakPulse,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warning.withValues(alpha: .4),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          '$streak ${streak == 1 ? 'mes' : 'meses'} de racha',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppColors.midnight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                streak > 0
                    ? '¡Imparable, $firstName!'
                    : 'Hola, $firstName 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                summary.finished == 0
                    ? 'Empieza tu primera lectura y construye tu universo'
                    : '${summary.finished} ${summary.finished == 1 ? 'libro terminado' : 'libros terminados'} · ${summary.pagesRead} páginas leídas',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ────────────────────────────────────────────────────────────────────────────
// _MotivationalCta
// ────────────────────────────────────────────────────────────────────────────

class _MotivationalCta extends StatelessWidget {
  const _MotivationalCta({
    required this.unlocked,
    required this.total,
    required this.reading,
  });

  final int unlocked;
  final int total;
  final int reading;

  String get _message {
    if (reading > 0) {
      return '¡Tienes $reading ${reading == 1 ? 'libro' : 'libros'} en marcha! Sigue leyendo para desbloquear más logros.';
    }
    if (unlocked == 0) return 'Empieza tu primera lectura. Cada página cuenta.';
    if (unlocked >= total) {
      return '¡Has completado la colección! Has conquistado todos los logros disponibles.';
    }
    return 'Te quedan ${total - unlocked} logros por conquistar. ¡Tú puedes!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.midnight, Color(0xFF4A2460)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 32)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              _message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizCta extends StatelessWidget {
  const _QuizCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E1A4A), Color(0xFF5E3A7A), Color(0xFF9E5FBF)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5E3A7A).withValues(alpha: .35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🧬', style: TextStyle(fontSize: 32)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¿Qué tipo de lectora eres?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '6 preguntas · Descubre tu personalidad lectora y compártela',
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
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareCardCta extends StatelessWidget {
  const _ShareCardCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5A3470), Color(0xFFBE4D4A)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('✨', style: TextStyle(fontSize: 32)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Comparte tu perfil lector',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Genera una tarjeta con tus estadísticas y compártela',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.ios_share_rounded,
              color: Colors.white.withValues(alpha: .80),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _ErrorView
// ────────────────────────────────────────────────────────────────────────────

// ────────────────────────────────────────────────────────────────────────────
// _SectionLabel — etiqueta pequeña tipo "eyebrow" para separar bloques
// ────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _LeyendoAhoraCard
// ────────────────────────────────────────────────────────────────────────────

class _LeyendoAhoraCard extends StatelessWidget {
  const _LeyendoAhoraCard({
    required this.book,
    required this.onTap,
    required this.onEditar,
  });
  final GeneralBook book;
  final VoidCallback onTap;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClubBookCover(
              title: book.title,
              imageUrl: book.coverUrl,
              width: 44,
              height: 64,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${book.genre} · Leyendo ahora',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (book.progress.clamp(0, 100)) / 100,
                      minHeight: 5,
                      backgroundColor: AppColors.primaryLight,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.currentPage != null && book.pages != null
                        ? 'Pág. ${book.currentPage} de ${book.pages} · ${book.progress}%'
                        : '${book.progress}%',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Actualizar progreso',
              visualDensity: VisualDensity.compact,
              onPressed: onEditar,
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _MiAnioEnLibrosCard
// ────────────────────────────────────────────────────────────────────────────

class _MiAnioEnLibrosCard extends StatelessWidget {
  const _MiAnioEnLibrosCard({
    required this.anio,
    required this.libros,
    required this.enEstanteria,
    this.generoFavorito,
  });

  final int anio;
  final List<YearShelfBook> libros;
  final int enEstanteria;
  final String? generoFavorito;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi año en libros',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$anio · ${libros.length} leídos',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${libros.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: libros.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) => ClubBookCover(
                title: libros[index].title,
                imageUrl: libros[index].coverUrl,
                width: 60,
                height: 88,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              if (generoFavorito != null && generoFavorito!.trim().isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, size: 15, color: AppColors.inkCoral),
                    const SizedBox(width: 4),
                    Text(
                      'Género favorito: $generoFavorito',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bookmark_outline_rounded,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$enEstanteria en mi estantería',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _SagaCard — tarjeta de una saga en curso, con progreso y siguiente libro
// ────────────────────────────────────────────────────────────────────────────

class _SagaCard extends StatelessWidget {
  const _SagaCard({required this.item, this.onTap});
  final GeneralOpenSeries item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClubBookCover(
                title: item.name,
                imageUrl: item.coverUrl,
                width: 52,
                height: 78,
                showShadow: false,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item.progress.clamp(0, 1),
                        minHeight: 5,
                        backgroundColor: AppColors.primaryLight,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.read} de ${item.total} leído${item.read == 1 ? '' : 's'}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (item.next != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Sig: ${item.next!.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
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
  }
}


class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48),
          const SizedBox(height: 12),
          const Text('No pudimos cargar tu espacio.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}
