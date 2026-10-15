import 'package:flutter/material.dart';

import '../../models/amistad.dart';
import '../../models/libro.dart';
import '../../pages/amistades_page.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_book_cover.dart';
import 'aviso_en_hoja.dart';

/// Botón de la ficha de un libro para recomendárselo a amistades.
class BotonRecomendarLibro extends StatelessWidget {
  const BotonRecomendarLibro({
    super.key,
    required this.bookId,
    required this.titulo,
    this.espacioDespues = 0,
  });

  final String bookId;
  final String titulo;
  final double espacioDespues;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: espacioDespues),
      child: OutlinedButton.icon(
        onPressed: () =>
            mostrarRecomendarLibro(context, bookId: bookId, titulo: titulo),
        icon: const Icon(Icons.favorite_border_rounded),
        label: const Text('Recomendar a un amigo'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}

Future<void> mostrarRecomendarLibro(
  BuildContext context, {
  required String bookId,
  required String titulo,
  String? preseleccion,
  Future<AmistadesData> Function()? cargar,
  Future<ResultadoAmistad> Function({
    required String bookId,
    required List<String> usuarios,
    String mensaje,
    bool juntas,
  })?
  enviar,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => RecomendarLibroSheet(
      bookId: bookId,
      titulo: titulo,
      preseleccion: preseleccion,
      cargar: cargar,
      enviar: enviar,
    ),
  );
}

/// Desde el perfil de una amiga (o el aviso «te pide una recomendación»):
/// eliges uno de tus libros y se lo recomiendas a ella.
Future<void> mostrarRecomendarAUnaAmiga(
  BuildContext context, {
  required String nombre,
  Future<List<Libro>> Function()? cargarLibros,
}) async {
  final elegido = await showModalBottomSheet<Libro>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => _ElegirLibroSheet(nombre: nombre, cargar: cargarLibros),
  );
  if (elegido == null || !context.mounted) return;
  await mostrarRecomendarLibro(
    context,
    bookId: elegido.bookId,
    titulo: elegido.libro,
    preseleccion: nombre,
  );
}

class _ElegirLibroSheet extends StatefulWidget {
  const _ElegirLibroSheet({required this.nombre, this.cargar});

  final String nombre;
  final Future<List<Libro>> Function()? cargar;

  @override
  State<_ElegirLibroSheet> createState() => _ElegirLibroSheetState();
}

class _ElegirLibroSheetState extends State<_ElegirLibroSheet> {
  late final Future<List<Libro>> _libros = _cargarLibros();
  String _busqueda = '';

  static double _nota(Libro l) =>
      double.tryParse(l.valoracion.replaceAll(',', '.')) ?? 0;

  /// Primero lo que ya has leído, de mayor a menor nota; después lo que
  /// también tienes pendiente. Lo demás (leyendo, pausado…) no se ofrece.
  Future<List<Libro>> _cargarLibros() async {
    final todos = await (widget.cargar ?? ApiService().getLibros)();
    final vistos = <String>{};
    final propios = [
      for (final l in todos)
        if (l.bookId.isNotEmpty && vistos.add(l.bookId)) l,
    ];
    final leidos = propios.where((l) => l.estado == 'FINALIZADO').toList()
      ..sort((a, b) {
        final c = _nota(b).compareTo(_nota(a));
        return c != 0 ? c : a.libro.compareTo(b.libro);
      });
    final pendientes = propios.where((l) => l.estado == 'PENDIENTE').toList()
      ..sort((a, b) => a.libro.compareTo(b.libro));
    return [...leidos, ...pendientes];
  }

