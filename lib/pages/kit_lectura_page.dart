import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import 'paleta_lectura_page.dart';
import 'subrayadores_page.dart';
import '../models/kit_lectura_seleccion.dart';
import '../services/kit_lectura_service.dart';
import 'atmosfera_lectura_page.dart';
import '../theme/atmosferas/atmosfera_experiencia.dart';
import '../theme/atmosferas/atmosfera_tipo.dart';
import '../services/atmosfera_scope.dart';

class KitLecturaPage extends StatefulWidget {
  final String bookId;
  final String libro;
  final String coverUrl;

  const KitLecturaPage({
    super.key,
    required this.bookId,
    required this.libro,
    this.coverUrl = '',
  });

  @override
  State<KitLecturaPage> createState() => _KitLecturaPageState();
}

class _KitLecturaPageState extends State<KitLecturaPage> {
  final KitLecturaService _kitService = KitLecturaService();

  KitLecturaSeleccion _seleccion = const KitLecturaSeleccion();

  bool _cargandoKit = true;

  @override
  void initState() {
    super.initState();
    _cargarKit();
  }

  Future<void> _cargarKit() async {
    final seleccion = await _kitService.obtener(widget.bookId);

    if (!mounted) return;

    setState(() {
      _seleccion = seleccion;
      _cargandoKit = false;
    });
  }

  bool get _tienePaleta => _seleccion.tienePaleta;

  bool get _tieneSubrayadores => _seleccion.tieneSubrayadores;

