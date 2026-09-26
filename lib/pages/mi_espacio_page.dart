import 'package:flutter/material.dart';

import '../models/achievements/achievement.dart';
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
import '../widgets/dashboard/bingo_lector_card.dart';
import 'book_of_year_page.dart';
import 'perfil_usuario_page.dart' show CheckinSection;
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
    final results = await Future.wait([
      GeneralDashboardService().load(),
      ApiService().getAchievements(),
    ]);
    return _PageData(
      dashboard: results[0] as GeneralDashboard,
      achievements: results[1] as List<UserAchievement>,
    );
  }

  @override
  void dispose() {
    _streakCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
            onVerWrapped: () => Navigator.push<void>(
              context,
              AppPageRoute(
                builder: (_) =>
                    WrappedPage(anio: WrappedAvailability().wrappedYear),
              ),
            ),
            onVerLibroDelAno: () => Navigator.push<void>(
              context,
              AppPageRoute(builder: (_) => const BookOfYearPage()),
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
  const _PageData({required this.dashboard, required this.achievements});
  final GeneralDashboard dashboard;
  final List<UserAchievement> achievements;
}

// ────────────────────────────────────────────────────────────────────────────
// _Content — toda la UI una vez cargado
// ────────────────────────────────────────────────────────────────────────────

class _Content extends StatelessWidget {
  const _Content({
    required this.data,
    required this.streakPulse,
    required this.onVerWrapped,
    required this.onVerLibroDelAno,
    required this.onOpenQuiz,
    required this.onShareCard,
  });

  final _PageData data;
  final Animation<double> streakPulse;
  final VoidCallback onVerWrapped;
  final VoidCallback onVerLibroDelAno;
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
    final proximaLectura = data.dashboard.personalLibrary.isNotEmpty
        ? data.dashboard.personalLibrary.first
        : null;

    return RefreshIndicator(
      onRefresh: () async {},
      child: CustomScrollView(
        slivers: [
          // ── AppBar con hero de racha ──────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: AppColors.primaryDark,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _HeroBanner(
                summary: summary,
                streakPulse: streakPulse,
                userName: data.dashboard.userName,
              ),
            ),
            title: Text(
              'Mi espacio lector',
              style: AppTextStyles.subtitle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
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

          // ── Sagas en curso / próxima lectura ────────────────────────────
          if (openSeries.isNotEmpty || proximaLectura != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (openSeries.isNotEmpty)
                      Expanded(
                        child: _MiniInfoCard(
                          eyebrow: 'Sagas en curso',
                          title: openSeries.first.name,
                          subtitle:
                              'Libro ${openSeries.first.read} de ${openSeries.first.total}',
                          coverUrl: openSeries.first.coverUrl,
                        ),
                      ),
                    if (openSeries.isNotEmpty && proximaLectura != null)
                      const SizedBox(width: AppSpacing.sm),
                    if (proximaLectura != null)
                      Expanded(
                        child: _MiniInfoCard(
                          eyebrow: 'Próxima lectura',
                          title: proximaLectura.title,
                          subtitle: proximaLectura.isHighPriority
                              ? 'Prioridad alta'
                              : proximaLectura.genre,
                          coverUrl: proximaLectura.coverUrl,
                          onTap: () => openBookDetail(
                            context,
                            title: proximaLectura.title,
                            bookId: proximaLectura.id,
                            coverUrl: proximaLectura.coverUrl,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

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

          // ── Quiz de personalidad ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _QuizCta(onTap: onOpenQuiz),
            ),
          ),

          // ── Wrapped anual ─────────────────────────────────────────────────
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

          // ── Libro del año (cuadro personal) ───────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _LibroDelAnoCta(onTap: onVerLibroDelAno),
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

          // ── Motivación ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xxxl,
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
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
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Disponible en $days ${days == 1 ? 'día' : 'días'} · llega en noviembre',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textMuted,
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
// _HeroBanner
// ────────────────────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            Color(0xFF7B3F8F),
            AppColors.inkCoral,
          ],
          stops: [0, .55, 1],
        ),
      ),
      child: Stack(
        children: [
          // Fondo decorativo
          Positioned(
            right: -30,
            top: -30,
            child: Opacity(
              opacity: .07,
              child: Icon(
                Icons.auto_stories_rounded,
                size: 200,
                color: Colors.white,
              ),
            ),
          ),
          // Contenido
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xxxl,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                        fontSize: 26,
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
              ),
            ),
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

// ────────────────────────────────────────────────────────────────────────────
// _ShareCardCta
// ────────────────────────────────────────────────────────────────────────────

class _LibroDelAnoCta extends StatelessWidget {
  const _LibroDelAnoCta({required this.onTap});
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
            colors: [Color(0xFF7A4B12), Color(0xFFB07B2A), Color(0xFFD9A441)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB07B2A).withValues(alpha: .35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 32)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mi libro del año',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Elige tu favorito de cada mes y descubre tu ganador en un cuadro eliminatorio',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .80),
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
  const _LeyendoAhoraCard({required this.book, required this.onTap});
  final GeneralBook book;
  final VoidCallback onTap;

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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _MiniInfoCard — usada para "Sagas en curso" / "Próxima lectura"
// ────────────────────────────────────────────────────────────────────────────

class _MiniInfoCard extends StatelessWidget {
  const _MiniInfoCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.coverUrl,
    this.onTap,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String? coverUrl;
  final VoidCallback? onTap;

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
            if (coverUrl != null && coverUrl!.trim().isNotEmpty) ...[
              ClubBookCover(title: title, imageUrl: coverUrl, width: 36, height: 52),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
