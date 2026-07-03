import 'package:flutter/material.dart';

import '../models/mi_voto.dart';
import '../services/api_service.dart';
import '../services/usuario_service.dart';

class ClubvisionMiVotoPage extends StatefulWidget {
  const ClubvisionMiVotoPage({super.key});

  @override
  State<ClubvisionMiVotoPage> createState() => _ClubvisionMiVotoPageState();
}

class _ClubvisionMiVotoPageState extends State<ClubvisionMiVotoPage> {
  late Future<MiVoto> future;

  @override
  void initState() {
    super.initState();
    future = _cargar();
  }

  Future<MiVoto> _cargar() async {
    final usuario = await UsuarioService().obtenerUsuario();
    return ApiService().getMiVoto(usuario ?? "");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📦 Mi voto")),

      body: FutureBuilder<MiVoto>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final voto = snapshot.data!;

          if (!voto.encontrado) {
            return const Center(
              child: Text(
                "No se ha encontrado tu voto.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final puntos = [12, 10, 8, 7, 6];

          final medallas = ["🥇", "🥈", "🥉", "4️⃣", "5️⃣"];

          final colores = [
            const Color(0xFF8E44AD),
            const Color(0xFF3498DB),
            const Color(0xFF27AE60),
            const Color(0xFFE67E22),
            const Color(0xFFE74C3C),
          ];

          return ListView(
            padding: const EdgeInsets.all(20),

            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 56,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "Tu voto está registrado",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "${voto.votosRecibidos} de ${voto.totalUsuarios} lectoras ya han votado",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Tu clasificación",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              for (int i = 0; i < voto.votos.length; i++)
                Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 14),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colores[i],
                      child: Text(
                        medallas[i],
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),

                    title: Text(
                      voto.votos[i],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    subtitle: Text("${puntos[i]} puntos"),

                    trailing: Text(
                      "${i + 1}º",
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),

                child: const Column(
                  children: [
                    Icon(Icons.favorite, color: Colors.deepPurple),

                    SizedBox(height: 10),

                    Text(
                      "Gracias por participar en Clubvisión.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    SizedBox(height: 8),

                    Text(
                      "Tu selección ya forma parte de la historia. Ahora solo queda descubrir cuál será la próxima lectura del club.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
