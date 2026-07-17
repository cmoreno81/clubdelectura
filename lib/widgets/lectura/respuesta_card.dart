import 'package:club_lectura_app/widgets/lectura/fecha_relativa.dart';
import 'package:flutter/material.dart';

import '../../models/respuesta_comentario.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_avatar.dart';

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
        title: const Text('Editar respuesta'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Escribe tu respuesta...',
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

    final ok = await ApiService().editarRespuesta(
      respuestaId: widget.respuesta.id,
      respuesta: nuevo,
    );

    if (!mounted) return;

    if (ok) {
      widget.onActualizar();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Respuesta actualizada 💜')));
    }
  }

  Future<void> _eliminarRespuesta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar respuesta'),
        content: const Text('¿Seguro que quieres eliminar esta respuesta?'),
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

    final ok = await ApiService().eliminarRespuesta(
      respuestaId: widget.respuesta.id,
    );

    if (!mounted) return;

    if (ok) {
      widget.onActualizar();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Respuesta eliminada')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final respuesta = widget.respuesta;

    if (respuesta.eliminado) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, left: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClubAvatar(
                    nombre: respuesta.usuario,
                    imageUrl: respuesta.avatarUrl,
                    size: 38,
                  ),

                  const SizedBox(width: AppSpacing.sm),

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
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),

                            if (respuesta.esMia)
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.more_horiz_rounded,
                                  color: AppColors.textMuted,
                                ),
                                onSelected: (accion) {
                                  if (accion == 'editar') {
                                    _editarRespuesta();
                                  }

                                  if (accion == 'eliminar') {
                                    _eliminarRespuesta();
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'editar',
                                    child: Text('Editar'),
                                  ),
                                  PopupMenuItem(
                                    value: 'eliminar',
                                    child: Text('Eliminar'),
                                  ),
                                ],
                              ),
                          ],
                        ),

                        Text(
                          FechaRelativa.formato(respuesta.fecha),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        Text(
                          respuesta.respuesta,
                          style: AppTextStyles.body.copyWith(
                            height: 1.45,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        if (respuesta.editado) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Editado',
                            style: AppTextStyles.caption.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
