import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/kit_lectura_seleccion.dart';
import '../models/libro.dart';
import '../models/libro_agrupado.dart';
import '../services/api_service.dart';
import '../services/atmosfera_controller.dart';
import '../services/atmosfera_scope.dart';
import '../services/favoritos_service.dart';
import '../services/kit_lectura_service.dart';
import '../services/usuario_service.dart';
import '../services/library_refresh_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/libro_finalizado_celebration.dart';
import '../widgets/common/screen_hint_banner.dart';
import '../widgets/libros/conversaciones_libro_card.dart';
import '../widgets/libros/finalizar_libro_dialog.dart';
import '../widgets/libros/kit_lectura_card.dart';
import '../widgets/libros/libro_header.dart';
import '../widgets/libros/libro_interesadas_section.dart';
import '../widgets/libros/libro_section.dart';
import '../widgets/libros/libro_valoraciones_section.dart';
import 'kit_export_page.dart';
import 'kit_lectura_page.dart';
import 'nuevo_libro_page.dart';

class DetalleLibroPage extends StatefulWidget {
  final LibroAgrupado libro;

  /// Tag Hero que coincide con el de la portada en la pantalla de origen.
  final String? heroTag;

  /// Cuando es `true` (abierto desde el dashboard global), sustituye
  /// "Lectores interesados" y "Valoraciones" por estadísticas anónimas
  /// (media, contadores, gráfica de distribución) sin mostrar nombres ni fotos.
  final bool globalStats;

  const DetalleLibroPage({
    super.key,
    required this.libro,
    this.heroTag,
    this.globalStats = false,
  });

  @override
  State<DetalleLibroPage> createState() => _DetalleLibroPageState();
}

class _DetalleLibroPageState extends State<DetalleLibroPage> {
  final KitLecturaService _kitService = KitLecturaService();
  late LibroAgrupado libro;
  late List<Libro> registros;
  late AtmosferaController _atmosferaController;

  String? usuarioActual;

  // Kit de lectura: atmósfera activa (Feature 2)
  KitLecturaSeleccion _kitSeleccion = const KitLecturaSeleccion();

  bool _controllerPreparado = false;
  bool _atmosferaCerrada = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();

    libro = widget.libro;

    registros = List<Libro>.from(libro.registros);

    _cargarUsuarioActual();
    unawaited(FavoritosService.instance.cargar());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _atmosferaController = AtmosferaScope.of(context);
      _controllerPreparado = true;

