import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/atmosferas/atmosfera_experiencia.dart';
import '../theme/atmosferas/atmosfera_tipo.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import '../widgets/atmosferas/atmosfera_ambient_layer.dart';

class AtmosferaLecturaPage extends StatefulWidget {
  final String libro;
  final String coverUrl;
  final List<Color> coloresPaleta;
  final String atmosferaActualId;

  const AtmosferaLecturaPage({
    super.key,
    required this.libro,
    this.coverUrl = '',
    this.coloresPaleta = const [],
    this.atmosferaActualId = '',
  });

  @override
  State<AtmosferaLecturaPage> createState() => _AtmosferaLecturaPageState();
}

class _AtmosferaLecturaPageState extends State<AtmosferaLecturaPage> {
  late final List<AtmosferaExperiencia> _propuestas;
  late int _indiceSeleccionado;

  AtmosferaExperiencia get _seleccionada {
    return _propuestas[_indiceSeleccionado];
  }

  @override
  void initState() {
    super.initState();

    _propuestas = _crearPropuestas();

    final indiceActual = _propuestas.indexWhere(
      (atmosfera) =>
          atmosfera.tipo.apiValue ==
          widget.atmosferaActualId.trim().toUpperCase(),
    );

    _indiceSeleccionado = indiceActual >= 0 ? indiceActual : 0;
  }

  List<AtmosferaExperiencia> _crearPropuestas() {
    final recomendada = _resolverRecomendada(widget.coloresPaleta);

    final orden = <AtmosferaLectura>[
      recomendada,
      ..._alternativasPara(recomendada),
      ...AtmosferaLectura.values,
    ];

    final tiposUnicos = <AtmosferaLectura>[];

    for (final tipo in orden) {
      if (tipo == AtmosferaLectura.neutra) continue;
      if (tiposUnicos.contains(tipo)) continue;

      tiposUnicos.add(tipo);
    }

    return tiposUnicos
        .map(AtmosferaExperiencias.desdeTipo)
        .toList(growable: false);
  }

  AtmosferaLectura _resolverRecomendada(List<Color> colores) {
    if (colores.isEmpty) {
      return AtmosferaLectura.magica;
    }

    var saturacionMedia = 0.0;
    var luminosidadMedia = 0.0;

    var rosas = 0;
    var azules = 0;
    var verdes = 0;
    var marrones = 0;
    var morados = 0;
    var oscuros = 0;

    for (final color in colores) {
      final hsl = HSLColor.fromColor(color);
      final hue = hsl.hue;

      saturacionMedia += hsl.saturation;
      luminosidadMedia += hsl.lightness;

      if (hsl.lightness < 0.30) {
        oscuros++;
      }

      if (hue >= 325 || hue < 15) {
        rosas++;
      } else if (hue >= 15 && hue < 55) {
        marrones++;
      } else if (hue >= 70 && hue < 165) {
        verdes++;
      } else if (hue >= 165 && hue < 255) {
        azules++;
      } else if (hue >= 255 && hue < 325) {
        morados++;
      }
    }

    saturacionMedia /= colores.length;
    luminosidadMedia /= colores.length;

    if (oscuros >= 3 || luminosidadMedia < 0.34) {
      if (morados >= 2) {
        return AtmosferaLectura.gotica;
      }

      return AtmosferaLectura.oscura;
    }

    if (rosas >= 2) {
      return AtmosferaLectura.romantica;
    }

    if (azules >= 3) {
      return AtmosferaLectura.marina;
    }

    if (verdes >= 3) {
      return AtmosferaLectura.bosque;
    }

    if (morados >= 2) {
      return AtmosferaLectura.magica;
    }

    if (marrones >= 3) {
      return AtmosferaLectura.acogedora;
    }

    if (saturacionMedia > 0.72) {
      return AtmosferaLectura.epica;
    }

    if (azules >= 2 && morados >= 1) {
      return AtmosferaLectura.futurista;
    }

    return AtmosferaLectura.magica;
  }

