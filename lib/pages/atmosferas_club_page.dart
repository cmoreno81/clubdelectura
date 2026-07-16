import 'package:flutter/material.dart';

import '../models/atmosfera_club.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/error_view.dart';

class AtmosferasClubPage extends StatefulWidget {
  const AtmosferasClubPage({super.key});

  @override
  State<AtmosferasClubPage> createState() => _AtmosferasClubPageState();
}

class _AtmosferasClubPageState extends State<AtmosferasClubPage> {
  late Future<AtmosferaClub> future;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    future = ApiService().getAtmosferaClub();
  }

  Future<void> _refrescar() async {
    setState(_recargar);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atmósferas')),
      body: FutureBuilder<AtmosferaClub>(
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

          final atmosfera = snapshot.data!;
          final principal = atmosfera.principal;

          final principalVacia =
              principal.nombre.trim().isEmpty &&
              principal.titulo.trim().isEmpty;

          if (principalVacia && atmosfera.secundarias.isEmpty) {
            return const _AtmosferaVacia();
          }

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
                _AtmosferaHero(atmosfera: principal),

                if (atmosfera.secundarias.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),

                  const _SectionHeader(
                    icon: Icons.blur_on_rounded,
                    color: AppColors.primary,
                    title: 'La mezcla del club',
                    subtitle:
                        'Las sensaciones que acompañan a las lecturas actuales',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  for (
                    var index = 0;
                    index < atmosfera.secundarias.length;
                    index++
                  ) ...[
                    _AtmosferaCard(
                      atmosfera: atmosfera.secundarias[index],
                      posicion: index,
                    ),

                    const SizedBox(height: AppSpacing.md),
                  ],
                ],

                const SizedBox(height: AppSpacing.lg),

                _CierreAtmosferas(
                  principal: principal,
                  total: atmosfera.secundarias.length + 1,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AtmosferaHero extends StatelessWidget {
  final AtmosferaItem atmosfera;

  const _AtmosferaHero({required this.atmosfera});

  @override
  Widget build(BuildContext context) {
    final estilo = _AtmosferaEstilo.desde(atmosfera.nombre);
    final intensidad = _normalizarIntensidad(atmosfera.intensidad);

    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: estilo.gradient,
      ),
      borderColor: estilo.color.withValues(alpha: 0.22),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.48),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              atmosfera.icono.trim().isEmpty ? '✨' : atmosfera.icono,
              style: const TextStyle(fontSize: 45),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'La atmósfera del club',
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 30),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            atmosfera.titulo.trim().isEmpty
                ? atmosfera.nombre
                : atmosfera.titulo,
            textAlign: TextAlign.center,
            style: AppTextStyles.section.copyWith(
              color: AppColors.textPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),

          if (atmosfera.descripcion.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),

            Text(
              atmosfera.descripcion,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(
                fontSize: 17,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ClubChip(
                label: atmosfera.nombre.trim().isEmpty
                    ? 'Atmósfera principal'
                    : atmosfera.nombre,
                icon: Icons.auto_awesome_rounded,
                variant: estilo.variant,
              ),

              ClubChip(
                label: _textoIntensidad(intensidad),
                icon: Icons.graphic_eq_rounded,
                variant: ClubChipVariant.primary,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          _BarraAtmosfera(intensidad: intensidad, color: estilo.color),
        ],
      ),
    );
  }
}

class _AtmosferaCard extends StatelessWidget {
  final AtmosferaItem atmosfera;
  final int posicion;

  const _AtmosferaCard({required this.atmosfera, required this.posicion});

