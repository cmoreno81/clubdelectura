import 'package:flutter/material.dart';

import '../../models/amistad.dart';
import '../../models/reaccion_comentario.dart';
import '../../services/api_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_card.dart';
import 'comentarios_progreso.dart';

/// En la ficha de un libro que estás leyendo: lo que tus amigos han dejado en tu lectura
/// (comentarios y reacciones). No ocupa nada si no hay nada o si el servidor es antiguo.
class AmigosDeMiLecturaCard extends StatefulWidget {
  const AmigosDeMiLecturaCard({
    super.key,
    required this.bookId,
    required this.titulo,
    this.cargar,
  });

  final String bookId;
  final String titulo;

  /// Para pruebas: sustituye la carga real.
  final Future<ResumenAmigosLectura> Function(String bookId)? cargar;

  @override
  State<AmigosDeMiLecturaCard> createState() => _AmigosDeMiLecturaCardState();
}

class _AmigosDeMiLecturaCardState extends State<AmigosDeMiLecturaCard> {
  ResumenAmigosLectura? _resumen;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final r = await (widget.cargar ?? ApiService().getResumenAmigosLectura)(
        widget.bookId,
      );
      if (!mounted) return;
      setState(() => _resumen = r);
    } catch (_) {
      if (!mounted) return;
      setState(() => _resumen = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _resumen;
    if (r == null || !r.hayAlgo) return const SizedBox.shrink();
    final reacciones = [
      for (final e in r.reacciones.entries)
        if (e.value > 0) '${e.key.emoji} ${e.value}',
    ].join('  ');
    final partes = [
      if (r.comentarios > 0)
        '💬 ${r.comentarios} ${r.comentarios == 1 ? 'comentario' : 'comentarios'}',
      if (reacciones.isNotEmpty) reacciones,
    ].join('  ·  ');
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: ClubCard(
        elevated: false,
        onTap: () async {
          await mostrarComentariosProgreso(
            context,
            libraryId: r.libraryId,
            titulo: widget.titulo,
          );
          if (mounted) _cargar();
        },
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tus amigos te animan',
                    style: AppTextStyles.section.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 2),
                  Text(partes, style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
