import 'package:flutter/material.dart';

import '../../models/estanteria_pendientes.dart';
import '../../navigation/app_page_route.dart';
import '../../navigation/book_detail_navigation.dart';
import '../../pages/comprar_libros_page.dart';
import '../../services/api_service.dart';
import '../../services/wishlist_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../common/club_book_cover.dart';

/// "Mi pila de pendientes": de los libros pendientes, cuántos ya están en la
/// estantería de la lectora, con sus portadas sobre una balda y, cuando hay
/// historial, cómo baja la pila mes a mes. En el perfil de otra lectora del
/// club ([usuario]) se ve igual pero sin el enlace a comprar.
class EstanteriaPendientesCard extends StatefulWidget {
  const EstanteriaPendientesCard({super.key, this.usuario = ''});

  /// Vacío = la propia lectora.
  final String usuario;

  @override
  State<EstanteriaPendientesCard> createState() =>
      _EstanteriaPendientesCardState();
}

class _EstanteriaPendientesCardState extends State<EstanteriaPendientesCard> {
  EstanteriaPendientes? _datos;
  int _peticion = 0;

  bool get _propia => widget.usuario.isEmpty;

  @override
  void initState() {
    super.initState();
    // "Ya lo tengo" se marca en otras pantallas.
    WishlistService.cambios.addListener(_cargar);
    _cargar();
  }

  @override
  void didUpdateWidget(covariant EstanteriaPendientesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.usuario != widget.usuario) _cargar();
  }

  @override
  void dispose() {
    WishlistService.cambios.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    final peticion = ++_peticion;
    try {
      final datos = await ApiService().getEstanteriaPendientes(
        usuario: widget.usuario,
      );
      if (!mounted || peticion != _peticion) return;
      setState(() => _datos = datos);
    } catch (_) {
      // Sin datos se deja la tarjeta como estaba (o sin tarjeta).
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _datos;
    if (d == null || (d.pendientes == 0 && d.tengo == 0)) {
      return const SizedBox.shrink();
    }
    final total = d.pendientes;
    final progreso = total == 0 ? 0.0 : (d.tengo / total).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4E7D3),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: const Color(0xFFD3B58E)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF65452F).withValues(alpha: .10),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${d.tengo}',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 38,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        'de $total pendientes ya los tienes',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progreso,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE3CFAE),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  d.faltan == 0
                      ? 'Todos tus pendientes ya están en casa'
                      : 'Te faltan ${d.faltan} por conseguir',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _Balda(libros: d.libros, vacia: d.tengo == 0, propia: _propia),
          if (d.otrosFormatos > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Text(
                '+ ${d.otrosFormatos} en ebook o audiolibro',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (d.hayHistorial)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: _LineaPila(serie: d.serie),
            ),
          if (_propia && d.faltan > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.push<void>(
                  context,
                  AppPageRoute(
                    builder: (_) => const ComprarLibrosPage(pestanaInicial: 1),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                iconAlignment: IconAlignment.end,
                label: const Text('Ver lo que me falta por comprar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}

/// Una balda de madera con las portadas en fila (se desliza si hay muchas).
class _Balda extends StatelessWidget {
  const _Balda({
    required this.libros,
    required this.vacia,
    required this.propia,
  });

  final List<LibroEstanteria> libros;
  final bool vacia;
  final bool propia;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8D4B7), Color(0xFFF8EEDD)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Container(
              height: 15,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFB9834F),
                    Color(0xFF8A5937),
                    Color(0xFF68422E),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x55351F14),
                    blurRadius: 7,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          if (libros.isEmpty)
            Positioned.fill(
              bottom: 24,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    vacia && propia
                        ? 'Pulsa «Ya lo tengo» en un pendiente y su portada '
                              'aparecerá aquí'
                        : 'Aquí no hay libros en papel todavía',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          else
            Positioned.fill(
              bottom: 22,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                itemCount: libros.length,
                separatorBuilder: (_, _) => const SizedBox(width: 7),
                itemBuilder: (context, i) {
                  final libro = libros[i];
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: ClubBookCover(
                      title: libro.titulo,
                      imageUrl: libro.portada,
                      width: 62,
                      height: 94,
                      borderRadius: BorderRadius.circular(4),
                      onTap: () => openBookDetail(
                        context,
                        title: libro.titulo,
                        bookId: libro.bookId,
                        coverUrl: libro.portada,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Línea fina con cómo evoluciona la pila de "ya lo tengo y sin leer".
class _LineaPila extends StatelessWidget {
  const _LineaPila({required this.serie});

  final List<PuntoPila> serie;

  @override
  Widget build(BuildContext context) {
    final actual = serie.last.pila;
    final maximo = serie.map((p) => p.pila).reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu pila sin leer: $actual ahora, $maximo como máximo',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 46,
          width: double.infinity,
          child: CustomPaint(
            painter: _PintorLinea([for (final p in serie) p.pila]),
          ),
        ),
      ],
    );
  }
}

class _PintorLinea extends CustomPainter {
  _PintorLinea(this.valores);

  final List<int> valores;

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.length < 2) return;
    final maximo = valores.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);
    final paso = size.width / (valores.length - 1);
    Offset punto(int i) => Offset(
      i * paso,
      size.height - 4 - (valores[i] / maximo) * (size.height - 8),
    );
    final linea = Path()..moveTo(punto(0).dx, punto(0).dy);
    for (var i = 1; i < valores.length; i++) {
      linea.lineTo(punto(i).dx, punto(i).dy);
    }
    final area = Path.from(linea)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = AppColors.primary.withValues(alpha: .12),
    );
    canvas.drawPath(
      linea,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      punto(valores.length - 1),
      4,
      Paint()..color = AppColors.inkCoral,
    );
  }

  @override
  bool shouldRepaint(covariant _PintorLinea old) => old.valores != valores;
}
