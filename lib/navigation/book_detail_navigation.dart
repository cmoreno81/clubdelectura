import 'package:club_lectura_app/services/usuario_service.dart';
import 'package:flutter/material.dart';

import '../models/libro.dart';
import '../models/libro_agrupado.dart';
import '../models/libro_finalizado.dart';
import '../pages/detalle_libro_page.dart';
import '../pages/catalog_book_detail_page.dart';
import '../services/api_service.dart';
import '../services/libros_data_cache.dart';
import 'book_detail_page_route.dart';

// ── Modelo mínimo de la respuesta de libroPorId ───────────────────────────────

class _LibroPorIdData {
  final List<Libro> libros;
  final List<LibroFinalizado> finalizados;

  const _LibroPorIdData({required this.libros, required this.finalizados});
}

// ── Fetch del nuevo endpoint rápido ──────────────────────────────────────────

Future<_LibroPorIdData?> _fetchLibroPorId(String bookId) async {
  try {
    final data = await ApiService().getLibroPorId(bookId);
    if (data['ok'] != true) return null;

    final libros = (data['libros'] as List? ?? [])
        .map((e) => Libro.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final finalizados = (data['finalizados'] as List? ?? [])
        .map(
          (e) => LibroFinalizado.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    return _LibroPorIdData(libros: libros, finalizados: finalizados);
  } catch (_) {
    return null;
  }
}

// ── Helpers compartidos ───────────────────────────────────────────────────────

String _resolvedCover(
  String coverUrl,
  List<Libro> registros,
  List<LibroFinalizado> finalizados,
) {
  if (coverUrl.isNotEmpty) return coverUrl;
  if (registros.isNotEmpty) return registros.first.coverUrl;
  if (finalizados.isNotEmpty) return finalizados.first.coverUrl;
  return '';
}

String _resolvedGenre(
  String genre,
  List<Libro> registros,
  List<LibroFinalizado> finalizados,
) {
  if (genre.isNotEmpty) return genre;
  if (registros.isNotEmpty) return registros.first.genero;
  if (finalizados.isNotEmpty) return finalizados.first.genero;
  return '';
}

// ── openBookDetail ────────────────────────────────────────────────────────────

Future<bool> openBookDetail(
  BuildContext context, {
  required String title,
  String bookId = '',
  String coverUrl = '',
  String genre = '',
}) async {
  final normalizedTitle = title.trim().toLowerCase();
  if (normalizedTitle.isEmpty) return false;

  try {
    List<Libro> registros;
    List<LibroFinalizado> finalizados;

    if (bookId.isNotEmpty) {
      // Ruta rápida: endpoint específico por bookId
      final result = await _fetchLibroPorId(bookId);
      if (!context.mounted) return false;

      if (result == null) {
        // El libro no existe o error → ficha de catálogo
        await Navigator.push<void>(
          context,
          BookDetailPageRoute(
            builder: (_) => CatalogBookDetailPage(
              bookId: bookId,
              title: title,
              coverUrl: coverUrl,
              genre: genre,
            ),
          ),
        );
        return true;
      }
      registros = result.libros;
      finalizados = result.finalizados;
    } else {
      // Fallback sin bookId: usar caché de biblioteca completa
      final data = await LibrosDataCache.instance.get(
        () => ApiService().getLibrosData(),
      );
      if (!context.mounted) return false;

      registros = data.libros
          .where((item) => item.libro.trim().toLowerCase() == normalizedTitle)
          .toList();
      finalizados = data.finalizados
          .where((item) => item.libro.trim().toLowerCase() == normalizedTitle)
          .toList();
    }

    if (registros.isEmpty && finalizados.isEmpty) {
      await Navigator.push<void>(
        context,
        BookDetailPageRoute(
          builder: (_) => CatalogBookDetailPage(
            bookId: bookId,
            title: title,
            coverUrl: coverUrl,
            genre: genre,
          ),
        ),
      );
      return true;
    }

    await Navigator.push<void>(
      context,
      BookDetailPageRoute(
        builder: (_) => DetalleLibroPage(
          libro: LibroAgrupado(
            libro: title,
            genero: _resolvedGenre(genre, registros, finalizados),
            registros: registros,
            finalizados: finalizados,
            yaLoTengo: registros.any((item) => item.yaLoTengo),
            leidoPorMi: finalizados.any((item) => item.yaLoTengo),
            coverUrl: _resolvedCover(coverUrl, registros, finalizados),
          ),
        ),
      ),
    );
    return false;
  } catch (e) {
    debugPrint('openBookDetail error: $e');
    if (!context.mounted) return false;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error: $e')));
    return false;
  }
}

// ── openCatalogBookDetail ─────────────────────────────────────────────────────

Future<bool> openCatalogBookDetail(
  BuildContext context, {
  required String title,
  String bookId = '',
  String coverUrl = '',
  String genre = '',
}) async {
  final normalizedTitle = title.trim().toLowerCase();
  if (normalizedTitle.isEmpty) return false;

  try {
    List<Libro> registros;
    List<LibroFinalizado> finalizados;

    if (bookId.isNotEmpty) {
      // Ruta rápida: endpoint específico por bookId, filtrado por usuaria actual
      final usuarioActual = ((await UsuarioService().obtenerUsuario()) ?? '')
          .trim()
          .toLowerCase();

      final result = await _fetchLibroPorId(bookId);
      if (!context.mounted) return false;

      if (result == null) {
        var changed = false;
        await Navigator.push<void>(
          context,
          BookDetailPageRoute(
            builder: (_) => CatalogBookDetailPage(
              bookId: bookId,
              title: title,
              coverUrl: coverUrl,
              genre: genre,
              onLibraryChanged: () => changed = true,
            ),
          ),
        );
        return changed;
      }

      registros = result.libros
          .where(
            (item) =>
                usuarioActual.isEmpty ||
                item.usuario.trim().toLowerCase() == usuarioActual,
          )
          .toList();
      finalizados = result.finalizados
          .where(
            (item) =>
                usuarioActual.isEmpty ||
                item.usuario.trim().toLowerCase() == usuarioActual,
          )
          .toList();
    } else {
      // Fallback sin bookId
      final usuarioActual = ((await UsuarioService().obtenerUsuario()) ?? '')
          .trim()
          .toLowerCase();

      final data = await LibrosDataCache.instance.get(
        () => ApiService().getLibrosData(),
      );
      if (!context.mounted) return false;

      registros = data.libros
          .where(
            (item) =>
                item.libro.trim().toLowerCase() == normalizedTitle &&
                (usuarioActual.isEmpty ||
                    item.usuario.trim().toLowerCase() == usuarioActual),
          )
          .toList();
      finalizados = data.finalizados
          .where(
            (item) =>
                item.libro.trim().toLowerCase() == normalizedTitle &&
                (usuarioActual.isEmpty ||
                    item.usuario.trim().toLowerCase() == usuarioActual),
          )
          .toList();
    }

    if (registros.isEmpty && finalizados.isEmpty) {
      var changed = false;
      await Navigator.push<void>(
        context,
        BookDetailPageRoute(
          builder: (_) => CatalogBookDetailPage(
            bookId: bookId,
            title: title,
            coverUrl: coverUrl,
            genre: genre,
            onLibraryChanged: () => changed = true,
          ),
        ),
      );
      return changed;
    }

    await Navigator.push<void>(
      context,
      BookDetailPageRoute(
        builder: (_) => DetalleLibroPage(
          libro: LibroAgrupado(
            libro: title,
            genero: _resolvedGenre(genre, registros, finalizados),
            registros: registros,
            finalizados: finalizados,
            yaLoTengo: registros.any((item) => item.yaLoTengo),
            leidoPorMi: finalizados.any((item) => item.yaLoTengo),
            coverUrl: _resolvedCover(coverUrl, registros, finalizados),
          ),
        ),
      ),
    );
    return false;
  } catch (_) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se ha podido abrir la ficha del libro.'),
      ),
    );
    return false;
  }
}