      _cargarAtmosferaDelLibro();
    });
  }

  Future<void> _cargarUsuarioActual() async {
    final usuario = await UsuarioService().obtenerUsuario();

    if (!mounted) return;

    setState(() {
      usuarioActual = usuario?.trim();
    });
  }

  Future<void> _cargarAtmosferaDelLibro() async {
    if (!_controllerPreparado) return;

    final bookId = libro.bookId.trim();

    if (bookId.isEmpty) {
      _atmosferaController.usarAtmosferaNeutra();
      return;
    }

    try {
      final seleccion = await _kitService.obtener(bookId);

      if (!mounted || _atmosferaCerrada) return;

      setState(() => _kitSeleccion = seleccion);

      _atmosferaController.entrarEnLibro(
        bookId: bookId,
        atmosferaId: seleccion.atmosferaId,
      );
    } catch (error) {
      if (!mounted || _atmosferaCerrada) return;

      _atmosferaController.entrarEnLibro(bookId: bookId, atmosferaId: '');
    }
  }

  /// Cierra la atmósfera del libro de forma segura.
  ///
  /// Puede llamarse desde el botón de volver, el gesto de iOS,
  /// una salida programática o dispose sin aplicar el cierre dos veces.
  void _cerrarAtmosferaDelLibro() {
    if (_atmosferaCerrada) return;

    _atmosferaCerrada = true;

    if (!_controllerPreparado) return;

    final bookId = libro.bookId.trim();

    _atmosferaController.salirDelLibro(bookId: bookId.isEmpty ? null : bookId);
  }

  void _volver() {
    _cerrarAtmosferaDelLibro();
    Navigator.pop(context);
  }

  Future<void> _cambiarEstado(
    Libro libro,
    String nuevoEstado, {
    String? valoracion,
    String? reflexion,
    String? motivoPausa,
    String? fechaInicio,
    String? fechaFin,
    String? formato,
  }) async {
    try {
      final bool ok;

      if (nuevoEstado == 'LEYENDO') {
        ok = await ApiService().iniciarLectura(
          usuario: libro.usuario,
          libro: libro.libro,
        );
      } else {
        ok = await ApiService().actualizarEstado(
          usuario: libro.usuario,
          libro: libro.libro,
          estado: nuevoEstado,
          valoracion: valoracion,
          reflexion: reflexion,
          motivoPausa: motivoPausa,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          formato: formato,
        );
      }

      if (!ok) {
        throw Exception('No se ha podido guardar el estado');
      }

      if (!mounted) return;

      LibraryRefreshNotifier.instance.invalidate();

      final index = registros.indexOf(libro);

      if (index == -1) {
        throw Exception('No se ha encontrado el registro del libro');
      }

      setState(() {
        registros[index] = libro.copyWith(
          estado: nuevoEstado,
          valoracion: nuevoEstado == 'FINALIZADO'
              ? (valoracion ?? libro.valoracion)
              : '',
          formato: formato ?? libro.formato,
        );
      });

      if (!mounted) return;

      if (nuevoEstado == 'FINALIZADO') {
        // Vibración + pantalla de celebración
        await mostrarCelebracionFinalizado(
          context,
          titulo: libro.libro,
          coverUrl: libro.coverUrl,
        );

        // Feature 4: prompt para compartir story si tiene kit con paleta
        if (!mounted) return;
        final bookId = widget.libro.bookId.trim();
        if (bookId.isNotEmpty) {
          final kit = await _kitService.obtener(bookId);
          if (!mounted) return;
          if (kit.tienePaleta) {
            await _mostrarPromptStory(libro, kit, finalizado: true);
          }
        }
      } else if (nuevoEstado == 'LEYENDO') {
        // Feature 3: prompt para preparar el kit si aún no lo tiene
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Estado actualizado')));

        final bookId = widget.libro.bookId.trim();
        if (bookId.isNotEmpty && !mounted) return;
        if (bookId.isNotEmpty) {
          final kit = await _kitService.obtener(bookId);
          if (!mounted) return;
          if (!kit.tienePaleta) {
            await _mostrarPromptKit(libro);
          }
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Estado actualizado')));
      }
    } catch (error) {
      if (!mounted) return;

      final mensaje = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $mensaje')));
    }
  }

  // ── Feature 3: prompt kit al empezar a leer ────────────────────────────
  Future<void> _mostrarPromptKit(Libro libro) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('✨', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(
              '¿Preparamos tu kit de lectura?',
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Paleta, subrayadores, atmósfera y playlist — todo listo en 2 minutos para que esta historia se convierta en una experiencia.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _abrirKitLectura();
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Preparar mi kit'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Más tarde'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Feature 4: prompt story al terminar ────────────────────────────────
  Future<void> _mostrarPromptStory(
    Libro libro,
    KitLecturaSeleccion kit, {
    bool finalizado = false,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('🎉', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(
              '¡Has terminado ${libro.libro}!',
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Tienes tu kit de lectura preparado. ¿Compartes tu story con la comunidad?',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _abrirExportacion(KitExportTipo.story, kit, finalizado: finalizado, valoracionStr: libro.valoracion);
              },
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Compartir mi story'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ahora no'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Convierte una cadena de valoración a double (1.0–5.0, admite medias) ─
  // Formatos soportados: "⭐⭐⭐⭐½", "4.5", "4,5"
  static double? _parseStarsCount(String? valoracion) {
    if (valoracion == null || valoracion.isEmpty) return null;
    final texto = valoracion.trim().replaceAll('⭐️', '⭐').replaceAll(',', '.');
    if (texto == '😞') return null;
    final num = double.tryParse(texto);
    if (num != null) {
      final v = ((num.clamp(0, 5)) * 2).round() / 2;
      return v > 0 ? v : null;
    }
    final stars = '⭐'.allMatches(texto).length;
    final half = texto.contains('½');
    final v = (((stars + (half ? 0.5 : 0)).clamp(0, 5)) * 2).round() / 2;
    return v > 0 ? v : null;
  }

  // ── Abre la exportación de story/wallpaper desde fuera del kit ─────────
  Future<void> _abrirExportacion(
    KitExportTipo tipo,
    KitLecturaSeleccion kit, {
    bool finalizado = false,
    String? valoracionStr,
  }) async {
    await Navigator.push<void>(
      context,
      AppPageRoute(
        builder: (_) => KitExportPage(
          tipo: tipo,
          libro: widget.libro.libro,
          coverUrl: widget.libro.coverUrl,
          colores: kit.paleta.map(_colorDesdeHex).toList(),
          subrayadores: kit.subrayadores.map(_colorDesdeHex).toList(),
          atmosferaTitulo: kit.atmosferaTitulo,
          atmosferaIcono: kit.atmosferaIcono,
          etiquetaStory: finalizado ? 'YA LO HE LEÍDO' : 'ESTOY LEYENDO',
          valoracion: _parseStarsCount(valoracionStr),
        ),
      ),
    );
  }

  Color _colorDesdeHex(String hex) {
    final limpio = hex.replaceAll('#', '').replaceAll('0x', '').trim();
    final valor = limpio.length == 6 ? 'FF$limpio' : limpio.padLeft(8, 'F');
    return Color(int.parse(valor, radix: 16));
  }

  Future<void> _actualizarPreferencias(
    Libro libro,
    String prioridad,
    String formato,
  ) async {
    final ok = await ApiService().actualizarPreferenciasLibro(
      libro: libro.libro,
      prioridad: prioridad,
      formato: formato,
    );
    if (!ok) throw Exception('No se han podido guardar tus preferencias');
    if (!mounted) return;
    final index = registros.indexOf(libro);
    if (index < 0) return;
    setState(() {
      registros[index] = libro.copyWith(prioridad: prioridad, formato: formato);
    });
  }

  Future<void> _quitarPendientes(Libro libro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🗑️ Quitar libro'),
        content: Text(
          "¿Quieres quitar '${libro.libro}' de tus pendientes?\n\n"
          'Si nadie más lo tiene pendiente y nunca se ha leído, '
          'desaparecerá del catálogo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final respuesta = await ApiService().quitarLibroPendientes(
      usuario: libro.usuario,
      libro: libro.libro,
      bookId: libro.bookId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          respuesta['mensaje']?.toString() ?? 'Operación realizada',
        ),
      ),
    );

    if (respuesta['ok'] == true) {
      LibraryRefreshNotifier.instance.invalidate();
      _cerrarAtmosferaDelLibro();

      if (!mounted) return;

      Navigator.pop(context, true);
    }
  }

  Future<void> _abrirGoodreads() async {
    var url = libro.goodreads;

    if (url.isEmpty) return;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.parse(url);

    final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!abierto) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _toggleFavorito() async {
    if (_toggling || libro.bookId.isEmpty) return;
    setState(() => _toggling = true);
    final resultado = await FavoritosService.instance.toggle(
      libro.bookId,
      libro.libro,
      coverUrl: libro.coverUrl.isNotEmpty ? libro.coverUrl : null,
    );
    if (!mounted) return;
    setState(() => _toggling = false);
    if (!resultado.ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(resultado.mensaje)));
    }
  }

  Future<void> _editarLibro() async {
    if (libro.bookId.isEmpty) return;

    final actualizado = await Navigator.push<bool>(
      context,
      AppPageRoute(builder: (_) => NuevoLibroPage(libro: libro)),
    );

    if (!mounted) return;

    if (actualizado == true) {
      _cerrarAtmosferaDelLibro();

      if (!mounted) return;

      Navigator.pop(context, true);
    }
  }

  Future<void> _abrirKitLectura({bool finalizado = false, double? valoracion}) async {
    await Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => KitLecturaPage(
          bookId: libro.bookId,
          libro: libro.libro,
          coverUrl: libro.coverUrl,
          finalizado: finalizado,
          valoracion: valoracion,
        ),
      ),
    );

    if (!mounted || !_controllerPreparado || _atmosferaCerrada) {
      return;
    }

    /*
     * Al volver del kit, recargamos la selección porque la lectora
     * podría haber cambiado la atmósfera del libro.
     */
    await _cargarAtmosferaDelLibro();
  }

  @override
  Widget build(BuildContext context) {
    final referencia = registros.isNotEmpty ? registros.first : null;

    // En modo global, calculamos el estado personal del usuario buscando
    // primero en registros (PENDIENTE/LEYENDO/PAUSADO…) y luego en finalizados.
    // Los registros en modo global contienen a TODOS los usuarios, así que
    // hay que filtrar por el usuario actual.
    final String? miEstado;
    if (!widget.globalStats) {
      miEstado = referencia?.estado;
    } else if (usuarioActual != null) {
      final normalizado = usuarioActual!.trim().toLowerCase();
      final enRegistros = registros
          .where((r) => r.usuario.trim().toLowerCase() == normalizado)
          .firstOrNull;
      if (enRegistros != null) {
        miEstado = enRegistros.estado;
      } else {
        final enFinalizados = libro.finalizados
            .where((f) => f.usuario.trim().toLowerCase() == normalizado)
            .firstOrNull;
        miEstado = enFinalizados != null ? 'FINALIZADO' : null;
      }
    } else {
      miEstado = null;
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _cerrarAtmosferaDelLibro();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _volver,
          ),
          title: Text(
            libro.libro,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (libro.bookId.isNotEmpty) ...[
              // ── Corazón de favorito ───────────────────────────────────────
              ListenableBuilder(
                listenable: FavoritosService.instance,
                builder: (context, _) {
                  final esFavorito = FavoritosService.instance.isFavorito(
                    libro.bookId,
                  );
                  return IconButton(
                    tooltip: esFavorito
                        ? 'Quitar de favoritos'
                        : 'Añadir a favoritos',
                    onPressed: _toggling ? null : _toggleFavorito,
                    icon: _toggling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            esFavorito
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: esFavorito ? const Color(0xFFD4537E) : null,
                          ),
                  );
                },
              ),
              // ── Editar ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                    onPressed: _editarLibro,
                  ),
                ),
              ),
            ],
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 32,
            ),
            children: [
              LibroHeader(
                libro: libro,
                referencia: referencia,
                heroTag: widget.heroTag,
                onAbrirGoodreads: _abrirGoodreads,
                globalStats: widget.globalStats,
                miEstado: miEstado,
              ),

              // Banner de sugerencia: anima a completar la ficha del libro
              // Aparece cuando el libro tiene bookId (se puede editar) y le falta portada o género
              if (libro.bookId.isNotEmpty &&
                  (libro.coverUrl.isEmpty ||
                      libro.genero.isEmpty ||
                      libro.genero.trim().toLowerCase() == 'sin género')) ...[
                const SizedBox(height: AppSpacing.md),
                ScreenHintBanner(
                  featureKey: 'hint_editar_ficha_v1',
                  titulo: '¿Le falta información a este libro?',
                  tips: const [
                    ScreenHintTip(
                      '🖊️',
                      'Pulsa "Editar" para añadir portada, género, enlace a Goodreads y más.',
                    ),
                    ScreenHintTip(
                      '📸',
                      'Si importaste desde Goodreads u otra app, la info puede venir incompleta: ¡complétala tú!',
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Kit de lectura: solo tiene sentido si el usuario tiene el libro
              // en su biblioteca. En vista global sin estado propio, se omite.
              if (!widget.globalStats || miEstado != null) ...[
                // Feature 2: banner de atmósfera activa cuando está configurada
                if (_kitSeleccion.tieneAtmosfera) ...[
                  _AtmosferaBanner(seleccion: _kitSeleccion),
                  const SizedBox(height: AppSpacing.sm),
                ],
                KitLecturaCard(
                  bookId: libro.bookId,
                  onTap: () => _abrirKitLectura(
                    finalizado: miEstado == 'FINALIZADO',
                    valoracion: _parseStarsCount(referencia?.valoracion),
                  ),
                ),
              ],

              // ── Sección de lectores / estadísticas ────────────────────────
              if (widget.globalStats) ...[
                // Vista global: estadísticas anónimas sin nombres ni fotos
                const SizedBox(height: AppSpacing.lg),
                _EstadisticasGlobalesSection(libro: libro),
              ] else if (registros.isNotEmpty) ...[
                // Vista de club: tarjetas de cada lector con controles
                const SizedBox(height: AppSpacing.lg),
                LibroInteresadasSection(
                  registros: registros,
                  usuariosConFinalizacion: libro.finalizados
                      .map(
                        (finalizado) => finalizado.usuario.trim().toLowerCase(),
                      )
                      .where((usuario) => usuario.isNotEmpty)
                      .toSet(),
                  usuarioActual: usuarioActual,
                  onCambiarEstado: _cambiarEstado,
                  onQuitarPendientes: _quitarPendientes,
                  onActualizarPreferencias: _actualizarPreferencias,
                  onPedirValoracion: (registro) {
                    return FinalizarLibroDialog.show(
                      context,
                      fechaInicioActual: registro.startedAt,
                      formatoActual: registro.formato,
                    );
                  },
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              ConversacionesLibroCard(
                libro: libro.libro,
                coverUrl: libro.coverUrl,
              ),

              // En vista global las valoraciones ya están integradas en
              // _EstadisticasGlobalesSection; solo mostramos aquí en modo club.
              if (!widget.globalStats && libro.finalizados.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),

                LibroValoracionesSection(
                  valoraciones: libro.finalizados,
                  mediaValoracion: libro.mediaValoracion,
                ),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cerrarAtmosferaDelLibro();
    super.dispose();
  }
}

// ─── Estadísticas globales anónimas ────────────────────────────────────────────
//
// Muestra media de valoración, número de personas que lo tienen en biblioteca
// y número de lecturas finalizadas, más una gráfica de barras con la
// distribución de puntuaciones. No expone nombres ni fotos de ningún usuario.

class _EstadisticasGlobalesSection extends StatelessWidget {
  const _EstadisticasGlobalesSection({required this.libro});

  final LibroAgrupado libro;

  /// Convierte la cadena de valoración a double (misma lógica que LibroAgrupado).
  static double _parseRating(String valoracion) {
    final texto = valoracion.trim().replaceAll('⭐️', '⭐').replaceAll(',', '.');
    if (texto.isEmpty || texto == '😞') return 0;
    final num = double.tryParse(texto);
    if (num != null) return ((num.clamp(0, 5)) * 2).round() / 2;
    final stars = RegExp('⭐').allMatches(texto).length;
    final half = texto.contains('½');
    return (((stars + (half ? 0.5 : 0)).clamp(0, 5)) * 2).round() / 2;
  }

  @override
  Widget build(BuildContext context) {
    final media = libro.mediaValoracion;
    final totalBiblioteca = libro.registros.length;
    final totalLeidos = libro.finalizados.length;

    // ── Distribución de puntuaciones ────────────────────────────────────────
    final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final fin in libro.finalizados) {
      final val = _parseRating(fin.valoracion);
      if (val > 0) {
        final rounded = val.round().clamp(1, 5);
        counts[rounded] = (counts[rounded] ?? 0) + 1;
      }
    }
    final maxCount = counts.values.fold(0, math.max);
    final hayPuntuaciones = maxCount > 0;

    // ── Formato de lectura ───────────────────────────────────────────────────
    // Combinamos registros (no finalizados) y finalizados para ver el formato
    // en el que cada persona tiene o leyó el libro.
    final formatCounts = <String, int>{};
    for (final r in libro.registros) {
      final f = r.formato.trim().toUpperCase();
      if (f.isNotEmpty) formatCounts[f] = (formatCounts[f] ?? 0) + 1;
    }
    for (final f in libro.finalizados) {
      final fmt = f.formato.trim().toUpperCase();
      if (fmt.isNotEmpty) formatCounts[fmt] = (formatCounts[fmt] ?? 0) + 1;
    }
    final hayFormatos = formatCounts.isNotEmpty;

    // ── Reflexiones compartidas ──────────────────────────────────────────────
    final conResena = libro.finalizados
        .where((f) => f.resena.trim().isNotEmpty)
        .length;
    final hayResenas = totalLeidos > 0 && conResena > 0;

    return LibroSection(
      icon: Icons.bar_chart_rounded,
      color: AppColors.primary,
      title: 'Estadísticas',
      subtitle: 'Datos globales de la comunidad',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Chips de resumen ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.gold,
                  value: media > 0 ? media.toStringAsFixed(1) : '—',
                  label: 'Valoración\nmedia',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatChip(
                  icon: Icons.bookmark_outline_rounded,
                  iconColor: AppColors.info,
                  value: '$totalBiblioteca',
                  label: 'En\nbiblioteca',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatChip(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppColors.success,
                  value: '$totalLeidos',
                  label: 'Han\nleído',
                ),
              ),
            ],
          ),

          // ── Gráfica de distribución de puntuaciones ──────────────────────
          if (hayPuntuaciones) ...[
            const SizedBox(height: AppSpacing.lg),
            _RatingBarChart(counts: counts, maxCount: maxCount),
          ],

          // ── Formato de lectura ────────────────────────────────────────────
          if (hayFormatos) ...[
            const SizedBox(height: AppSpacing.lg),
            _FormatoSection(formatCounts: formatCounts),
          ],

          // ── Reflexiones compartidas ───────────────────────────────────────
          if (hayResenas) ...[
            const SizedBox(height: AppSpacing.lg),
            _ResenasSection(total: totalLeidos, conResena: conResena),
          ],
        ],
      ),
    );
  }
}

