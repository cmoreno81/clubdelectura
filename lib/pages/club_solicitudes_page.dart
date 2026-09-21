import 'package:flutter/material.dart';

import '../models/club_directory.dart';
import '../services/api_exception.dart';
import '../services/club_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/error_view.dart';

/// Solicitudes pendientes de ingreso a un club público — solo visible para
/// quien administra el club (OWNER/ADMIN).
class SolicitudesClubPage extends StatefulWidget {
  final String clubId;
  final String clubNombre;

  const SolicitudesClubPage({
    super.key,
    required this.clubId,
    required this.clubNombre,
  });

  @override
  State<SolicitudesClubPage> createState() => _SolicitudesClubPageState();
}

class _SolicitudesClubPageState extends State<SolicitudesClubPage> {
  late Future<List<SolicitudClub>> _future;
  final Set<String> _procesando = {};

  @override
  void initState() {
    super.initState();
    _future = ClubService().getSolicitudesClub(widget.clubId);
  }

  void _recargar() =>
      setState(() => _future = ClubService().getSolicitudesClub(widget.clubId));

  Future<void> _responder(SolicitudClub solicitud, bool aceptar) async {
    setState(() => _procesando.add(solicitud.id));
    try {
      await ClubService().responderSolicitudClub(
        clubId: widget.clubId,
        requestId: solicitud.id,
        aceptar: aceptar,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aceptar
                ? '${solicitud.nombre} ahora forma parte del club'
                : 'Solicitud de ${solicitud.nombre} rechazada',
          ),
        ),
      );
      _recargar();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _procesando.remove(solicitud.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Solicitudes · ${widget.clubNombre}')),
      body: FutureBuilder<List<SolicitudClub>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(onRetry: _recargar);
          }
          final solicitudes = snapshot.data ?? const [];
          if (solicitudes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mark_email_read_outlined,
                      size: 56,
                      color: AppColors.primary.withValues(alpha: .4),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No hay solicitudes pendientes',
                      style: AppTextStyles.section,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _recargar(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: solicitudes.length,
              itemBuilder: (context, index) {
                final s = solicitudes[index];
                final procesando = _procesando.contains(s.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        ClubAvatar(nombre: s.nombre, imageUrl: s.avatarUrl, size: 44),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            s.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (procesando)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else ...[
                          IconButton(
                            tooltip: 'Rechazar',
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.danger,
                            ),
                            onPressed: () => _responder(s, false),
                          ),
                          IconButton(
                            tooltip: 'Aceptar',
                            icon: const Icon(
                              Icons.check_rounded,
                              color: AppColors.success,
                            ),
                            onPressed: () => _responder(s, true),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
