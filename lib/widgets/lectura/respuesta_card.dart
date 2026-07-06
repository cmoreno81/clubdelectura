import 'package:flutter/material.dart';

import '../../models/respuesta_comentario.dart';
import '../../services/api_service.dart';
import 'avatar_usuario.dart';
import 'fecha_relativa.dart';

class RespuestaCard extends StatefulWidget {
  final RespuestaComentario respuesta;
  final VoidCallback onActualizar;

  const RespuestaCard({
    super.key,
    required this.respuesta,
    required this.onActualizar,
  });

  @override
  State<RespuestaCard> createState() => _RespuestaCardState();
}

class _RespuestaCardState extends State<RespuestaCard> {
  Future<void> _editarRespuesta() async {
    final controller = TextEditingController(text: widget.respuesta.respuesta);

    final nuevo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar respuesta"),
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

    if (nuevo == null || nuevo.isEmpty) return;

    final ok = await ApiService().editarRespuesta(
      respuestaId: widget.respuesta.id,
      respuesta: nuevo,
    );

    if (!mounted) return;

    if (ok) {
      widget.onActualizar();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Respuesta actualizada 💜")));
    }
  }

  Future<void> _eliminarRespuesta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Eliminar respuesta"),
        content: const Text("¿Seguro que quieres eliminar esta respuesta?"),
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

    final ok = await ApiService().eliminarRespuesta(
      respuestaId: widget.respuesta.id,
    );

    if (!mounted) return;

    if (ok) {
      widget.onActualizar();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Respuesta eliminada")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final respuesta = widget.respuesta;

    if (respuesta.eliminado) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 48, top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvatarUsuario(nombre: respuesta.usuario),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        respuesta.usuario,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    if (respuesta.esMia)
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == "editar") {
                            _editarRespuesta();
                          }

                          if (v == "eliminar") {
                            _eliminarRespuesta();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: "editar", child: Text("Editar")),

                          PopupMenuItem(
                            value: "eliminar",
                            child: Text("Eliminar"),
                          ),
                        ],
                      ),
                  ],
                ),

                Text(
                  FechaRelativa.formato(respuesta.fecha),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),

                const SizedBox(height: 8),

                Text(respuesta.respuesta),

                if (respuesta.editado)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      "(editado)",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
