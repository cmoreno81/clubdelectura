import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../navigation/book_detail_navigation.dart';

import '../models/mood_club.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/error_view.dart';
import 'capitulo_page.dart';

class MoodClubPage extends StatefulWidget {
  const MoodClubPage({super.key});

  @override
  State<MoodClubPage> createState() => _MoodClubPageState();
}

class _MoodClubPageState extends State<MoodClubPage> {
  late Future<MoodClub> future;
  bool votando = false;

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

  Future<void> _votar(String mood) async {
    if (votando) return;
    setState(() => votando = true);
    final ok = await ApiService().registrarMoodClub(mood);
    if (!mounted) return;
    if (ok) {
      setState(_recargar);
      await future;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido guardar tu mood.')),
      );
    }
    if (mounted) setState(() => votando = false);
  }

  void _abrirConversacion(String libro, String capitulo) {
    if (libro.isEmpty || capitulo.isEmpty) return;
    Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => CapituloPage(libro: libro, capitulo: capitulo),
      ),
    );
  }

  Future<void> _abrirLibro(ActividadClub actividad) async {
    if (actividad.libro.trim().isEmpty) return;
    await openBookDetail(
      context,
      title: actividad.libro,
      bookId: actividad.bookId,
      coverUrl: actividad.coverUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pulso del club')),
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

                _MoodVoteCard(
                  mood: mood.moodSemanal,
                  enabled: !votando,
                  onVote: _votar,
                ),

                const SizedBox(height: AppSpacing.xl),

                _MetricasMood(resumen: mood.resumen),

                if (mood.conversacionDestacada != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  _ConversacionDestacada(
                    conversacion: mood.conversacionDestacada!,
                    onTap: () => _abrirConversacion(
                      mood.conversacionDestacada!.libro,
                      mood.conversacionDestacada!.capitulo,
                    ),
                  ),
                ],

                if (mood.libroActivo != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _LibroActivo(libro: mood.libroActivo!),
                ],

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
                            onTap:
                                mood.actividad[index].tipo == 'COMENTARIO' &&
                                    mood.actividad[index].capitulo.isNotEmpty
                                ? () => _abrirConversacion(
                                    mood.actividad[index].libro,
                                    mood.actividad[index].capitulo,
                                  )
                                : mood.actividad[index].tipo == 'LIBRO' &&
                                      mood.actividad[index].libro.isNotEmpty
                                ? () => _abrirLibro(mood.actividad[index])
                                : null,
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

const _moodOpciones = [
  ('HOOKED', '😍', 'Enganchada'),
  ('SHOCKED', '🤯', 'En shock'),
  ('CRYING', '😭', 'Sufriendo'),
  ('ANGRY', '😡', 'Enfadada'),
  ('LAUGHING', '😂', 'Divertida'),
  ('BLOCKED', '😴', 'Bloqueada'),
];

class _MoodVoteCard extends StatelessWidget {
  final MoodSemanal mood;
  final bool enabled;
  final ValueChanged<String> onVote;

  const _MoodVoteCard({
    required this.mood,
    required this.enabled,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: AppColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Cómo estás viviendo tu lectura?',
            style: AppTextStyles.section,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            mood.total == 0
                ? 'Estrena el pulso de esta semana.'
                : '${mood.total} lectoras han compartido su mood esta semana.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _moodOpciones.map((opcion) {
              final seleccionada = mood.miMood == opcion.$1;
              final total = mood.distribucion[opcion.$1] ?? 0;
              return Tooltip(
                message: opcion.$3,
                child: InkWell(
                  onTap: enabled ? () => onVote(opcion.$1) : null,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: seleccionada
                          ? AppColors.primaryLight
                          : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: seleccionada
                            ? AppColors.primary
                            : AppColors.border,
                        width: seleccionada ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(opcion.$2, style: const TextStyle(fontSize: 23)),
                        if (total > 0) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '$total',
                            style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MetricasMood extends StatelessWidget {
  final ResumenMood resumen;

  const _MetricasMood({required this.resumen});

  @override
  Widget build(BuildContext context) {
    final metricas = [
      (Icons.people_outline_rounded, resumen.lectorasActivas, 'leyendo'),
      (Icons.chat_bubble_outline_rounded, resumen.comentarios, 'comentarios'),
      (Icons.add_reaction_outlined, resumen.reacciones, 'reacciones'),
      (Icons.task_alt_rounded, resumen.terminados, 'terminados'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.monitor_heart_outlined,
          color: AppColors.success,
          title: 'Esta semana',
          subtitle: 'El club en cuatro señales',
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.9,
          children: metricas
              .map(
                (metrica) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(metrica.$1, color: AppColors.primary, size: 22),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${metrica.$2}',
                                style: AppTextStyles.section,
                              ),
                              Text(
                                metrica.$3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _ConversacionDestacada extends StatefulWidget {
  final ConversacionMood conversacion;
  final VoidCallback onTap;

  const _ConversacionDestacada({
    required this.conversacion,
    required this.onTap,
  });

  @override
  State<_ConversacionDestacada> createState() => _ConversacionDestacadaState();
}

class _ConversacionDestacadaState extends State<_ConversacionDestacada> {
  bool spoilerVisible = false;

  @override
  Widget build(BuildContext context) {
    final conversacion = widget.conversacion;

    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: const Color(0xFFFFF5F8),
      borderColor: const Color(0xFFF4D2DF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                color: AppColors.danger,
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'La conversación del momento',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: spoilerVisible
                ? Container(
                    key: const ValueKey('spoiler-visible'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '“${conversacion.texto}”',
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(height: 1.45),
                    ),
                  )
                : InkWell(
                    key: const ValueKey('spoiler-oculto'),
                    onTap: () => setState(() => spoilerVisible = true),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.lg,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.midnight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.visibility_off_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Posible spoiler',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            'Toca para revelar el comentario',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFFD9D4E5)),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${conversacion.usuario} · ${conversacion.libro} · ${conversacion.capitulo}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '✨ ${conversacion.reacciones}   💬 ${conversacion.respuestas}',
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w800),
          ),
          if (spoilerVisible) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onTap,
                icon: const Icon(Icons.forum_outlined),
                label: const Text('Abrir conversación'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LibroActivo extends StatelessWidget {
  final LibroMood libro;

  const _LibroActivo({required this.libro});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          ClubBookCover(
            title: libro.libro,
            imageUrl: libro.coverUrl,
            width: 64,
            showShadow: false,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'El libro que mueve el club',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  libro.libro,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '💬 ${libro.comentarios}   ✨ ${libro.reacciones}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
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
  final VoidCallback? onTap;

  const _ActividadItem({
    required this.icono,
    required this.texto,
    required this.destacada,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: destacada
                    ? AppColors.primaryLight
                    : AppColors.surfaceSoft,
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
            if (onTap != null) ...[
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ],
        ),
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
