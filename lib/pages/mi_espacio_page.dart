import 'package:flutter/material.dart';

import '../models/achievements/achievement.dart';
import '../models/general_dashboard.dart';
import '../navigation/app_page_route.dart';
import '../services/achievement_service.dart';
import '../services/api_service.dart';
import '../services/general_dashboard_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/checkin_button.dart';
import '../widgets/common/mapa_calor_widget.dart';
import '../utils/wrapped_availability.dart';
import 'mis_logros_page.dart';
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
      ApiService().getHistorialCheckin(dias: 7),
    ]);
    final checkinData = results[2] as Map<String, dynamic>;
    return _PageData(
      dashboard: results[0] as GeneralDashboard,
      achievements: results[1] as List<UserAchievement>,
      checkedToday: checkinData['checkedToday'] as bool? ?? false,
      streak: (checkinData['streak'] as num?)?.toInt() ?? 0,
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
            onVerTodos: () => Navigator.push<void>(
              context,
              AppPageRoute(builder: (_) => const MisLogrosPage()),
            ),
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
    required this.checkedToday,
    required this.streak,
  });
  final GeneralDashboard dashboard;
  final List<UserAchievement> achievements;
  final bool checkedToday;
  final int streak;
}

// ────────────────────────────────────────────────────────────────────────────
// _Content — toda la UI una vez cargado
// ────────────────────────────────────────────────────────────────────────────

class _Content extends StatelessWidget {
  const _Content({
    required this.data,
    required this.streakPulse,
    required this.onVerTodos,
    required this.onVerWrapped,
    required this.onOpenQuiz,
    required this.onShareCard,
  });

  final _PageData data;
  final Animation<double> streakPulse;
  final VoidCallback onVerTodos;
  final VoidCallback onVerWrapped;
  final VoidCallback onOpenQuiz;
  final VoidCallback onShareCard;

  @override
  Widget build(BuildContext context) {
    final summary = data.dashboard.summary;
    final achievements = data.achievements;
    final unlocked = achievements.where((a) => a.unlocked).toList();
    final locked = achievements.where((a) => !a.unlocked).toList();
    final total = achievements.length;
    final pct = total > 0 ? unlocked.length / total : 0.0;

    // Ordenar desbloqueados por rareza
    const rarityOrder = {'legendary': 0, 'epic': 1, 'rare': 2, 'common': 3};
    unlocked.sort(
      (a, b) =>
          (rarityOrder[a.rarity] ?? 3).compareTo(rarityOrder[b.rarity] ?? 3),
    );

    // Próximos logros a desbloquear
    final proximos = [...locked]
      ..sort(
        (a, b) => ((a.target > 0 ? a.progress / a.target : 0) * -1).compareTo(
          (b.target > 0 ? b.progress / b.target : 0) * -1,
        ),
      );
    final proximosMostrados = proximos.take(3).toList();

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

          // ── Progreso logros ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _LogrosProgress(
                unlocked: unlocked.length,
                total: total,
                pct: pct,
                onVerTodos: onVerTodos,
              ),
            ),
          ),

          // ── Logros desbloqueados ─────────────────────────────────────────
          if (unlocked.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _SectionLabel(icon: '🏆', label: 'Logros conquistados'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: .78,
                ),
                itemCount: unlocked.length,
                itemBuilder: (context, i) =>
                    _AchievementTile(achievement: unlocked[i]),
              ),
            ),
          ],

          // ── Próximos logros ───────────────────────────────────────────────
          if (proximosMostrados.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _SectionLabel(icon: '🎯', label: 'Próximos retos'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              sliver: SliverList.separated(
                itemCount: proximosMostrados.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) =>
                    _ProximoLogroCard(achievement: proximosMostrados[i]),
              ),
            ),
          ],

          // ── CTA motivacional ──────────────────────────────────────────────
          // ── Check-in diario ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _SectionLabel(icon: '📖', label: 'Check-in diario'),
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
              child: CheckinButton(
                checkedToday: data.checkedToday,
                streak: data.streak,
              ),
            ),
          ),

          // ── Mapa de calor ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.md,
              0,
            ),
            sliver: const SliverToBoxAdapter(child: MapaCalorWidget()),
          ),

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
                unlocked: unlocked.length,
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
// _LogrosProgress
// ────────────────────────────────────────────────────────────────────────────

class _LogrosProgress extends StatelessWidget {
  const _LogrosProgress({
    required this.unlocked,
    required this.total,
    required this.pct,
    required this.onVerTodos,
  });

  final int unlocked;
  final int total;
  final double pct;
  final VoidCallback onVerTodos;

  String get _motivationalText {
    if (pct >= 1.0) {
      return '¡Has alcanzado un nivel legendario! Todos los logros conseguidos 🎉';
    }
    if (pct >= .75) return 'Casi lo tienes todo. ¡Sigue así!';
    if (pct >= .5) return 'Ya has superado la mitad. ¡Buen camino!';
    if (pct >= .25) return 'Cada libro te acerca a nuevos logros.';
    if (unlocked > 0) return 'Tus primeros logros están esperando.';
    return 'Empieza a leer y descubre tus primeros logros.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark.withValues(alpha: .06),
            AppColors.primary.withValues(alpha: .03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.primary.withValues(alpha: .15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progreso de logros',
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
              TextButton(onPressed: onVerTodos, child: const Text('Ver todos')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _AnimatedProgressBar(value: pct),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _motivationalText,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedProgressBar extends StatefulWidget {
  const _AnimatedProgressBar({required this.value});
  final double value;

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: _anim.value * widget.value,
          minHeight: 10,
          backgroundColor: AppColors.primaryLight,
          valueColor: AlwaysStoppedAnimation<Color>(
            Color.lerp(AppColors.primary, AppColors.inkCoral, widget.value) ??
                AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _AchievementTile
// ────────────────────────────────────────────────────────────────────────────

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});
  final UserAchievement achievement;

  Color get _color => switch (achievement.rarity) {
    'legendary' => const Color(0xFFD97706),
    'epic' => const Color(0xFF7C3AED),
    'rare' => const Color(0xFF2563EB),
    _ => AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Tooltip(
      message: '${achievement.title}\n${achievement.description}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withValues(alpha: .2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(achievement.icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 5),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color.withValues(alpha: .85),
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
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _ProximoLogroCard
// ────────────────────────────────────────────────────────────────────────────

class _ProximoLogroCard extends StatelessWidget {
  const _ProximoLogroCard({required this.achievement});
  final UserAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final pct = achievement.target > 0
        ? (achievement.progress / achievement.target).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(achievement.icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  achievement.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: AppColors.primaryLight,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${achievement.progress} / ${achievement.target}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 10,
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
// _SectionLabel
// ────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// _ShareCardCta
// ────────────────────────────────────────────────────────────────────────────

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
