import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../navigation/app_page_route.dart';
import '../navigation/book_detail_navigation.dart';

import '../models/perfil_usuario.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/genero_utils.dart';
import '../utils/wrapped_availability.dart';
import '../widgets/common/checkin_button.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/common/club_empty_state.dart';
import '../widgets/common/club_section_title.dart';
import '../widgets/common/mapa_calor_widget.dart';
import '../widgets/common/optimized_network_image.dart';
import '../widgets/profile/book_of_year_preview.dart';
import '../widgets/error_view.dart';
import '../services/usuario_service.dart';
import '../widgets/perfil/editar_fechas_lectura_dialog.dart';
import '../utils/lectura_fecha_utils.dart';
import 'wrapped_page.dart';
import '../widgets/perfil/editar_avatar_dialog.dart';
import '../widgets/perfil/perfil_timeline_lectura.dart';
import '../widgets/perfil/perfil_historico_meses.dart';
import '../widgets/common/club_rating_stars.dart';
import 'acerca_de_page.dart';
import 'ayuda_page.dart';
import 'change_password_page.dart';
import 'goodreads_import_page.dart';
import 'hidden_series_page.dart';
import '../services/auth_service.dart';
import '../services/favoritos_service.dart';
import '../widgets/dashboard/year_reading_shelf.dart';
import '../models/general_dashboard.dart' show YearShelfBook;
import 'year_reading_share_page.dart';
import '../models/achievements/achievement.dart';
import '../services/achievement_service.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';

class PerfilUsuarioPage extends StatefulWidget {
  const PerfilUsuarioPage({
    super.key,
    required this.usuario,
    this.initialTab = 'RESUMEN',
    this.scrollToSeguimiento = false,
    this.loadProfile,
    this.loadCurrentUser,
    this.onEditReading,
    this.bookOfYearPreviewBuilder,
    this.trackingContentBuilder,
    this.hiddenSeriesBuilder,
  });

  final String usuario;
  final String initialTab;

  /// Si es true, hace scroll automático a la sección "Seguimiento lector"
  /// una vez cargado el perfil.
  final bool scrollToSeguimiento;
  final Future<PerfilUsuario> Function()? loadProfile;
  final Future<String?> Function()? loadCurrentUser;
  final Future<void> Function(PerfilLibroTerminado book)? onEditReading;
  final Widget Function(String profile, bool editable)?
  bookOfYearPreviewBuilder;
  final Widget Function()? trackingContentBuilder;
  final Widget Function()? hiddenSeriesBuilder;

  @override
  State<PerfilUsuarioPage> createState() => _PerfilUsuarioPageState();
}

class _FinalizadosYearGroup extends StatelessWidget {
  const _FinalizadosYearGroup({
    required this.year,
    required this.books,
    required this.itemBuilder,
  });

  final int? year;
  final List<PerfilLibroTerminado> books;
  final Widget Function(PerfilLibroTerminado book) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final label = year?.toString() ?? 'Sin fecha';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClubCard(
        elevated: false,
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            clipBehavior: Clip.antiAlias,
            child: ExpansionTile(
              key: PageStorageKey('finalizados-${year ?? 'sin-fecha'}'),
              initiallyExpanded: true,
              tilePadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              iconColor: color,
              collapsedIconColor: AppColors.textMuted,
              title: Row(
                children: [
                  Text(
                    label,
                    style: AppTextStyles.title.copyWith(
                      color: color,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Divider(color: color.withValues(alpha: .22))),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    books.length == 1 ? '1 libro' : '${books.length} libros',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              children: books
                  .map(
                    (book) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: itemBuilder(book),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }
}

class _PerfilUsuarioPageState extends State<PerfilUsuarioPage> {
  late Future<PerfilUsuario> future;
  String? usuarioActual;
  String _menuPerfil = 'RESUMEN';
  String _historialVista = 'CRONOLOGIA';
  int? _historialYear;

  final _scrollController = ScrollController();

  /// Clave global para el título de "Seguimiento lector" — usada para scroll automático.
  final _seguimientoKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _menuPerfil = switch (widget.initialTab) {
      'TIMELINE' || 'LIBROS' => 'HISTORIAL',
      'SAGAS_OCULTAS' => 'MAS',
      _ => widget.initialTab,
    };
    if (widget.initialTab != 'LOGROS') {
      future = _cargarPerfil();
    }
    _cargarUsuarioActual();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _seleccionarSeccion(String seccion) {
    setState(() => _menuPerfil = seccion);
    // Recargar al entrar en Meses para tener datos frescos
    if (seccion == 'MESES') {
      _recargar();
    }
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _editarAvatar(PerfilUsuario perfil) async {
    if (!esMiPerfil) return;

    final nuevaUrl = await showDialog<String>(
      context: context,
      builder: (_) => EditarAvatarDialog(avatarUrlActual: perfil.avatarUrl),
    );

    if (nuevaUrl == null) return;

    final respuesta = await ApiService().actualizarAvatarPerfil(
      usuario: widget.usuario,
      avatarUrl: nuevaUrl,
    );

    if (!mounted) return;

    final ok = respuesta['ok'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          respuesta['mensaje']?.toString() ??
              (ok
                  ? 'Foto de perfil actualizada'
                  : 'No se ha podido actualizar la foto'),
        ),
      ),
    );

    if (ok) {
      await _recargar();
    }
  }

  Future<void> _editarFechas(PerfilLibroTerminado libro) async {
    if (!esMiPerfil || libro.libraryId.trim().isEmpty) {
      return;
    }
    if (widget.onEditReading != null) {
      await widget.onEditReading!(libro);
      if (mounted) await _recargar();
      return;
    }

    final resultado = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => EditarFechasLecturaDialog(libro: libro),
    );

    if (resultado == null) return;

    Map<String, dynamic> respuesta;

    try {
      respuesta = await ApiService().actualizarFechasLectura(
        usuario: widget.usuario,
        libraryId: libro.libraryId,
        completionId: libro.completionId,
        fechaInicio: resultado['fechaInicio'] ?? '',
        fechaFin: resultado['fechaFin'] ?? '',
        valoracion: resultado['valoracion'],
        resena: resultado['resena'],
      );
    } catch (_) {
      respuesta = {
        'ok': false,
        'mensaje': 'No se han podido actualizar las fechas.',
      };
    }

    if (!mounted) return;

    final ok = respuesta['ok'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          respuesta['mensaje']?.toString() ??
              (ok
                  ? 'Fechas actualizadas'
                  : 'No se han podido actualizar las fechas'),
        ),
      ),
    );

    if (ok) {
      await _recargar();
    }
  }

  Future<void> _cargarUsuarioActual() async {
    final usuario =
        await (widget.loadCurrentUser?.call() ??
            UsuarioService().obtenerUsuario());
    if (!mounted) return;
    setState(() {
      usuarioActual = usuario?.trim();
    });
    // Cargar favoritos del servicio singleton (para la vista propia)
    if (widget.loadCurrentUser == null &&
        usuario != null &&
        usuario.trim().toLowerCase() == widget.usuario.trim().toLowerCase()) {
      unawaited(FavoritosService.instance.cargar());
    }
  }

  bool get esMiPerfil {
    return usuarioActual != null &&
        usuarioActual!.trim().isNotEmpty &&
        usuarioActual!.toLowerCase() == widget.usuario.trim().toLowerCase();
  }

  Future<PerfilUsuario> _cargarPerfil() {
    return widget.loadProfile?.call() ??
        ApiService().getPerfilUsuarioCompleto(widget.usuario);
  }

  Future<void> _recargar() async {
    final previousOffset = _scrollController.hasClients
        ? _scrollController.offset
        : null;
    setState(() {
      future = _cargarPerfil();
    });
    await future;
    if (!mounted || previousOffset == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(
        previousOffset.clamp(0, _scrollController.position.maxScrollExtent),
      );
    });
  }

