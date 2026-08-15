import 'package:club_lectura_app/widgets/lectura/fecha_relativa.dart';
import 'package:flutter/material.dart';

import '../../models/respuesta_comentario.dart';
import '../../models/reaccion_comentario.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_avatar.dart';
import '../common/reaction_details_sheet.dart';

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
  late int _likes;
  late bool _miLike;
  late Map<ReaccionComentario, int> _reacciones;

  /// Reacción visual local (no persiste en el modelo del servidor, pero sí
  /// se envía al endpoint para que lo procese si tiene soporte).
  ReaccionComentario? _miReaccion;

  final GlobalKey _reaccionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _likes = widget.respuesta.likes;
    _miLike = widget.respuesta.miLike;
    _miReaccion =
        widget.respuesta.miReaccion ??
        (_miLike ? ReaccionComentario.meGusta : null);
    _reacciones = Map.of(widget.respuesta.reacciones);
  }

  Future<void> _toggleReaccion(ReaccionComentario reaccion) async {
    // Optimistic update
    final anteriorReaccion = _miReaccion;
    final anteriorLike = _miLike;
    final anteriorLikes = _likes;

    setState(() {
      if (_miReaccion == reaccion) {
        // Quitar reacción
        _miReaccion = null;
        _miLike = false;
        _likes = (_likes - 1).clamp(0, 9999);
      } else {
        final teniaPreviamenteReaccion = _miReaccion != null;
        _miReaccion = reaccion;
        _miLike = true;
        if (!teniaPreviamenteReaccion) _likes += 1;
      }
    });

    try {
      final json = await ApiService().toggleLikeComentario(
        comentarioId: widget.respuesta.id,
        reaccion: reaccion.apiValue,
      );
      if (!mounted) return;
      setState(() {
        _miLike = json['miLike'] as bool? ?? _miLike;
        _likes = (json['likes'] as num?)?.toInt() ?? _likes;
        _miReaccion = ReaccionComentarioDatos.fromApi(
          json['miReaccion']?.toString(),
        );
        final raw = json['reacciones'];
        if (raw is Map) {
          _reacciones = {
            for (final tipo in ReaccionComentario.values)
              tipo: (raw[tipo.apiValue] as num?)?.toInt() ?? 0,
          };
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _miReaccion = anteriorReaccion;
        _miLike = anteriorLike;
        _likes = anteriorLikes;
      });
    }
  }

  Future<void> _mostrarReacciones() async {
    final buttonBox =
        _reaccionKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (buttonBox == null || overlayBox == null) return;

    final buttonOffset = buttonBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );
    final buttonRect = buttonOffset & buttonBox.size;
    final anchor = Rect.fromLTWH(
      12,
      buttonRect.top - 62,
      overlayBox.size.width - 24,
      1,
    );

    final seleccion = await showMenu<ReaccionComentario>(
      context: context,
      position: RelativeRect.fromRect(anchor, Offset.zero & overlayBox.size),
      elevation: 10,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: const BorderSide(color: AppColors.border),
      ),
      constraints: BoxConstraints.tightFor(
        width: (overlayBox.size.width - 24).clamp(340, 410).toDouble(),
      ),
      menuPadding: EdgeInsets.zero,
      items: [
        PopupMenuItem<ReaccionComentario>(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ReaccionComentario.values.map((reaccion) {
              final seleccionada = _miReaccion == reaccion;
              return Tooltip(
                message: reaccion.titulo,
                child: Semantics(
                  button: true,
                  selected: seleccionada,
                  label: reaccion.titulo,
                  child: InkWell(
                    onTap: () => Navigator.pop(context, reaccion),
                    customBorder: const CircleBorder(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: seleccionada
                            ? AppColors.primaryLight
                            : Colors.transparent,
                        border: seleccionada
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Text(
                        reaccion.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
    if (seleccion != null) await _toggleReaccion(seleccion);
  }

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

                        const SizedBox(height: AppSpacing.sm),

                        // ── Botón de reacción ──
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final tipo in ReaccionComentario.values)
                              if ((_reacciones[tipo] ?? 0) > 0)
                                ActionChip(
                                  tooltip: 'Ver quién reaccionó ${tipo.emoji}',
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.padded,
                                  onPressed: () => ReactionDetailsSheet.show(
                                    context,
                                    targetType: 'COMMENT',
                                    targetId: widget.respuesta.id,
                                  ),
                                  label: Text(
                                    '${tipo.emoji} ${_reacciones[tipo]}',
                                  ),
                                ),
                            Tooltip(
                              message: _miReaccion?.titulo ?? 'Reaccionar',
                              child: SizedBox(
                                height: 32,
                                child: FilledButton.tonalIcon(
                                  key: _reaccionKey,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: _mostrarReacciones,
                                  icon: _miReaccion == null
                                      ? const Icon(
                                          Icons.add_reaction_outlined,
                                          size: 16,
                                        )
                                      : Text(
                                          _miReaccion!.emoji,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                  label: _likes > 0
                                      ? Text(
                                          '$_likes',
                                          style: AppTextStyles.caption.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ],
                        ),
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
