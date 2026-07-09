import 'package:flutter/material.dart';

import '../models/perfil_usuario.dart';
import '../services/api_service.dart';

class PerfilUsuarioPage extends StatefulWidget {
  final String usuario;

  const PerfilUsuarioPage({super.key, required this.usuario});

  @override
  State<PerfilUsuarioPage> createState() => _PerfilUsuarioPageState();
}

class _PerfilUsuarioPageState extends State<PerfilUsuarioPage> {
  late Future<PerfilUsuario> future;

  @override
  void initState() {
    super.initState();
    future = ApiService().getPerfilUsuario(widget.usuario);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),

      body: FutureBuilder<PerfilUsuario>(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final perfil = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 46,
                  child: Text(
                    _iniciales(perfil.usuario),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  perfil.usuario,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: _stat(
                      "Terminados",
                      perfil.resumen.terminados.toString(),
                      Icons.menu_book,
                    ),
                  ),
                  Expanded(
                    child: _stat(
                      "Leyendo",
                      perfil.resumen.leyendo.toString(),
                      Icons.auto_stories,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _stat(
                      "Media",
                      perfil.resumen.media.toStringAsFixed(2),
                      Icons.star,
                    ),
                  ),
                  Expanded(
                    child: _stat(
                      "Pendientes",
                      perfil.resumen.pendientes.toString(),
                      Icons.bookmark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              if (perfil.leyendo.isNotEmpty) ...[
                const Text(
                  "📖 Leyendo ahora",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                ...perfil.leyendo.map(
                  (e) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book),
                      title: Text(e.libro),
                      subtitle: Text(e.genero),
                    ),
                  ),
                ),

                const SizedBox(height: 28),
              ],

              const Text(
                "⭐ Últimos libros terminados",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              ...perfil.terminados
                  .take(10)
                  .map(
                    (e) => Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.menu_book,
                          color: Colors.deepPurple,
                        ),
                        title: Text(
                          e.libro,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.genero),

                              if (e.valoracion.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  e.valoracion,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],

                              if (e.fecha.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Finalizado el ${e.fecha}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

              const SizedBox(height: 28),

              if (perfil.generosFavoritos.isNotEmpty) ...[
                const Text(
                  "❤️ Géneros favoritos",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: perfil.generosFavoritos
                      .map((g) => Chip(label: Text("${g.genero} (${g.total})")))
                      .toList(),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String titulo, String valor, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: Colors.deepPurple),
            const SizedBox(height: 8),
            Text(
              valor,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(titulo),
          ],
        ),
      ),
    );
  }

  String _iniciales(String nombre) {
    final limpio = nombre.trim();

    if (limpio.isEmpty) return "?";

    final partes = limpio.split(RegExp(r'\s+'));

    if (partes.length == 1) {
      return partes.first.substring(0, 1).toUpperCase();
    }

    final primera = partes.first.isNotEmpty ? partes.first[0] : "";
    final ultima = partes.last.isNotEmpty ? partes.last[0] : "";

    final iniciales = "$primera$ultima".trim();

    return iniciales.isEmpty ? "?" : iniciales.toUpperCase();
  }
}