  @override
  Widget build(BuildContext context) {
    final estilo = _AtmosferaEstilo.desde(atmosfera.nombre);
    final intensidad = _normalizarIntensidad(atmosfera.intensidad);

    return ClubCard(
      elevated: posicion == 0,
      padding: const EdgeInsets.all(AppSpacing.lg),
      gradient: posicion == 0
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: estilo.gradient,
            )
          : null,
      backgroundColor: posicion == 0 ? null : AppColors.surface,
      borderColor: estilo.color.withValues(alpha: 0.20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: estilo.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                alignment: Alignment.center,
                child: Text(
                  atmosfera.icono.trim().isEmpty
                      ? estilo.emoji
                      : atmosfera.icono,
                  style: const TextStyle(fontSize: 31),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      atmosfera.nombre.trim().isEmpty
                          ? 'Atmósfera'
                          : atmosfera.nombre,
                      style: AppTextStyles.section.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    if (atmosfera.titulo.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),

                      Text(
                        atmosfera.titulo,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              ClubChip(
                label: '${(intensidad * 100).round()}%',
                icon: Icons.bolt_rounded,
                variant: estilo.variant,
              ),
            ],
          ),

          if (atmosfera.descripcion.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),

            Text(
              atmosfera.descripcion,
              style: AppTextStyles.bodySecondary.copyWith(height: 1.5),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          _BarraAtmosfera(intensidad: intensidad, color: estilo.color),

          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Icon(Icons.graphic_eq_rounded, size: 17, color: estilo.color),

              const SizedBox(width: AppSpacing.xs),

              Text(
                _textoIntensidad(intensidad),
                style: AppTextStyles.caption.copyWith(
                  color: estilo.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarraAtmosfera extends StatelessWidget {
  final double intensidad;
  final Color color;

  const _BarraAtmosfera({required this.intensidad, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: LinearProgressIndicator(
        value: intensidad,
        minHeight: 10,
        backgroundColor: color.withValues(alpha: 0.10),
        valueColor: AlwaysStoppedAnimation<Color>(color),
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

class _CierreAtmosferas extends StatelessWidget {
  final AtmosferaItem principal;
  final int total;

  const _CierreAtmosferas({required this.principal, required this.total});

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
        children: [
          const Icon(
            Icons.nights_stay_outlined,
            color: AppColors.primary,
            size: 38,
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'Cada lectura deja una sensación',
            textAlign: TextAlign.center,
            style: AppTextStyles.section.copyWith(color: AppColors.textPrimary),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            principal.nombre.trim().isEmpty
                ? 'El club está construyendo una mezcla propia entre todas sus historias.'
                : 'Ahora mismo predomina ${principal.nombre.toLowerCase()}, acompañada por ${total - 1} ${total == 2 ? 'atmósfera secundaria' : 'atmósferas secundarias'}.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _AtmosferaVacia extends StatelessWidget {
  const _AtmosferaVacia();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ClubCard(
          elevated: false,
          padding: const EdgeInsets.all(AppSpacing.xl),
          backgroundColor: AppColors.surfaceSoft,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.blur_on_rounded, color: AppColors.textMuted, size: 44),

              SizedBox(height: AppSpacing.md),

              Text(
                'La atmósfera todavía se está formando',
                textAlign: TextAlign.center,
                style: AppTextStyles.section,
              ),

              SizedBox(height: AppSpacing.sm),

              Text(
                'Cuando haya suficientes lecturas activas, aparecerán aquí las sensaciones que dominan el club.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AtmosferaEstilo {
  final Color color;
  final List<Color> gradient;
  final String emoji;
  final ClubChipVariant variant;

  const _AtmosferaEstilo({
    required this.color,
    required this.gradient,
    required this.emoji,
    required this.variant,
  });

  factory _AtmosferaEstilo.desde(String nombre) {
    final valor = nombre.toLowerCase();

    if (valor.contains('oscur') ||
        valor.contains('sombr') ||
        valor.contains('gótic')) {
      return const _AtmosferaEstilo(
        color: Color(0xFF68538A),
        gradient: [Color(0xFFF3EEFA), Color(0xFFEAE1F5)],
        emoji: '🌑',
        variant: ClubChipVariant.primary,
      );
    }

    if (valor.contains('románt') ||
        valor.contains('romance') ||
        valor.contains('amor')) {
      return const _AtmosferaEstilo(
        color: Color(0xFFD75784),
        gradient: [Color(0xFFFFF3F7), Color(0xFFFFE8F0)],
        emoji: '💜',
        variant: ClubChipVariant.danger,
      );
    }

    if (valor.contains('magi') ||
        valor.contains('fantas') ||
        valor.contains('encant')) {
      return const _AtmosferaEstilo(
        color: AppColors.primary,
        gradient: [Color(0xFFF8F3FF), Color(0xFFF0E5FF)],
        emoji: '✨',
        variant: ClubChipVariant.primary,
      );
    }

    if (valor.contains('intens') ||
        valor.contains('fuego') ||
        valor.contains('eléctric')) {
      return const _AtmosferaEstilo(
        color: Color(0xFFE98325),
        gradient: [Color(0xFFFFF8EC), Color(0xFFFFEFD7)],
        emoji: '🔥',
        variant: ClubChipVariant.warning,
      );
    }

    if (valor.contains('mister') ||
        valor.contains('intriga') ||
        valor.contains('secreto')) {
      return const _AtmosferaEstilo(
        color: Color(0xFF5C79A8),
        gradient: [Color(0xFFF1F6FD), Color(0xFFE5EEF9)],
        emoji: '🌫️',
        variant: ClubChipVariant.info,
      );
    }

    if (valor.contains('seren') ||
        valor.contains('calma') ||
        valor.contains('lumin')) {
      return const _AtmosferaEstilo(
        color: AppColors.success,
        gradient: [Color(0xFFF0FFF4), Color(0xFFE5F6EA)],
        emoji: '🌿',
        variant: ClubChipVariant.success,
      );
    }

    return const _AtmosferaEstilo(
      color: AppColors.primary,
      gradient: [Color(0xFFF8F3FF), Color(0xFFF1E8FF)],
      emoji: '✨',
      variant: ClubChipVariant.primary,
    );
  }
}

double _normalizarIntensidad(double valor) {
  if (valor.isNaN || valor.isInfinite || valor <= 0) {
    return 0;
  }

  if (valor > 1) {
    return (valor / 100).clamp(0.0, 1.0);
  }

  return valor.clamp(0.0, 1.0);
}

String _textoIntensidad(double intensidad) {
  if (intensidad >= 0.85) return 'Atmósfera arrolladora';
  if (intensidad >= 0.70) return 'Muy presente';
  if (intensidad >= 0.50) return 'Presencia notable';
  if (intensidad >= 0.30) return 'Toque perceptible';
  if (intensidad > 0) return 'Ligera presencia';

  return 'Empezando a aparecer';
}
