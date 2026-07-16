import 'package:flutter/material.dart';

import '../models/mood_club.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/error_view.dart';

class MoodClubPage extends StatefulWidget {
  const MoodClubPage({super.key});

  @override
  State<MoodClubPage> createState() => _MoodClubPageState();
}

class _MoodClubPageState extends State<MoodClubPage> {
  late Future<MoodClub> future;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    future = ApiService().getMoodClub();
  }

  Future<void> _refrescar() async {
    setState(_recargar);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood del club')),
      body: FutureBuilder<MoodClub>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorView(
              onRetry: () {
                setState(_recargar);
              },
            );
          }

          final mood = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                110,
              ),
              children: [
                _MoodHeader(titular: mood.titular),

                const SizedBox(height: AppSpacing.xl),

                const _SectionHeader(
                  icon: Icons.record_voice_over_outlined,
                  color: AppColors.primary,
                  title: 'La voz del club',
                  subtitle: 'El narrador interpreta el momento lector',
                ),

                const SizedBox(height: AppSpacing.md),

                _NarradorCard(texto: mood.narrador),

                if (mood.estados.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),

                  const _SectionHeader(
                    icon: Icons.auto_awesome_outlined,
                    color: Color(0xFFD75784),
                    title: 'Así está el ambiente',
                    subtitle: 'Las sensaciones que recorren el club',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  ClubCard(
                    elevated: false,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    backgroundColor: const Color(0xFFFFF5F8),
                    borderColor: const Color(0xFFF4D2DF),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final estado in mood.estados)
                          ClubChip(
                            label: estado,
                            icon: _iconoEstado(estado),
                            variant: _varianteEstado(estado),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),

                const _SectionHeader(
                  icon: Icons.history_edu_outlined,
                  color: AppColors.info,
                  title: 'Crónicas del club',
                  subtitle:
                      'Los pequeños momentos que cuentan nuestra historia',
                ),

                const SizedBox(height: AppSpacing.md),

                if (mood.actividad.isEmpty)
                  const _ActividadVacia()
                else
                  ClubCard(
                    elevated: false,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      children: [
                        for (
                          var index = 0;
                          index < mood.actividad.length;
                          index++
                        ) ...[
                          _ActividadItem(
                            icono: mood.actividad[index].icono,
                            texto: mood.actividad[index].texto,
                            destacada: index == 0,
                          ),

                          if (index < mood.actividad.length - 1)
                            const Divider(
                              height: 1,
                              indent: AppSpacing.md,
                              endIndent: AppSpacing.md,
                            ),
                        ],
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

  static IconData _iconoEstado(String estado) {
    final valor = estado.toLowerCase();

    if (valor.contains('feliz') ||
        valor.contains('enamor') ||
        valor.contains('encant')) {
      return Icons.favorite_outline_rounded;
    }

    if (valor.contains('debate') ||
        valor.contains('opiniones') ||
        valor.contains('divid')) {
      return Icons.forum_outlined;
    }

    if (valor.contains('triste') ||
        valor.contains('abandono') ||
        valor.contains('decepcion')) {
      return Icons.sentiment_dissatisfied_outlined;
    }

    if (valor.contains('leyendo') ||
        valor.contains('lectura') ||
        valor.contains('libro')) {
      return Icons.auto_stories_outlined;
    }

    return Icons.auto_awesome_outlined;
  }

  static ClubChipVariant _varianteEstado(String estado) {
    final valor = estado.toLowerCase();

    if (valor.contains('feliz') ||
        valor.contains('enamor') ||
        valor.contains('encant')) {
      return ClubChipVariant.danger;
    }

    if (valor.contains('triste') ||
        valor.contains('abandono') ||
        valor.contains('decepcion')) {
      return ClubChipVariant.warning;
    }

    if (valor.contains('debate') ||
        valor.contains('opiniones') ||
        valor.contains('divid')) {
      return ClubChipVariant.primary;
    }

    return ClubChipVariant.info;
  }
}

class _MoodHeader extends StatelessWidget {
  final String titular;

  const _MoodHeader({required this.titular});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF3F7), Color(0xFFF5E9FF)],
      ),
      borderColor: const Color(0xFFF0D4E2),
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              color: Color(0xFFFFDDEA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_outlined,
              color: Color(0xFFD75784),
              size: 40,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'El club hoy',
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 29),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            titular.trim().isEmpty
                ? 'El club sigue escribiendo su propia historia.'
                : titular,
            textAlign: TextAlign.center,
            style: AppTextStyles.section.copyWith(
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          const ClubChip(
            label: 'Pulso lector',
            icon: Icons.monitor_heart_outlined,
            variant: ClubChipVariant.danger,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(icon, color: color, size: 27),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.section.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                subtitle,
                style: AppTextStyles.bodySecondary.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NarradorCard extends StatelessWidget {
  final String texto;

  const _NarradorCard({required this.texto});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF8F3FF), Color(0xFFF1E8FF)],
      ),
      borderColor: AppColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.format_quote_rounded,
                color: AppColors.primary,
                size: 34,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'El narrador cuenta...',
                  style: AppTextStyles.subtitle,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            texto.trim().isEmpty
                ? 'Hoy el club guarda silencio entre páginas.'
                : texto,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 17,
              height: 1.55,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActividadItem extends StatelessWidget {
  final String icono;
  final String texto;
  final bool destacada;

  const _ActividadItem({
    required this.icono,
    required this.texto,
    required this.destacada,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: destacada ? AppColors.primaryLight : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Text(
              icono.trim().isEmpty ? '📖' : icono,
              style: const TextStyle(fontSize: 23),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Text(
              texto,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
                fontWeight: destacada ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActividadVacia extends StatelessWidget {
  const _ActividadVacia();

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: AppColors.surfaceSoft,
      child: const Column(
        children: [
          Icon(
            Icons.nights_stay_outlined,
            color: AppColors.textMuted,
            size: 38,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Hoy el club está tranquilo',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Las próximas crónicas aparecerán cuando haya nueva actividad.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}
