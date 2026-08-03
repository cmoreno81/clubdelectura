import 'package:flutter/material.dart';

import '../models/notificacion.dart';
import '../navigation/app_page_route.dart';
import '../navigation/book_detail_navigation.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/club_context_controller.dart';
import '../services/club_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/error_view.dart';
import 'clubvision_menu_page.dart';
import 'home_page.dart';
import 'lectura_page.dart';

class NotificacionesPage extends StatefulWidget {
  const NotificacionesPage({super.key});

  @override
  State<NotificacionesPage> createState() => _NotificacionesPageState();
}

class _NotificacionesPageState extends State<NotificacionesPage> {
  late Future<NotificacionesData> _future;
  final Set<String> _eliminadas = {};
  final Set<String> _abriendo = {};

  @override
  void initState() {
    super.initState();
    _future = ApiService().getNotificaciones();
  }

  Future<void> _marcarTodas() async {
    await ApiService().marcarTodasNotificacionesLeidas();
    setState(() {
      _future = ApiService().getNotificaciones();
    });
  }

  Future<void> _marcarLeida(String id) async {
    await ApiService().marcarNotificacionLeida(id);
    // Refresh silencioso
    ApiService().getNotificaciones().then((data) {
      if (mounted) {
        setState(() {
          _future = Future.value(data);
        });
      }
    });
  }

  Future<bool> _eliminar(Notificacion notificacion) async {
    try {
      await ApiService().eliminarNotificacion(notificacion.id);
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'No se ha podido borrar la notificación',
            ),
          ),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          TextButton(
            onPressed: _marcarTodas,
            child: const Text('Marcar todas'),
          ),
        ],
      ),
      body: FutureBuilder<NotificacionesData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              onRetry: () {
                setState(() {
                  _future = ApiService().getNotificaciones();
                });
              },
            );
          }

          final data = snapshot.data!;
          final notificaciones = data.notificaciones
              .where((notificacion) => !_eliminadas.contains(notificacion.id))
              .toList(growable: false);

          if (notificaciones.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 72,
                    color: AppColors.textMuted.withValues(alpha: .4),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Todo al día', style: AppTextStyles.section),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'No tienes notificaciones pendientes',
                    style: AppTextStyles.bodySecondary,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            itemCount: notificaciones.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final n = notificaciones[i];
              return Dismissible(
                key: ValueKey(n.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) => _eliminar(n),
                onDismissed: (_) => setState(() => _eliminadas.add(n.id)),
                background: Container(
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  alignment: Alignment.centerRight,
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                  ),
                ),
                child: _NotificacionCard(
                  notificacion: n,
                  loading: _abriendo.contains(n.id),
                  onTap: () async {
                    if (_abriendo.contains(n.id)) return;
                    setState(() => _abriendo.add(n.id));
                    try {
                      if (!n.leida) await _marcarLeida(n.id);
                      if (mounted) await _navegarA(n);
                    } finally {
                      if (mounted) setState(() => _abriendo.remove(n.id));
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _navegarA(Notificacion n) async {
    final selectedClub = await _selectClub(n.clubId);
    if (!mounted || !selectedClub) return;

    final title = _bookTitle(n);
    switch (n.tipo) {
      case 'LIBRO_TERMINADO':
      case 'LIBRO_EMPEZADO':
      case 'LIBRO_NUEVO_BIBLIOTECA':
        if (title.isNotEmpty) {
          await openBookDetail(
            context,
            title: title,
            bookId: n.bookId?.trim() ?? '',
          );
          return;
        }
        break;
      case 'LECTURA_NUEVA':
      case 'COMENTARIO_LECTURA':
        if (title.isNotEmpty) {
          await Navigator.push<void>(
            context,
            AppPageRoute(builder: (_) => LecturaPage(libro: title)),
          );
          return;
        }
        break;
      case 'CLUBVISION_ABIERTA':
      case 'CLUBVISION_RESULTADOS':
        await Navigator.push<void>(
          context,
          AppPageRoute(builder: (_) => const ClubvisionMenuPage()),
        );
        return;
      case 'NUEVA_MIEMBRO':
        final clubId = n.clubId?.trim() ?? '';
        final clubs = await ClubService().getMyClubs();
        if (!mounted) return;
        final matches = clubs.clubs.where((club) => club.id == clubId);
        if (matches.isNotEmpty) {
          await Navigator.push<void>(
            context,
            AppPageRoute(builder: (_) => HomePage(club: matches.first)),
          );
          return;
        }
        break;
      default:
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta notificación no tiene un destino disponible.'),
        ),
      );
    }
  }

  Future<bool> _selectClub(String? clubId) async {
    final id = clubId?.trim() ?? '';
    if (id.isEmpty) return true;
    try {
      await ClubService().selectClub(id);
      ClubContextController.instance.refresh();
      return true;
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return false;
    }
  }

  String _bookTitle(Notificacion notification) {
    final extra = notification.extra ?? const <String, dynamic>{};
    for (final key in const ['bookTitle', 'titulo', 'libro']) {
      final value = extra[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    final quoted = RegExp(r'[“"]([^”"]+)[”"]').firstMatch(notification.mensaje);
    return quoted?.group(1)?.trim() ?? '';
  }
}

class _NotificacionCard extends StatelessWidget {
  const _NotificacionCard({
    required this.notificacion,
    required this.onTap,
    required this.loading,
  });

  final Notificacion notificacion;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final leida = notificacion.leida;

    return ClubCard(
      elevated: !leida,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emoji / indicador
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: leida ? AppColors.surfaceSoft : AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              notificacion.emoji,
              style: const TextStyle(fontSize: 22),
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
                        notificacion.titulo,
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: leida ? FontWeight.w600 : FontWeight.w800,
                          color: leida
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (loading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (!leida)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notificacion.mensaje,
                  style: AppTextStyles.body.copyWith(
                    color: leida
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatFecha(notificacion.fecha),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(String iso) {
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
