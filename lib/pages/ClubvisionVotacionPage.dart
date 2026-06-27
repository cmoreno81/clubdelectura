import 'package:flutter/material.dart';

import '../models/clubvision.dart';
import '../services/api_service.dart';
import '../services/usuario_service.dart';

class ClubvisionVotacionPage extends StatefulWidget {
  const ClubvisionVotacionPage({super.key});

  @override
  State<ClubvisionVotacionPage> createState() => _ClubvisionVotacionPageState();
}

class _ClubvisionVotacionPageState extends State<ClubvisionVotacionPage> {
  late Future<ClubvisionData> future;

  String usuario = '';
  final List<String> seleccionadas = [];

  @override
  void initState() {
    super.initState();

    future = ApiService().getClubvision();

    UsuarioService().obtenerUsuario().then((value) {
      if (!mounted) return;

      setState(() {
        usuario = value ?? '';
      });
    });
  }

  String iconoGenero(String genero) {
    switch (genero.toLowerCase()) {
      case 'fantasía':
        return '🐉';
      case 'novela negra':
        return '🔪';
      case 'romance':
        return '💕';
      case 'terror':
        return '👻';
      case 'ciencia ficción':
        return '🚀';
      case 'novela contemporánea':
        return '📖';
      case 'novela histórica':
        return '🏰';
      case 'romantasy':
        return '🦄';
      case 'thriller':
        return '🕵️';
      case 'dark academia':
        return '🎭';
      case 'dark romance':
        return '🖤';
      case 'drama':
        return '😭';
      default:
        return '📚';
    }
  }

  Color bordeCandidata(int index, bool seleccionada) {
    if (seleccionada) return Colors.deepPurple;

    return switch (index) {
      0 => Colors.amber,
      1 => Colors.blueGrey,
      2 => const Color(0xFF8D6E63),
      _ => Colors.transparent,
    };
  }

  double anchoBordeCandidata(int index, bool seleccionada) {
    if (seleccionada) return 3;
    if (index < 3) return 1.8;
    return 0;
  }

