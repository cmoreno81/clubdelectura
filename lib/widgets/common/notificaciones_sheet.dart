import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/notificacion.dart';
import '../../services/api_service.dart';
import '../../services/notificaciones_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/lectura/fecha_relativa.dart';

/// Muestra un bottom sheet con notificaciones filtradas.
///
/// Devuelve la [Notificacion] que el usuario pulsó (para que el caller
/// navegue con su propio contexto), o `null` si cerró sin pulsar nada.
/// Si el usuario marcó notificaciones como leídas sin pulsar ninguna,
/// devuelve el primer elemento de la lista como señal de "hubo cambios"
/// (el caller solo necesita saber si debe refrescar el badge).
Future<Notificacion?> mostrarNotificacionesSheet(
  BuildContext context, {
  required String titulo,
  required bool Function(Notificacion) filtro,
}) {
  return showModalBottomSheet<Notificacion>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Sin color propio para que el DraggableScrollableSheet pinte su fondo
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => _NotificacionesSheet(titulo: titulo, filtro: filtro),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _NotificacionesSheet extends StatefulWidget {
  const _NotificacionesSheet({required this.titulo, required this.filtro});

  final String titulo;
  final bool Function(Notificacion) filtro;

  @override
  State<_NotificacionesSheet> createState() => _NotificacionesSheetState();
}

class _NotificacionesSheetState extends State<_NotificacionesSheet> {
  List<Notificacion>? _notifs;
  bool _loading = true;
  bool _marcandoTodas = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await ApiService().getNotificaciones();
      if (!mounted) return;
      final filtradas = data.notificaciones.where(widget.filtro).toList();
      setState(() {
        _notifs = filtradas;
        _loading = false;
      });
      // NO auto-marcamos al abrir: el usuario debe ver qué es nuevo.
      // El badge global se resetea cuando el sheet cierra o el usuario toca algo.
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _marcarTodas() async {
    setState(() => _marcandoTodas = true);
    // Usar el servicio para que todos los badges se actualicen
    await NotificacionesService.instance.marcarTodas();
    if (!mounted) return;
    setState(() {
      _marcandoTodas = false;
      _notifs = _notifs?.map((n) => n.copyWith(leida: true)).toList();
    });
  }

  void _tocar(Notificacion n) {
    // Marcar como leída en el servicio (actualiza todos los badges)
    if (!n.leida) {
      unawaited(NotificacionesService.instance.marcarLeida(n.id, tipo: n.tipo));
      // Actualizar la lista local para que el punto desaparezca
      setState(() {
        _notifs = _notifs
            ?.map((x) => x.id == n.id ? x.copyWith(leida: true) : x)
            .toList();
      });
    }
    // Cerrar el sheet y devolver la notificación al caller para que navegue
    Navigator.pop(context, n);
  }

  int get _noLeidas => _notifs?.where((n) => !n.leida).length ?? 0;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
          // ── Handle ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),

          // ── Cabecera ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.titulo,
                          style: AppTextStyles.section,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_noLeidas > 0) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '$_noLeidas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_noLeidas > 0 && !_loading)
                  _marcandoTodas
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: _marcarTodas,
                          child: const Text('Marcar leídas'),
                        ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Cuerpo ────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : (_notifs == null || _notifs!.isEmpty)
                ? const _EmptyNotifs()
                : ListView.separated(
                    controller: scrollController,
                    itemCount: _notifs!.length,
                    separatorBuilder:
                        (context, i) => const Divider(
                          height: 1,
                          indent: AppSpacing.lg + 24 + AppSpacing.md,
                        ),
                    itemBuilder:
                        (_, i) => _NotifTile(
                          notif: _notifs![i],
                          onTap: () => _tocar(_notifs![i]),
                        ),
                  ),
          ),
        ],
      ),    // Column
        ),  // ColoredBox
      ),    // ClipRRect
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.notif, required this.onTap});

  final Notificacion notif;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final leida = notif.leida;

    return InkWell(
      onTap: onTap,
      child: ColoredBox(
        color: leida ? Colors.transparent : AppColors.primary.withValues(alpha: .04),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji
              SizedBox(
                width: 24,
                child: Text(
                  notif.emoji,
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subtitle.copyWith(
                              fontWeight:
                                  leida ? FontWeight.w500 : FontWeight.w700,
                              color:
                                  leida
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!leida)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(left: AppSpacing.sm),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Text(
                      notif.mensaje,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: leida ? AppColors.textMuted : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      FechaRelativa.formato(notif.fecha),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EmptyNotifs extends StatelessWidget {
  const _EmptyNotifs();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Todo al día', style: AppTextStyles.subtitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No hay notificaciones nuevas',
            style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
