import 'package:club_lectura_app/services/usuario_service.dart';
import 'package:flutter/material.dart';

import '../models/libro.dart';
import '../models/libro_agrupado.dart';
import '../models/libro_finalizado.dart';
import '../pages/catalog_book_detail_page.dart';
import '../pages/detalle_libro_page.dart';
import '../services/api_service.dart';
import '../services/libros_data_cache.dart';
import 'book_detail_page_route.dart';

// ── Modelo de respuesta de libroPorId (público para inyección en tests) ────────

class LibroPorIdData {
  final List<Libro> libros;
  final List<LibroFinalizado> finalizados;

  const LibroPorIdData({required this.libros, required this.finalizados});
}

// ── Fetch del nuevo endpoint rápido ──────────────────────────────────────────

Future<LibroPorIdData?> _fetchLibroPorId(String bookId) async =>
    _fetchLibroPorIdInternal(bookId, global: false);

Future<LibroPorIdData?> _fetchLibroPorIdGlobal(String bookId) async =>
    _fetchLibroPorIdInternal(bookId, global: true);

Future<LibroPorIdData?> _fetchLibroPorIdInternal(
  String bookId, {
  required bool global,
}) async {
  try {
    final data = await ApiService().getLibroPorId(bookId, global: global);
    if (data['ok'] != true) return null;

    final libros = (data['libros'] as List? ?? [])
        .map((e) => Libro.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final finalizados = (data['finalizados'] as List? ?? [])
        .map(
          (e) => LibroFinalizado.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();

    return LibroPorIdData(libros: libros, finalizados: finalizados);
  } catch (_) {
    return null;
  }
}

/// Tipo de la función de fetch inyectable para tests.
@visibleForTesting
typedef FetchLibroPorId = Future<LibroPorIdData?> Function(String bookId);

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
  @visibleForTesting FetchLibroPorId? fetchForTesting,
}) async {
  final fetch = fetchForTesting ?? _fetchLibroPorId;
  final normalizedTitle = title.trim().toLowerCase();
  if (normalizedTitle.isEmpty) return false;

  try {
    List<Libro> registros;
    List<LibroFinalizado> finalizados;

    if (bookId.isNotEmpty) {
      // Ruta rápida: endpoint específico por bookId
      final result = await fetch(bookId);
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
        return false;
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
      return false;
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
//
// [forceFullDetail] = false (por defecto, tap simple):
//   Si el libro no está en la biblioteca del usuario, abre CatalogBookDetailPage
//   con "Añadir a mi biblioteca". Si ya lo tiene, abre DetalleLibroPage.
//
// [forceFullDetail] = true (pulsación larga → "Ver ficha completa"):
//   Siempre abre DetalleLibroPage con todos los datos disponibles.
//
// [globalStats] = false (por defecto, contexto de club):
//   Filtra registros/finalizados al usuario actual → stats del propio usuario.
//
// [globalStats] = true (dashboard global, fuera de un club):
//   Usa TODOS los registros/finalizados para los contadores y la valoración media.
//   Los flags personales (yaLoTengo, leidoPorMi) siguen calculándose solo con
//   los datos del usuario actual. La sección "Lectores interesados" muestra a
//   todos los lectores pero solo permite editar el registro propio.

Future<bool> openCatalogBookDetail(
  BuildContext context, {
  required String title,
  String bookId = '',
  String coverUrl = '',
  String genre = '',
  bool forceFullDetail = false,
  bool globalStats = false,
  @visibleForTesting FetchLibroPorId? fetchForTesting,
  @visibleForTesting String? usuarioActualForTesting,
}) async {
  // Cuando globalStats=true usamos el fetch global (sin filtro de club)
  final fetch = fetchForTesting ?? (globalStats ? _fetchLibroPorIdGlobal : _fetchLibroPorId);
  final normalizedTitle = title.trim().toLowerCase();
  if (normalizedTitle.isEmpty) return false;

  try {
    List<Libro> registros;
    List<LibroFinalizado> finalizados;

    if (bookId.isNotEmpty) {
      // Ruta rápida: endpoint específico por bookId
      final usuarioActual = usuarioActualForTesting ??
          ((await UsuarioService().obtenerUsuario()) ?? '').trim().toLowerCase();

      final result = await fetch(bookId);
      if (!context.mounted) return false;

      if (result == null) {
        // Libro no encontrado en servidor
        if (forceFullDetail) {
          // Pulsación larga → ficha completa aunque no haya datos de biblioteca
          await Navigator.push<void>(
            context,
            BookDetailPageRoute(
              builder: (_) => DetalleLibroPage(
                libro: LibroAgrupado(
                  libro: title,
                  genero: genre,
                  registros: const [],
                  finalizados: const [],
                  yaLoTengo: false,
                  coverUrl: coverUrl,
                  bookId: bookId,
                ),
              ),
            ),
          );
          return true;
        } else {
          // Tap simple → ficha de catálogo con "Añadir a mi biblioteca"
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
      }

      if (globalStats) {
        // Dashboard global: stats de todos los usuarios.
        // Se pasan todos los registros/finalizados para contadores y valoración,
        // pero yaLoTengo/leidoPorMi se calculan solo del usuario actual.
        registros = result.libros;
        finalizados = result.finalizados;
      } else {
        // Contexto de club: filtrar al usuario actual.
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
      }

      // Flags personales siempre del usuario actual
      final misRegistros = globalStats
          ? result.libros
              .where(
                (item) =>
                    usuarioActual.isEmpty ||
                    item.usuario.trim().toLowerCase() == usuarioActual,
              )
              .toList()
          : registros;
      final misFinalizados = globalStats
          ? result.finalizados
              .where(
                (item) =>
                    usuarioActual.isEmpty ||
                    item.usuario.trim().toLowerCase() == usuarioActual,
              )
              .toList()
          : finalizados;

      // Si en modo filtrado el usuario no tiene el libro → CatalogBookDetailPage
      if (!globalStats && registros.isEmpty && finalizados.isEmpty) {
        if (forceFullDetail) {
          await Navigator.push<void>(
            context,
            BookDetailPageRoute(
              builder: (_) => DetalleLibroPage(
                libro: LibroAgrupado(
                  libro: title,
                  genero: genre,
                  registros: const [],
                  finalizados: const [],
                  yaLoTengo: false,
                  coverUrl: coverUrl,
                  bookId: bookId,
                ),
              ),
            ),
          );
          return true;
        } else {
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
      }

      // En modo globalStats con forceFullDetail, siempre DetalleLibroPage
      if (globalStats && forceFullDetail) {
        await Navigator.push<void>(
          context,
          BookDetailPageRoute(
            builder: (_) => DetalleLibroPage(
              libro: LibroAgrupado(
                libro: title,
                genero: _resolvedGenre(genre, registros, finalizados),
                registros: registros,
                finalizados: finalizados,
                yaLoTengo: misRegistros.any((item) => item.yaLoTengo),
                leidoPorMi: misFinalizados.any((item) => item.yaLoTengo),
                coverUrl: _resolvedCover(coverUrl, registros, finalizados),
                bookId: bookId,
              ),
            ),
          ),
        );
        return true;
      }

      // En modo globalStats con tap simple → CatalogBookDetailPage si el usuario
      // no tiene el libro; DetalleLibroPage si ya lo tiene.
      if (globalStats && !forceFullDetail) {
        if (misRegistros.isEmpty && misFinalizados.isEmpty) {
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
        // Usuario tiene el libro → ficha completa con stats globales
        await Navigator.push<void>(
          context,
          BookDetailPageRoute(
            builder: (_) => DetalleLibroPage(
              libro: LibroAgrupado(
                libro: title,
                genero: _resolvedGenre(genre, registros, finalizados),
                registros: registros,
                finalizados: finalizados,
                yaLoTengo: misRegistros.any((item) => item.yaLoTengo),
                leidoPorMi: misFinalizados.any((item) => item.yaLoTengo),
                coverUrl: _resolvedCover(coverUrl, registros, finalizados),
                bookId: bookId,
              ),
            ),
          ),
        );
        return true;
      }

      // Modo club, usuario tiene el libro → ficha completa
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
              bookId: bookId,
            ),
          ),
        ),
      );
      return true;
    } else {
      // Fallback sin bookId
      final usuarioActual = usuarioActualForTesting ??
          ((await UsuarioService().obtenerUsuario()) ?? '').trim().toLowerCase();

      final data = await LibrosDataCache.instance.get(
        () => ApiService().getLibrosData(),
      );
      if (!context.mounted) return false;

      if (globalStats) {
        registros = data.libros
            .where(
              (item) => item.libro.trim().toLowerCase() == normalizedTitle,
            )
            .toList();
        finalizados = data.finalizados
            .where(
              (item) => item.libro.trim().toLowerCase() == normalizedTitle,
            )
            .toList();
      } else {
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

      final misRegistros = globalStats
          ? registros
              .where(
                (item) =>
                    usuarioActual.isEmpty ||
                    item.usuario.trim().toLowerCase() == usuarioActual,
              )
              .toList()
          : registros;
      final misFinalizados = globalStats
          ? finalizados
              .where(
                (item) =>
                    usuarioActual.isEmpty ||
                    item.usuario.trim().toLowerCase() == usuarioActual,
              )
              .toList()
          : finalizados;

      // Si el usuario no tiene el libro en su biblioteca
      if (misRegistros.isEmpty && misFinalizados.isEmpty) {
        if (forceFullDetail) {
          await Navigator.push<void>(
            context,
            BookDetailPageRoute(
              builder: (_) => DetalleLibroPage(
                libro: LibroAgrupado(
                  libro: title,
                  genero: genre,
                  registros: globalStats ? registros : const [],
                  finalizados: globalStats ? finalizados : const [],
                  yaLoTengo: false,
                  coverUrl: coverUrl,
                  bookId: bookId,
                ),
              ),
            ),
          );
          return true;
        } else {
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
      }

      // El usuario ya tiene el libro → ficha completa con stats adecuados
      await Navigator.push<void>(
        context,
        BookDetailPageRoute(
          builder: (_) => DetalleLibroPage(
            libro: LibroAgrupado(
              libro: title,
              genero: _resolvedGenre(genre, registros, finalizados),
              registros: registros,
              finalizados: finalizados,
              yaLoTengo: misRegistros.any((item) => item.yaLoTengo),
              leidoPorMi: misFinalizados.any((item) => item.yaLoTengo),
              coverUrl: _resolvedCover(coverUrl, registros, finalizados),
              bookId: bookId,
            ),
          ),
        ),
      );
      return true;
    }
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
