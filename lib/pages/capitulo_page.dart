import 'package:club_lectura_app/models/comentarios_capitulo.dart';
import 'package:club_lectura_app/services/usuario_service.dart';
import 'package:flutter/material.dart';
import '../widgets/lectura/comentario_card.dart';
import '../widgets/lectura/comentario_input.dart';
import '../services/api_service.dart';

class CapituloPage extends StatefulWidget {
  final String libro;
  final String capitulo;

  const CapituloPage({super.key, required this.libro, required this.capitulo});

  @override
  State<CapituloPage> createState() => _CapituloPageState();
}

class _CapituloPageState extends State<CapituloPage> {
  late Future<ComentariosCapitulo> future;

  final TextEditingController controller = TextEditingController();

  String? usuario;
  bool enviando = false;

  @override
  void initState() {
    super.initState();

    _cargarUsuario();

    _recargar();
  }

  Future<void> _cargarUsuario() async {
    final u = await UsuarioService().obtenerUsuario();

    if (!mounted) return;

    usuario = u;
  }

  void _recargar() {
    future = ApiService().getComentariosCapitulo(
      libro: widget.libro,
      capitulo: widget.capitulo,
    );
  }

  Future<void> _publicar() async {
    final texto = controller.text.trim();

    if (texto.isEmpty || enviando) return;

    FocusScope.of(context).unfocus();

    setState(() {
      enviando = true;
    });

    await ApiService().guardarComentarioLectura(
      libro: widget.libro,
      capitulo: widget.capitulo,
      usuario: usuario ?? "",
      comentario: texto,
    );

    if (!mounted) return;

    controller.clear();

    setState(() {
      enviando = false;
      _recargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.capitulo)),

      body: FutureBuilder<ComentariosCapitulo>(
        future: future,

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  children: [
                    Text(
                      widget.libro,

                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        fontSize: 24,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      widget.capitulo,

                      style: const TextStyle(
                        fontSize: 18,

                        color: Colors.black54,
                      ),
                    ),
                    if (widget.capitulo == "💭 Reflexión final") ...[
                      const SizedBox(height: 16),

                      Card(
                        color: Colors.deepPurple.shade50,
                        elevation: 0,
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                "💭 El gran debate",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),

                              SizedBox(height: 10),

                              Text(
                                "Este espacio es para compartir tu valoración global, hablar del desenlace y debatir libremente con el resto del club.\n\n⚠️ A partir de aquí puede haber spoilers.",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Expanded(
                child: data.comentarios.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),

                          child: Text(
                            widget.capitulo == "💭 Reflexión final"
                                ? "Todavía nadie ha compartido su reflexión sobre el libro.\n\nSé la primera en abrir el debate 💜"
                                : "Todavía nadie ha comentado este capítulo.\n\nSé la primera en romper el hielo 💜",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: data.comentarios.length,
                        itemBuilder: (context, index) {
                          return ComentarioCard(
                            comentario: data.comentarios[index],
                            usuarioActual: usuario ?? '',
                            onActualizar: () {
                              if (!mounted) return;

                              setState(() {
                                _recargar();
                              });
                            },
                          );
                        },
                      ),
              ),

              const Divider(height: 1),

              ComentarioInput(
                controller: controller,
                onEnviar: _publicar,
                enviando: enviando,
                hintText: widget.capitulo == "💭 Reflexión final"
                    ? "Comparte tu reflexión sobre el libro..."
                    : "¿Qué te ha parecido este capítulo?",
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
