import 'package:flutter/material.dart';
import 'respuesta_card.dart';
import '../../models/comentario_lectura.dart';
import '../../services/api_service.dart';
import 'avatar_usuario.dart';
import 'fecha_relativa.dart';

class ComentarioCard extends StatefulWidget {
  final ComentarioLectura comentario;
  final VoidCallback onActualizar;
  final String usuarioActual;

  const ComentarioCard({
    super.key,
    required this.comentario,
    required this.onActualizar,
    required this.usuarioActual,
  });

  @override
  State<ComentarioCard> createState() => _ComentarioCardState();
}

class _ComentarioCardState extends State<ComentarioCard> {
  late bool miLike;
  late int likes;
  bool respondiendo = false;

  final TextEditingController respuestaController = TextEditingController();

  bool enviando = false;

  @override
  void initState() {
    super.initState();

    miLike = widget.comentario.miLike;
    likes = widget.comentario.likes;
  }

  Future<void> _toggleLike() async {
    final json = await ApiService().toggleLikeComentario(
      comentarioId: widget.comentario.id,
    );

    if (!mounted) return;

    setState(() {
      miLike = json["miLike"] ?? false;
      likes = json["likes"] ?? likes;
    });
  }

  Future<void> _enviarRespuesta() async {
    final texto = respuestaController.text.trim();

    if (texto.isEmpty) return;

    setState(() {
      enviando = true;
    });

    final ok = await ApiService().guardarRespuestaComentario(
      comentarioId: widget.comentario.id,

      usuario: widget.usuarioActual,

      respuesta: texto,
    );

    if (!mounted) return;

    setState(() {
      enviando = false;

      respuestaController.clear();

      respondiendo = false;
    });

    widget.onActualizar();

    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Respuesta publicada 💜")));
    }
  }

  Future<void> _editarComentario() async {
    final controller = TextEditingController(
      text: widget.comentario.comentario,
    );

    final nuevo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar comentario"),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );

    if (nuevo == null) return;

    if (nuevo.isEmpty) return;

    final ok = await ApiService().editarComentario(
      comentarioId: widget.comentario.id,
      comentario: nuevo,
    );

    if (!mounted) return;

    if (ok) {
      widget.onActualizar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Comentario actualizado 💜")),
      );
    }
  }

  Future<void> _eliminarComentario() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar comentario"),
        content: const Text("¿Seguro que quieres eliminar este comentario?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final ok = await ApiService().eliminarComentario(
      comentarioId: widget.comentario.id,
    );

    if (!mounted) return;

    if (ok) {
      widget.onActualizar();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Comentario eliminado")));
    }
  }

  void _accion(String accion) {
    switch (accion) {
      case "editar":
        _editarComentario();
        break;

      case "eliminar":
        _eliminarComentario();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final comentario = widget.comentario;

    if (comentario.eliminado) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          title: Text(
            "Este comentario fue eliminado.",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            AvatarUsuario(nombre: comentario.usuario),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comentario.usuario,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                      ),

                      PopupMenuButton<String>(
                        onSelected: _accion,

                        itemBuilder: (_) => [
                          if (comentario.esMio)
                            const PopupMenuItem(
                              value: "editar",
                              child: Text("Editar"),
                            ),

                          if (comentario.esMio)
                            const PopupMenuItem(
                              value: "eliminar",
                              child: Text("Eliminar"),
                            ),
                        ],
                      ),
                    ],
                  ),

                  Text(
                    FechaRelativa.formato(comentario.fecha),
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    comentario.comentario,
                    style: const TextStyle(fontSize: 16),
                  ),

                  if (comentario.editado)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        "(editado)",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(20),

                        onTap: _toggleLike,

                        child: Row(
                          children: [
                            Icon(
                              miLike ? Icons.favorite : Icons.favorite_border,
                              color: miLike ? Colors.red : Colors.grey,
                              size: 20,
                            ),

                            const SizedBox(width: 6),

                            Text(
                              "$likes",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            respondiendo = !respondiendo;
                          });
                        },

                        icon: const Icon(Icons.reply, size: 18),

                        label: const Text("Responder"),
                      ),
                    ],
                  ),
                  if (respondiendo) ...[
                    const SizedBox(height: 16),

                    TextField(
                      controller: respuestaController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: "Escribe una respuesta...",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: enviando ? null : _enviarRespuesta,
                        icon: const Icon(Icons.send),
                        label: const Text("Responder"),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                  if (comentario.respuestas.isNotEmpty) ...[
                    const SizedBox(height: 16),

                    ...comentario.respuestas.map(
                      (respuesta) => RespuestaCard(
                        respuesta: respuesta,
                        onActualizar: widget.onActualizar,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    respuestaController.dispose();
    super.dispose();
  }
}
