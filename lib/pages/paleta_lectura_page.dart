import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator_plus/palette_generator_plus.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import '../widgets/ui/club_section_title.dart';

class PaletaLecturaPage extends StatefulWidget {
  final String bookId;
  final String libro;
  final String coverUrl;

  const PaletaLecturaPage({
    super.key,
    required this.bookId,
    required this.libro,
    this.coverUrl = '',
  });

  @override
  State<PaletaLecturaPage> createState() => _PaletaLecturaPageState();
}

class _PaletaLecturaPageState extends State<PaletaLecturaPage> {
  late Future<List<_ColorLector>> _futurePaleta;
  List<List<_ColorLector>> _variantes = [];
  int _indiceVariante = 0;

  @override
  void initState() {
    super.initState();
    _futurePaleta = _generarPaleta();
  }

  Future<List<_ColorLector>> _generarPaleta() async {
    final coverUrl = widget.coverUrl.trim();

    if (coverUrl.isEmpty) {
      return _prepararVariantes(_coloresFallback());
    }

    try {
      final provider = ResizeImage(NetworkImage(coverUrl), width: 500);

      final palette = await PaletteGenerator.fromImageProvider(
        provider,
        maximumColorCount: 24,
      );

      final candidatos = <Color>[
        if (palette.dominantColor?.color case final color?) color,
        if (palette.vibrantColor?.color case final color?) color,
        if (palette.darkVibrantColor?.color case final color?) color,
        if (palette.lightVibrantColor?.color case final color?) color,
        if (palette.mutedColor?.color case final color?) color,
        if (palette.darkMutedColor?.color case final color?) color,
        if (palette.lightMutedColor?.color case final color?) color,
        ...palette.paletteColors.map((e) => e.color),
      ];

      final seleccionados = _seleccionarColores(candidatos);

      if (seleccionados.length < 3) {
        return _prepararVariantes(_coloresFallback());
      }

      final completados = _completarPaleta(seleccionados);

      return _prepararVariantes(completados);
    } catch (error) {
      return _prepararVariantes(_coloresFallback());
    }
  }

  List<Color> _seleccionarColores(List<Color> candidatos) {
    final resultado = <Color>[];

    for (final original in candidatos) {
      final color = _normalizarColor(original);

      if (_esDemasiadoBlanco(color) || _esDemasiadoNegro(color)) {
        continue;
      }

      final esParecido = resultado.any(
        (existente) => _distanciaColor(existente, color) < 0.16,
      );

      if (!esParecido) {
        resultado.add(color);
      }

      if (resultado.length == 5) {
        break;
      }
    }

    return resultado;
  }

  List<Color> _completarPaleta(List<Color> colores) {
    final resultado = List<Color>.from(colores);

    final base = resultado.isNotEmpty ? resultado.first : AppColors.primary;

    final hsl = HSLColor.fromColor(base);

    final variaciones = <Color>[
      hsl.withLightness((hsl.lightness + 0.22).clamp(0.18, 0.88)).toColor(),
      hsl.withLightness((hsl.lightness - 0.18).clamp(0.12, 0.82)).toColor(),
      hsl
          .withHue((hsl.hue + 32) % 360)
          .withSaturation((hsl.saturation * 0.85).clamp(0.25, 0.90))
          .toColor(),
      hsl
          .withHue((hsl.hue + 330) % 360)
          .withLightness((hsl.lightness + 0.08).clamp(0.18, 0.88))
          .toColor(),
      const Color(0xFFEDE7F6),
    ];

    for (final color in variaciones) {
      final esParecido = resultado.any(
        (existente) => _distanciaColor(existente, color) < 0.13,
      );

      if (!esParecido) {
        resultado.add(color);
      }

      if (resultado.length == 5) {
        break;
      }
    }

    while (resultado.length < 5) {
      resultado.add(
        Color.lerp(base, Colors.white, 0.18 * resultado.length) ?? base,
      );
    }

    return resultado.take(5).toList();
  }

  Color _normalizarColor(Color color) {
    final hsl = HSLColor.fromColor(color);

    return hsl
        .withSaturation(hsl.saturation.clamp(0.18, 0.88))
        .withLightness(hsl.lightness.clamp(0.16, 0.84))
        .toColor();
  }

