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
import '../widgets/dashboard/monthly_reading_shelf.dart';
import 'book_of_year_page.dart';
import 'personalidad_lectora_page.dart';
import 'share_reader_card_page.dart';
import 'wrapped_page.dart';

/// Pantalla de logros y estadísticas personales para el modo lector solitario.
/// Diseñada para motivar al lector con datos propios y hitos alcanzados.
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
            onOpenBook: (book) => openBookDetail(
              context,
              title: book.title,
              bookId: book.bookId,
              coverUrl: book.coverUrl,
            ),
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
    required this.onOpenBook,
  });

  final _PageData data;
  final Animation<double> streakPulse;
  final VoidCallback onVerWrapped;
  final VoidCallback onVerLibroDelAno;
  final VoidCallback onOpenQuiz;
  final VoidCallback onShareCard;
  final ValueChanged<MonthlyFinishedBook> onOpenBook;

  @override
  Widget build(BuildContext context) {
    final summary = data.dashboard.summary;
    final achievements = data.achievements;
    final unlockedCount = achievements.where((a) => a.unlocked).length;
    final total = achievements.length;
    final calendar = data.dashboard.calendar;

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

          // ── Estadísticas ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(child: _StatsGrid(summary: summary)),
          ),

          // ── Quiz de personalidad ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _QuizCta(onTap: onOpenQuiz),
            ),
          ),

          // ── Meses lectores (mes actual) ───────────────────────────────────
          if (calendar.finishedBooks.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: MonthlyReadingShelf(
                  key: ValueKey('monthly-${calendar.year}-${calendar.month}'),
                  year: calendar.year,
                  month: calendar.month,
                  books: calendar.finishedBooks,
                  onBookTap: onOpenBook,
                ),
              ),
            ),
          ],

          // ── Wrapped anual ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
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
// _StatsGrid
// ────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.summary});
  final GeneralSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2,
      children: [
        _StatCard(
          value: '${summary.reading}',
          label: 'Leyendo ahora',
          icon: Icons.menu_book_rounded,
          color: AppColors.info,
        ),
        _StatCard(
          value: '${summary.finished}',
          label: 'Terminados',
          icon: Icons.check_circle_rounded,
          color: AppColors.success,
        ),
        _StatCard(
          value: '${summary.finishedThisMonth}',
          label: 'Este mes',
          icon: Icons.bolt_rounded,
          color: AppColors.warning,
        ),
        _StatCard(
          value: '${summary.pagesRead}',
          label: 'Páginas leídas',
          icon: Icons.bookmark_rounded,
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: .14),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
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
