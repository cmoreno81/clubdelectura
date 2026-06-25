import 'package:flutter/material.dart';

import '../models/clubvision.dart';
import '../services/api_service.dart';
import '../services/usuario_service.dart';

class ClubvisionVotacionPage
    extends StatefulWidget {

  const ClubvisionVotacionPage({
    super.key,
  });

  @override
  State<ClubvisionVotacionPage>
      createState() =>
          _ClubvisionVotacionPageState();
}

class _ClubvisionVotacionPageState
    extends State<ClubvisionVotacionPage> {

  late Future<ClubvisionData>
      future;

  String usuario = ""; 
  final List<String> seleccionadas = [];   

  @override
  void initState() {

    super.initState();

    future =
        ApiService()
            .getClubvision();

        UsuarioService()

            .obtenerUsuario()

            .then((value) {

          setState(() {

            usuario = value ?? "";

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
  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          '🎤 Clubvisión',
        ),
      ),

      body:
          FutureBuilder<ClubvisionData>(

        future: future,

        builder: (
          context,
          snapshot,
        ) {

          if (snapshot
                  .connectionState ==
              ConnectionState
                  .waiting) {

            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {

            return Center(
              child: Text(
                snapshot.error
                    .toString(),
              ),
            );
          }

          final clubvision =
              snapshot.data!;

          final totalIntereses =
              clubvision.candidatas.fold<int>(
                0,
                (total, candidata) =>
                    total + candidata.interesadas,
              );    

          return ListView(

            padding:
                const EdgeInsets
                    .all(16),

            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      if (usuario.isNotEmpty)

                Padding(

                  padding: const EdgeInsets.only(

                    bottom: 16,

                  ),

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
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        const Text(
          'Elegimos juntas la próxima lectura del club 💜',
          style: TextStyle(
            fontSize: 16,
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        Row(
          children: [

            Expanded(
              child: Column(
                children: [

                  Text(
                    '${clubvision.candidatas.length}',
                    style:
                        const TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const Text(
                    'candidatas',
                  ),
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

                  const Text(
                    'intereses',
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  ),
),

              const SizedBox(
                height: 16,
              ),


          ...clubvision.candidatas.asMap().entries.map(

            (entry) {

              final index = entry.key;
              final c = entry.value;
                    

              return GestureDetector(

  onTap: () {

    setState(() {

      if (seleccionadas.contains(c.libro)) {

        seleccionadas.remove(c.libro);

      } else {

        seleccionadas.add(c.libro);

      }

    });

  },


 child: AnimatedContainer(

  duration: const Duration(milliseconds: 200),

  child: Card(
    color: seleccionadas.contains(c.libro)

    ? Colors.deepPurple.withOpacity(0.06)

    : null,

                elevation: index < 3 ? 6 : 2,

                shape: RoundedRectangleBorder(

  borderRadius: BorderRadius.circular(20),

  side: BorderSide(

    color: seleccionadas.contains(c.libro)

        ? Colors.deepPurple

        : index == 0

            ? Colors.amber

            : index == 1

                ? Colors.blueGrey

                : index == 2

                    ? const Color(0xFF8D6E63)

                    : Colors.transparent,

    width: seleccionadas.contains(c.libro)

        ? 3

        : index < 3

            ? 1.8

            : 0,
  ),
),

                  borderRadius:
                      BorderRadius.circular(20),

                  side: BorderSide(

                    color:

                        index == 0

                            ? Colors.amber

                            : index == 1

                                ? Colors.blueGrey

                                : index == 2

                                    ? const Color(0xFF8D6E63)

                                    : Colors.transparent,

                    width: index < 3 ? 1.8 : 0,
                  ),
                ),

                child: Padding(

                            padding:
                                const EdgeInsets.all(16),

                            child: Column(

                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                                Text(

                                c.libro,

                                style:
                                    const TextStyle(

                                    fontSize: 28,

                                    fontWeight:
                                        FontWeight.bold,
                                ),
                                ),

                                if (seleccionadas.contains(c.libro))

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

                                const SizedBox(
                                height: 8,
                                ),

                                Text(
                                '${iconoGenero(c.genero)} ${c.genero}',
                                ),

                                const SizedBox(
                                height: 6,
                                ),

                                Text(
                                '👥 ${c.interesadas} interesadas',
                                ),
                                const SizedBox(
                                  height: 4,
                                ),

                                LinearProgressIndicator(

                                  value: c.interesadas / 9,

                                  minHeight: 5,

                                  borderRadius:
                                      BorderRadius.circular(20),

                                ),

                                const SizedBox(
                                height: 14,
                                ),

                              if (index == 0)

                              const Text(

                                '🥇 Favorita del club',

                                style: TextStyle(

                                  color: const Color(0xFFFFB300),

                                  fontWeight: FontWeight.bold,

                                  fontSize: 18,
                                ),
                              )

                              else if (index == 1)

                              const Text(

                                '🥈 Segunda favorita',

                                style: TextStyle(

                                  color: const Color(0xFF78909C),

                                  fontWeight: FontWeight.bold,

                                  fontSize: 18,
                                ),
                              )

                              else if (index == 2)

                              const Text(

                                '🥉 Tercera favorita',

                                style: TextStyle(

                                  color: const Color(0xFF8D6E63),

                                  fontWeight: FontWeight.bold,

                                  fontSize: 18,
                                ),
                              )

                              else if (c.interesadas >= 4)

                              const Text(

                                '🔥 Muy popular',

                                style: TextStyle(

                                  color: Colors.deepOrange,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            ),
                        ),
                        ),
                        );
                    },
                    ),

            ],
          );
        },
      ),
    );
  }
}