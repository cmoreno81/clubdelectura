import 'package:club_lectura_app/services/usuario_service.dart';
import 'package:club_lectura_app/widgets/error_view.dart';
import 'package:flutter/material.dart';

import '../models/libro_agrupado.dart';
import '../services/api_service.dart';
import 'detalle_libro_page.dart';
import 'nuevo_libro_page.dart';
import '../models/libros_data.dart';
import '../utils/genero_utils.dart';

class LibrosPage extends StatefulWidget {
  const LibrosPage({super.key});

  @override
  State<LibrosPage> createState() => _LibrosPageState();
}

class _LibrosPageState extends State<LibrosPage> {
  late Future<LibrosData> librosFuture;
  final TextEditingController buscadorController = TextEditingController();
  String filtroBusqueda = '';
  String filtroEstado = 'TODOS';
  String filtroUsuario = 'TODAS';

  @override
  void initState() {
    super.initState();

    librosFuture = ApiService().getLibrosData();
  }

  @override
  void dispose() {
    buscadorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(title: const Text('📚 Libros'), centerTitle: true),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NuevoLibroPage()),
          );

          setState(() {
            librosFuture = ApiService().getLibrosData();
          });
        },

        child: const Icon(Icons.add),
      ),

      body: FutureBuilder<LibrosData>(
        future: librosFuture,

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(
              onRetry: () {
                setState(() {
                  librosFuture = ApiService().getLibrosData();
                });
              },
            );
          }

          final data = snapshot.data!;

          final libros = data.libros;

          final finalizados = data.finalizados;

          List<LibroAgrupado> resultado = [];

          final usuarios = libros.map((e) => e.usuario.trim()).toSet().toList()
            ..sort();

          final usuariosFiltro = ['TODAS', ...usuarios];
          if (filtroEstado != 'TERMINADOS') {
            final librosFiltrados = libros.where((libro) {
              final coincideBusqueda = normalizar(
                libro.libro,
              ).contains(normalizar(filtroBusqueda));

              final coincideUsuario =
                  filtroUsuario == 'TODAS' ||
                  libro.usuario.trim() == filtroUsuario;

              bool coincideEstado = true;

              if (filtroEstado != 'TODOS') {
                coincideEstado = libro.estado == filtroEstado;
              }

              return coincideBusqueda && coincideEstado && coincideUsuario;
            }).toList();

            final Map<String, LibroAgrupado> agrupados = {};

            for (final libro in librosFiltrados) {
              if (!agrupados.containsKey(libro.libro)) {
                agrupados[libro.libro] = LibroAgrupado(
                  libro: libro.libro,
                  genero: libro.genero,
                  registros: [],
                  finalizados: [],
                  yaLoTengo: libro.yaLoTengo,
                );
              }

              agrupados[libro.libro]!.registros.add(libro);

              if (libro.yaLoTengo) {
                agrupados[libro.libro]!.yaLoTengo = true;
              }
            }

            resultado = agrupados.values.toList();

            for (final agrupado in resultado) {
              agrupado.finalizados.addAll(
                finalizados.where(
                  (f) => f.libro.trim() == agrupado.libro.trim(),
                ),
              );
            }

            resultado.sort((a, b) => b.total.compareTo(a.total));
          } else {
            final finalizadosFiltrados = finalizados.where((f) {
              if (filtroUsuario != 'TODAS' &&
                  f.usuario.trim() != filtroUsuario) {
                return false;
              }

              if (filtroBusqueda.isNotEmpty &&
                  !f.libro.toLowerCase().contains(
                    filtroBusqueda.toLowerCase(),
                  )) {
                return false;
              }

              return true;
            });

            final agrupados = <String, LibroAgrupado>{};

            for (final f in finalizadosFiltrados) {
              agrupados.putIfAbsent(
                f.libro,

                () => LibroAgrupado(
                  libro: f.libro,

                  genero: f.genero,

                  registros: [],

                  finalizados: [],

                  yaLoTengo: false,
                ),
              );

              agrupados[f.libro]!.finalizados.add(f);
            }

            resultado = agrupados.values.toList();

            resultado.sort(
              (a, b) => b.totalFinalizados.compareTo(a.totalFinalizados),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),

                child: TextField(
                  controller: buscadorController,
                  decoration: InputDecoration(
                    suffixIcon: filtroBusqueda.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              buscadorController.clear();

                              setState(() {
                                filtroBusqueda = '';
                              });
                            },
                          ),
                    hintText: 'Buscar libro...',

                    prefixIcon: const Icon(Icons.search),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  onChanged: (value) {
                    setState(() {
                      filtroBusqueda = value;
                    });
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: DropdownButtonFormField<String>(
                  value: filtroUsuario,

                  decoration: const InputDecoration(labelText: 'Usuaria'),

                  items: usuariosFiltro.map((usuario) {
                    return DropdownMenuItem(
                      value: usuario,

                      child: Text(usuario),
                    );
                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      filtroUsuario = value!;
                    });
                  },
                ),
              ),

              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,

                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: Row(
                  children: [
                    _chip('TODOS'),

                    const SizedBox(width: 8),

                    _chip('PENDIENTE'),

                    const SizedBox(width: 8),

                    _chip('LEYENDO'),

                    const SizedBox(width: 8),

                    _chip('RELECTURA'),
                    const SizedBox(width: 8),

                    _chip('TERMINADOS'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  itemCount: resultado.length,

                  itemBuilder: (context, index) {
                    final libro = resultado[index];

                    return InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) => DetalleLibroPage(libro: libro),
                          ),
                        );

                        setState(() {
                          librosFuture = ApiService().getLibrosData();
                        });
                      },

                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,

                          vertical: 8,
                        ),

                        child: Padding(
                          padding: const EdgeInsets.all(16),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Row(
                                children: [
                                  Text(
                                    iconoGenero(libro.genero),
                                    style: const TextStyle(fontSize: 28),
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Text(
                                      libro.libro,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  libro.yaLoTengo
                                      ? const Tooltip(
                                          message: "Ya está en tu lista",
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 30,
                                          ),
                                        )
                                      : IconButton(
                                          tooltip: "Añadir a mi lista",
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.deepPurple,
                                          ),
                                          onPressed: () {
                                            _confirmarAgregarLibro(libro);
                                          },
                                        ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Text(
                                '👥 ${libro.total} interesadas',

                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (libro.totalFinalizados > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),

                                  child: Text(
                                    '🏁 ${libro.totalFinalizados} finalizados',

                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (libro.mediaValoracion > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),

                                  child: Text(
                                    '⭐ ${libro.mediaValoracion.toStringAsFixed(1)} / 5',

                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 8),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: libro.registros.map((registro) {
                                  final seleccionada =
                                      registro.usuario.trim() == filtroUsuario;

                                  return Text(
                                    seleccionada
                                        ? '⭐ ${registro.usuario}'
                                        : registro.usuario,

                                    style: TextStyle(
                                      fontWeight: seleccionada
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  );
                                }).toList(),
                              ),

                              if (libro.total >= 3)
                                const Padding(
                                  padding: EdgeInsets.only(top: 8),

                                  child: Text(
                                    '🔥 Coincidencia de club',

                                    style: TextStyle(
                                      color: Colors.deepOrange,

                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String estado) {
    return ChoiceChip(
      label: Text(estado),

      selected: filtroEstado == estado,

      onSelected: (_) {
        setState(() {
          filtroEstado = estado;
        });
      },
    );
  }

  Future<void> _confirmarAgregarLibro(LibroAgrupado libro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("📚 Añadir libro"),
          content: Text(
            "¿Quieres añadir '${libro.libro}' a tu lista de pendientes?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Añadir"),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final usuario = await UsuarioService().obtenerUsuario();

    final respuesta = await ApiService().anadirLibroExistente(
      usuario: usuario!,
      libro: libro.libro,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          respuesta["ok"] ? "✅ Añadido a tu lista" : respuesta["mensaje"],
        ),
      ),
    );

    if (respuesta["ok"]) {
      setState(() {
        librosFuture = ApiService().getLibrosData();
      });
    }
  }

  String normalizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }
}
