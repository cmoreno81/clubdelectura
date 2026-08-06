import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_card.dart';
import '../widgets/error_view.dart';

class ClubChallengePage extends StatefulWidget {
  const ClubChallengePage({super.key});

  @override
  State<ClubChallengePage> createState() => _ClubChallengePageState();
}

class _ClubChallengePageState extends State<ClubChallengePage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService().getClubChallenges();
  }

  Future<void> _reload() async {
    setState(() => _future = ApiService().getClubChallenges());
    await _future;
  }

  Future<void> _setChallenge(int? current) async {
    final controller = TextEditingController(
      text: current != null ? '$current' : '',
    );
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Mi reto lector ${DateTime.now().year}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Cuántos libros quieres leer este año?',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número de libros',
                hintText: 'Ej. 24',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v > 0) Navigator.pop(context, v);
            },
            child: const Text('Guardar reto'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    try {
      await ApiService().setReadingChallenge(target: result);
      if (mounted) await _reload();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reto lector ${DateTime.now().year}')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return ErrorView(onRetry: _reload);
          }

          final data = snap.data!;
          final year = data['year'] as int;
          final clubTotal = (data['clubTotal'] as num? ?? 0).toInt();
          final clubTarget = (data['clubTarget'] as num? ?? 0).toInt();
          final challenges = (data['challenges'] as List<dynamic>)
              .cast<Map<String, dynamic>>();

          // Mi challenge
          final myChallenge = challenges
              .cast<Map<String, dynamic>>()
              .firstWhere(
                (c) => c['isMe'] == true,
                orElse: () => <String, dynamic>{},
              );
          final myTarget =
              myChallenge.isNotEmpty && myChallenge['target'] != null
              ? (myChallenge['target'] as num).toInt()
              : null;
          final myRead = (myChallenge['read'] as num? ?? 0).toInt();

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                100,
              ),
              children: [
                // ── Reto colectivo del club ──
                if (clubTarget > 0) ...[
                  _ClubCollectiveCard(
                    year: year,
                    clubTotal: clubTotal,
                    clubTarget: clubTarget,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Mi reto ──
                ClubCard(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: .08),
                      AppColors.primary.withValues(alpha: .03),
                    ],
                  ),
                  borderColor: AppColors.primary.withValues(alpha: .2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('📖', style: TextStyle(fontSize: 22)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Mi reto $year',
                              style: AppTextStyles.subtitle.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _setChallenge(myTarget),
                            icon: Icon(
                              myTarget == null
                                  ? Icons.add_rounded
                                  : Icons.edit_rounded,
                              size: 16,
                            ),
                            label: Text(
                              myTarget == null ? 'Crear reto' : 'Cambiar',
                            ),
                          ),
                        ],
                      ),
                      if (myTarget != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$myRead',
                              style: AppTextStyles.title.copyWith(
                                fontSize: 36,
                                color: AppColors.primary,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'de $myTarget libros',
                                style: AppTextStyles.bodySecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${((myRead / myTarget) * 100).clamp(0, 100).round()}%',
                              style: AppTextStyles.section.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: (myRead / myTarget).clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: AppColors.primaryLight,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _progressMessage(myRead, myTarget, year),
                      ] else ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Aún no tienes un reto para $year. '
                          'Márcate un objetivo y sigue tu progreso.',
                          style: AppTextStyles.bodySecondary,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Ranking del club ──
                Text(
                  'El club lee',
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Progreso de cada lectora en su reto $year',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.md),

                for (var i = 0; i < challenges.length; i++)
                  _ChallengeRow(
                    position: i + 1,
                    challenge: challenges[i],
                    isFirst: i == 0,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _progressMessage(int read, int target, int year) {
    final daysInYear = DateTime(
      year + 1,
      1,
      1,
    ).difference(DateTime(year, 1, 1)).inDays;
    final daysPassed = DateTime.now()
        .difference(DateTime(year, 1, 1))
        .inDays
        .clamp(1, daysInYear);
    final expectedByNow = (target * daysPassed / daysInYear).ceil();
    final diff = read - expectedByNow;

    if (read >= target) {
      return Text(
        '🎉 ¡Reto conseguido!',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    if (diff >= 0) {
      return Text(
        '✅ Vas por delante del ritmo',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return Text(
      'Lee ${(-diff)} más para estar al ritmo',
      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
    );
  }
}

// ─── Logro colectivo del club ─────────────────────────────────

class _ClubCollectiveCard extends StatelessWidget {
  const _ClubCollectiveCard({
    required this.year,
    required this.clubTotal,
    required this.clubTarget,
  });

  final int year;
  final int clubTotal;
  final int clubTarget;

  @override
  Widget build(BuildContext context) {
    final pct = (clubTotal / clubTarget).clamp(0.0, 1.0);
    final achieved = clubTotal >= clubTarget;

    return ClubCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: achieved
            ? [
                const Color(0xFFD97706).withValues(alpha: .12),
                const Color(0xFFD97706).withValues(alpha: .04),
              ]
            : [
                AppColors.primaryDark.withValues(alpha: .08),
                AppColors.primary.withValues(alpha: .03),
              ],
      ),
      borderColor: achieved
          ? const Color(0xFFD97706).withValues(alpha: .3)
          : AppColors.primaryDark.withValues(alpha: .15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                achieved ? '🏆' : '🎯',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reto colectivo del club',
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'La suma de todos los retos de $year',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$clubTotal',
                style: AppTextStyles.title.copyWith(
                  fontSize: 40,
                  color: achieved
                      ? const Color(0xFFD97706)
                      : AppColors.primaryDark,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'de $clubTarget libros',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(pct * 100).round()}%',
                style: AppTextStyles.section.copyWith(
                  color: achieved
                      ? const Color(0xFFD97706)
                      : AppColors.primaryDark,
                  fontSize: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 12,
              backgroundColor: achieved
                  ? const Color(0xFFD97706).withValues(alpha: .15)
                  : AppColors.primaryLight,
              color: achieved ? const Color(0xFFD97706) : AppColors.primary,
            ),
          ),
          if (achieved) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '🎉 ¡El club ha conseguido su reto colectivo!',
              style: AppTextStyles.caption.copyWith(
                color: const Color(0xFFD97706),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Fila de challenge por lectora ──────────────────────────────

class _ChallengeRow extends StatelessWidget {
  const _ChallengeRow({
    required this.position,
    required this.challenge,
    required this.isFirst,
  });

  final int position;
  final Map<String, dynamic> challenge;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final userName = challenge['userName'] as String;
    final avatarUrl = challenge['avatarUrl'] as String? ?? '';
    final target = challenge['target'] as int?;
    final read = (challenge['read'] as num? ?? 0).toInt();
    final pct = (challenge['pct'] as num? ?? 0).toDouble();
    final hasChallenge = challenge['hasChallenge'] as bool? ?? false;

    final posColors = [
      const Color(0xFFD97706), // oro
      const Color(0xFF9AA3AD), // plata
      const Color(0xFFB77A4A), // bronce
    ];
    final posColor = position <= 3
        ? posColors[position - 1]
        : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isFirst
              ? AppColors.primary.withValues(alpha: .04)
              : AppColors.surfaceSoft.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isFirst
                ? AppColors.primary.withValues(alpha: .15)
                : AppColors.border.withValues(alpha: .5),
          ),
        ),
        child: Row(
          children: [
            // Posición
            SizedBox(
              width: 28,
              child: Text(
                '$position',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: posColor,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Avatar
            ClubAvatar(nombre: userName, imageUrl: avatarUrl, size: 40),
            const SizedBox(width: AppSpacing.sm),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasChallenge && target != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: AppColors.primaryLight,
                        color: pct >= 1.0
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$read de $target libros · '
                      '${(pct * 100).clamp(0, 100).round()}%',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ] else
                    Text(
                      'Sin reto este año · $read leídos',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            // Badge si completó
            if (hasChallenge && pct >= 1.0)
              const Padding(
                padding: EdgeInsets.only(left: AppSpacing.xs),
                child: Text('🏆', style: TextStyle(fontSize: 20)),
              ),
          ],
        ),
      ),
    );
  }
}
