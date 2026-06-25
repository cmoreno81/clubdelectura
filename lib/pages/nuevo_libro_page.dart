import 'package:flutter/material.dart';

import '../models/nuevo_libro.dart';
import '../services/api_service.dart';

class NuevoLibroPage extends StatefulWidget {
  const NuevoLibroPage({super.key});

  @override
  State<NuevoLibroPage> createState() =>
      _NuevoLibroPageState();
}

class _NuevoLibroPageState
    extends State<NuevoLibroPage> {

  final usuarioController =
      TextEditingController();

  final libroController =
      TextEditingController();

  final sagaController =
      TextEditingController();

  final numSagaController =
      TextEditingController();

  String genero = 'Fantasía';

  String prioridad = 'Media';

  String autoconclusivo = 'Si';

  bool guardando = false;

  Future<void> guardarLibro() async {

    if (usuarioController.text.isEmpty ||
        libroController.text.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Completa usuario y libro',
          ),
        ),
      );

      return;
    }

    setState(() {
      guardando = true;
    });

    try {

      final libro =
          NuevoLibro(

        usuario:
            usuarioController.text,

        libro:
            libroController.text,

        genero: genero,

        saga:
            sagaController.text,

        numSaga:
            numSagaController.text,

        autoconclusivo:
            autoconclusivo,

        prioridad:
            prioridad,
      );

      await ApiService()
          .crearLibro(libro);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            '✅ Libro añadido',
          ),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );

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

      appBar: AppBar(
        title: const Text(
          '➕ Nuevo libro',
        ),
      ),

      body: SingleChildScrollView(

        padding:
            const EdgeInsets.all(16),

        child: Column(

          children: [

            TextField(
              controller:
                  usuarioController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Usuario',
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
                  libroController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Libro',
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(

              value: genero,

              decoration:
                  const InputDecoration(
                labelText:
                    'Género',
              ),

              items: [

                'Fantasía',
                'Romantasy',
                'Romance',
                'Thriller',
                'Dark Romance',
                'Dark Academia',
                'Drama',
                'Clásicos',
                'Distopía',
                'Novela contemporánea',
                'Novela Histórica',
                'Ciencia Ficción',
                'Terror',
                'Novela Negra'

              ].map((e) {

                return DropdownMenuItem(
                  value: e,
                  child: Text(e),
                );

              }).toList(),

              onChanged: (value) {

                setState(() {

                  genero = value!;

                });
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
                  sagaController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Saga',
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller:
                  numSagaController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Nº Saga',
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(

              value: prioridad,

              decoration:
                  const InputDecoration(
                labelText:
                    'Prioridad',
              ),

              items: [
                'Alta',
                'Media',
                'Baja'
              ].map((e) {

                return DropdownMenuItem(
                  value: e,
                  child: Text(e),
                );

              }).toList(),

              onChanged: (value) {

                setState(() {

                  prioridad =
                      value!;

                });
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(

              value:
                  autoconclusivo,

              decoration:
                  const InputDecoration(
                labelText:
                    'Autoconclusivo',
              ),

              items: [

                'Si',
                'No'

              ].map((e) {

                return DropdownMenuItem(
                  value: e,
                  child: Text(e),
                );

              }).toList(),

              onChanged: (value) {

                setState(() {

                  autoconclusivo =
                      value!;

                });
              },
            ),

            const SizedBox(height: 32),

            SizedBox(

              width:
                  double.infinity,

              child:
                  ElevatedButton(

                onPressed:
                    guardando
                        ? null
                        : guardarLibro,

                child: Padding(

                  padding:
                      const EdgeInsets
                          .all(16),

                  child: Text(

                    guardando
                        ? 'Guardando...'
                        : 'GUARDAR',

                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}