  bool _esDemasiadoBlanco(Color color) {
    return color.computeLuminance() > 0.91;
  }

  bool _esDemasiadoNegro(Color color) {
    return color.computeLuminance() < 0.018;
  }

  double _distanciaColor(Color a, Color b) {
    final dr = a.r - b.r;
    final dg = a.g - b.g;
    final db = a.b - b.b;

    return math.sqrt((dr * dr) + (dg * dg) + (db * db));
  }

  _ColorLector _crearColorLector(Color color, int index) {
    const usos = [
      _UsoColor(
        titulo: 'Momentos favoritos',
        descripcion: 'Escenas que quieres recordar',
        icono: Icons.favorite_outline_rounded,
      ),
      _UsoColor(
        titulo: 'Teorías',
        descripcion: 'Pistas, sospechas y predicciones',
        icono: Icons.psychology_alt_outlined,
      ),
      _UsoColor(
        titulo: 'Citas',
        descripcion: 'Frases para volver a leer',
        icono: Icons.format_quote_rounded,
      ),
      _UsoColor(
        titulo: 'Mundo y personajes',
        descripcion: 'Detalles importantes de la historia',
        icono: Icons.auto_stories_outlined,
      ),
      _UsoColor(
        titulo: 'Escenas intensas',
        descripcion: 'Giros, drama y momentos clave',
        icono: Icons.bolt_outlined,
      ),
    ];

    return _ColorLector(
      color: color,
      nombre: _nombreColor(color),
      uso: usos[index % usos.length],
    );
  }

  String _nombreColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final hue = hsl.hue;
    final lightness = hsl.lightness;
    final saturation = hsl.saturation;

    if (saturation < 0.14) {
      if (lightness < 0.28) return 'Carbón';
      if (lightness < 0.58) return 'Gris humo';
      return 'Perla';
    }

    String familia;

    if (hue < 15 || hue >= 345) {
      familia = 'Rojo';
    } else if (hue < 40) {
      familia = 'Terracota';
    } else if (hue < 65) {
      familia = 'Dorado';
    } else if (hue < 95) {
      familia = 'Oliva';
    } else if (hue < 155) {
      familia = 'Verde';
    } else if (hue < 190) {
      familia = 'Turquesa';
    } else if (hue < 225) {
      familia = 'Azul';
    } else if (hue < 265) {
      familia = 'Índigo';
    } else if (hue < 295) {
      familia = 'Violeta';
    } else if (hue < 325) {
      familia = 'Magenta';
    } else {
      familia = 'Rosa';
    }

    if (lightness < 0.30) {
      return '$familia profundo';
    }

    if (lightness > 0.72) {
      return '$familia suave';
    }

    if (saturation > 0.68) {
      return '$familia intenso';
    }

