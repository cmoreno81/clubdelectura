import 'package:flutter/material.dart';

import '../../models/comentario_lectura.dart';
import '../../models/reaccion_comentario.dart';
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
  late ReaccionComentario? miReaccion;
  late Map<ReaccionComentario, int> reacciones;

  bool respondiendo = false;
  bool enviando = false;

  final TextEditingController respuestaController = TextEditingController();
  final GlobalKey _reaccionKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    miReaccion = widget.comentario.miReaccion;
    reacciones = Map.of(widget.comentario.reacciones);
  }

  Future<void> _toggleReaccion(ReaccionComentario reaccion) async {
    final json = await ApiService().toggleLikeComentario(
      comentarioId: widget.comentario.id,
      reaccion: reaccion.apiValue,
    );

    if (!mounted) return;

    setState(() {
      miReaccion = ReaccionComentarioDatos.fromApi(
        json['miReaccion']?.toString(),
      );
      final raw = json['reacciones'];
      if (raw is Map) {
        reacciones = {
          for (final tipo in ReaccionComentario.values)
            tipo: (raw[tipo.apiValue] as num?)?.toInt() ?? 0,
        };
      }
    });
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
              final seleccionada = miReaccion == reaccion;
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
    final colorCita = _colorCita(comentario.color);

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
        backgroundColor: comentario.esCita
            ? Color.alphaBlend(
                colorCita.withValues(alpha: .18),
                AppColors.surface,
              )
            : null,
        borderColor: comentario.esCita
            ? colorCita.withValues(alpha: .55)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClubAvatar(
                  nombre: comentario.usuario,
                  imageUrl: comentario.avatarUrl,
                  size: 48,
                ),

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

            if (comentario.esCita)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorCita.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border(left: BorderSide(color: colorCita, width: 4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_quote_rounded,
                          color: colorCita,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Cita del libro',
                          style: AppTextStyles.caption.copyWith(
                            color: colorCita,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '“${comentario.comentario}”',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 17,
                        height: 1.55,
                        color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              )
            else
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
                Tooltip(
                  message: miReaccion?.titulo ?? 'Reaccionar',
                  child: IconButton.filledTonal(
                    key: _reaccionKey,
                    onPressed: _mostrarReacciones,
                    icon: miReaccion == null
                        ? const Icon(Icons.add_reaction_outlined, size: 22)
                        : Text(
                            miReaccion!.emoji,
                            style: const TextStyle(fontSize: 21),
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

            if (reacciones.values.any((total) => total > 0)) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: ReaccionComentario.values
                    .where((tipo) => (reacciones[tipo] ?? 0) > 0)
                    .map(
                      (tipo) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: miReaccion == tipo
                              ? AppColors.primaryLight
                              : AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '${tipo.emoji} ${reacciones[tipo]}',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

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

  Color _colorCita(String value) {
    final limpio = value.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(limpio)) {
      return AppColors.primary;
    }
    return Color(int.parse('FF$limpio', radix: 16));
  }

  @override
  void dispose() {
    respuestaController.dispose();
    super.dispose();
  }
}
