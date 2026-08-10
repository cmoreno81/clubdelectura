import 'package:flutter/material.dart';

import '../models/achievements/achievement.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/error_view.dart';

class ClubLogrosPage extends StatefulWidget {
  const ClubLogrosPage({super.key});

  @override
  State<ClubLogrosPage> createState() => _ClubLogrosPageState();
}

class _ClubLogrosPageState extends State<ClubLogrosPage> {
  late Future<Map<String, dynamic>> _future;
  String _tab = 'miembros'; // 'recientes' | 'miembros'

  @override
  void initState() {
    super.initState();
    _future = ApiService().getRecentClubAchievements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logros del club')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return ErrorView(
              onRetry: () => setState(
                () => _future = ApiService().getRecentClubAchievements(),
              ),
            );
          }

          final data = snap.data!;
          final events = (data['achievements'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>()
              .map(ClubAchievementEvent.fromJson)
              .toList();

          return Column(
            children: [
              // ── Tabs ──
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
                      label: '🕒 Recientes',
                      selected: _tab == 'recientes',
                      variant: ClubChipVariant.primary,
                      onTap: () => setState(() => _tab = 'recientes'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ClubChip(
                      label: '👥 Por miembro',
                      selected: _tab == 'miembros',
                      variant: ClubChipVariant.info,
                      onTap: () => setState(() => _tab = 'miembros'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Expanded(
                child: _tab == 'recientes'
                    ? _RecentList(events: events)
                    : _MemberGrid(events: events),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Lista de logros recientes ───────────────────────────────────

class _RecentList extends StatelessWidget {
  const _RecentList({required this.events});
  final List<ClubAchievementEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
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
            const Text(
              'Aún no hay logros desbloqueados',
              style: AppTextStyles.section,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('¡Seguid leyendo!', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 0,
      ),
      itemCount: events.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final e = events[i];
        return ClubCard(
          elevated: false,
          padding: const EdgeInsets.all(AppSpacing.md),
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

// ─── Grid por miembro ────────────────────────────────────────────

class _MemberGrid extends StatelessWidget {
  const _MemberGrid({required this.events});
  final List<ClubAchievementEvent> events;

  @override
  Widget build(BuildContext context) {
    // Agrupar por miembro
    final byMember = <String, List<ClubAchievementEvent>>{};
    for (final e in events) {
      byMember.putIfAbsent(e.userName, () => []).add(e);
    }

    // Ordenar por número de logros
    final members = byMember.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    if (members.isEmpty) {
      return const Center(child: Text('Sin logros aún'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 0,
      ),
      itemCount: members.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final entry = members[i];
        final nombre = entry.key;
        final logros = entry.value;
        final avatarUrl = logros.first.avatarUrl;

        return ClubCard(
          elevated: false,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClubAvatar(nombre: nombre, imageUrl: avatarUrl, size: 40),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${logros.length} ${logros.length == 1 ? 'logro' : 'logros'}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Emojis de los logros
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: logros
                    .map(
                      (e) => Tooltip(
                        message: e.achievementTitle,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            e.achievementIcon,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