    return familia;
  }

  List<Color> _coloresFallback() {
    return const [
      Color(0xFF68489A),
      Color(0xFFB25A83),
      Color(0xFF6E8292),
      Color(0xFFB98A72),
      Color(0xFF384B48),
    ];
  }

  List<_ColorLector> _prepararVariantes(List<Color> coloresBase) {
    final paletas = <List<Color>>[
      // 1. Equilibrada: los colores originales.
      coloresBase,

      // 2. Vibrante: más saturación y algo más de luz.
      _transformarPaleta(
        coloresBase,
        saturationFactor: 1.28,
        lightnessOffset: 0.035,
      ),

      // 3. Suave: tonos más claros y menos saturados.
      _transformarPaleta(
        coloresBase,
        saturationFactor: 0.72,
        lightnessOffset: 0.16,
      ),

      // 4. Oscura: tonos más profundos y cinematográficos.
      _transformarPaleta(
        coloresBase,
        saturationFactor: 0.92,
        lightnessFactor: 0.72,
      ),
    ];

    _variantes = paletas.map((paleta) {
      return List.generate(
        5,
        (index) => _crearColorLector(paleta[index], index),
      );
    }).toList();

    _indiceVariante = 0;

    return _variantes.first;
  }

  List<Color> _transformarPaleta(
    List<Color> colores, {
    double saturationFactor = 1,
    double saturationOffset = 0,
    double lightnessFactor = 1,
    double lightnessOffset = 0,
  }) {
    return colores.map((color) {
      final hsl = HSLColor.fromColor(color);

      final saturation = (hsl.saturation * saturationFactor + saturationOffset)
          .clamp(0.16, 0.92)
          .toDouble();

      final lightness = (hsl.lightness * lightnessFactor + lightnessOffset)
          .clamp(0.12, 0.88)
          .toDouble();

      return hsl.withSaturation(saturation).withLightness(lightness).toColor();
    }).toList();
  }

  void _regenerar() {
    setState(() {
      _variantes = [];
      _indiceVariante = 0;
      _futurePaleta = _generarPaleta();
    });
  }

  void _probarOtraCombinacion() {
    if (_variantes.length < 2) return;

    setState(() {
      _indiceVariante = (_indiceVariante + 1) % _variantes.length;

      _futurePaleta = Future.value(_variantes[_indiceVariante]);
    });
  }

  void _usarEstaPaleta(List<_ColorLector> colores) {
    final resultado = colores.map((item) => item.hex).toList(growable: false);

    Navigator.pop<List<String>>(context, resultado);
  }

  String _nombreVariante(int indice) {
    switch (indice) {
      case 0:
        return 'Equilibrada';
      case 1:
        return 'Vibrante';
      case 2:
        return 'Suave';
      case 3:
        return 'Oscura';
      default:
        return 'Personalizada';
    }
  }

  Future<void> _copiarHex(BuildContext context, _ColorLector item) async {
    await Clipboard.setData(ClipboardData(text: item.hex));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${item.hex} copiado'),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paleta lectora')),
      body: FutureBuilder<List<_ColorLector>>(
        future: _futurePaleta,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _CargandoPaleta(
              libro: widget.libro,
              coverUrl: widget.coverUrl,
            );
          }

          if (snapshot.hasError) {
            return _ErrorPaleta(onRetry: _regenerar);
          }
          final colores = snapshot.data;

          if (colores == null || colores.isEmpty) {
            return _ErrorPaleta(onRetry: _regenerar);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              48,
            ),
            children: [
              _HeroPaleta(
                libro: widget.libro,
                coverUrl: widget.coverUrl,
                colores: colores,
              ),

              const SizedBox(height: AppSpacing.xl),

              const ClubSectionTitle(
                icon: Icons.palette_outlined,
                color: AppColors.primary,
                title: 'Colores de la portada',
                subtitle: 'Una selección pensada para acompañar tu lectura',
              ),

              const SizedBox(height: AppSpacing.md),

              ...colores.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _ColorCard(
                    item: item,
                    onCopiar: () {
                      _copiarHex(context, item);
                    },
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              const ClubSectionTitle(
                icon: Icons.bookmark_border_rounded,
                color: Color(0xFFD85D88),
                title: 'Tus post-it',
                subtitle: 'Así podría quedar tu combinación física',
              ),

              const SizedBox(height: AppSpacing.md),

              _PostItsCard(colores: colores),

              const SizedBox(height: AppSpacing.xl),

              const ClubSectionTitle(
                icon: Icons.auto_awesome_outlined,
                color: Color(0xFFE49A24),
                title: 'Leyenda lectora',
                subtitle: 'Una propuesta para organizar tus marcas',
              ),

              const SizedBox(height: AppSpacing.md),

              _LeyendaCard(colores: colores),

              const SizedBox(height: AppSpacing.lg),

              FilledButton.icon(
                onPressed: () {
                  _usarEstaPaleta(colores);
                },
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Text('Usar esta paleta'),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              OutlinedButton.icon(
                onPressed: _variantes.length > 1
                    ? _probarOtraCombinacion
                    : null,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Probar otra combinación'),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                _variantes.isEmpty
                    ? 'Paleta generada automáticamente desde la portada.'
                    : 'Combinación ${_indiceVariante + 1} de '
                          '${_variantes.length} · '
                          '${_nombreVariante(_indiceVariante)}',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                'Toca cualquier color para copiar su código HEX.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroPaleta extends StatelessWidget {
  final String libro;
  final String coverUrl;
  final List<_ColorLector> colores;

  const _HeroPaleta({
    required this.libro,
    required this.coverUrl,
    required this.colores,
  });

  @override
  Widget build(BuildContext context) {
    final base = colores.first.color;

    return ClubCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: base.withOpacity(0.25),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [base.withOpacity(0.08), colores.last.color.withOpacity(0.12)],
      ),
      child: Column(
        children: [
          ClubBookCover(
            title: libro,
            imageUrl: coverUrl,
            width: 145,
            showShadow: true,
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            libro,
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 27, height: 1.15),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Una paleta inspirada en su portada',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),

          const SizedBox(height: AppSpacing.lg),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < colores.length; i++)
                Transform.rotate(
                  angle: (i - 2) * 0.035,
                  child: Container(
                    width: 49,
                    height: 68,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: colores[i].color,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: colores[i].color.withOpacity(0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorCard extends StatelessWidget {
  final _ColorLector item;
  final VoidCallback onCopiar;

  const _ColorCard({required this.item, required this.onCopiar});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: EdgeInsets.zero,
      borderColor: item.color.withOpacity(0.24),
      onTap: onCopiar,
      child: Row(
        children: [
          Container(
            width: 88,
            height: 92,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                bottomLeft: Radius.circular(AppRadius.lg),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombre,
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    item.hex,
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.copy_rounded, color: item.color, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostItsCard extends StatelessWidget {
  final List<_ColorLector> colores;

  const _PostItsCard({required this.colores});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: AppColors.primaryLight,
      backgroundColor: AppColors.surfaceSoft,
      child: Column(
        children: [
          SizedBox(
            height: 165,
            child: Stack(
              alignment: Alignment.center,
              children: [
                for (int i = 0; i < colores.length; i++)
                  Positioned(
                    left: 22.0 + (i * 47),
                    top: 20.0 + ((i % 2) * 13),
                    child: Transform.rotate(
                      angle: (i - 2) * 0.07,
                      child: _PostIt(
                        color: colores[i].color,
                        texto: '${i + 1}',
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Cinco tonos distintos, pero conectados entre sí.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}

class _PostIt extends StatelessWidget {
  final Color color;
  final String texto;

  const _PostIt({required this.color, required this.texto});

  @override
  Widget build(BuildContext context) {
    final textoOscuro = color.computeLuminance() > 0.48;

    return Container(
      width: 58,
      height: 112,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        texto,
        style: AppTextStyles.caption.copyWith(
          color: textoOscuro ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LeyendaCard extends StatelessWidget {
  final List<_ColorLector> colores;

  const _LeyendaCard({required this.colores});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: AppColors.border,
      child: Column(
        children: [
          for (int i = 0; i < colores.length; i++) ...[
            _LeyendaRow(item: colores[i]),
            if (i < colores.length - 1) const Divider(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _LeyendaRow extends StatelessWidget {
  final _ColorLector item;

  const _LeyendaRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.16),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(item.uso.icono, color: item.color, size: 22),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.uso.titulo,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 2),

              Text(item.uso.descripcion, style: AppTextStyles.caption),
            ],
          ),
        ),

        Container(
          width: 26,
          height: 44,
          decoration: BoxDecoration(
            color: item.color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _CargandoPaleta extends StatelessWidget {
  final String libro;
  final String coverUrl;

  const _CargandoPaleta({required this.libro, required this.coverUrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClubBookCover(
              title: libro,
              imageUrl: coverUrl,
              width: 130,
              showShadow: true,
            ),

            const SizedBox(height: AppSpacing.xl),

            const CircularProgressIndicator(),

            const SizedBox(height: AppSpacing.md),

            Text(
              'Preparando los colores de tu lectura…',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorPaleta extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorPaleta({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.palette_outlined,
              size: 64,
              color: AppColors.primary,
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              'No hemos podido preparar la paleta.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle,
            ),

            const SizedBox(height: AppSpacing.lg),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Volver a intentarlo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorLector {
  final Color color;
  final String nombre;
  final _UsoColor uso;

  const _ColorLector({
    required this.color,
    required this.nombre,
    required this.uso,
  });

  String get hex {
    final rgb = color.toARGB32() & 0x00FFFFFF;

    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

class _UsoColor {
  final String titulo;
  final String descripcion;
  final IconData icono;

  const _UsoColor({
    required this.titulo,
    required this.descripcion,
    required this.icono,
  });
}
