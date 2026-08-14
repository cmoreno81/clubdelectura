import 'dart:async';

import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../navigation/book_detail_navigation.dart';

import '../models/lectura_activa.dart';
import '../models/notificacion.dart';
import '../services/api_service.dart';
import '../services/notificaciones_service.dart';
import '../services/reading_last_seen_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/common/notificaciones_sheet.dart';
import '../widgets/lectura/fecha_relativa.dart';
import '../widgets/ui/club_metric.dart';
import 'capitulo_page.dart';
import 'configurar_lectura_page.dart';
import 'lectura_page.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';

class LecturasPage extends StatefulWidget {
  const LecturasPage({super.key, this.onBackToClub});

  final VoidCallback? onBackToClub;

  @override
  State<LecturasPage> createState() => _LecturasPageState();
}

class _LecturasPageState extends State<LecturasPage> {
  late Future<List<LecturaActiva>> future;

  /// Última vez que el usuario abrió cada lectura, indexado por título.
  Map<String, DateTime> _lastSeen = {};

  @override
  void initState() {
    super.initState();
    _recargar();
    // Asegurar que el servicio compartido tiene datos actualizados
    unawaited(NotificacionesService.instance.cargar());
  }

  /// Abre el sheet de notificaciones y navega al destino correcto.
  Future<void> _abrirNotificaciones() async {
    final notif = await mostrarNotificacionesSheet(
      context,
      titulo: 'Novedades en Lecturas',
      filtro:
          (n) =>
              n.tipo == 'LECTURA_NUEVA' || n.tipo == 'COMENTARIO_LECTURA',
    );

    // Refrescar el servicio compartido (actualiza todos los badges)
    unawaited(NotificacionesService.instance.cargar());

    if (notif == null || !mounted) return;
    await _navegarDesdeNotificacion(notif);
  }

  Future<void> _navegarDesdeNotificacion(Notificacion n) async {
    final extra = n.extra ?? const <String, dynamic>{};

    // Extraer título del libro
    String libro = '';
    for (final key in const ['bookTitle', 'titulo', 'libro']) {
      final v = extra[key]?.toString().trim() ?? '';
      if (v.isNotEmpty) { libro = v; break; }
    }
    // Fallback: intentar leerlo del mensaje entre comillas
    if (libro.isEmpty) {
      final match = RegExp(r'["«"]([^""»"]+)["»"]').firstMatch(n.mensaje);
      libro = match?.group(1)?.trim() ?? '';
    }
    if (libro.isEmpty) return;

    // Extraer capítulo si existe (COMENTARIO_LECTURA lleva el capítulo en extra)
    String capitulo = '';
    for (final key in const ['capitulo', 'capituloId', 'capituloNombre', 'chapter']) {
      final v = extra[key]?.toString().trim() ?? '';
      if (v.isNotEmpty) { capitulo = v; break; }
    }

    if (!mounted) return;

    if (capitulo.isNotEmpty) {
      // Navegar directamente al capítulo con el comentario
      await Navigator.push(
        context,
        AppPageRoute(
          builder:
              (_) => CapituloPage(
                libro: libro,
                capitulo: capitulo,
                bookId: n.bookId ?? '',
              ),
        ),
      );
    } else {
      // Navegar a la página de la lectura (el usuario elegirá capítulo)
      await Navigator.push(
        context,
        AppPageRoute(builder: (_) => LecturaPage(libro: libro)),
      );
    }

    if (mounted) setState(_recargar);
  }

  void _recargar() {
    final f = ApiService().getLecturasActivas();
    future = f;
    // Carga los timestamps en cuanto tengamos los títulos.
    f.then((lecturas) {
      if (!mounted) return;
      ReadingLastSeenService.ultimasVistas(
        lecturas.map((l) => l.libro),
      ).then((map) {
        if (mounted) setState(() => _lastSeen = map);
      });
    }).ignore();
  }

  Future<void> _refrescar() async {
    setState(_recargar);
    await future;
  }

  /// Devuelve true si [lectura] tiene actividad posterior a la última vez
  /// que el usuario la abrió.
  bool _tieneActividadNueva(LecturaActiva lectura) {
    final raw = lectura.ultimaActividad;
    if (raw == null || raw.trim().isEmpty) return false;
    final ultimaAct = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (ultimaAct == null) return false;
    final visto = _lastSeen[lectura.libro];
    // Nunca la abrió → no mostramos badge para no alarmar desde el principio.
    if (visto == null) return false;
    return ultimaAct.isAfter(visto);
  }