  List<AtmosferaLectura> _alternativasPara(AtmosferaLectura recomendada) {
    return switch (recomendada) {
      AtmosferaLectura.romantica => const [
        AtmosferaLectura.acogedora,
        AtmosferaLectura.marina,
        AtmosferaLectura.magica,
      ],

      AtmosferaLectura.oscura => const [
        AtmosferaLectura.gotica,
        AtmosferaLectura.misteriosa,
        AtmosferaLectura.epica,
      ],

      AtmosferaLectura.gotica => const [
        AtmosferaLectura.oscura,
        AtmosferaLectura.misteriosa,
        AtmosferaLectura.historica,
      ],

      AtmosferaLectura.marina => const [
        AtmosferaLectura.romantica,
        AtmosferaLectura.acogedora,
        AtmosferaLectura.misteriosa,
      ],

      AtmosferaLectura.bosque => const [
        AtmosferaLectura.magica,
        AtmosferaLectura.acogedora,
        AtmosferaLectura.misteriosa,
      ],

      AtmosferaLectura.epica => const [
        AtmosferaLectura.magica,
        AtmosferaLectura.oscura,
        AtmosferaLectura.historica,
      ],

      AtmosferaLectura.futurista => const [
        AtmosferaLectura.misteriosa,
        AtmosferaLectura.epica,
        AtmosferaLectura.oscura,
      ],

      AtmosferaLectura.historica => const [
        AtmosferaLectura.acogedora,
        AtmosferaLectura.gotica,
        AtmosferaLectura.misteriosa,
      ],

      AtmosferaLectura.acogedora => const [
        AtmosferaLectura.romantica,
        AtmosferaLectura.bosque,
        AtmosferaLectura.historica,
      ],

      AtmosferaLectura.misteriosa => const [
        AtmosferaLectura.oscura,
        AtmosferaLectura.gotica,
        AtmosferaLectura.futurista,
      ],

      AtmosferaLectura.magica => const [
        AtmosferaLectura.bosque,
        AtmosferaLectura.epica,
        AtmosferaLectura.misteriosa,
      ],

      AtmosferaLectura.neutra => const [
        AtmosferaLectura.acogedora,
        AtmosferaLectura.magica,
        AtmosferaLectura.misteriosa,
      ],
    };
  }

  void _seleccionar(int indice) {
    setState(() {
      _indiceSeleccionado = indice;
    });
  }

  void _usarAtmosfera() {
    Navigator.pop<AtmosferaExperiencia>(context, _seleccionada);
  }

