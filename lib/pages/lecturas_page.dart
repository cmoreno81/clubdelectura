import 'package:flutter/material.dart';
import 'configurar_lectura_page.dart';
import '../models/lectura_activa.dart';
import '../services/api_service.dart';
import 'lectura_page.dart';

class LecturasPage extends StatefulWidget {
  const LecturasPage({super.key});

  @override
  State<LecturasPage> createState() => _LecturasPageState();
}

class _LecturasPageState extends State<LecturasPage> {
  late Future<List<LecturaActiva>> future;

  @override
  void initState() {
    super.initState();

    future = ApiService().getLecturasActivas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📖 Lecturas")),

      body: FutureBuilder<List<LecturaActiva>>(
        future: future,

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final lecturas = snapshot.data!;

          if (lecturas.isEmpty) {
            return const Center(
              child: Text("Todavía no hay lecturas compartidas."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),

            itemCount: lecturas.length,

            itemBuilder: (context, index) {
              final lectura = lecturas[index];

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.menu_book)),

                  title: Text(lectura.libro),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text("👥 ${lectura.lectoras} lectoras"),

                      Text(
                        lectura.comentarios == 1
                            ? "💬 1 comentario"
                            : "💬 ${lectura.comentarios} comentarios",
                      ),

                      if (lectura.ultimaActividad.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            lectura.ultimaActividad,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),

                      if (!lectura.configurada)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),

                          child: Text(
                            "Pendiente de configurar",

                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                    ],
                  ),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: () async {
                    if (!lectura.configurada) {
                      final creado = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ConfigurarLecturaPage(libro: lectura.libro),
                        ),
                      );

                      if (creado == true) {
                        setState(() {
                          future = ApiService().getLecturasActivas();
                        });
                      }

                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LecturaPage(libro: lectura.libro),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