  Future<void> _abrirLectura(LecturaActiva lectura) async {
    if (!lectura.configurada) {
      final creado = await Navigator.push<bool>(
        context,
        AppPageRoute(
          builder: (_) =>
              ConfigurarLecturaPage(libro: lectura.libro, tipo: lectura.tipo),
        ),
      );

      if (!mounted) return;

      if (creado == true) {
        setState(_recargar);
      }

      return;
    }

    // Registramos la apertura ANTES de navegar para que al volver
    // el badge desaparezca sin esperar a la próxima carga.
    await ReadingLastSeenService.marcarVista(lectura.libro);
    if (!mounted) return;
    setState(() => _lastSeen[lectura.libro] = DateTime.now());

    if (!mounted) return;
    await Navigator.push(
      context,
      AppPageRoute(
        builder: (_) =>
            LecturaPage(libro: lectura.libro, coverUrl: lectura.coverUrl),
      ),
    );

    if (!mounted) return;

    setState(_recargar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.onBackToClub == null,
        leading: widget.onBackToClub == null
            ? null
            : IconButton(
                tooltip: 'Volver a El Club',
                onPressed: widget.onBackToClub,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
        title: const Text('Lecturas'),
        actions: [
          ListenableBuilder(
            listenable: NotificacionesService.instance,
            builder: (context, _) {
              final n = NotificacionesService.instance.noLeidasLecturas;
              return IconButton(
                tooltip: 'Notificaciones',
                onPressed: _abrirNotificaciones,
                icon: Badge(
                  isLabelVisible: n > 0,
                  label: Text(n < 10 ? '$n' : '9+'),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              );
            },
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: FutureBuilder<List<LecturaActiva>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CardListSkeleton();
          }

          if (snapshot.hasError) {
            return _ErrorLecturas(
              onRetry: () {
                setState(_recargar);
              },
            );
          }

          final lecturas = snapshot.data ?? const <LecturaActiva>[];

          if (lecturas.isEmpty) {
            return _LecturasVacias(onRefresh: _refrescar);
          }

          final oficiales = lecturas
              .where((lectura) => lectura.esOficial && lectura.configurada)
              .toList();

          final compartidas = lecturas
              .where((lectura) => !lectura.esOficial && lectura.configurada)
              .toList();

          final pendientes = lecturas
              .where((lectura) => !lectura.configurada)
              .toList();

          final mayorNumeroComentarios = lecturas.fold<int>(0, (
            mayor,
            lectura,
          ) {
            return lectura.comentarios > mayor ? lectura.comentarios : mayor;
          });

          bool esMasComentada(LecturaActiva lectura) {
            return mayorNumeroComentarios > 0 &&
                lectura.comentarios == mayorNumeroComentarios;
          }

          return RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                110,
              ),
              children: [
                _CabeceraLecturas(total: lecturas.length),

                const SizedBox(height: AppSpacing.md),

                if (oficiales.isNotEmpty) ...[
                  const _SectionTitle(
                    icon: Icons.emoji_events_outlined,
                    color: AppColors.primary,
                    title: 'Lectura oficial',
                    subtitle: 'La historia elegida por el club',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  for (final lectura in oficiales) ...[
                    _LecturaCard(
                      lectura: lectura,
                      destacada: true,
                      masComentada: esMasComentada(lectura),
                      tieneActividadNueva: _tieneActividadNueva(lectura),
                      onTap: () => _abrirLectura(lectura),
                      onBookTap: () => openBookDetail(
                        context,
                        title: lectura.libro,
                        coverUrl: lectura.coverUrl,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                ],

                if (compartidas.isNotEmpty) ...[
                  const _SectionTitle(
                    icon: Icons.groups_2_outlined,
                    color: AppColors.info,
                    title: 'Lecturas compartidas',
                    subtitle: 'Historias que coinciden entre lectoras',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  for (final lectura in compartidas) ...[
                    _LecturaCard(
                      lectura: lectura,
                      masComentada: esMasComentada(lectura),
                      tieneActividadNueva: _tieneActividadNueva(lectura),
                      onTap: () => _abrirLectura(lectura),
                      onBookTap: () => openBookDetail(
                        context,
                        title: lectura.libro,
                        coverUrl: lectura.coverUrl,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                ],

                if (pendientes.isNotEmpty) ...[
                  const _SectionTitle(
                    icon: Icons.settings_outlined,
                    color: Color(0xFFB48113),
                    title: 'Pendientes de configurar',
                    subtitle: 'Estas lecturas todavía necesitan capítulos',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  for (final lectura in pendientes) ...[
                    _LecturaCard(
                      lectura: lectura,
                      onTap: () => _abrirLectura(lectura),
                      onBookTap: () => openBookDetail(
                        context,
                        title: lectura.libro,
                        coverUrl: lectura.coverUrl,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CabeceraLecturas extends StatelessWidget {
  final int total;

  const _CabeceraLecturas({required this.total});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceSoft, Color(0xFFF1E8FF)],
      ),
      borderColor: AppColors.primaryLight,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.primary,
              size: 25,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lecturas del club',
                  style: AppTextStyles.section.copyWith(fontSize: 21),
                ),
                const SizedBox(height: 2),
                Text(
                  total == 1 ? '1 lectura activa' : '$total lecturas activas',
                  style: AppTextStyles.bodySecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(icon, color: color, size: 27),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.section.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                subtitle,
                style: AppTextStyles.bodySecondary.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LecturaCard extends StatelessWidget {
  final LecturaActiva lectura;
  final VoidCallback onTap;
  final VoidCallback onBookTap;
  final bool destacada;
  final bool masComentada;
  final bool tieneActividadNueva;

  const _LecturaCard({
    required this.lectura,
    required this.onTap,
    required this.onBookTap,
    this.destacada = false,
    this.masComentada = false,
    this.tieneActividadNueva = false,
  });

  @override
  Widget build(BuildContext context) {
    final tieneActividad = lectura.ultimaActividad?.trim().isNotEmpty == true;

    return ClubCard(
      elevated: destacada,
      padding: const EdgeInsets.all(AppSpacing.md),
      gradient: destacada
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8F3FF), Color(0xFFF1E8FF)],
            )
          : null,
      borderColor: destacada
          ? AppColors.primaryLight
          : lectura.configurada
          ? AppColors.border
          : const Color(0xFFF1E2B3),
      backgroundColor: lectura.configurada
          ? AppColors.surface
          : const Color(0xFFFFFBF0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: onBookTap,
                child: Hero(
                  tag: 'book-${lectura.libro}',
                  child: ClubBookCover(
                    title: lectura.libro,
                    imageUrl: lectura.coverUrl,
                    width: destacada ? 104 : 92,
                    showShadow: true,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      onTap: onBookTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          lectura.libro,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.subtitle.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: destacada ? 21 : 20,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (!lectura.configurada)
                          const ClubChip(
                            label: 'Pendiente',
                            icon: Icons.settings_outlined,
                            variant: ClubChipVariant.warning,
                          )
                        else if (lectura.esOficial)
                          const ClubChip(
                            label: 'Lectura oficial',
                            icon: Icons.emoji_events_outlined,
                            variant: ClubChipVariant.primary,
                          )
                        else
                          const ClubChip(
                            label: 'Compartida',
                            icon: Icons.groups_2_outlined,
                            variant: ClubChipVariant.info,
                          ),

                        if (masComentada)
                          const ClubChip(
                            label: 'Debate activo',
                            icon: Icons.local_fire_department_outlined,
                            variant: ClubChipVariant.danger,
                          ),

                        if (tieneActividadNueva)
                          const ClubChip(
                            label: 'Nuevo',
                            icon: Icons.mark_chat_unread_outlined,
                            variant: ClubChipVariant.success,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ClubMetric(
                icon: Icons.people_outline_rounded,
                value: '${lectura.lectoras}',
                label: lectura.lectoras == 1 ? 'lectora' : 'lectoras',
                variant: ClubMetricVariant.info,
                compact: true,
              ),

              ClubMetric(
                icon: Icons.chat_bubble_outline_rounded,
                value: '${lectura.comentarios}',
                label: lectura.comentarios == 1 ? 'comentario' : 'comentarios',
                variant: ClubMetricVariant.primary,
                compact: true,
              ),
            ],
          ),

          if (tieneActividad) ...[
            const SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: destacada ? 0.68 : 1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 17,
                    color: AppColors.textMuted,
                  ),

                  const SizedBox(width: AppSpacing.xs),

                  Expanded(
                    child: Text(
                      FechaRelativa.formato(lectura.ultimaActividad),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (lectura.configurada) ...[
            const SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Todavía no hay comentarios. ¿Quién rompe el hielo?',
                style: AppTextStyles.caption.copyWith(height: 1.3),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onBookTap,
                  icon: const Icon(Icons.info_outline_rounded),
                  label: const Text('Ver ficha'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onTap,
                  icon: Icon(
                    lectura.configurada
                        ? Icons.auto_stories_outlined
                        : Icons.settings_outlined,
                  ),
                  label: Text(
                    lectura.configurada ? 'Abrir lectura' : 'Configurar',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LecturasVacias extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _LecturasVacias({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_stories_outlined,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      'Todavía no hay lecturas compartidas',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.section,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Cuando el club empiece una historia, aparecerá aquí.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorLecturas extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorLecturas({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: AppColors.textMuted,
            ),

            const SizedBox(height: AppSpacing.md),

            const Text(
              'No hemos podido cargar las lecturas.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.md),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