  Future<void> _abrirPaleta() async {
    final resultado = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => PaletaLecturaPage(
          bookId: widget.bookId,
          libro: widget.libro,
          coverUrl: widget.coverUrl,
        ),
      ),
    );

    if (!mounted || resultado == null || resultado.isEmpty) {
      return;
    }

    final nuevaSeleccion = _seleccion.copyWith(
      paleta: resultado,
      subrayadores: const [],
    );

    await _kitService.guardar(widget.bookId, nuevaSeleccion);

    if (!mounted) return;

    setState(() {
      _seleccion = nuevaSeleccion;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('✨ Paleta añadida al kit de lectura')),
      );
  }

  Future<void> _abrirSubrayadores() async {
    if (!_tienePaleta) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Primero elige una paleta para preparar los subrayadores.',
            ),
          ),
        );

      return;
    }

    final colores = _seleccion.paleta
        .map(_colorDesdeHex)
        .toList(growable: false);

    final resultado = await Navigator.push<List<Color>>(
      context,
      MaterialPageRoute(
        builder: (_) => SubrayadoresPage(
          libro: widget.libro,
          coverUrl: widget.coverUrl,
          colores: colores,
        ),
      ),
    );

    if (!mounted || resultado == null || resultado.isEmpty) {
      return;
    }

    final subrayadores = resultado.map(_colorAHex).toList(growable: false);

    final nuevaSeleccion = _seleccion.copyWith(subrayadores: subrayadores);

    await _kitService.guardar(widget.bookId, nuevaSeleccion);

    if (!mounted) return;

    setState(() {
      _seleccion = nuevaSeleccion;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('🖍️ Subrayadores añadidos al kit de lectura'),
        ),
      );
  }

  Future<void> _abrirAtmosfera() async {
    final coloresPaleta = _seleccion.paleta
        .map(_colorDesdeHex)
        .toList(growable: false);

    final resultado = await Navigator.push<AtmosferaExperiencia>(
      context,
      MaterialPageRoute(
        builder: (_) => AtmosferaLecturaPage(
          libro: widget.libro,
          coverUrl: widget.coverUrl,
          coloresPaleta: coloresPaleta,
          atmosferaActualId: _seleccion.atmosferaId,
        ),
      ),
    );

    if (!mounted || resultado == null) return;

    final nuevaSeleccion = _seleccion.copyWith(
      atmosferaId: resultado.tipo.apiValue,
      atmosferaTitulo: resultado.titulo,
      atmosferaDescripcion: resultado.descripcion,
      atmosferaIcono: resultado.icono,
      luz: resultado.luz,
      bebida: resultado.bebida,
      snack: resultado.snack,
      musica: resultado.musica,
      momento: resultado.momento,
    );

    await _kitService.guardar(widget.bookId, nuevaSeleccion);

    if (!mounted) return;

    AtmosferaScope.of(
      context,
    ).aplicarAtmosferaLibro(bookId: widget.bookId, atmosfera: resultado.tipo);

    setState(() {
      _seleccion = nuevaSeleccion;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${resultado.icono} Atmósfera añadida al kit')),
      );
  }

  Color _colorDesdeHex(String hex) {
    final limpio = hex.replaceAll('#', '').replaceAll('0x', '').trim();

    final valor = limpio.length == 6 ? 'FF$limpio' : limpio.padLeft(8, 'F');

    return Color(int.parse(valor, radix: 16));
  }

  String _colorAHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;

    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void _mostrarProximamente(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kit de lectura')),
      body: _cargandoKit
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                48,
              ),
              children: [
                ClubCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.surfaceSoft, Color(0xFFF0E5FF)],
                  ),
                  borderColor: AppColors.primaryLight,
                  child: Column(
                    children: [
                      ClubBookCover(
                        title: widget.libro,
                        imageUrl: widget.coverUrl,
                        width: 150,
                        showShadow: true,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        widget.libro,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 27,
                          height: 1.15,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      Text(
                        _tienePaleta
                            ? '✨ Tu experiencia empieza a tomar forma'
                            : '✨ Preparando tu experiencia de lectura',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary,
                      ),

                      if (_tienePaleta) ...[
                        const SizedBox(height: AppSpacing.lg),

                        _PaletaHeroPreview(
                          colores: _seleccion.paleta
                              .map(_colorDesdeHex)
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                _KitSectionCard(
                  icon: Icons.palette_outlined,
                  title: 'Paleta lectora',
                  subtitle: _tienePaleta
                      ? 'Paleta preparada · Toca para cambiarla'
                      : 'Post-it inspirados en la portada',
                  color: AppColors.primary,
                  preparada: _tienePaleta,
                  previewColors: _tienePaleta
                      ? _seleccion.paleta.map(_colorDesdeHex).toList()
                      : const [],
                  onTap: _abrirPaleta,
                ),

                const SizedBox(height: AppSpacing.md),

                _KitSectionCard(
                  icon: Icons.brush_outlined,
                  title: 'Subrayadores',
                  subtitle: _tieneSubrayadores
                      ? 'Subrayadores preparados · Toca para cambiarlos'
                      : _tienePaleta
                      ? 'Crearemos tonos a partir de tu paleta'
                      : 'Primero elige una paleta',
                  color: const Color(0xFFE49A24),
                  preparada: _tieneSubrayadores,
                  previewColors: _tieneSubrayadores
                      ? _seleccion.subrayadores.map(_colorDesdeHex).toList()
                      : const [],
                  onTap: _abrirSubrayadores,
                ),

                const SizedBox(height: AppSpacing.md),

                _KitSectionCard(
                  icon: Icons.nights_stay_outlined,
                  title: 'Atmósfera',
                  subtitle: _seleccion.tieneAtmosfera
                      ? '${_seleccion.atmosferaIcono} ${_seleccion.atmosferaTitulo}'
                      : 'Hemos preparado un rincón para este libro',
                  color: const Color(0xFF5F63A8),
                  preparada: _seleccion.tieneAtmosfera,
                  onTap: _abrirAtmosfera,
                ),

                const SizedBox(height: AppSpacing.md),

                _KitSectionCard(
                  icon: Icons.music_note_rounded,
                  title: 'Playlist',
                  subtitle: 'Una banda sonora para acompañarte',
                  color: const Color(0xFFD85D88),
                  onTap: () {
                    _mostrarProximamente(
                      'La playlist llegará en una fase posterior.',
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                _KitSectionCard(
                  icon: Icons.wallpaper_outlined,
                  title: 'Fondo de pantalla',
                  subtitle: _tienePaleta
                      ? 'Diseñado con los colores de tu paleta'
                      : 'Lleva la estética del libro contigo',
                  color: const Color(0xFF5D91CE),
                  onTap: () {
                    _mostrarProximamente(
                      'Próximamente crearemos el fondo de pantalla.',
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                _KitSectionCard(
                  icon: Icons.ios_share_rounded,
                  title: 'Story',
                  subtitle: _tienePaleta
                      ? 'Una tarjeta con la estética elegida'
                      : 'Una tarjeta lista para compartir',
                  color: const Color(0xFF5CA77A),
                  onTap: () {
                    _mostrarProximamente(
                      'Próximamente generaremos la story compartible.',
                    );
                  },
                ),
              ],
            ),
    );
  }
}

class _PaletaHeroPreview extends StatelessWidget {
  final List<Color> colores;

  const _PaletaHeroPreview({required this.colores});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int index = 0; index < colores.length; index++)
          Transform.rotate(
            angle: (index - 2) * 0.035,
            child: Container(
              width: 37,
              height: 51,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: colores[index],
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: colores[index].withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _KitSectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool preparada;
  final List<Color> previewColors;

  const _KitSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.preparada = false,
    this.previewColors = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: preparada,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: preparada
          ? color.withValues(alpha: 0.42)
          : color.withValues(alpha: 0.22),
      backgroundColor: preparada
          ? color.withValues(alpha: 0.075)
          : color.withValues(alpha: 0.045),
      onTap: onTap,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 28),
              ),

              if (preparada)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: 21,
                    height: 21,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
            ],
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
                        title,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    if (preparada) ...[
                      const SizedBox(width: AppSpacing.sm),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Preparada',
                          style: AppTextStyles.caption.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(subtitle, style: AppTextStyles.bodySecondary),

                if (previewColors.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),

                  Row(
                    children: previewColors.map((previewColor) {
                      return Container(
                        width: 23,
                        height: 23,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: previewColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: previewColor.withValues(alpha: 0.18),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              shape: BoxShape.circle,
            ),
            child: Icon(
              preparada ? Icons.edit_outlined : Icons.arrow_forward_rounded,
              color: color,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
