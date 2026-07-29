import 'package:flutter/material.dart';

import '../models/libro_agrupado.dart';
import '../pages/detalle_libro_page.dart';
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

    if (registros.isEmpty && finalizados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este libro todavía no está disponible en el club.'),
        ),
      );
      return false;
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
