import 'package:flutter/material.dart';

import '../../models/libro.dart';
import '../../models/libro_agrupado.dart';
import '../../services/api_service.dart';
import '../../services/library_refresh_notifier.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_colors.dart';
import '../common/libro_finalizado_celebration.dart';
import 'finalizar_libro_dialog.dart';
import 'add_book_sheet.dart';
import 'libro_acciones_sheet.dart';
import 'pausar_lectura_dialog.dart';

typedef AbrirFichaLibro = Future<void> Function(LibroAgrupado libro);

Future<bool> mostrarAccionesRapidasLibro(
  BuildContext context, {
  required String bookId,
  required String titulo,
  required String autor,
  required String genero,
  required String coverUrl,
  required AbrirFichaLibro abrirFicha,
}) async {
  final libro = await _resolverLibro(
    bookId: bookId,
    titulo: titulo,
    autor: autor,
    genero: genero,
    coverUrl: coverUrl,
  );
  if (!context.mounted) return false;
  final accion = await mostrarLibroAccionesSheet(context, libro);
  if (!context.mounted || accion == null) return false;
  if (accion == LibroAccion.verFicha) {
    await abrirFicha(libro);
    return false;
  }

  final usuario = await UsuarioService().obtenerUsuario();
  if (!context.mounted || usuario == null || usuario.trim().isEmpty) {
    return false;
  }

  var ok = false;
  switch (accion) {
    case LibroAccion.anadir:
      final referencia = libro.referencia;
      final preferencias = await showAddBookSheet(
        context,
        title: libro.libro,
        author: referencia?.autor ?? '',
        coverUrl: libro.coverUrl,
      );
      if (preferencias == null || !context.mounted) return false;
      final respuesta = await ApiService().anadirLibroExistente(
        usuario: usuario,
        libro: libro.libro,
        prioridad: preferencias.priority,
        formato: preferencias.format,
      );
      ok = respuesta['ok'] == true;
    case LibroAccion.empezar:
      ok = await ApiService().iniciarLectura(
        usuario: usuario,
        libro: libro.libro,
      );
    case LibroAccion.reanudar:
      ok = await ApiService().actualizarEstado(
        usuario: usuario,
        libro: libro.libro,
        estado: 'LEYENDO',
      );
    case LibroAccion.pausar:
      final motivo = await showDialog<String>(
        context: context,
        builder: (_) => const PausarLecturaDialog(),
      );
      if (motivo == null || !context.mounted) return false;
      ok = await ApiService().actualizarEstado(
        usuario: usuario,
        libro: libro.libro,
        estado: 'PAUSADO',
        motivoPausa: motivo.isEmpty ? null : motivo,
      );
    case LibroAccion.finalizar:
      final resultado = await showDialog<Map<String, String>>(
        context: context,
        builder: (_) => const FinalizarLibroDialog(),
      );
      if (resultado == null || !context.mounted) return false;
      ok = await ApiService().actualizarEstado(
        usuario: usuario,
        libro: libro.libro,
        estado: 'FINALIZADO',
        valoracion: resultado['valoracion'],
        reflexion: resultado['reflexion'],
        fechaInicio: resultado['fechaInicio'],
        fechaFin: resultado['fechaFin'],
        formato: resultado['formato'],
      );
    case LibroAccion.releer:
      ok = await ApiService().actualizarEstado(
        usuario: usuario,
        libro: libro.libro,
        estado: 'RELECTURA',
      );
    case LibroAccion.quitar:
      final confirmado = await _confirmarQuitar(context, libro.libro);
      if (!confirmado || !context.mounted) return false;
      final respuesta = await ApiService().quitarLibroPendientes(
        usuario: usuario,
        libro: libro.libro,
      );
      ok = respuesta['ok'] == true;
    case LibroAccion.editarFechaInicio:
      final registroActivo = libro.registros
          .where((r) => r.yaLoTengo)
          .firstOrNull;
      final fechaActual = registroActivo?.startedAt ?? DateTime.now();
      final nuevaFecha = await showDatePicker(
        context: context,
        initialDate: fechaActual.isAfter(DateTime.now())
            ? DateTime.now()
            : fechaActual,
        firstDate: DateTime(1950),
        lastDate: DateTime.now(),
        helpText: 'Fecha en que empezaste a leer',
        confirmText: 'Guardar',
        cancelText: 'Cancelar',
      );
      if (nuevaFecha == null || !context.mounted) return false;
      ok = await ApiService().editarFechaInicioLectura(
        usuario: usuario,
        libro: libro.libro,
        fechaInicio: nuevaFecha,
      );
    case LibroAccion.verFicha:
      break;
  }

  if (!context.mounted) return false;

  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se ha podido actualizar')),
    );
    return false;
  }

  LibraryRefreshNotifier.instance.invalidate();

  // Celebración solo cuando se finaliza un libro
  if (accion == LibroAccion.finalizar && context.mounted) {
    await mostrarCelebracionFinalizado(
      context,
      titulo: libro.libro,
      coverUrl: libro.coverUrl,
    );
  } else if (accion == LibroAccion.editarFechaInicio && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fecha de inicio actualizada')),
    );
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Biblioteca actualizada')),
    );
  }

  return ok;
}

Future<LibroAgrupado> _resolverLibro({
  required String bookId,
  required String titulo,
  required String autor,
  required String genero,
  required String coverUrl,
}) async {
  final data = await ApiService().getLibrosData();
  bool coincide(String id, String nombre) =>
      (bookId.trim().isNotEmpty && id.trim() == bookId.trim()) ||
      nombre.trim().toLowerCase() == titulo.trim().toLowerCase();
  final registros = data.libros
      .where((item) => coincide(item.bookId, item.libro))
      .toList();
  final finalizados = data.finalizados
      .where((item) => coincide(item.bookId, item.libro))
      .toList();
  final propioFinalizado = finalizados.any((item) => item.yaLoTengo);
  final propios = registros.any((item) => item.yaLoTengo);
  final referencia = registros.firstOrNull;
  final terminado = finalizados.firstOrNull;
  if (registros.isEmpty && finalizados.isEmpty) {
    registros.add(
      Libro.fromJson({
        'bookId': bookId,
        'libro': titulo,
        'autor': autor,
        'genero': genero,
        'coverUrl': coverUrl,
        'yaLoTengo': false,
      }),
    );
  }
  String valorVisible(String? principal, String respaldo) =>
      principal?.trim().isNotEmpty == true ? principal! : respaldo;
  return LibroAgrupado(
    libro: referencia?.libro ?? terminado?.libro ?? titulo,
    genero: valorVisible(referencia?.genero ?? terminado?.genero, genero),
    registros: registros,
    finalizados: finalizados,
    yaLoTengo: propios || propioFinalizado,
    leidoPorMi: propioFinalizado,
    coverUrl: valorVisible(
      referencia?.coverUrl ?? terminado?.coverUrl,
      coverUrl,
    ),
  );
}

Future<bool> _confirmarQuitar(BuildContext context, String titulo) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Quitar de pendientes?'),
        content: Text('«$titulo» se eliminará de tu lista de pendientes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    ) ??
    false;
