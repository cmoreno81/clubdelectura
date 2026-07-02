import 'package:flutter/material.dart';
import '../services/usuario_service.dart';
import '../models/nuevo_libro.dart';
import '../services/api_service.dart';

class NuevoLibroPage extends StatefulWidget {
  const NuevoLibroPage({super.key});

  @override
  State<NuevoLibroPage> createState() => _NuevoLibroPageState();
}

class _NuevoLibroPageState extends State<NuevoLibroPage> {
  final libroController = TextEditingController();

  final sagaController = TextEditingController();

  final numSagaController = TextEditingController();

  String genero = 'Fantasía';

  String prioridad = 'Media';

  String autoconclusivo = 'Si';

  bool guardando = false;

  Widget _tituloSeccion(String texto) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        texto,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _chipGenero({
    required String icono,
    required String valor,
    required String texto,
  }) {
    return ChoiceChip(
      label: Text('$icono $texto'),
      selected: genero == valor,
      showCheckmark: false,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      onSelected: (_) {
        setState(() {
          genero = valor;
        });
      },
    );
  }

  Future<void> guardarLibro() async {
    final usuario = await UsuarioService().obtenerUsuario();

    if (usuario == null) {
      throw Exception("No se ha encontrado el usuario");
    }
    if (libroController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa el nombre del libro')),
      );

      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final libro = NuevoLibro(
        usuario: usuario,

        libro: libroController.text,

        genero: genero,

        saga: sagaController.text,

        numSaga: numSagaController.text,

        autoconclusivo: autoconclusivo,

        prioridad: prioridad,
      );

      await ApiService().crearLibro(libro);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ Libro añadido')));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('➕ Nuevo libro')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            const SizedBox(height: 16),

            TextField(
              controller: libroController,
              decoration: const InputDecoration(labelText: 'Libro'),
            ),
            const SizedBox(height: 28),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '📖 ¿Es autoconclusivo?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 12,
                children: [
                  ChoiceChip(
                    showCheckmark: false,
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    label: const Text('Sí'),
                    selected: autoconclusivo == 'Si',
                    onSelected: (_) {
                      setState(() {
                        autoconclusivo = 'Si';
                        sagaController.clear();
                        numSagaController.clear();
                      });
                    },
                  ),

                  ChoiceChip(
                    showCheckmark: false,
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    label: const Text('No'),
                    selected: autoconclusivo == 'No',
                    onSelected: (_) {
                      setState(() {
                        autoconclusivo = 'No';
                      });
                    },
                  ),
                ],
              ),
            ),
            if (autoconclusivo == "No") ...[
              TextField(
                controller: sagaController,
                decoration: const InputDecoration(labelText: 'Saga'),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: numSagaController,
                decoration: const InputDecoration(labelText: 'Nº Saga'),
              ),

              const SizedBox(height: 16),
            ],

            const SizedBox(height: 16),

            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '🏷️ Género',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _chipGenero(icono: '🐉', valor: 'Fantasía', texto: 'Fantasía'),
                _chipGenero(
                  icono: '🌹',
                  valor: 'Romantasy',
                  texto: 'Romantasy',
                ),
                _chipGenero(icono: '💕', valor: 'Romance', texto: 'Romance'),
                _chipGenero(icono: '🔪', valor: 'Thriller', texto: 'Thriller'),
                _chipGenero(
                  icono: '🖤',
                  valor: 'Dark Romance',
                  texto: 'Dark Romance',
                ),
                _chipGenero(
                  icono: '🎓',
                  valor: 'Dark Academia',
                  texto: 'Dark Academia',
                ),
                _chipGenero(icono: '🎭', valor: 'Drama', texto: 'Drama'),
                _chipGenero(icono: '📜', valor: 'Clásicos', texto: 'Clásicos'),
                _chipGenero(icono: '🌇', valor: 'Distopía', texto: 'Distopía'),

                _chipGenero(
                  icono: '🏙️',
                  valor: 'Novela contemporánea',
                  texto: 'Contemporánea',
                ),
                _chipGenero(
                  icono: '🏰',
                  valor: 'Novela Histórica',
                  texto: 'Histórica',
                ),
                _chipGenero(
                  icono: '🚀',
                  valor: 'Ciencia Ficción',
                  texto: 'Sci-Fi',
                ),
                _chipGenero(icono: '👻', valor: 'Terror', texto: 'Terror'),
                _chipGenero(
                  icono: '🕵️',
                  valor: 'Novela Negra',
                  texto: 'Novela Negra',
                ),
              ],
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 16),

            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '⭐ Prioridad',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 12,
                children: [
                  ChoiceChip(
                    label: const Text('🟢 Baja'),
                    selected: prioridad == 'Baja',
                    showCheckmark: false,
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    onSelected: (_) {
                      setState(() {
                        prioridad = 'Baja';
                      });
                    },
                  ),

                  ChoiceChip(
                    label: const Text('🟡 Media'),
                    selected: prioridad == 'Media',
                    showCheckmark: false,
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    onSelected: (_) {
                      setState(() {
                        prioridad = 'Media';
                      });
                    },
                  ),

                  ChoiceChip(
                    label: const Text('🔴 Alta'),
                    selected: prioridad == 'Alta',
                    showCheckmark: false,
                    selectedColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    onSelected: (_) {
                      setState(() {
                        prioridad = 'Alta';
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: guardando ? null : guardarLibro,

                child: Padding(
                  padding: const EdgeInsets.all(16),

                  child: Text(guardando ? 'Guardando...' : '➕ Añadir libro'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
