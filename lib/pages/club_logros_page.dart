import 'package:flutter/material.dart';

import '../models/achievements/achievement.dart';
import '../navigation/app_page_route.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/error_view.dart';
import 'perfil_usuario_page.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';

// ─── Modelo de ranking por miembro ───────────────────────────────────────────

class _MemberRankingEntry {
  const _MemberRankingEntry({
    required this.userName,
    required this.avatarUrl,
    required this.total,
    required this.logros,
  });

  final String userName;
  final String avatarUrl;
  final int total;
  final List<ClubAchievementEvent> logros;

  factory _MemberRankingEntry.fromJson(Map<String, dynamic> json) {
    return _MemberRankingEntry(
      userName: json['userName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      total: (json['total'] as num?)?.toInt() ?? 0,
      logros: (json['logros'] as List? ?? [])
          .map(
            (e) => ClubAchievementEvent.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

// ─── Página principal ─────────────────────────────────────────────────────────

class ClubLogrosPage extends StatefulWidget {
  const ClubLogrosPage({super.key});

  @override
  State<ClubLogrosPage> createState() => _ClubLogrosPageState();
}

class _ClubLogrosPageState extends State<ClubLogrosPage> {
  late Future<Map<String, dynamic>> _future;
  String _tab = 'ranking';

  @override
  void initState() {
    super.initState();
    _future = ApiService().getRecentClubAchievements();
  }

  void _reload() =>
      setState(() => _future = ApiService().getRecentClubAchievements());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logros del club')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const CardListSkeleton();
          }
          if (snap.hasError || snap.data == null) {
            return ErrorView(onRetry: _reload);
          }

          final data = snap.data!;

          final recientes = (data['achievements'] as List? ?? [])
              .map(
                (e) => ClubAchievementEvent.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();

          final ranking = (data['ranking'] as List? ?? [])
              .map(
                (e) => _MemberRankingEntry.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    ClubChip(
                      label: '🏆 Ranking',
                      selected: _tab == 'ranking',
                      variant: ClubChipVariant.primary,
                      onTap: () => setState(() => _tab = 'ranking'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ClubChip(
                      label: '🕒 Recientes',
                      selected: _tab == 'recientes',
                      variant: ClubChipVariant.info,
                      onTap: () => setState(() => _tab = 'recientes'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _tab == 'ranking'
                    ? _RankingList(ranking: ranking)
                    : _RecentList(events: recientes),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Ranking por miembro ──────────────────────────────────────────────────────

class _RankingList extends StatelessWidget {
  const _RankingList({required this.ranking});
  final List<_MemberRankingEntry> ranking;

  @override
  Widget build(BuildContext context) {
    if (ranking.isEmpty) {
      return _empty('Aún no hay logros en el club', '¡Seguid leyendo!');
    }

    final medals = ['🥇', '🥈', '🥉'];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: ranking.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final entry = ranking[i];
        return ClubCard(
          elevated: i == 0,
          padding: const EdgeInsets.all(AppSpacing.md),
          onTap: () => Navigator.push<void>(
            context,
            AppPageRoute(
              builder: (_) => PerfilUsuarioPage(
                usuario: entry.userName,
                initialTab: 'LOGROS',
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Medalla o número
                  SizedBox(
                    width: 28,
                    child: Text(
                      i < 3 ? medals[i] : '${i + 1}',
                      style: TextStyle(
                        fontSize: i < 3 ? 20 : 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ClubAvatar(
                    nombre: entry.userName,
                    imageUrl: entry.avatarUrl,
                    size: 40,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.userName,
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${entry.total} ${entry.total == 1 ? 'logro' : 'logros'}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              if (entry.logros.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: entry.logros
                      .map(
                        (e) => Tooltip(
                          message: e.achievementTitle,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              e.achievementIcon,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Feed de logros recientes ─────────────────────────────────────────────────

class _RecentList extends StatelessWidget {
  const _RecentList({required this.events});
  final List<ClubAchievementEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _empty('Aún no hay logros desbloqueados', '¡Seguid leyendo!');
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final e = events[i];
        return ClubCard(
          elevated: false,
          padding: const EdgeInsets.all(AppSpacing.md),
          onTap: () => Navigator.push<void>(
            context,
            AppPageRoute(
              builder: (_) => PerfilUsuarioPage(usuario: e.userName),
            ),
          ),
          child: Row(
            children: [
              ClubAvatar(nombre: e.userName, imageUrl: e.avatarUrl, size: 44),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.userName,
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          e.achievementIcon,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            e.achievementTitle,
                            style: AppTextStyles.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(e.unlockedAt),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'hoy';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 30) return 'hace ${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

Widget _empty(String title, String subtitle) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.emoji_events_outlined,
          size: 64,
          color: AppColors.textMuted.withValues(alpha: .4),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: AppTextStyles.section),
        const SizedBox(height: AppSpacing.sm),
        Text(subtitle, style: AppTextStyles.bodySecondary),
      ],
    ),
  );
}
