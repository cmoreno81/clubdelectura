import 'package:club_lectura_app/utils/genero_utils.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/libro.dart';
import '../models/libro_agrupado.dart';
import '../services/api_service.dart';
import '../widgets/libros/conversaciones_libro_card.dart';
import '../widgets/libros/finalizar_libro_dialog.dart';

class DetalleLibroPage extends StatefulWidget {
  final LibroAgrupado libro;

  const DetalleLibroPage({super.key, required this.libro});

  @override
  State<DetalleLibroPage> createState() => _DetalleLibroPageState();
}

class _DetalleLibroPageState extends State<DetalleLibroPage> {
  late List<Libro> registros;

  @override
  void initState() {
    super.initState();

    registros = List.from(widget.libro.registros);
  }

  IconData _iconoEstado(String estado) {
    switch (estado) {
      case 'LEYENDO':
        return Icons.menu_book;

      case 'RELECTURA':
        return Icons.refresh;

      case 'FINALIZADO':
        return Icons.check_circle;

      default:
        return Icons.schedule;
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'LEYENDO':
        return Colors.blue;

      case 'RELECTURA':
        return Colors.orange;

      case 'FINALIZADO':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }

  Future<void> _cambiarEstado(
    Libro libro,
    String nuevoEstado, {
    String? valoracion,
    String? reflexion,
  }) async {
    try {
      final bool ok;

      if (nuevoEstado == 'LEYENDO') {
        ok = await ApiService().iniciarLectura(
          usuario: libro.usuario,
          libro: libro.libro,
        );
      } else {
        ok = await ApiService().actualizarEstado(
          usuario: libro.usuario,
          libro: libro.libro,
          estado: nuevoEstado,
          valoracion: valoracion,
          reflexion: reflexion,
        );
      }

      if (!ok) {
        throw Exception('No se ha podido guardar el estado');
      }

      if (!mounted) return;

      final index = registros.indexOf(libro);

      setState(() {
        registros[index] = Libro(
          usuario: libro.usuario,
          libro: libro.libro,
          genero: libro.genero,
          saga: libro.saga,
          numSaga: libro.numSaga,
          autoconclusivo: libro.autoconclusivo,
          prioridad: libro.prioridad,
          estado: nuevoEstado,
          valoracion: valoracion ?? libro.valoracion,
          yaLoTengo: libro.yaLoTengo,
          goodreads: libro.goodreads,
        );
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Estado actualizado')));
    } catch (e) {
      if (!mounted) return;

      final mensaje = e.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $mensaje')));
    }
  }

  Future<void> _abrirGoodreads() async {
    if (widget.libro.registros.isEmpty) return;

    var url = widget.libro.registros.first.goodreads.trim();

    if (url.isEmpty) return;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.parse(url);

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Widget _estadistica({
    required IconData icono,
    required String titulo,
    required String valor,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),

      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),

      child: Column(
        children: [
          Icon(icono, color: color),

          const SizedBox(height: 8),

          Text(
            valor,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          Text(
            titulo,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final referencia = registros.isNotEmpty ? registros.first : null;
    return Scaffold(
      appBar: AppBar(title: Text(widget.libro.libro)),

      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).padding.bottom + 32,
          ),

          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      widget.libro.libro,

                      style: const TextStyle(
                        fontSize: 22,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${iconoGenero(widget.libro.genero)} ${widget.libro.genero}',
                    ),
                    const SizedBox(height: 12),

                    if (referencia?.autoconclusivo == "Si")
                      const Row(
                        children: [
                          Icon(Icons.auto_stories_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Autoconclusivo",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    else ...[
                      Row(
                        children: [
                          const Icon(Icons.forest_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              referencia?.saga ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      if ((referencia?.numSaga ?? "").isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 26, top: 4),
                          child: Text(
                            "Libro ${referencia?.numSaga ?? ""}",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                    ],

                    const SizedBox(height: 16),

                    const SizedBox(height: 8),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Expanded(
                          child: _estadistica(
                            icono: Icons.people,
                            titulo: "Interesadas",
                            valor: "${widget.libro.total}",
                            color: Colors.blue,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _estadistica(
                            icono: Icons.flag,
                            titulo: "Leídos",
                            valor: "${widget.libro.totalFinalizados}",
                            color: Colors.green,
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: _estadistica(
                            icono: Icons.star,
                            titulo: "Media",
                            valor: widget.libro.mediaValoracion > 0
                                ? widget.libro.mediaValoracion.toStringAsFixed(
                                    1,
                                  )
                                : "-",
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    if (referencia?.goodreads.isNotEmpty ?? false) ...[
                      const SizedBox(height: 20),

                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _abrirGoodreads,
                        child: Card(
                          elevation: 0,
                          color: Colors.amber.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.menu_book_rounded,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Ver ficha en Goodreads",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Sinopsis, opiniones y valoraciones",
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.open_in_new),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (registros.isNotEmpty) ...[
              const Text(
                'Interesadas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              ...registros.map((registro) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(
                            _iconoEstado(registro.estado),
                            color: _colorEstado(registro.estado),
                          ),
                          title: Text(registro.usuario),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonFormField<String>(
                            value: registro.estado,
                            decoration: const InputDecoration(
                              labelText: 'Estado',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'PENDIENTE',
                                child: Text('PENDIENTE'),
                              ),
                              DropdownMenuItem(
                                value: 'LEYENDO',
                                child: Text('LEYENDO'),
                              ),
                              DropdownMenuItem(
                                value: 'RELECTURA',
                                child: Text('RELECTURA'),
                              ),
                              DropdownMenuItem(
                                value: 'FINALIZADO',
                                child: Text('FINALIZADO'),
                              ),
                            ],
                            onChanged: (value) async {
                              if (value == null || value == registro.estado) {
                                return;
                              }

                              Map<String, String>? datosValoracion;

                              if (value == 'FINALIZADO') {
                                datosValoracion =
                                    await showDialog<Map<String, String>>(
                                      context: context,
                                      builder: (_) =>
                                          const FinalizarLibroDialog(),
                                    );

                                if (!mounted || datosValoracion == null) {
                                  return;
                                }
                              }

                              await _cambiarEstado(
                                registro,
                                value,
                                valoracion: datosValoracion?["valoracion"],
                                reflexion: datosValoracion?["reflexion"],
                              );
                            },
                          ),
                        ),

                        if (registro.valoracion.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              '⭐ ${registro.valoracion}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),

            ConversacionesLibroCard(libro: widget.libro.libro),

            const SizedBox(height: 8),

            if (widget.libro.finalizados.isNotEmpty) ...[
              const SizedBox(height: 24),

              const Text(
                '🏁 Valoraciones',

                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              ...widget.libro.finalizados.map((finalizado) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(child: Icon(Icons.person, size: 18)),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                finalizado.usuario,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              if (finalizado.resena.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  finalizado.resena,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        Text(
                          finalizado.valoracion,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
