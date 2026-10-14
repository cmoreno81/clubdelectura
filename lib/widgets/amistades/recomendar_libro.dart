import 'package:flutter/material.dart';

import '../../models/amistad.dart';
import '../../pages/amistades_page.dart';
import '../../services/api_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

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
      cargar: cargar,
      enviar: enviar,
    ),
  );
}

class RecomendarLibroSheet extends StatefulWidget {
  const RecomendarLibroSheet({
    super.key,
    required this.bookId,
    required this.titulo,
    this.cargar,
    this.enviar,
  });

  final String bookId;
  final String titulo;
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

class _RecomendarLibroSheetState extends State<RecomendarLibroSheet> {
  late final Future<AmistadesData> _amistades =
      (widget.cargar ?? ApiService().getAmistades)();
  final _mensaje = TextEditingController();
  final Set<String> _elegidas = {};
  bool _juntas = false;
  bool _enviando = false;

  @override
  void dispose() {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado.mensaje.isEmpty
                ? 'No se ha podido enviar. Inténtalo de nuevo.'
                : resultado.mensaje,
          ),
        ),
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
                      'No se han podido cargar tus amistades. Inténtalo más tarde.',
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
                          'Todavía no tienes amistades en ClubReads.',
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
                          child: const Text('Buscar o invitar amistades'),
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
                            ? 'Enviar a 1 amistad'
                            : 'Enviar a ${_elegidas.length} amistades',
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