  @override
  Widget build(BuildContext context) {
    final seleccionada = _seleccionada;
    final paleta = seleccionada.paleta;

    return Scaffold(
      appBar: AppBar(title: const Text('Atmósfera lectora')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          48,
        ),
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: _AtmosferaHero(
              key: ValueKey(seleccionada.tipo),
              libro: widget.libro,
              coverUrl: widget.coverUrl,
              experiencia: seleccionada,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          _SectionTitle(
            icon: Icons.auto_awesome_rounded,
            color: paleta.primary,
            title: 'Tu rincón ideal',
            subtitle: 'Todo listo para sumergirte en esta historia',
          ),

          const SizedBox(height: AppSpacing.md),

          _ExperienciaGrid(experiencia: seleccionada),

          const SizedBox(height: AppSpacing.xl),

          _SectionTitle(
            icon: Icons.blur_on_rounded,
            color: AppColors.primary,
            title: 'Otras atmósferas',
            subtitle: 'Puedes elegir la sensación que mejor encaje contigo',
          ),

          const SizedBox(height: AppSpacing.md),

          for (var index = 0; index < _propuestas.length; index++) ...[
            _AtmosferaOptionCard(
              experiencia: _propuestas[index],
              seleccionada: index == _indiceSeleccionado,
              recomendada: index == 0,
              onTap: () => _seleccionar(index),
            ),

            const SizedBox(height: AppSpacing.md),
          ],

          const SizedBox(height: AppSpacing.md),

          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: paleta.primary,
              foregroundColor: AtmosferaExperiencias.colorTextoSobre(
                paleta.primary,
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onPressed: _usarAtmosfera,
            icon: const Icon(Icons.nights_stay_outlined),
            label: Text(
              '✨ Entrar en esta atmósfera',
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'La atmósfera se guardará dentro del kit de este libro.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _AtmosferaHero extends StatelessWidget {
  final String libro;
  final String coverUrl;
  final AtmosferaExperiencia experiencia;

  const _AtmosferaHero({
    super.key,
    required this.libro,
    required this.coverUrl,
    required this.experiencia,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = experiencia.paleta;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AtmosferaAmbientLayer(
        atmosfera: experiencia.tipo,
        color: paleta.primary,
        accentColor: paleta.secondary,
        backgroundColor: paleta.background,
        child: ClubCard(
          elevated: true,
          padding: const EdgeInsets.all(AppSpacing.xl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: paleta.heroGradient
                .map((color) => color.withValues(alpha: 0.84))
                .toList(),
          ),
          borderColor: paleta.primary.withValues(alpha: 0.36),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 190,
                    height: 225,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: paleta.primary.withValues(alpha: 0.20),
                          blurRadius: 32,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),

                  ClubBookCover(
                    title: libro,
                    imageUrl: coverUrl,
                    width: 145,
                    showShadow: true,
                  ),

                  Positioned(
                    right: -4,
                    bottom: -10,
                    child: Container(
                      width: 67,
                      height: 67,
                      decoration: BoxDecoration(
                        color: paleta.surface.withValues(alpha: 0.94),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: paleta.primary.withValues(alpha: 0.20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: paleta.primary.withValues(alpha: 0.16),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        experiencia.icono,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: paleta.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '✨ Hemos preparado tu rincón de lectura',
                  style: AppTextStyles.caption.copyWith(
                    color: paleta.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                experiencia.titulo,
                textAlign: TextAlign.center,
                style: AppTextStyles.title.copyWith(fontSize: 28, height: 1.15),
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                experiencia.descripcion,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySecondary.copyWith(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: experiencia.etiquetas.map((etiqueta) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: paleta.primary.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Text(
                      etiqueta,
                      style: AppTextStyles.caption.copyWith(
                        color: paleta.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExperienciaGrid extends StatelessWidget {
  final AtmosferaExperiencia experiencia;

  const _ExperienciaGrid({required this.experiencia});

  @override
  Widget build(BuildContext context) {
    final paleta = experiencia.paleta;

    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: paleta.border,
      backgroundColor: paleta.surface,
      child: Column(
        children: [
          _ExperienciaRow(
            icon: Icons.light_mode_outlined,
            titulo: 'Luz',
            valor: experiencia.luz,
            color: paleta.primary,
          ),

          Divider(color: paleta.border),

          _ExperienciaRow(
            icon: Icons.local_cafe_outlined,
            titulo: 'Bebida',
            valor: experiencia.bebida,
            color: paleta.primary,
          ),

          Divider(color: paleta.border),

          _ExperienciaRow(
            icon: Icons.cookie_outlined,
            titulo: 'Snack',
            valor: experiencia.snack,
            color: paleta.primary,
          ),

          Divider(color: paleta.border),

          _ExperienciaRow(
            icon: Icons.music_note_rounded,
            titulo: 'Música',
            valor: experiencia.musica,
            color: paleta.primary,
          ),

          Divider(color: paleta.border),

          _ExperienciaRow(
            icon: Icons.schedule_rounded,
            titulo: 'Momento ideal',
            valor: experiencia.momento,
            color: paleta.primary,
          ),

          Divider(color: paleta.border),

          _ExperienciaRow(
            icon: Icons.photo_camera_outlined,
            titulo: 'Mood Bookstagram',
            valor: experiencia.moodBookstagram,
            color: paleta.primary,
          ),
        ],
      ),
    );
  }
}

class _ExperienciaRow extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String valor;
  final Color color;

  const _ExperienciaRow({
    required this.icon,
    required this.titulo,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(icon, color: color, size: 23),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                valor,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AtmosferaOptionCard extends StatelessWidget {
  final AtmosferaExperiencia experiencia;
  final bool seleccionada;
  final bool recomendada;
  final VoidCallback onTap;

  const _AtmosferaOptionCard({
    required this.experiencia,
    required this.seleccionada,
    required this.recomendada,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final paleta = experiencia.paleta;

    return ClubCard(
      elevated: seleccionada,
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: seleccionada
          ? paleta.primary.withValues(alpha: 0.07)
          : AppColors.surface,
      borderColor: seleccionada
          ? paleta.primary.withValues(alpha: 0.42)
          : paleta.border,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: paleta.heroGradient,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            alignment: Alignment.center,
            child: Text(
              experiencia.icono,
              style: const TextStyle(fontSize: 29),
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
                        experiencia.titulo,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    if (recomendada) ...[
                      const SizedBox(width: AppSpacing.sm),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: paleta.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'Recomendada',
                          style: AppTextStyles.caption.copyWith(
                            color: paleta.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  experiencia.descripcion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySecondary.copyWith(height: 1.35),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: seleccionada
                  ? paleta.primary
                  : paleta.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              seleccionada ? Icons.check_rounded : Icons.chevron_right_rounded,
              color: seleccionada ? Colors.white : paleta.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SectionTitle({
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
            color: color.withValues(alpha: 0.12),
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