  @override
  Widget build(BuildContext context) {
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
            '¿Qué libro le recomiendas a ${widget.nombre}?',
            style: AppTextStyles.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Primero los que has leído, de mayor a menor nota; luego los que también tienes pendientes.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const Key('recomendar-buscar-libro'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por título',
            ),
            onChanged: (v) =>
                setState(() => _busqueda = v.trim().toLowerCase()),
          ),
          Flexible(
            child: FutureBuilder<List<Libro>>(
              future: _libros,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No se ha podido cargar tu biblioteca. Inténtalo más tarde.',
                      style: AppTextStyles.bodySecondary,
                    ),
                  );
                }
                final lista = [
                  for (final l in snapshot.data ?? const <Libro>[])
                    if (_busqueda.isEmpty ||
                        l.libro.toLowerCase().contains(_busqueda))
                      l,
                ];
                if (lista.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No hay libros que coincidan.',
                      style: AppTextStyles.bodySecondary,
                    ),
                  );
                }
                return GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: .52,
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  children: [
                    for (final l in lista)
                      InkWell(
                        key: Key('recomendar-libro-${l.bookId}'),
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(context, l),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClubBookCover(
                                      title: l.libro,
                                      imageUrl: l.coverUrl,
                                      width: double.infinity,
                                    ),
                                  ),
                                  if (_nota(l) > 0)
                                    Positioned(
                                      left: 6,
                                      bottom: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: .6,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              size: 13,
                                              color: AppColors.gold,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              _nota(l) % 1 == 0
                                                  ? _nota(l).toStringAsFixed(0)
                                                  : _nota(l).toStringAsFixed(1),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l.libro,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RecomendarLibroSheet extends StatefulWidget {
  const RecomendarLibroSheet({
    super.key,
    required this.bookId,
    required this.titulo,
    this.preseleccion,
    this.cargar,
    this.enviar,
  });

  final String bookId;
  final String titulo;

  /// Amiga ya marcada al abrir (cuando vienes de su perfil).
  final String? preseleccion;
  final Future<AmistadesData> Function()? cargar;
  final Future<ResultadoAmistad> Function({
    required String bookId,
    required List<String> usuarios,
    String mensaje,
    bool juntas,
  })?
  enviar;

  @override
  State<RecomendarLibroSheet> createState() => _RecomendarLibroSheetState();
}

class _RecomendarLibroSheetState extends State<RecomendarLibroSheet>
    with AvisoEnHojaState<RecomendarLibroSheet> {
  late final Future<AmistadesData> _amistades =
      (widget.cargar ?? ApiService().getAmistades)();
  final _mensaje = TextEditingController();
  late final Set<String> _elegidas = {
    if (widget.preseleccion != null) widget.preseleccion!,
  };
  bool _juntas = false;
  bool _enviando = false;

  @override
  void dispose() {
    cancelarAviso();
    _mensaje.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final resultado = await (widget.enviar ?? ApiService().recomendarLibro)(
      bookId: widget.bookId,
      usuarios: _elegidas.toList(),
      mensaje: _mensaje.text,
      juntas: _juntas,
    );
    if (!mounted) return;
    if (!resultado.ok) {
      setState(() => _enviando = false);
      avisar(
        resultado.mensaje.isEmpty
            ? 'No se ha podido enviar. Inténtalo de nuevo.'
            : resultado.mensaje,
      );
      return;
    }
    Navigator.pop(context);
    final texto = resultado.enviadas == 0
        ? 'Ya se lo habías recomendado hace poco 💜'
        : resultado.enviadas == 1
        ? 'Recomendación enviada 💌'
        : '${resultado.enviadas} recomendaciones enviadas 💌';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  @override
  Widget build(BuildContext context) {
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
            'Recomendar a un amigo',
            style: AppTextStyles.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Elige a quién le quieres hablar de «${widget.titulo}».',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          AvisoEnHoja(texto: avisoTexto),
          Flexible(
            child: FutureBuilder<AmistadesData>(
              future: _amistades,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No se han podido cargar tus amigos. Inténtalo más tarde.',
                      style: AppTextStyles.bodySecondary,
                    ),
                  );
                }
                final lista =
                    snapshot.data?.amistades ?? const <PersonaAmistad>[];
                if (lista.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Todavía no tienes amigos en ClubReads.',
                          style: AppTextStyles.bodySecondary,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AmistadesPage(),
                              ),
                            );
                          },
                          child: const Text('Buscar o invitar amigos'),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final a in lista)
                            CheckboxListTile(
                              value: _elegidas.contains(a.nombre),
                              title: Text(a.nombre),
                              controlAffinity: ListTileControlAffinity.trailing,
                              onChanged: _enviando
                                  ? null
                                  : (v) => setState(() {
                                      v == true
                                          ? _elegidas.add(a.nombre)
                                          : _elegidas.remove(a.nombre);
                                    }),
                            ),
                        ],
                      ),
                    ),
                    TextField(
                      controller: _mensaje,
                      maxLength: 140,
                      enabled: !_enviando,
                      decoration: const InputDecoration(
                        labelText: 'Un mensaje personal (opcional)',
                        hintText: 'Te va a encantar…',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _juntas,
                      onChanged: _enviando
                          ? null
                          : (v) => setState(() => _juntas = v),
                      title: const Text('Proponer leerlo a la vez'),
                    ),
                    FilledButton(
                      onPressed: _enviando || _elegidas.isEmpty
                          ? null
                          : _enviar,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text(
                        _elegidas.isEmpty
                            ? 'Elige a alguien'
                            : _elegidas.length == 1
                            ? 'Enviar a 1 amigo'
                            : 'Enviar a ${_elegidas.length} amigos',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