  Widget etiquetaCandidata(int index, int interesadas) {
    if (index == 0) {
      return const Text(
        '🥇 Favorita del club',
        style: TextStyle(
          color: Color(0xFFFFB300),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      );
    }

    if (index == 1) {
      return const Text(
        '🥈 Segunda favorita',
        style: TextStyle(
          color: Color(0xFF78909C),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      );
    }

    if (index == 2) {
      return const Text(
        '🥉 Tercera favorita',
        style: TextStyle(
          color: Color(0xFF8D6E63),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      );
    }

    if (interesadas >= 4) {
      return const Text(
        '🔥 Muy popular',
        style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎤 Clubvisión')),
      body: FutureBuilder<ClubvisionData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final clubvision = snapshot.data!;
          final totalIntereses = clubvision.candidatas.fold<int>(
            0,
            (total, candidata) => total + candidata.interesadas,
          );

          final votos = seleccionadas
              .map(
                (titulo) =>
                    clubvision.candidatas.firstWhere((c) => c.libro == titulo),
              )
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (usuario.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            '👋 Hola $usuario',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        clubvision.abierta
                            ? '🟢 Votación abierta'
                            : '🔒 Votación cerrada',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Elegimos juntas la próxima lectura del club 💜',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      if (votos.isNotEmpty)
                        Card(
                          color: Colors.deepPurple.shade50,

                          child: Padding(
                            padding: const EdgeInsets.all(20),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                const Text(
                                  '🗳️ Tu papeleta',

                                  style: TextStyle(
                                    fontSize: 24,

                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                ...votos.asMap().entries.map((entry) {
                                  final posicion = entry.key;

                                  final libro = entry.value;

                                  final etiqueta = switch (posicion) {
                                    0 => '🥇 12',

                                    1 => '🥈 10',

                                    2 => '🥉 8',

                                    3 => '④ 7',

                                    _ => '⑤ 6',
                                  };

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),

                                    child: Text(
                                      '$etiqueta   ${libro.libro}',

                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  );
                                }),
                                if (seleccionadas.length == 5) ...[
                                  const SizedBox(height: 20),

                                  SizedBox(
                                    width: double.infinity,

                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,

                                          builder: (_) {
                                            return AlertDialog(
                                              title: const Text(
                                                '🗳️ Confirmar votación',
                                              ),

                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,

                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,

                                                children: [
                                                  const Text(
                                                    '¿Quieres enviar esta papeleta?',
                                                  ),

                                                  const SizedBox(height: 16),

                                                  ...votos.asMap().entries.map((
                                                    entry,
                                                  ) {
                                                    final posicion = entry.key;

                                                    final libro = entry.value;

                                                    final puntos =
                                                        switch (posicion) {
                                                          0 => '🥇 12',

                                                          1 => '🥈 10',

                                                          2 => '🥉 8',

                                                          3 => '④ 7',

                                                          _ => '⑤ 6',
                                                        };

                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 8,
                                                          ),

                                                      child: Text(
                                                        '$puntos  ${libro.libro}',
                                                      ),
                                                    );
                                                  }),
                                                ],
                                              ),

                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },

                                                  child: const Text('Cancelar'),
                                                ),

                                                ElevatedButton(
                                                  onPressed: () async {
                                                    final ok =
                                                        await ApiService()
                                                            .enviarVotacion(
                                                              usuario: usuario,

                                                              votos:
                                                                  seleccionadas,
                                                            );

                                                    if (!mounted) return;

                                                    Navigator.pop(context);

                                                    if (ok) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            '✅ Votación enviada correctamente',
                                                          ),

                                                          backgroundColor:
                                                              Colors.green,
                                                        ),
                                                      );
                                                    }
                                                  },

                                                  child: const Text(
                                                    'Enviar votación',
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },

                                      icon: const Icon(Icons.how_to_vote),

                                      label: const Text(
                                        'Enviar mi votación',

                                        style: TextStyle(fontSize: 18),
                                      ),

                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurple,

                                        foregroundColor: Colors.white,

                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 12),

                                  Text(
                                    'Selecciona ${5 - seleccionadas.length} libros más para completar tu papeleta.',

                                    style: TextStyle(
                                      color: Colors.grey.shade700,

                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${clubvision.candidatas.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('candidatas'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '$totalIntereses',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text('intereses'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...clubvision.candidatas.asMap().entries.map((entry) {
                final index = entry.key;
                final candidata = entry.value;
                final seleccionada = seleccionadas.contains(candidata.libro);

                final posicion = seleccionadas.indexOf(candidata.libro);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (seleccionada) {
                        seleccionadas.remove(candidata.libro);
                      } else {
                        if (seleccionadas.length < 5) {
                          seleccionadas.add(candidata.libro);
                        }
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    child: Card(
                      color: seleccionada
                          ? Colors.deepPurple.withValues(alpha: 0.06)
                          : null,
                      elevation: index < 3 ? 6 : 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: bordeCandidata(index, seleccionada),
                          width: anchoBordeCandidata(index, seleccionada),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Expanded(
                                  child: Text(
                                    candidata.libro,

                                    style: const TextStyle(
                                      fontSize: 28,

                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                if (seleccionada)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,

                                      vertical: 6,
                                    ),

                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple,

                                      borderRadius: BorderRadius.circular(20),
                                    ),

                                    child: Text(
                                      switch (posicion) {
                                        0 => '🥇 12',

                                        1 => '🥈 10',

                                        2 => '🥉 8',

                                        3 => '④ 7',

                                        _ => '⑤ 6',
                                      },

                                      style: const TextStyle(
                                        color: Colors.white,

                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            Text(
                              '${iconoGenero(candidata.genero)} ${candidata.genero}',
                            ),
                            const SizedBox(height: 6),
                            Text('👥 ${candidata.interesadas} interesadas'),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: candidata.interesadas / 9,
                              minHeight: 5,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            const SizedBox(height: 14),
                            etiquetaCandidata(index, candidata.interesadas),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
