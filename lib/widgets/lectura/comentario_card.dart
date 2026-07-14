import 'package:flutter/material.dart';

import '../../models/comentario_lectura.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_avatar.dart';
import '../common/club_card.dart';
import 'fecha_relativa.dart';
import 'respuesta_card.dart';

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
  bool enviando = false;

  final TextEditingController respuestaController = TextEditingController();

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
      miLike = json['miLike'] ?? false;
      likes = json['likes'] ?? likes;
    });
  }

  Future<void> _enviarRespuesta() async {
    final texto = respuestaController.text.trim();

    if (texto.isEmpty || enviando) return;

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
    });

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido publicar la respuesta.')),
      );
      return;
    }

    respuestaController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      respondiendo = false;
    });

    widget.onActualizar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Respuesta publicada 💜')));
  }

  Future<void> _editarComentario() async {
    final controller = TextEditingController(
      text: widget.comentario.comentario,
    );

    final nuevo = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar comentario'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Escribe tu comentario...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (nuevo == null || nuevo.isEmpty) return;

    final ok = await ApiService().editarComentario(
      comentarioId: widget.comentario.id,
      comentario: nuevo,
    );

    if (!mounted) return;

    if (ok) {
      widget.onActualizar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentario actualizado 💜')),
      );
    }
  }

  Future<void> _eliminarComentario() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text('¿Seguro que quieres eliminar este comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
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
      ).showSnackBar(const SnackBar(content: Text('Comentario eliminado')));
    }
  }

  void _accion(String accion) {
    if (accion == 'editar') {
      _editarComentario();
    }

    if (accion == 'eliminar') {
      _eliminarComentario();
    }
  }

  @override
  Widget build(BuildContext context) {
    final comentario = widget.comentario;

    if (comentario.eliminado) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: ClubCard(
          elevated: false,
          padding: const EdgeInsets.all(AppSpacing.md),
          backgroundColor: AppColors.surfaceSoft,
          child: Text(
            'Este comentario fue eliminado.',
            style: AppTextStyles.bodySecondary.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: ClubCard(
        elevated: false,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClubAvatar(nombre: comentario.usuario, size: 48),

                const SizedBox(width: AppSpacing.md),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comentario.usuario,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxs),

                      Text(
                        FechaRelativa.formato(comentario.fecha),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                if (comentario.esMio)
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: AppColors.textMuted,
                    ),
                    onSelected: _accion,
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'editar', child: Text('Editar')),
                      PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              comentario.comentario,
              style: AppTextStyles.body.copyWith(
                fontSize: 16,
                height: 1.55,
                color: AppColors.textPrimary,
              ),
            ),

            if (comentario.editado) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Editado',
                style: AppTextStyles.caption.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggleLike,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: miLike
                            ? const Color(0xFFFFF1F1)
                            : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: miLike
                              ? const Color(0xFFF5C7C7)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            miLike
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 19,
                            color: miLike
                                ? AppColors.danger
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '$likes',
                            style: AppTextStyles.caption.copyWith(
                              color: miLike
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      respondiendo = !respondiendo;
                    });
                  },
                  icon: Icon(
                    respondiendo ? Icons.close_rounded : Icons.reply_rounded,
                    size: 19,
                  ),
                  label: Text(respondiendo ? 'Cancelar' : 'Responder'),
                ),
              ],
            ),

            if (respondiendo) ...[
              const SizedBox(height: AppSpacing.md),

              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: respuestaController,
                      enabled: !enviando,
                      minLines: 2,
                      maxLines: 6,
                      maxLength: 3000,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      scrollPadding: const EdgeInsets.only(bottom: 180),
                      decoration: const InputDecoration(
                        hintText: 'Escribe una respuesta...',
                        filled: false,
                        border: InputBorder.none,
                        counterStyle: TextStyle(color: AppColors.textMuted),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: enviando ? null : _enviarRespuesta,
                        icon: enviando
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(enviando ? 'Publicando...' : 'Responder'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (comentario.respuestas.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),

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
    );
  }

  @override
  void dispose() {
    respuestaController.dispose();
    super.dispose();
  }
}
