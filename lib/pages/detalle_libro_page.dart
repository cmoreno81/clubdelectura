import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/libro.dart';
import '../models/libro_agrupado.dart';
import '../services/api_service.dart';
import '../services/atmosfera_controller.dart';
import '../services/atmosfera_scope.dart';
import '../services/kit_lectura_service.dart';
import '../services/usuario_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/libros/conversaciones_libro_card.dart';
import '../widgets/libros/finalizar_libro_dialog.dart';
import '../widgets/libros/kit_lectura_card.dart';
import '../widgets/libros/libro_header.dart';
import '../widgets/libros/libro_interesadas_section.dart';
import '../widgets/libros/libro_valoraciones_section.dart';
import 'kit_lectura_page.dart';
import 'nuevo_libro_page.dart';

class DetalleLibroPage extends StatefulWidget {
  final LibroAgrupado libro;

  const DetalleLibroPage({super.key, required this.libro});

  @override
  State<DetalleLibroPage> createState() => _DetalleLibroPageState();
}

class _DetalleLibroPageState extends State<DetalleLibroPage> {
  final KitLecturaService _kitService = KitLecturaService();
  late LibroAgrupado libro;
  late List<Libro> registros;
  late AtmosferaController _atmosferaController;

  String? usuarioActual;

  bool _controllerPreparado = false;
  bool _atmosferaCerrada = false;

  @override
  void initState() {
    super.initState();

    libro = widget.libro;

    registros = List<Libro>.from(libro.registros);

    _cargarUsuarioActual();

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
        );
      }

      if (!ok) {
        throw Exception('No se ha podido guardar el estado');
      }

      if (!mounted) return;

      final index = registros.indexOf(libro);

      if (index == -1) {
        throw Exception('No se ha encontrado el registro del libro');
      }

      setState(() {
        registros[index] = libro.copyWith(
          estado: nuevoEstado,
          valoracion: valoracion ?? libro.valoracion,
        );
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Estado actualizado')));
    } catch (error) {
      if (!mounted) return;

      final mensaje = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $mensaje')));
    }
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
      _cerrarAtmosferaDelLibro();

      if (!mounted) return;

      Navigator.pop(context, true);
    }
  }

  Future<void> _abrirGoodreads() async {
    if (libro.registros.isEmpty) return;

    var url = libro.registros.first.goodreads.trim();

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

  Future<void> _editarLibro() async {
    if (libro.bookId.isEmpty) return;

    final actualizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NuevoLibroPage(libro: libro)),
    );

    if (!mounted) return;

    if (actualizado == true) {
      _cerrarAtmosferaDelLibro();

      if (!mounted) return;

      Navigator.pop(context, true);
    }
  }

  Future<void> _abrirKitLectura() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KitLecturaPage(
          bookId: libro.bookId,
          libro: libro.libro,
          coverUrl: libro.coverUrl,
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
            if (libro.bookId.isNotEmpty)
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
                onAbrirGoodreads: _abrirGoodreads,
              ),

              const SizedBox(height: AppSpacing.lg),

              KitLecturaCard(onTap: _abrirKitLectura),

              if (registros.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),

                LibroInteresadasSection(
                  registros: registros,
                  usuarioActual: usuarioActual,
                  onCambiarEstado: _cambiarEstado,
                  onQuitarPendientes: _quitarPendientes,
                  onPedirValoracion: () {
                    return showDialog<Map<String, String>>(
                      context: context,
                      builder: (_) => const FinalizarLibroDialog(),
                    );
                  },
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              ConversacionesLibroCard(
                libro: libro.libro,
                coverUrl: libro.coverUrl,
              ),

              if (libro.finalizados.isNotEmpty) ...[
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
