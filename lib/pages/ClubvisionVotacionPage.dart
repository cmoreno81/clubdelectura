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

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (seleccionada) {
                        seleccionadas.remove(candidata.libro);
                      } else {
                        seleccionadas.add(candidata.libro);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    child: Card(
                      color: seleccionada
                          ? Colors.deepPurple.withOpacity(0.06)
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
                            Text(
                              candidata.libro,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (seleccionada)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.deepPurple,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Seleccionado',
                                      style: TextStyle(
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
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