/// Chip de estadística con icono, valor grande y etiqueta pequeña.
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.section.copyWith(
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formato de lectura ────────────────────────────────────────────────────────

class _FormatoSection extends StatelessWidget {
  const _FormatoSection({required this.formatCounts});

  final Map<String, int> formatCounts;

  static const _formatos = [
    (key: 'FISICO',      emoji: '📖', label: 'Físico'),
    (key: 'DIGITAL',     emoji: '📱', label: 'Digital'),
    (key: 'AUDIOLIBRO',  emoji: '🎧', label: 'Audiolibro'),
  ];

  @override
  Widget build(BuildContext context) {
    final total = formatCounts.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formato de lectura',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: .3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: _formatos
                .where((f) => (formatCounts[f.key] ?? 0) > 0)
                .map((f) {
              final count = formatCounts[f.key]!;
              final pct = total > 0 ? (count / total * 100).round() : 0;
              return Expanded(
                flex: count,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _FormatoPill(
                    emoji: f.emoji,
                    label: f.label,
                    count: count,
                    pct: pct,
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

class _FormatoPill extends StatelessWidget {
  const _FormatoPill({
    required this.emoji,
    required this.label,
    required this.count,
    required this.pct,
  });

  final String emoji;
  final String label;
  final int count;
  final int pct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            '$pct%',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          Text(
            count == 1 ? '1 lector' : '$count lectores',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reflexiones compartidas ───────────────────────────────────────────────────

class _ResenasSection extends StatelessWidget {
  const _ResenasSection({required this.total, required this.conResena});

  final int total;
  final int conResena;

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? conResena / total : 0.0;
    final pct = (ratio * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💬', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Reflexiones compartidas',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: .3,
                  ),
                ),
              ),
              Text(
                '$conResena de $total',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: AppColors.border.withValues(alpha: .5),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary.withValues(alpha: .7),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$pct% de los lectores escribió su opinión',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Gráfica de barras horizontal con la distribución de puntuaciones 1-5.
class _RatingBarChart extends StatelessWidget {
  const _RatingBarChart({
    required this.counts,
    required this.maxCount,
  });

  final Map<int, int> counts;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución de puntuaciones',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: .3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (int stars = 5; stars >= 1; stars--) ...[
            _BarRow(
              stars: stars,
              count: counts[stars] ?? 0,
              maxCount: maxCount,
            ),
            if (stars > 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.stars,
    required this.count,
    required this.maxCount,
  });

  final int stars;
  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final ratio = maxCount > 0 ? count / maxCount : 0.0;
    return Row(
      children: [
        // Etiqueta de estrellas
        SizedBox(
          width: 28,
          child: Row(
            children: [
              Text(
                '$stars',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 12),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Barra
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Fondo
                  Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.border.withValues(alpha: .5),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  // Relleno
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    height: 18,
                    width: constraints.maxWidth * ratio,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: .75),
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Contador
        SizedBox(
          width: 24,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: count > 0 ? AppColors.textSecondary : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Feature 2: banner de atmósfera en la ficha del libro ──────────────────
class _AtmosferaBanner extends StatelessWidget {
  final KitLecturaSeleccion seleccion;

  const _AtmosferaBanner({required this.seleccion});

  @override
  Widget build(BuildContext context) {
    final icono = seleccion.atmosferaIcono.trim().isEmpty
        ? '✨'
        : seleccion.atmosferaIcono;
    final titulo = seleccion.atmosferaTitulo.trim().isEmpty
        ? 'Atmósfera activa'
        : seleccion.atmosferaTitulo;
    final descripcion = seleccion.atmosferaDescripcion.trim().isEmpty
        ? null
        : seleccion.atmosferaDescripcion;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(icono, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                if (descripcion != null)
                  Text(
                    descripcion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            'Tu atmósfera',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
