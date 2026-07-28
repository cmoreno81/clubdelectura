import 'package:flutter/material.dart';

import '../models/club_membership.dart';
import '../models/general_dashboard.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/club_service.dart';
import '../services/general_dashboard_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import 'clubs_page.dart';
import 'home_page.dart';

class GeneralDashboardPage extends StatefulWidget {
  const GeneralDashboardPage({super.key});

  @override
  State<GeneralDashboardPage> createState() => _GeneralDashboardPageState();
}

class _GeneralDashboardPageState extends State<GeneralDashboardPage> {
  late Future<GeneralDashboard> _future;
  String? _openingClubId;

  @override
  void initState() {
    super.initState();
    _future = GeneralDashboardService().load();
  }

  Future<void> _reload() async {
    setState(() => _future = GeneralDashboardService().load());
    await _future;
  }

  Future<void> _manageClubs() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const ClubsPage()),
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
        MaterialPageRoute(
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
      backgroundColor: AppColors.background,
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
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.background,
                  title: const Text('Mi universo lector'),
                  actions: [
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
                      _metrics(data.summary),
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
                      const SizedBox(height: AppSpacing.xl),
                      _sectionTitle(
                        'Tu mes lector',
                        'Inicios, avances y libros terminados',
                        Icons.calendar_month_outlined,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _calendar(data.calendar),
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
    return ClubCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF5D3AA5), Color(0xFF9574D4)],
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metrics(GeneralSummary summary) {
    final metrics = [
      ('Leyendo', summary.reading, Icons.menu_book_rounded, AppColors.info),
      ('Terminados', summary.finished, Icons.check_rounded, AppColors.success),
      (
        'Este mes',
        summary.finishedThisMonth,
        Icons.bolt_rounded,
        AppColors.warning,
      ),
      ('Páginas', summary.pagesRead, Icons.bookmark_rounded, AppColors.primary),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.65,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      children: metrics
          .map(
            (metric) => ClubCard(
              elevated: false,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: metric.$4.withValues(alpha: .14),
                    child: Icon(metric.$3, color: metric.$4),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${metric.$2}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(metric.$1, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          )
          .toList(),
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
          );
        },
      ),
    );
  }

  Widget _calendar(ReadingCalendar calendar) {
    final first = DateTime(calendar.year, calendar.month);
    final days = DateTime(calendar.year, calendar.month + 1, 0).day;
    final offset = first.weekday - 1;
    final events = {for (final event in calendar.events) event.day: event};
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return ClubCard(
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${months[calendar.month - 1]} ${calendar.year}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: labels
                .map(
                  (label) => Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: offset + days,
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox.shrink();
              final day = index - offset + 1;
              final event = events[day];
              final starts = event?.types.contains('INICIO') ?? false;
              final finishes = event?.types.contains('FIN') ?? false;
              final progresses = event?.types.contains('PROGRESO') ?? false;
              return Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: event == null
                      ? Colors.transparent
                      : AppColors.primaryLight.withValues(alpha: .55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontWeight: event == null
                            ? FontWeight.w400
                            : FontWeight.w800,
                        color: event == null
                            ? AppColors.textPrimary
                            : AppColors.primaryDark,
                      ),
                    ),
                    if (event != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (starts)
                            const Icon(
                              Icons.play_arrow_rounded,
                              size: 13,
                              color: AppColors.success,
                            ),
                          if (progresses)
                            Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (finishes)
                            const Icon(
                              Icons.flag_rounded,
                              size: 11,
                              color: Color(0xFFE36A8D),
                            ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'Aún no hay actividad registrada este mes.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else ...[
            const SizedBox(height: AppSpacing.md),
            const Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                _CalendarKey(
                  icon: Icons.play_arrow_rounded,
                  color: AppColors.success,
                  label: 'Inicio de libro',
                ),
                _CalendarKey(
                  icon: Icons.circle,
                  color: AppColors.primary,
                  label: 'Avance',
                ),
                _CalendarKey(
                  icon: Icons.flag_rounded,
                  color: Color(0xFFE36A8D),
                  label: 'Fin de libro',
                ),
              ],
            ),
          ],
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
          );
        },
      ),
    );
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
              _communityMetric('${community.readers}', 'lectoras'),
              _communityMetric('${community.activeReadings}', 'leyendo'),
            ],
          ),
        ],
      ),
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

class _CalendarKey extends StatelessWidget {
  const _CalendarKey({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
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
