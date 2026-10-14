import 'package:flutter/material.dart';

import '../../models/amistad.dart';
import '../../models/reaccion_comentario.dart';
import '../../services/amistades_cambios.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_avatar.dart';
import 'aviso_en_hoja.dart';

/// Abre los comentarios de una lectura (la tuya o la de una amistad).
Future<void> mostrarComentariosProgreso(
  BuildContext context, {
  required String libraryId,
  required String titulo,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) =>
        ComentariosProgresoSheet(libraryId: libraryId, titulo: titulo),
  );
}

class ComentariosProgresoSheet extends StatefulWidget {
  const ComentariosProgresoSheet({
    super.key,
    required this.libraryId,
    required this.titulo,
    this.cargar,
    this.enviar,
    this.borrar,
    this.reportar,
    this.bloquear,
  });

  final String libraryId;
  final String titulo;

  /// Para pruebas: sustituyen las llamadas al servidor.
  final Future<ComentariosProgresoData> Function(String libraryId)? cargar;
  final Future<ResultadoAmistad> Function(String libraryId, String texto)?
  enviar;
  final Future<ResultadoAmistad> Function(String id)? borrar;
  final Future<bool> Function(String id, String motivo)? reportar;
  final Future<bool> Function(String nombre)? bloquear;

  @override
  State<ComentariosProgresoSheet> createState() =>
      _ComentariosProgresoSheetState();
}

class _ComentariosProgresoSheetState extends State<ComentariosProgresoSheet>
    with AvisoEnHojaState<ComentariosProgresoSheet> {
  final _texto = TextEditingController();
  ComentariosProgresoData? _data;
  String _error = '';
  bool _cargando = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    cancelarAviso();
    _texto.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final data = await (widget.cargar ?? ApiService().getComentariosProgreso)(
        widget.libraryId,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = '';
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se han podido cargar los comentarios.';
        _cargando = false;
      });
    }
  }

  // Dentro de la hoja (un SnackBar saldría por detrás y no se vería).
  void _aviso(String texto) => avisar(texto);

  Future<void> _enviar() async {
    final texto = _texto.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    final r = await (widget.enviar ?? ApiService().comentarProgreso)(
      widget.libraryId,
      texto,
    );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (!r.ok) {
      _aviso(
        r.mensaje.isEmpty
            ? 'No se ha podido enviar. Inténtalo de nuevo.'
            : r.mensaje,
      );
      return;
    }
    _texto.clear();
    await _cargar();
  }

  Future<void> _borrar(ComentarioProgreso c) async {
    final r = await (widget.borrar ?? ApiService().borrarComentarioProgreso)(
      c.id,
    );
    if (!mounted) return;
    if (!r.ok) {
      _aviso(r.mensaje.isEmpty ? 'No se ha podido borrar.' : r.mensaje);
      return;
    }
    await _cargar();
  }

  Future<void> _reportar(ComentarioProgreso c) async {
    final motivo = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reportar comentario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cuéntanos brevemente qué pasa con este comentario.'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: motivo,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Motivo (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
    // El controlador no se libera aquí: el diálogo aún se está cerrando.
    final textoMotivo = motivo.text.trim();
    if (confirmar != true || !mounted) return;
    final ok = widget.reportar != null
        ? await widget.reportar!(c.id, textoMotivo)
        : await ApiService().reportarContenido(
            tipo: 'comentarioProgreso',
            id: c.id,
            motivo: textoMotivo,
          );
    if (!mounted) return;
    _aviso(
      ok
          ? 'Gracias, lo revisaremos en breve.'
          : 'No se pudo enviar el reporte, inténtalo de nuevo.',
    );
  }

  Future<void> _bloquear(ComentarioProgreso c) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Bloquear a esta persona?'),
        content: Text(
          'Dejarás de ver sus comentarios y ya no seréis amigos. Puedes '
          'deshacerlo desde Perfil → Más → Cuentas bloqueadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final ok =
        await (widget.bloquear ??
            (n) => ApiService().bloquearUsuario(nombre: n))(c.autor);
    if (!mounted) return;
    if (!ok) {
      _aviso('No se pudo bloquear, inténtalo de nuevo.');
      return;
    }
    AmistadesCambios.avisar();
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Has bloqueado a ${c.autor}.')));
  }

  /// Reacciones a la lectura. Quien lee ve quién ha reaccionado; el resto, el recuento.
  Widget _reacciones() {
    final data = _data;
    if (data == null) return const SizedBox.shrink();
    final total = data.reacciones.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    final detalle = data.soyDuena && data.reaccionesDe.isNotEmpty
        ? data.reaccionesDe
              .map((r) => '${r.reaccion?.emoji ?? ''} ${r.nombre}'.trim())
              .join(' · ')
        : [
            for (final e in data.reacciones.entries)
              if (e.value > 0) '${e.key.emoji} ${e.value}',
          ].join('  ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text('Reacciones: $detalle', style: AppTextStyles.bodySecondary),
    );
  }

  Widget _comentario(ComentarioProgreso c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClubAvatar(nombre: c.autor, imageUrl: c.avatarUrl, size: 34),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.esMio ? '${c.autor} (tú)' : c.autor,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(c.texto, style: AppTextStyles.body),
              ],
            ),
          ),
          if (c.puedoBorrar || !c.esMio)
            PopupMenuButton<String>(
              tooltip: 'Más opciones',
              icon: const Icon(Icons.more_horiz_rounded, size: 20),
              onSelected: (accion) {
                switch (accion) {
                  case 'borrar':
                    _borrar(c);
                  case 'reportar':
                    _reportar(c);
                  case 'bloquear':
                    _bloquear(c);
                }
              },
              itemBuilder: (_) => [
                if (c.puedoBorrar)
                  const PopupMenuItem(value: 'borrar', child: Text('Borrar')),
                if (!c.esMio) ...const [
                  PopupMenuItem(value: 'reportar', child: Text('Reportar')),
                  PopupMenuItem(value: 'bloquear', child: Text('Bloquear')),
                ],
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comentarios = _data?.comentarios ?? const <ComentarioProgreso>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comentarios',
            style: AppTextStyles.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(widget.titulo, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          AvisoEnHoja(texto: avisoTexto),
          _reacciones(),
          Flexible(
            child: _cargando
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error, style: AppTextStyles.bodySecondary),
                  )
                : comentarios.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Todavía no hay comentarios. ¡Anima con el primero! 💜',
                      style: AppTextStyles.bodySecondary,
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [for (final c in comentarios) _comentario(c)],
                  ),
          ),
          if (_error.isEmpty && !_cargando)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _texto,
                    maxLength: 300,
                    minLines: 1,
                    maxLines: 3,
                    enabled: !_enviando,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un comentario…',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Enviar',
                  onPressed: _enviando ? null : _enviar,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
