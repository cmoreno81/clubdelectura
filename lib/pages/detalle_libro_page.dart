import 'package:club_lectura_app/utils/genero_utils.dart';
import 'package:flutter/material.dart';

import '../models/libro.dart';
import '../models/libro_agrupado.dart';
import '../services/api_service.dart';

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

  Future<void> _cambiarEstado(Libro libro, String nuevoEstado) async {
    try {
      await ApiService().actualizarEstado(
        usuario: libro.usuario,

        libro: libro.libro,

        estado: nuevoEstado,
      );

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

          valoracion: nuevoEstado == 'FINALIZADO'
              ? 'Valorado'
              : libro.valoracion,

          yaLoTengo: libro.yaLoTengo,
        );
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Estado actualizado')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<String?> _pedirValoracion() async {
    return showDialog<String>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text('⭐ Valora el libro'),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              _opcionValoracion('⭐️⭐️⭐️⭐️⭐️'),

              _opcionValoracion('⭐️⭐️⭐️⭐️'),

              _opcionValoracion('⭐️⭐️⭐️'),

              _opcionValoracion('⭐️⭐️'),

              _opcionValoracion('⭐️'),

              _opcionValoracion('😞'),
            ],
          ),
        );
      },
    );
  }

  Widget _opcionValoracion(String valor) {
    return ListTile(
      title: Text(
        valor,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22),
      ),

      onTap: () {
        Navigator.pop(context, valor);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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

                    const SizedBox(height: 8),

                    Text('👥 ${widget.libro.total} interesadas'),
                    const SizedBox(height: 8),

                    if (widget.libro.totalFinalizados > 0)
                      Text('🏁 ${widget.libro.totalFinalizados} terminados'),

                    if (widget.libro.mediaValoracion > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '⭐ ${widget.libro.mediaValoracion.toStringAsFixed(1)} / 5',
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

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
                            if (value == null) {
                              return;
                            }

                            if (value == 'FINALIZADO') {
                              final valoracion = await _pedirValoracion();

                              if (valoracion == null) {
                                return;
                              }

                              await ApiService().actualizarValoracion(
                                usuario: registro.usuario,

                                libro: registro.libro,

                                valoracion: valoracion,
                              );
                            }

                            await _cambiarEstado(registro, value);
                          },
                        ),
                      ),

                      if (registro.valoracion.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12),

                          child: Text(
                            '⭐ ${registro.valoracion}',

                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            if (widget.libro.finalizados.isNotEmpty) ...[
              const SizedBox(height: 24),

              const Text(
                '🏁 Valoraciones',

                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              ...widget.libro.finalizados.map((finalizado) {
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person, size: 18),
                    ),

                    title: Text(finalizado.usuario),

                    trailing: Text(
                      finalizado.valoracion,

                      style: const TextStyle(
                        fontSize: 20,

                        fontWeight: FontWeight.bold,
                      ),
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
