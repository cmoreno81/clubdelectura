import 'package:club_lectura_app/services/usuario_service.dart';
import 'package:flutter/material.dart';

import '../models/libro_agrupado.dart';
import '../pages/detalle_libro_page.dart';
import '../pages/catalog_book_detail_page.dart'; // ← nueva página
import '../services/api_service.dart';
import 'app_page_route.dart';

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
    final data = await ApiService().getLibrosData();
    if (!context.mounted) return false;

    final registros = data.libros
        .where(
          (item) =>
              (bookId.isNotEmpty && item.bookId == bookId) ||
              item.libro.trim().toLowerCase() == normalizedTitle,
        )
        .toList();
    final finalizados = data.finalizados
        .where(
          (item) =>
              (bookId.isNotEmpty && item.bookId == bookId) ||
              item.libro.trim().toLowerCase() == normalizedTitle,
        )
        .toList();

    // Si no está en biblioteca del club → ficha ligera con opción de añadir
    if (registros.isEmpty && finalizados.isEmpty) {
      await Navigator.push<void>(
        context,
        AppPageRoute(
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

    final resolvedCover = coverUrl.isNotEmpty
        ? coverUrl
        : registros.isNotEmpty
        ? registros.first.coverUrl
        : finalizados.first.coverUrl;
    final resolvedGenre = genre.isNotEmpty
        ? genre
        : registros.isNotEmpty
        ? registros.first.genero
        : finalizados.first.genero;

    await Navigator.push<void>(
      context,
      AppPageRoute(
        builder: (_) => DetalleLibroPage(
          libro: LibroAgrupado(
            libro: title,
            genero: resolvedGenre,
            registros: registros,
            finalizados: finalizados,
            yaLoTengo: registros.any((item) => item.yaLoTengo),
            leidoPorMi: finalizados.any((item) => item.yaLoTengo),
            coverUrl: resolvedCover,
          ),
        ),
      ),
    );
    return true;
  } catch (e) {
    debugPrint('openBookDetail error: $e');
    if (!context.mounted) return false;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error: $e')));
    return false;
  }
}

// En book_detail_navigation.dart — función nueva SOLO para el dashboard global
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
    final usuarioActual = ((await UsuarioService().obtenerUsuario()) ?? '')
        .trim()
        .toLowerCase();
    final data = await ApiService().getLibrosData();
    if (!context.mounted) return false;

    final registros = data.libros
        .where(
          (item) =>
              ((bookId.isNotEmpty && item.bookId == bookId) ||
                  item.libro.trim().toLowerCase() == normalizedTitle) &&
              (usuarioActual.isEmpty ||
                  item.usuario.trim().toLowerCase() == usuarioActual),
        )
        .toList();
    final finalizados = data.finalizados
        .where(
          (item) =>
              ((bookId.isNotEmpty && item.bookId == bookId) ||
                  item.libro.trim().toLowerCase() == normalizedTitle) &&
              (usuarioActual.isEmpty ||
                  item.usuario.trim().toLowerCase() == usuarioActual),
        )
        .toList();

    if (registros.isEmpty && finalizados.isEmpty) {
      await Navigator.push<void>(
        context,
        AppPageRoute(
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

    final resolvedCover = coverUrl.isNotEmpty
        ? coverUrl
        : registros.isNotEmpty
        ? registros.first.coverUrl
        : finalizados.first.coverUrl;
    final resolvedGenre = genre.isNotEmpty
        ? genre
        : registros.isNotEmpty
        ? registros.first.genero
        : finalizados.first.genero;

    await Navigator.push<void>(
      context,
      AppPageRoute(
        builder: (_) => DetalleLibroPage(
          libro: LibroAgrupado(
            libro: title,
            genero: resolvedGenre,
            registros: registros,
            finalizados: finalizados,
            yaLoTengo: registros.any((item) => item.yaLoTengo),
            leidoPorMi: finalizados.any((item) => item.yaLoTengo),
            coverUrl: resolvedCover,
          ),
        ),
      ),
    );
    return true;
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