  // ─── Sección activa ─────────────────────────────────────────────

  Widget _seccionActual(PerfilUsuario perfil) {
    switch (_menuPerfil) {
      case 'HISTORIAL':
        return _seccionHistorial(perfil);

      case 'FAVORITOS':
        return _seccionFavoritos(perfil);

      case 'MESES':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClubSectionTitle(
              title: 'Mis meses lectores',
              subtitle: 'Un calendario por cada mes leído',
              icon: Icons.calendar_view_month_outlined,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (perfil.historicoMeses.isEmpty)
              const ClubEmptyState(
                icon: Icons.calendar_view_month_outlined,
                title: 'Todavía no hay meses registrados',
                message:
                    'Aquí aparecerán tus calendarios de lectura mes a mes.',
              )
            else
              PerfilHistoricoMeses(
                meses: perfil.historicoMeses,
                onBookTap:
                    ({
                      required String title,
                      required String bookId,
                      required String coverUrl,
                    }) => openBookDetail(
                      context,
                      title: title,
                      bookId: bookId,
                      coverUrl: coverUrl,
                    ),
              ),
          ],
        );

      case 'LOGROS':
        return _PerfilLogrosSection(usuario: perfil.usuario);

      case 'MAS':
        if (!esMiPerfil) return const SizedBox.shrink();
        return _seccionMas();

      default: // RESUMEN
        return _seccionResumen(perfil);
    }
  }

  Widget _seccionHistorial(PerfilUsuario perfil) {
    final years = <int>{
      ...perfil.terminados
          .map((book) => LecturaFechaUtils.parse(book.fechaFin)?.year)
          .whereType<int>(),
      ...perfil.abandonados
          .map((book) => LecturaFechaUtils.parse(book.fechaFin)?.year)
          .whereType<int>(),
    }.toList()..sort((left, right) => right.compareTo(left));
    if (_historialYear == null || !years.contains(_historialYear)) {
      _historialYear = years.firstOrNull;
    }
    final selectedYear = _historialYear;
    final terminados = selectedYear == null
        ? <PerfilLibroTerminado>[]
        : perfil.terminados
              .where(
                (book) =>
                    LecturaFechaUtils.parse(book.fechaFin)?.year ==
                    selectedYear,
              )
              .toList(growable: false);
    final abandonados = selectedYear == null
        ? <PerfilLibroTerminado>[]
        : perfil.abandonados
              .where(
                (book) =>
                    LecturaFechaUtils.parse(book.fechaFin)?.year ==
                    selectedYear,
              )
              .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ClubSectionTitle(
          title: 'Historial',
          subtitle: 'Tu recorrido lector año a año',
          icon: Icons.history_rounded,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 'CRONOLOGIA',
                    icon: Icon(Icons.timeline_rounded),
                    label: Text('Cronología'),
                  ),
                  ButtonSegment(
                    value: 'LIBROS',
                    icon: Icon(Icons.menu_book_outlined),
                    label: Text('Libros'),
                  ),
                ],
                selected: {_historialVista},
                onSelectionChanged: (selection) {
                  setState(() {
                    _historialVista = selection.first;
                  });
                },
              ),
            ),
            if (years.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              DropdownButton<int>(
                key: const ValueKey('history-year-selector'),
                value: selectedYear,
                items: years
                    .map(
                      (year) =>
                          DropdownMenuItem(value: year, child: Text('$year')),
                    )
                    .toList(growable: false),
                onChanged: (year) {
                  if (year == null) return;
                  setState(() {
                    _historialYear = year;
                  });
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (selectedYear == null)
          const ClubEmptyState(
            icon: Icons.history_rounded,
            title: 'Todavía no hay historial',
            message: 'Las lecturas con fecha aparecerán aquí.',
          )
        else if (_historialVista == 'CRONOLOGIA')
          if (terminados.isEmpty)
            const ClubEmptyState(
              icon: Icons.timeline_rounded,
              title: 'No hay actividad este año',
              message: 'El recorrido lector aparecerá aquí.',
            )
          else
            PerfilTimelineLectura(
              key: ValueKey('timeline-$selectedYear'),
              libros: terminados,
              sagas: perfil.sagas,
              onBookTap: (libro) => openBookDetail(
                context,
                title: libro.libro,
                bookId: libro.bookId,
                coverUrl: libro.coverUrl,
                genre: libro.genero,
              ),
            )
        else ...[
          if (terminados.isEmpty)
            const ClubEmptyState(
              icon: Icons.flag_outlined,
              title: 'No hay libros terminados este año',
              message: 'Las próximas lecturas finalizadas aparecerán aquí.',
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            )
          else
            _finalizadosAgrupados(terminados),
          const SizedBox(height: AppSpacing.lg),
          ClubSectionTitle(
            title: 'Libros abandonados',
            subtitle: 'Las lecturas que decidió dejar',
            icon: Icons.heart_broken_outlined,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (abandonados.isEmpty)
            const ClubEmptyState(
              icon: Icons.heart_broken_outlined,
              title: 'No hay libros abandonados este año',
              message: 'Todas sus lecturas siguen adelante.',
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            )
          else
            ...abandonados.map(
              (libro) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _libroAbandonado(libro: libro),
              ),
            ),
        ],
      ],
    );
  }

  Widget _seccionFavoritos(PerfilUsuario perfil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (esMiPerfil || perfil.favoritos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ClubSectionTitle(
            title: 'Libros favoritos',
            subtitle: esMiPerfil
                ? 'Tus 5 favoritos de siempre'
                : 'Sus 5 libros favoritos',
            icon: Icons.favorite_rounded,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FavoritosShelf(
            favoritos: perfil.favoritos,
            esMiPerfil: esMiPerfil,
            todosLosLibros: esMiPerfil
                ? [
                    ...perfil.leyendo.map(
                      (book) => _LibroSeleccionable(
                        bookId: book.bookId,
                        title: book.libro,
                        coverUrl: book.coverUrl,
                      ),
                    ),
                    ...perfil.terminados.map(
                      (book) => _LibroSeleccionable(
                        bookId: book.bookId,
                        title: book.libro,
                        coverUrl: book.coverUrl,
                      ),
                    ),
                    ...perfil.pendientes.map(
                      (book) => _LibroSeleccionable(
                        bookId: book.bookId,
                        title: book.libro,
                        coverUrl: book.coverUrl,
                      ),
                    ),
                  ]
                : const [],
          ),
        ],
        widget.bookOfYearPreviewBuilder?.call(perfil.usuario, esMiPerfil) ??
            BookOfYearPreview(profile: perfil.usuario, editable: esMiPerfil),
        if (esMiPerfil) ...[
          const SizedBox(height: AppSpacing.xl),
          _WrappedPerfilCta(
            availability: WrappedAvailability(),
            onTap: () => Navigator.push<void>(
              context,
              AppPageRoute(
                builder: (_) =>
                    WrappedPage(anio: WrappedAvailability().wrappedYear),
              ),
            ),
            onLongPress: () => Navigator.push<void>(
              context,
              AppPageRoute(
                builder: (_) =>
                    WrappedPage(anio: WrappedAvailability().wrappedYear),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _seccionResumen(PerfilUsuario perfil) {
    final now = DateTime.now();
    final yearBooks = perfil.terminados
        .where((libro) {
          final date = _parseFecha(libro.fechaFin);
          return date != null && date.year == now.year;
        })
        .map(
          (libro) => YearShelfBook(
            id: libro.completionId,
            bookId: libro.bookId,
            title: libro.libro,
            coverUrl: libro.coverUrl,
            finishedAt: libro.fechaFin,
          ),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Biblioteca del año PRIMERO ──
        if (yearBooks.isNotEmpty) ...[
          YearReadingShelf(
            key: ValueKey('year-${DateTime.now().year}'),
            year: now.year,
            books: yearBooks,
            onShare: esMiPerfil
                ? () => Navigator.push<void>(
                    context,
                    AppPageRoute(
                      builder: (_) => YearReadingSharePage(
                        year: now.year,
                        books: yearBooks,
                        userName: perfil.usuario,
                      ),
                    ),
                  )
                : null,
            onBookTap: (book) => openBookDetail(
              context,
              title: book.title,
              bookId: book.bookId,
              coverUrl: book.coverUrl,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // ── Su historia lectora DESPUÉS ──
        _resumenLectura(perfil),

        // ── Seguimiento lector (solo propio perfil) ──────────────────────────
        if (esMiPerfil) ...[
          const SizedBox(height: AppSpacing.xl),
          ClubSectionTitle(
            key: _seguimientoKey,
            title: 'Seguimiento de lectura',
            subtitle: 'Tu racha y actividad anual',
            icon: Icons.local_fire_department_outlined,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          widget.trackingContentBuilder?.call() ??
              Column(
                children: [
                  _CheckinSection(),
                  const SizedBox(height: AppSpacing.md),
                  ClubCard(elevated: false, child: MapaCalorWidget()),
                ],
              ),
        ],

        // ── Géneros favoritos ─────────────────────────────────────────────
        const SizedBox(height: AppSpacing.xl),
        const ClubSectionTitle(
          title: 'Géneros favoritos',
          subtitle: 'Los universos que más visitas',
          icon: Icons.favorite_border_rounded,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        ProfileFavoriteGenresContent(genres: perfil.generosFavoritos),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _seccionMas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ClubSectionTitle(
          title: 'Más',
          icon: Icons.settings_outlined,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        ClubCard(
          elevated: false,
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              key: const ValueKey('hidden-series-management'),
              leading: const Icon(Icons.visibility_off_outlined),
              title: const Text('Sagas ocultas'),
              subtitle: const Text(
                'Gestiona las sagas apartadas del seguimiento',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push<void>(
                context,
                AppPageRoute(
                  builder: (_) => HiddenSeriesPage(
                    contentBuilder: widget.hiddenSeriesBuilder,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClubCard(
          elevated: false,
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(Icons.auto_stories_outlined),
              title: const Text('Importar desde Bookmory'),
              subtitle: const Text('Trae tus lecturas terminadas y valoradas'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final imported = await Navigator.push<bool>(
                  context,
                  AppPageRoute(
                    builder: (_) => const GoodreadsImportPage(
                      source: ReadingImportSource.bookmory,
                    ),
                  ),
                );
                if (imported == true && mounted) {
                  await _recargar();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClubCard(
          elevated: false,
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(Icons.import_export_rounded),
              title: const Text('Importar desde Goodreads'),
              subtitle: const Text(
                'Trae tus libros sin sobrescribir ClubReaders',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final imported = await Navigator.push<bool>(
                  context,
                  AppPageRoute(builder: (_) => const GoodreadsImportPage()),
                );
                if (imported == true && mounted) {
                  await _recargar();
                }
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClubCard(
          elevated: false,
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('Sugerencias y errores'),
              subtitle: const Text('Cuéntanos qué mejorar o qué no funciona'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final uri = Uri(
                  scheme: 'mailto',
                  path: 'c.moreno.benavente@gmail.com',
                  queryParameters: {
                    'subject': 'ClubReaders · Sugerencia / Error',
                    'body':
                        'Hola,\n\nQuiero reportar lo siguiente:\n\n\n'
                        '---\n(Adjunta capturas si puedes, nos ayuda mucho 🙏)',
                  },
                );
                final abierto = await launchUrl(uri);
                if (!abierto && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No se ha podido abrir el correo.'),
                    ),
                  );
                }
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClubCard(
          elevated: false,
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(Icons.help_outline_rounded),
              title: const Text('Ayuda'),
              subtitle: const Text(
                'Guía completa de todas las funciones de la app',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push<void>(
                context,
                AppPageRoute(builder: (_) => const AyudaPage()),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClubCard(
          elevated: false,
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Acerca de ClubReaders'),
              subtitle: const Text('Versión, créditos, privacidad y contacto'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.push<void>(
                context,
                AppPageRoute(builder: (_) => const AcercaDePage()),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ClubCard(
          elevated: false,
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: const Text('Cambiar contraseña'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push<void>(
                    context,
                    AppPageRoute(builder: (_) => const ChangePasswordPage()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text('Cerrar sesión'),
                  onTap: _cerrarSesion,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Ruta rápida: si venimos de logros del club, mostrar logros sin esperar al perfil completo
    if (widget.initialTab == 'LOGROS' && _menuPerfil == 'LOGROS') {
      return Scaffold(
        appBar: AppBar(title: Text(widget.usuario.split(' ').first)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: _PerfilLogrosSection(usuario: widget.usuario),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil lector')),
      body: FutureBuilder<PerfilUsuario>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ProfileSkeleton();
          }

          if (snapshot.hasError) {
            return ErrorView(onRetry: _recargar);
          }

          final perfil = snapshot.data!;

          // Scroll automático a "Seguimiento lector" cuando se solicita
          if (widget.scrollToSeguimiento) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              final ctx = _seguimientoKey.currentContext;
              if (ctx != null) {
                Scrollable.ensureVisible(
                  ctx,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  alignment: 0.0,
                );
              }
            });
          }

          final tabs = [
            _TabItem('RESUMEN', Icons.person_outline_rounded, 'Resumen'),
            _TabItem('HISTORIAL', Icons.history_rounded, 'Historial'),
            _TabItem('FAVORITOS', Icons.favorite_outline_rounded, 'Favoritos'),
            _TabItem(
              'MESES',
              Icons.calendar_view_month_outlined,
              'Meses lectores',
            ),
            _TabItem('LOGROS', Icons.emoji_events_outlined, 'Logros'),
            if (esMiPerfil) _TabItem('MAS', Icons.settings_outlined, 'Más'),
          ];

          return RefreshIndicator(
            onRefresh: _recargar,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Cabecera ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      0,
                    ),
                    child: _cabeceraPerfil(perfil),
                  ),
                ),

                // ── Tabs pegados ──
                SliverPersistentHeader(
                  pinned: false, // ← sube con el scroll
                  floating: true,
                  delegate: _TabBarDelegate(
                    tabs: tabs,
                    selected: _menuPerfil,
                    onTap: _seleccionarSeccion,
                  ),
                ),

                // ── Contenido de la sección activa ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      100,
                    ),
                    child: _seccionActual(perfil),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    await AuthService().logout();
    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  DateTime? _parseFecha(String fecha) {
    if (fecha.isEmpty) return null;
    final iso = DateTime.tryParse(fecha);
    if (iso != null) return iso;
    final parts = fecha.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }

  Widget _finalizadosAgrupados(List<PerfilLibroTerminado> libros) {
    final ordenados = [...libros]
      ..sort((left, right) {
        final leftDate = LecturaFechaUtils.parse(left.fechaFin);
        final rightDate = LecturaFechaUtils.parse(right.fechaFin);
        if (leftDate == null && rightDate == null) return 0;
        if (leftDate == null) return 1;
        if (rightDate == null) return -1;
        return rightDate.compareTo(leftDate);
      });
    final grupos = <int?, List<PerfilLibroTerminado>>{};
    for (final libro in ordenados) {
      final year = LecturaFechaUtils.parse(libro.fechaFin)?.year;
      grupos.putIfAbsent(year, () => []).add(libro);
    }

    return Column(
      children: grupos.entries
          .map(
            (entry) => _FinalizadosYearGroup(
              year: entry.key,
              books: entry.value,
              itemBuilder: (book) => _libroTerminado(libro: book),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _cabeceraPerfil(PerfilUsuario perfil) {
    return ClubCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceSoft, Color(0xFFF0E5FF)],
      ),
      borderColor: AppColors.primaryLight,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClubAvatar(
                    nombre: perfil.usuario,
                    imageUrl: perfil.avatarUrl,
                    size: 96,
                    onTap: esMiPerfil
                        ? () {
                            _editarAvatar(perfil);
                          }
                        : null,
                  ),
                  if (esMiPerfil)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Material(
                        color: Theme.of(context).colorScheme.primary,
                        shape: const CircleBorder(),
                        elevation: 3,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            _editarAvatar(perfil);
                          },
                          child: const SizedBox(
                            width: 34,
                            height: 34,
                            child: Icon(
                              Icons.photo_camera_outlined,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Positioned(
                right: -3,
                bottom: -3,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            perfil.usuario,
            textAlign: TextAlign.center,
            style: AppTextStyles.title,
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Cada lector vive mil vidas entre páginas.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),

          if (perfil.resumen.clubes > 0) ...[
            const SizedBox(height: AppSpacing.md),
            ClubChip(
              label: perfil.resumen.clubes == 1
                  ? 'Miembro de 1 club'
                  : 'Miembro de ${perfil.resumen.clubes} clubes',
              icon: Icons.local_library_outlined,
              variant: ClubChipVariant.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _resumenLectura(PerfilUsuario perfil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ClubSectionTitle(
          title: 'Tu historia lectora',
          subtitle: 'Tu recorrido como lector',
          icon: Icons.insights_rounded,
          padding: EdgeInsets.zero,
        ),

        const SizedBox(height: AppSpacing.sm),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.32,
          children: [
            _statCard(
              titulo: 'Terminados',
              valor: perfil.resumen.terminados.toString(),
              icono: Icons.check_circle_outline_rounded,
              background: const Color(0xFFF1F8F3),
              iconBackground: const Color(0xFFDFF0E4),
              foreground: AppColors.success,
            ),
            _statCard(
              titulo: 'Leyendo',
              valor: perfil.resumen.leyendo.toString(),
              icono: Icons.menu_book_rounded,
              background: const Color(0xFFF1F5FC),
              iconBackground: const Color(0xFFDDE8F8),
              foreground: AppColors.info,
            ),
            _statCard(
              titulo: 'Valoración media',
              valor: perfil.resumen.media > 0
                  ? '${perfil.resumen.media.toStringAsFixed(2)} / 5'
                  : 'Sin datos',
              icono: Icons.star_outline_rounded,
              background: const Color(0xFFFFF9EA),
              iconBackground: const Color(0xFFFFEDBA),
              foreground: const Color(0xFFB48113),
            ),
            _statCard(
              titulo: 'Pendientes',
              valor: perfil.resumen.pendientes.toString(),
              icono: Icons.bookmark_border_rounded,
              background: AppColors.surfaceSoft,
              iconBackground: AppColors.primaryLight,
              foreground: AppColors.primary,
            ),
            if (perfil.resumen.clubes > 0)
              _statCard(
                titulo: 'Clubes',
                valor: perfil.resumen.clubes.toString(),
                icono: Icons.groups_2_outlined,
                background: const Color(0xFFF4F1FB),
                iconBackground: const Color(0xFFE5DCF7),
                foreground: AppColors.primary,
              )
            else
              _statCard(
                titulo: 'Abandonados',
                valor: perfil.resumen.abandonados.toString(),
                icono: Icons.heart_broken_outlined,
                background: const Color(0xFFF4F1FB),
                iconBackground: const Color(0xFFE5DCF7),
                foreground: AppColors.primary,
              ),
            _statCard(
              titulo: 'Sagas empezadas',
              valor: perfil.resumen.sagasAbiertas.toString(),
              icono: Icons.view_week_outlined,
              background: const Color(0xFFFFF3F7),
              iconBackground: const Color(0xFFFFDFEA),
              foreground: const Color(0xFFD75784),
            ),
          ],
        ),
        if (perfil.resumen.relecturas > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          ClubChip(
            label:
                '${perfil.resumen.relecturas} ${perfil.resumen.relecturas == 1 ? 'relectura' : 'relecturas'}',
            icon: Icons.refresh_rounded,
            variant: ClubChipVariant.primary,
          ),
        ],
      ],
    );
  }

  Widget _statCard({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color background,
    required Color iconBackground,
    required Color foreground,
  }) {
    return ClubCard(
      elevated: false,
      padding: EdgeInsets.zero,
      backgroundColor: background,
      borderColor: foreground.withValues(alpha: 0.18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -13,
            top: -11,
            child: Icon(
              icono,
              size: 82,
              color: foreground.withValues(alpha: .075),
            ),
          ),
          Positioned(
            left: 0,
            top: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: .42),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(icono, color: foreground, size: 19),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(
                        3,
                        (index) => Container(
                          width: index == 1 ? 12 : 5,
                          height: 5,
                          margin: const EdgeInsets.only(left: 3),
                          decoration: BoxDecoration(
                            color: foreground.withValues(
                              alpha: index == 1 ? .48 : .2,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.section.copyWith(
                    fontSize: 23,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: foreground.withValues(alpha: .88),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _libroTerminado({required PerfilLibroTerminado libro}) {
    final duracion = LecturaFechaUtils.duracion(
      libro.fechaInicio,
      libro.fechaFin,
    );

    final rangoFechas = LecturaFechaUtils.rango(
      libro.fechaInicio,
      libro.fechaFin,
    );

    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => openBookDetail(
        context,
        title: libro.libro,
        bookId: libro.bookId,
        coverUrl: libro.coverUrl,
        genre: libro.genero,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 62,
              height: 88,
              child: OptimizedNetworkImage(
                url: libro.coverUrl,
                width: 62,
                height: 88,
                fallback: _portadaVacia(),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  libro.libro,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  '${iconoGenero(libro.genero)} ${libro.genero}',
                  style: AppTextStyles.bodySecondary,
                ),

                if (libro.esRelectura) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const ClubChip(
                    label: 'Relectura',
                    icon: Icons.refresh_rounded,
                    variant: ClubChipVariant.primary,
                  ),
                ],

                if (libro.valoracion.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClubRatingStars(
                    valoracion: libro.valoracion,
                    size: 19,
                    spacing: 1,
                  ),
                ],
                if (duracion.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    duracion,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],

                if (rangoFechas.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    rangoFechas,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (esMiPerfil) ...[
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                tooltip: 'Editar fechas',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                  maxWidth: 44,
                  maxHeight: 44,
                ),
                icon: const Icon(Icons.edit_calendar_outlined),
                onPressed: libro.libraryId.trim().isEmpty
                    ? null
                    : () {
                        _editarFechas(libro);
                      },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _libroAbandonado({required PerfilLibroTerminado libro}) {
    final rangoFechas = LecturaFechaUtils.rango(
      libro.fechaInicio,
      libro.fechaFin,
    );

    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => openBookDetail(
        context,
        title: libro.libro,
        bookId: libro.bookId,
        coverUrl: libro.coverUrl,
        genre: libro.genero,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 62,
              height: 88,
              child: OptimizedNetworkImage(
                url: libro.coverUrl,
                width: 62,
                height: 88,
                fallback: _portadaVacia(),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  libro.libro,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  '${iconoGenero(libro.genero)} ${libro.genero}',
                  style: AppTextStyles.bodySecondary,
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  '💔 Lectura abandonada',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),

                if (rangoFechas.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    rangoFechas,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (esMiPerfil) ...[
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                tooltip: 'Editar fechas',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                  maxWidth: 44,
                  maxHeight: 44,
                ),
                icon: const Icon(Icons.edit_calendar_outlined),
                onPressed: libro.libraryId.trim().isEmpty
                    ? null
                    : () {
                        _editarFechas(libro);
                      },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _portadaVacia() {
    return Container(
      color: AppColors.surfaceSoft,
      alignment: Alignment.center,
      child: const Icon(
        Icons.menu_book_rounded,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}

class ProfileFavoriteGenresContent extends StatelessWidget {
  const ProfileFavoriteGenresContent({super.key, required this.genres});

  final List<PerfilGenero> genres;

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) {
      return const SizedBox(
        key: ValueKey('favorite-genres-empty'),
        width: double.infinity,
        child: ClubEmptyState(
          icon: Icons.favorite_border_rounded,
          title: 'Todavía no hay géneros favoritos',
          message: 'Aparecerán a medida que avances en tus lecturas.',
        ),
      );
    }

    return ClubCard(
      key: const ValueKey('favorite-genres-card'),
      width: double.infinity,
      elevated: false,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: genres
            .map(
              (genre) => ClubChip(
                label:
                    '${iconoGenero(genre.genero)} ${genre.genero} · ${genre.total}',
                variant: ClubChipVariant.primary,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─── Tab model ───────────────────────────────────────────────────

class _TabItem {
  const _TabItem(this.value, this.icon, this.label);
  final String value;
  final IconData icon;
  final String label;
}

// ─── Sticky tab bar ──────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate({
    required this.tabs,
    required this.selected,
    required this.onTap,
  });

  final List<_TabItem> tabs;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: .6),
            width: 1,
          ),
        ),
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: _ProfileSectionBar(tabs: tabs, selected: selected, onTap: onTap),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) =>
      old.selected != selected || old.tabs.length != tabs.length;
}

class _ProfileSectionBar extends StatefulWidget {
  const _ProfileSectionBar({
    required this.tabs,
    required this.selected,
    required this.onTap,
  });
  final List<_TabItem> tabs;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  State<_ProfileSectionBar> createState() => _ProfileSectionBarState();
}

class _ProfileSectionBarState extends State<_ProfileSectionBar> {
  final _keys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _ensureSelectedVisible();
  }

  @override
  void didUpdateWidget(covariant _ProfileSectionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) _ensureSelectedVisible();
  }

  void _ensureSelectedVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedContext =
          (_keys[widget.selected] ??= GlobalKey()).currentContext;
      if (selectedContext == null) return;
      Scrollable.ensureVisible(
        selectedContext,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignment: .5,
      );
    });
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
    child: Row(
      children: [
        for (final entry in widget.tabs.indexed) ...[
          if (entry.$1 > 0) const SizedBox(width: AppSpacing.xs),
          _ProfileSectionChip(
            key: _keys[entry.$2.value] ??= GlobalKey(),
            tab: entry.$2,
            selected: entry.$2.value == widget.selected,
            onTap: () => widget.onTap(entry.$2.value),
          ),
        ],
      ],
    ),
  );
}

class _ProfileSectionChip extends StatelessWidget {
  const _ProfileSectionChip({
    super.key,
    required this.tab,
    required this.selected,
    required this.onTap,
  });
  final _TabItem tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary
            : AppColors.primaryLight.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: .2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tab.icon,
            size: 14,
            color: selected ? Colors.white : AppColors.primaryDark,
          ),
          const SizedBox(width: 5),
          Text(
            tab.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.primaryDark,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─── Sección de logros en perfil ─────────────────────────────────────────────

class _PerfilLogrosSection extends StatefulWidget {
  const _PerfilLogrosSection({required this.usuario});
  final String usuario;

  @override
  State<_PerfilLogrosSection> createState() => _PerfilLogrosSectionState();
}

class _PerfilLogrosSectionState extends State<_PerfilLogrosSection> {
  late Future<List<UserAchievement>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService().getAchievements(user: widget.usuario);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserAchievement>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CardListSkeleton(count: 4);
        }

        final achievements = snapshot.data ?? [];
        final unlocked = achievements.where((a) => a.unlocked).toList();
        final locked = achievements.where((a) => !a.unlocked).toList();

        final rarityOrder = {'legendary': 0, 'epic': 1, 'rare': 2, 'common': 3};
        unlocked.sort(
          (a, b) => (rarityOrder[a.rarity] ?? 3).compareTo(
            rarityOrder[b.rarity] ?? 3,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClubSectionTitle(
              title: 'Logros de ${widget.usuario.split(' ').first}',
              subtitle:
                  '${unlocked.length} de ${achievements.length} desbloqueados',
              icon: Icons.emoji_events_outlined,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: AppSpacing.md),
            if (unlocked.isEmpty)
              const ClubEmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'Todavía sin logros',
                message: 'Los logros desbloqueados aparecerán aquí.',
              )
            else ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.9,
                ),
                itemCount: unlocked.length,
                itemBuilder: (context, i) =>
                    _PerfilLogroTile(achievement: unlocked[i]),
              ),
              if (locked.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                ClubSectionTitle(
                  title: 'Por desbloquear',
                  subtitle: 'Retos pendientes',
                  icon: Icons.lock_outline_rounded,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.md),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: locked.length,
                  itemBuilder: (context, i) =>
                      _PerfilLogroTile(achievement: locked[i], locked: true),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _PerfilLogroTile extends StatelessWidget {
  const _PerfilLogroTile({required this.achievement, this.locked = false});

  final UserAchievement achievement;
  final bool locked;

  Color get _color => locked
      ? AppColors.textMuted
      : switch (achievement.rarity) {
          'legendary' => const Color(0xFFD97706),
          'epic' => const Color(0xFF7C3AED),
          'rare' => const Color(0xFF2563EB),
          _ => AppColors.primary,
        };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Tooltip(
      message: '${achievement.title}\n${achievement.description}',
      child: Opacity(
        opacity: locked ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .05),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: color.withValues(alpha: locked ? .1 : .18),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(achievement.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(
                achievement.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color.withValues(alpha: locked ? 0.5 : .75),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  AchievementService.rarityLabels[achievement.rarity] ?? '',
                  style: TextStyle(
                    fontSize: 8,
                    color: color.withValues(alpha: .75),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Check-in en perfil ────────────────────────────────────────────────────────

class _CheckinSection extends StatefulWidget {
  @override
  State<_CheckinSection> createState() => _CheckinSectionState();
}

class _CheckinSectionState extends State<_CheckinSection> {
  bool _checkedToday = false;
  int _streak = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final data = await ApiService().getHistorialCheckin(dias: 7);
      if (mounted) {
        setState(() {
          _checkedToday = data['checkedToday'] as bool? ?? false;
          _streak = (data['streak'] as num?)?.toInt() ?? 0;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return CheckinButton(
      checkedToday: _checkedToday,
      streak: _streak,
      onCheckinDone: (newStreak) => setState(() {
        _checkedToday = true;
        _streak = newStreak;
      }),
    );
  }
}

// ── Wrapped CTA en perfil ─────────────────────────────────────────────────────

class _WrappedPerfilCta extends StatelessWidget {
  const _WrappedPerfilCta({
    required this.onTap,
    required this.availability,
    this.onLongPress,
  });
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final WrappedAvailability availability;

  @override
  Widget build(BuildContext context) {
    final wrappedYear = availability.wrappedYear;

    if (availability.isAvailable) {
      // ── Estado activo: Wrapped disponible ──────────────────────────────
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C3FF5), Color(0xFF1DB954)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              const Text('✨', style: TextStyle(fontSize: 28)),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu Wrapped $wrappedYear',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const Text(
                      'Tu año en libros, de un vistazo.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      );
    }

    // ── Estado inactivo: Wrapped no disponible todavía ──────────────────
    final dias = availability.daysUntilNovember;
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF6C3FF5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🎁', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wrapped $wrappedYear',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    dias > 0
                        ? 'Disponible en $dias ${dias == 1 ? 'día' : 'días'} · llega en noviembre'
                        : 'Disponible en noviembre',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estantería de favoritos
// ─────────────────────────────────────────────────────────────────────────────

// Modelo ligero para la selección de favoritos
class _LibroSeleccionable {
  const _LibroSeleccionable({
    required this.bookId,
    required this.title,
    required this.coverUrl,
  });
  final String bookId;
  final String title;
  final String coverUrl;
}

class _FavoritosShelf extends StatelessWidget {
  const _FavoritosShelf({
    required this.favoritos,
    required this.esMiPerfil,
    this.todosLosLibros = const [],
  });

  final List<LibroFavorito> favoritos;
  final bool esMiPerfil;
  final List<_LibroSeleccionable> todosLosLibros;

  static const int _maxSlots = 5;

  @override
  Widget build(BuildContext context) {
    // Si es mi perfil, usar ListenableBuilder para reflejar cambios en tiempo real
    if (esMiPerfil) {
      return ListenableBuilder(
        listenable: FavoritosService.instance,
        builder: (context, _) {
          final live = FavoritosService.instance.favoritos;
          final lista = FavoritosService.instance.perteneceASesionActual
              ? (FavoritosService.instance.cargado
                    ? live
                    : const <LibroFavorito>[])
              : const <LibroFavorito>[];
          return _buildShelf(context, lista);
        },
      );
    }
    return _buildShelf(context, favoritos);
  }

  void _mostrarSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SeleccionFavoritoSheet(todosLosLibros: todosLosLibros),
    );
  }

  Future<void> _mostrarAcciones(
    BuildContext context,
    LibroFavorito libro,
  ) async {
    if (FavoritosService.instance.operando) return;
    final accion = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              key: const Key('cambiar_favorito'),
              leading: const Icon(Icons.swap_horiz_rounded),
              title: const Text('Cambiar favorito'),
              onTap: () => Navigator.pop(sheetContext, 'cambiar'),
            ),
            ListTile(
              key: const Key('quitar_favorito'),
              leading: const Icon(Icons.favorite_border_rounded),
              title: const Text('Quitar de favoritos'),
              onTap: () => Navigator.pop(sheetContext, 'quitar'),
            ),
            ListTile(
              key: const Key('cancelar_edicion_favorito'),
              leading: const Icon(Icons.close_rounded),
              title: const Text('Cancelar'),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || accion == null) return;
    if (accion == 'cambiar') {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SeleccionFavoritoSheet(
          todosLosLibros: todosLosLibros,
          favoritoActual: libro,
        ),
      );
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quitar de favoritos'),
        content: Text('¿Quieres quitar “${libro.title}” de tus favoritos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirmar_quitar_favorito'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmado != true ||
        !context.mounted ||
        FavoritosService.instance.operando) {
      return;
    }
    final resultado = await FavoritosService.instance.toggle(
      libro.id,
      libro.title,
      coverUrl: libro.coverUrl,
      authorName: libro.authorName,
    );
    if (!resultado.ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(resultado.mensaje)));
    }
  }

  Widget _buildShelf(BuildContext context, List<LibroFavorito> lista) {
    final slots = List<LibroFavorito?>.generate(
      _maxSlots,
      (i) => i < lista.length ? lista[i] : null,
    );

    if (!esMiPerfil && lista.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          'Todavía no ha marcado favoritos',
          style: AppTextStyles.bodySecondary.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    return Row(
      children: slots.asMap().entries.map((entry) {
        final libro = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: entry.key < _maxSlots - 1 ? 8 : 0),
            child: _FavoritoSlot(
              key: ValueKey('favorito_${libro?.id ?? entry.key}'),
              libro: libro,
              esMiPerfil: esMiPerfil,
              cargando: esMiPerfil && FavoritosService.instance.operando,
              onTap: esMiPerfil && libro != null
                  ? () => _mostrarAcciones(context, libro)
                  : null,
              onAnadir: esMiPerfil && libro == null
                  ? () => _mostrarSelector(context)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FavoritoSlot extends StatelessWidget {
  const _FavoritoSlot({
    super.key,
    required this.libro,
    required this.esMiPerfil,
    this.cargando = false,
    this.onTap,
    this.onAnadir,
  });

  final LibroFavorito? libro;
  final bool esMiPerfil;
  final bool cargando;
  final VoidCallback? onTap;
  final VoidCallback? onAnadir;

  @override
  Widget build(BuildContext context) {
    if (libro == null) {
      if (!esMiPerfil) return const SizedBox.shrink();
      // Hueco vacío con "+" para el propio usuario — tappable
      return GestureDetector(
        onTap: onAnadir,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.border,
                    width: 1.5,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Añadir',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: cargando ? null : onTap,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 2 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: libro!.coverUrl != null && libro!.coverUrl!.isNotEmpty
                      ? OptimizedNetworkImage(
                          url: libro!.coverUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Text(
                              libro!.title.isNotEmpty
                                  ? libro!.title[0].toUpperCase()
                                  : '?',
                              style: AppTextStyles.section.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
              // Corazoncito
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4537E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
              if (cargando)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x66000000),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          libro!.title,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet para seleccionar un libro favorito
// ─────────────────────────────────────────────────────────────────────────────

class _SeleccionFavoritoSheet extends StatefulWidget {
  const _SeleccionFavoritoSheet({
    required this.todosLosLibros,
    this.favoritoActual,
  });
  final List<_LibroSeleccionable> todosLosLibros;
  final LibroFavorito? favoritoActual;

  @override
  State<_SeleccionFavoritoSheet> createState() =>
      _SeleccionFavoritoSheetState();
}

class _SeleccionFavoritoSheetState extends State<_SeleccionFavoritoSheet> {
  String _query = '';
  bool _toggling = false;

  List<_LibroSeleccionable> get _disponibles {
    // Deduplicar por bookId y excluir ya favoritos
    final vistos = <String>{};
    return widget.todosLosLibros.where((l) {
      if (l.bookId.isEmpty) return false;
      if (FavoritosService.instance.isFavorito(l.bookId)) return false;
      return vistos.add(l.bookId);
    }).toList();
  }

  List<_LibroSeleccionable> get _filtrados {
    if (_query.isEmpty) return _disponibles;
    final q = _query.toLowerCase();
    return _disponibles
        .where((l) => l.title.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _elegir(_LibroSeleccionable libro) async {
    if (_toggling) return;
    setState(() => _toggling = true);
    final actual = widget.favoritoActual;
    late final ({bool ok, String mensaje}) resultado;
    if (actual == null) {
      final toggle = await FavoritosService.instance.toggle(
        libro.bookId,
        libro.title,
        coverUrl: libro.coverUrl.isNotEmpty ? libro.coverUrl : null,
      );
      resultado = (ok: toggle.ok, mensaje: toggle.mensaje);
    } else {
      resultado = await FavoritosService.instance.reemplazar(
        actual,
        LibroFavorito(
          id: libro.bookId,
          title: libro.title,
          coverUrl: libro.coverUrl.isNotEmpty ? libro.coverUrl : null,
        ),
      );
    }
    if (!mounted) return;
    if (resultado.ok) {
      Navigator.pop(context);
    } else {
      setState(() => _toggling = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(resultado.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtrados = _filtrados;

    return Material(
      color: cs.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.xl),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
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

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Elige un favorito', style: AppTextStyles.section),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Selecciona uno de tus libros para marcarlo como favorito',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    autofocus: false,
                    textInputAction: TextInputAction.search,
                    autocorrect: false,
                    enableSuggestions: false,
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                    decoration: InputDecoration(
                      hintText: 'Buscar libro…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Flexible(
              child: _toggling
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : filtrados.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        widget.todosLosLibros.isEmpty
                            ? 'Añade libros a tu biblioteca primero'
                            : 'No se encontraron libros',
                        style: AppTextStyles.bodySecondary.copyWith(
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtrados.length,
                      separatorBuilder: (context, i) =>
                          const Divider(height: 1, indent: 72),
                      itemBuilder: (_, i) {
                        final l = filtrados[i];
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                            child: l.coverUrl.isNotEmpty
                                ? OptimizedNetworkImage(
                                    url: l.coverUrl,
                                    width: 36,
                                    height: 52,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 36,
                                    height: 52,
                                    color: cs.surfaceContainerHighest,
                                    child: const Icon(
                                      Icons.menu_book_rounded,
                                      size: 16,
                                    ),
                                  ),
                          ),
                          title: Text(
                            l.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subtitle,
                          ),
                          trailing: const Icon(
                            Icons.add_rounded,
                            color: AppColors.primary,
                          ),
                          onTap: () => _elegir(l),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
