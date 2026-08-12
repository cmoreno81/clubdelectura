import 'package:club_lectura_app/services/libros_data_cache.dart';
import 'package:club_lectura_app/services/usuario_service.dart';
import 'package:club_lectura_app/theme/app_colors.dart';
import 'package:club_lectura_app/theme/app_spacing.dart';
import 'package:club_lectura_app/theme/app_text_styles.dart';
import 'package:club_lectura_app/widgets/common/club_book_cover.dart';
import 'package:club_lectura_app/widgets/common/club_card.dart';
import 'package:club_lectura_app/widgets/common/club_chip.dart';
import 'package:club_lectura_app/widgets/common/club_empty_state.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';
import 'package:club_lectura_app/widgets/error_view.dart';
import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../navigation/book_detail_page_route.dart';

import '../models/libro_agrupado.dart';
import '../models/libro.dart';
import '../models/libro_finalizado.dart';
import '../models/libros_data.dart';
import '../services/api_service.dart';
import '../services/auth_session_service.dart';
import '../services/library_order_preferences.dart';
import '../services/library_refresh_notifier.dart';
import '../utils/genero_utils.dart';
import '../utils/reading_status_copy.dart';
import 'detalle_libro_page.dart';
import 'nuevo_libro_page.dart';
import '../services/atmosfera_scope.dart';
import '../widgets/common/onboarding_tutorial.dart';

enum OrdenLibros { populares, recientes, tituloAsc, tituloDesc, mejorValorados }

typedef LibraryDataLoader = Future<LibrosData> Function();

class LibrosPageController {
  Future<void> Function()? _refresh;

  Future<void> refresh() => _refresh?.call() ?? Future<void>.value();
}

class LibrosPage extends StatefulWidget {
  const LibrosPage({
    super.key,
    this.onBackToClub,
    this.controller,
    this.loadData,
  });

  final VoidCallback? onBackToClub;
  final LibrosPageController? controller;
  final LibraryDataLoader? loadData;

  @override
  State<LibrosPage> createState() => _LibrosPageState();
}

class _LibrosPageState extends State<LibrosPage> with WidgetsBindingObserver {
  late Future<LibrosData> librosFuture;
  Future<LibrosData>? _reloadInFlight;
  LibrosData? _lastData;
  final _orderPreferences = const LibraryOrderPreferences();
  final _scrollController = ScrollController();
  // Offset guardado solo al navegar al detalle de un libro.
  // null = volver al inicio (cualquier otra navegación).
  double? _pendingScrollOffset;

  final TextEditingController buscadorController = TextEditingController();

  String filtroBusqueda = '';
  String filtroEstado = 'TODOS';
  String filtroUsuario = 'TODAS';
  List<Libro>? _cachedBooks;
  List<LibroFinalizado>? _cachedFinishedBooks;
  String? _cachedFilterKey;
  List<LibroAgrupado>? _cachedResult;
  OrdenLibros ordenSeleccionado = OrdenLibros.populares;
  bool _orderChangedInThisVisit = false;

  bool _atmosferaRestaurada = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller?._refresh = _refresh;
    LibraryRefreshNotifier.instance.addListener(_onLibraryInvalidated);
    librosFuture = _startReload(notify: false);
    _restoreOrder();
  }

  Future<LibrosData> _fetchData() => widget.loadData != null
      ? widget.loadData!()
      : LibrosDataCache.instance.get(() => ApiService().getLibrosData());

  Future<LibrosData> _startReload({bool notify = true}) {
    final active = _reloadInFlight;
    if (active != null) return active;

    late final Future<LibrosData> request;
    request = _fetchData()
        .then((data) {
          _lastData = data;
          return data;
        })
        .whenComplete(() {
          if (identical(_reloadInFlight, request)) _reloadInFlight = null;
        });
    _reloadInFlight = request;

    if (notify && mounted) {
      setState(() {
        librosFuture = request;
      });
    }
    return request;
  }

  Future<void> _refresh() async {
    try {
      await _startReload();
    } catch (_) {
      // FutureBuilder conserva los datos anteriores y muestra el error si no
      // existe todavía una primera carga válida.
    }
  }

  void _onLibraryInvalidated() {
    _refresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _restoreOrder() async {
    await AuthSessionService.instance.initialize();
    final userId = AuthSessionService.instance.user?.id.trim() ?? '';
    if (userId.isEmpty) return;
    final stored = await _orderPreferences.read(userId);
    if (!mounted || stored == null || _orderChangedInThisVisit) return;
    final restored = OrdenLibros.values.where((order) => order.name == stored);
    if (restored.isEmpty) return;
    setState(() => ordenSeleccionado = restored.first);
  }

  Future<void> _abrirNuevoLibro() async {
    final creado = await Navigator.push<bool>(
      context,
      AppPageRoute(builder: (_) => const NuevoLibroPage()),
    );

    if (!mounted) return;

    if (creado == true) {
      await _refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LibraryRefreshNotifier.instance.removeListener(_onLibraryInvalidated);
    if (identical(widget.controller?._refresh, _refresh)) {
      widget.controller?._refresh = null;
    }
    buscadorController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _recargar() => _startReload();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_atmosferaRestaurada) return;

      _atmosferaRestaurada = true;

      AtmosferaScope.of(context).usarAtmosferaNeutra();
    });

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        automaticallyImplyLeading: widget.onBackToClub == null,
        leading: widget.onBackToClub == null
            ? null
            : IconButton(
                tooltip: 'Volver a El Club',
                onPressed: widget.onBackToClub,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_library_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Biblioteca',
              style: AppTextStyles.title.copyWith(
                color: colorScheme.onSurface,
                fontSize: 23,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FeatureTooltip(
              featureKey: 'ft_add_book',
              message: '¡Pulsa aquí para añadir tu primer libro!',
              icon: Icons.menu_book_outlined,
              child: Material(
                color: colorScheme.primary,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Añadir libro',
                  onPressed: _abrirNuevoLibro,
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  iconSize: 24,
                  splashRadius: 22,
                ),
              ),
            ),
          ),
        ],
      ),

      body: FutureBuilder<LibrosData>(
        future: librosFuture,
        initialData: _lastData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const BookListSkeleton();
          }

          final data = snapshot.data ?? _lastData;
          if (snapshot.hasError && data == null) {
            return ErrorView(onRetry: _recargar);
          }

          if (data == null) {
            return const BookListSkeleton();
          }
          final libros = data.libros;
          final finalizados = data.finalizados;

          final usuarios = {
            ...libros.map((e) => e.usuario.trim()).where((u) => u.isNotEmpty),
            ...finalizados
                .map((e) => e.usuario.trim())
                .where((u) => u.isNotEmpty),
          }.toList()..sort();

          final usuariosFiltro = ['TODAS', ...usuarios];

          if (!usuariosFiltro.contains(filtroUsuario)) {
            filtroUsuario = 'TODAS';
          }

          final resultado = _crearResultado(
            libros: libros,
            finalizados: finalizados,
          );

          return Stack(
            children: [
              Column(
                children: [
                  _cabeceraFiltros(
                    usuariosFiltro: usuariosFiltro,
                    totalResultados: resultado.length,
                  ),
                  Expanded(
                    child: resultado.isEmpty
                        ? ClubEmptyState(
                            icon: Icons.auto_stories_outlined,
                            title: 'No hay libros',
                            message:
                                'No hemos encontrado libros con los filtros seleccionados.',
                            actionLabel:
                                filtroBusqueda.isNotEmpty ||
                                    filtroEstado != 'TODOS' ||
                                    filtroUsuario != 'TODAS'
                                ? 'Limpiar filtros'
                                : null,
                            onAction:
                                filtroBusqueda.isNotEmpty ||
                                    filtroEstado != 'TODOS' ||
                                    filtroUsuario != 'TODAS'
                                ? _limpiarFiltros
                                : null,
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.xs,
                              AppSpacing.md,
                              110,
                            ),
                            itemCount: resultado.length,
                            itemBuilder: (context, index) {
                              return _libroCard(resultado[index]);
                            },
                          ),
                  ),
                ],
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _cabeceraFiltros({
    required List<String> usuariosFiltro,
    required int totalResultados,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: const BoxDecoration(color: AppColors.background),
      child: Column(
        children: [
          TextField(
            controller: buscadorController,
            style: AppTextStyles.body,
            textAlignVertical: TextAlignVertical.center,
            onChanged: (value) {
              setState(() {
                filtroBusqueda = value;
              });
            },
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              hintText: 'Buscar en la biblioteca...',
              prefixIconConstraints: const BoxConstraints(minWidth: 42),
              prefixIcon: const Icon(Icons.search_rounded, size: 21),
              suffixIcon: filtroBusqueda.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      icon: const Icon(Icons.close_rounded, size: 20),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        buscadorController.clear();

                        setState(() {
                          filtroBusqueda = '';
                        });
                      },
                    ),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          DropdownButtonFormField<String>(
            initialValue: filtroUsuario,
            isDense: true,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
              labelText: 'Lectora',
              prefixIconConstraints: BoxConstraints(minWidth: 42),
              prefixIcon: Icon(Icons.person_outline_rounded, size: 21),
            ),
            items: usuariosFiltro.map((usuario) {
              return DropdownMenuItem(
                value: usuario,
                child: Text(
                  usuario == 'TODAS' ? 'Todas las lectoras' : usuario,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                filtroUsuario = value;
              });
            },
          ),

          const SizedBox(height: AppSpacing.sm),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(
                  estado: 'TODOS',
                  label: 'Todos',
                  icon: Icons.grid_view_rounded,
                ),
                const SizedBox(width: AppSpacing.xs),
                _chip(
                  estado: 'PENDIENTE',
                  label: ReadingStatusCopy.label('PENDIENTE', plural: true),
                  icon: ReadingStatusCopy.icon('PENDIENTE'),
                ),
                const SizedBox(width: AppSpacing.xs),
                _chip(
                  estado: 'LEYENDO',
                  label: ReadingStatusCopy.label('LEYENDO', plural: true),
                  icon: ReadingStatusCopy.icon('LEYENDO'),
                ),
                const SizedBox(width: AppSpacing.xs),

                _chip(
                  estado: 'PAUSADO',
                  label: ReadingStatusCopy.label('PAUSADO', plural: true),
                  icon: ReadingStatusCopy.icon('PAUSADO'),
                ),
                const SizedBox(width: AppSpacing.xs),
                _chip(
                  estado: 'RELECTURA',
                  label: ReadingStatusCopy.label('RELECTURA', plural: true),
                  icon: ReadingStatusCopy.icon('RELECTURA'),
                ),
                const SizedBox(width: AppSpacing.xs),
                _chip(
                  estado: 'TERMINADOS',
                  label: ReadingStatusCopy.label('TERMINADOS', plural: true),
                  icon: ReadingStatusCopy.icon('TERMINADOS'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: Text(
                  totalResultados == 1 ? '1 libro' : '$totalResultados libros',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              OutlinedButton.icon(
                onPressed: _mostrarOpcionesOrden,
                icon: const Icon(Icons.swap_vert_rounded, size: 19),
                label: Text('Ordenar · $_labelOrden'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String estado,
    required String label,
    required IconData icon,
  }) {
    return ClubChip(
      label: label,
      icon: icon,
      selected: filtroEstado == estado,
      variant: _chipVariant(estado),
      onTap: () {
        setState(() {
          filtroEstado = estado;
        });
      },
    );
  }

  ClubChipVariant _chipVariant(String estado) {
    switch (estado) {
      case 'TODOS':
        return ClubChipVariant.success;

      case 'PENDIENTE':
        return ClubChipVariant.warning;

      case 'LEYENDO':
        return ClubChipVariant.info;

      case 'RELECTURA':
        return ClubChipVariant.primary;

      case 'FINALIZADO':
        return ClubChipVariant.success;

      case 'ABANDONADO':
        return ClubChipVariant.danger;

      case 'PAUSADO':
        return ClubChipVariant.danger;

      default:
        return ClubChipVariant.neutral;
    }
  }

  Widget _libroCard(LibroAgrupado libro) {
    final formatosPropios = libro.registros
        .where((registro) => registro.yaLoTengo)
        .map((registro) => registro.formato.trim().toUpperCase())
        .where((formato) => formato.isNotEmpty);
    final formatoPropio = formatosPropios.isEmpty ? '' : formatosPropios.first;
    final iconoPropio = switch (formatoPropio) {
      'FISICO' || 'FÍSICO' => Icons.menu_book_rounded,
      'DIGITAL' => Icons.tablet_mac_rounded,
      'AUDIOLIBRO' => Icons.headphones_rounded,
      _ => Icons.auto_stories_rounded,
    };

    final heroTag = 'book-cover-${libro.bookId.isNotEmpty ? libro.bookId : libro.libro.hashCode}';

    return ClubCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () async {
        // Guardamos la posición antes de navegar al detalle
        final scrollOffset = _scrollController.hasClients
            ? _scrollController.offset
            : 0.0;

        await Navigator.push<bool>(
          context,
          BookDetailPageRoute(
            builder: (_) => DetalleLibroPage(libro: libro, heroTag: heroTag),
          ),
        );

        _atmosferaRestaurada = false;

        if (!mounted) return;

        // Guardamos el offset pendiente ANTES de recargar
        _pendingScrollOffset = scrollOffset;

        // Recargamos datos y esperamos a que el future se complete
        _recargar();
        await librosFuture;

        if (!mounted) return;

        // Consumimos y limpiamos el offset pendiente
        final targetOffset = _pendingScrollOffset;
        _pendingScrollOffset = null;

        if (targetOffset != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || !_scrollController.hasClients) return;
              final max = _scrollController.position.maxScrollExtent;
              _scrollController.jumpTo(targetOffset.clamp(0.0, max));
            });
          });
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              // Estado propio: registro del usuario actual (yaLoTengo)
              final propioEstado =
                  libro.registros
                      .where((r) => r.yaLoTengo)
                      .map((r) => r.estado.toUpperCase())
                      .firstOrNull ??
                  '';
              final esPausado = propioEstado == 'PAUSADO';
              final esAbandonado = propioEstado == 'ABANDONADO';

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  ClubBookCover(
                    title: libro.libro,
                    imageUrl: libro.coverUrl,
                    width: 92,
                    showShadow: false,
                    heroTag: heroTag,
                  ),
                  // Badge en esquina superior derecha de la portada
                  if (libro.leidoPorMi)
                    _CoverBadge(
                      label: 'Leído',
                      icon: iconoPropio,
                      color: AppColors.primary,
                    )
                  else if (esPausado)
                    const _CoverBadge(
                      label: 'Pausa',
                      icon: Icons.nights_stay_outlined,
                      color: Color(0xFFE8A020),
                    )
                  else if (esAbandonado)
                    const _CoverBadge(
                      label: 'Abandonado',
                      icon: Icons.heart_broken_rounded,
                      color: AppColors.danger,
                    ),
                ],
              );
            },
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        libro.libro,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.section.copyWith(fontSize: 19),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.xs),

                    if (!libro.leidoPorMi && libro.yaLoTengo)
                      const Tooltip(
                        message: 'Ya está en tu lista',
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 27,
                        ),
                      )
                    else if (!libro.leidoPorMi)
                      IconButton(
                        tooltip: 'Añadir a mi lista',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          _confirmarAgregarLibro(libro);
                        },
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xs),

                Row(
                  children: [
                    Text(
                      iconoGenero(libro.genero),
                      style: const TextStyle(fontSize: 17),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        libro.genero,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    // "Leído por ti" se muestra sobre la portada (badge)
                    if (libro.esReciente)
                      const ClubChip(
                        label: 'Nuevo',
                        icon: Icons.auto_awesome_rounded,
                        variant: ClubChipVariant.primary,
                      ),
                    ClubChip(
                      label: '${libro.total} interesadas',
                      icon: Icons.people_outline_rounded,
                      variant: ClubChipVariant.info,
                    ),

                    if (libro.totalFinalizados > 0)
                      ClubChip(
                        label: '${libro.totalFinalizados} leídos',
                        icon: Icons.check_circle_outline_rounded,
                        variant: ClubChipVariant.success,
                      ),

                    if (libro.mediaValoracion > 0)
                      ClubChip(
                        label: libro.mediaValoracion.toStringAsFixed(1),
                        icon: Icons.star_rounded,
                        variant: ClubChipVariant.warning,
                      ),
                  ],
                ),

                if (libro.registros.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    libro.registros.map((e) => e.usuario).join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],

                if (libro.total >= 3) ...[
                  const SizedBox(height: AppSpacing.sm),

                  const ClubChip(
                    label: 'Coincidencia del club',
                    icon: Icons.local_fire_department_rounded,
                    variant: ClubChipVariant.danger,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _labelOrden {
    switch (ordenSeleccionado) {
      case OrdenLibros.populares:
        return 'Más populares';

      case OrdenLibros.recientes:
        return 'Más recientes';

      case OrdenLibros.tituloAsc:
        return 'Título A–Z';

      case OrdenLibros.tituloDesc:
        return 'Título Z–A';

      case OrdenLibros.mejorValorados:
        return 'Mejor valorados';
    }
  }

  Future<void> _mostrarOpcionesOrden() async {
    final seleccionado = await showModalBottomSheet<OrdenLibros>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ordenar biblioteca', style: AppTextStyles.section),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  'Elige cómo quieres ver los libros.',
                  style: AppTextStyles.bodySecondary,
                ),

                const SizedBox(height: AppSpacing.md),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _opcionOrden(
                        context: sheetContext,
                        orden: OrdenLibros.populares,
                        titulo: 'Más populares',
                        subtitulo: 'Los que interesan a más lectoras',
                        icono: Icons.local_fire_department_outlined,
                      ),

                      _opcionOrden(
                        context: sheetContext,
                        orden: OrdenLibros.recientes,
                        titulo: 'Añadidos recientemente',
                        subtitulo: 'Las últimas incorporaciones al catálogo',
                        icono: Icons.schedule_rounded,
                      ),

                      _opcionOrden(
                        context: sheetContext,
                        orden: OrdenLibros.tituloAsc,
                        titulo: 'Título: A–Z',
                        subtitulo: 'Orden alfabético ascendente',
                        icono: Icons.sort_by_alpha_rounded,
                      ),

                      _opcionOrden(
                        context: sheetContext,
                        orden: OrdenLibros.tituloDesc,
                        titulo: 'Título: Z–A',
                        subtitulo: 'Orden alfabético descendente',
                        icono: Icons.sort_by_alpha_rounded,
                      ),

                      _opcionOrden(
                        context: sheetContext,
                        orden: OrdenLibros.mejorValorados,
                        titulo: 'Mejor valorados',
                        subtitulo: 'Los favoritos del club primero',
                        icono: Icons.star_outline_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (seleccionado == null || !mounted) {
      return;
    }

    setState(() {
      _orderChangedInThisVisit = true;
      ordenSeleccionado = seleccionado;
    });
    final userId = AuthSessionService.instance.user?.id.trim() ?? '';
    if (userId.isNotEmpty) {
      await _orderPreferences.write(userId, seleccionado.name);
    }
  }

  Widget _opcionOrden({
    required BuildContext context,
    required OrdenLibros orden,
    required String titulo,
    required String subtitulo,
    required IconData icono,
  }) {
    final seleccionada = ordenSeleccionado == orden;
    final color = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        selected: seleccionada,
        selectedTileColor: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: seleccionada
                ? color.withValues(alpha: 0.12)
                : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icono,
            color: seleccionada ? color : AppColors.textSecondary,
          ),
        ),
        title: Text(
          titulo,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitulo, style: AppTextStyles.caption),
        trailing: seleccionada
            ? Icon(Icons.check_circle_rounded, color: color)
            : const Icon(Icons.circle_outlined, color: AppColors.textMuted),
        onTap: () {
          Navigator.pop(context, orden);
        },
      ),
    );
  }

  void _aplicarOrden(List<LibroAgrupado> resultado) {
    resultado.sort((a, b) {
      switch (ordenSeleccionado) {
        case OrdenLibros.populares:
          final popularidadA = a.total + a.totalFinalizados;
          final popularidadB = b.total + b.totalFinalizados;

          final comparacion = popularidadB.compareTo(popularidadA);

          if (comparacion != 0) {
            return comparacion;
          }

          return normalizar(a.libro).compareTo(normalizar(b.libro));

        case OrdenLibros.recientes:
          final fechaA = a.fechaAlta;
          final fechaB = b.fechaAlta;

          if (fechaA == null && fechaB == null) {
            return normalizar(a.libro).compareTo(normalizar(b.libro));
          }

          if (fechaA == null) return 1;
          if (fechaB == null) return -1;

          final comparacion = fechaB.compareTo(fechaA);

          if (comparacion != 0) {
            return comparacion;
          }

          return normalizar(a.libro).compareTo(normalizar(b.libro));

        case OrdenLibros.tituloAsc:
          return normalizar(a.libro).compareTo(normalizar(b.libro));

        case OrdenLibros.tituloDesc:
          return normalizar(b.libro).compareTo(normalizar(a.libro));

        case OrdenLibros.mejorValorados:
          final comparacion = b.mediaValoracion.compareTo(a.mediaValoracion);

          if (comparacion != 0) {
            return comparacion;
          }

          return normalizar(a.libro).compareTo(normalizar(b.libro));
      }
    });
  }

  Libro _registroDesdeFinalizado(LibroFinalizado finalizado) {
    return Libro(
      bookId: finalizado.bookId,
      usuario: finalizado.usuario,
      libro: finalizado.libro,
      autor: finalizado.autor,
      genero: finalizado.genero,
      saga: finalizado.saga,
      numSaga: finalizado.numSaga,
      autoconclusivo: finalizado.autoconclusivo,
      prioridad: 'MEDIA',
      formato: finalizado.formato,
      estado: 'FINALIZADO',
      valoracion: finalizado.valoracion,
      yaLoTengo: false,
      goodreads: '',
      coverUrl: finalizado.coverUrl,
      fechaAlta: finalizado.fechaAlta,
      startedAt: null,
      pausedAt: null,
      pauseReason: '',
      avatarUrl: finalizado.avatarUrl,
      paginas: finalizado.paginas,
    );
  }

  List<LibroAgrupado> _crearResultado({
    required List<Libro> libros,
    required List<LibroFinalizado> finalizados,
  }) {
    final filterKey =
        '$filtroBusqueda\u0000$filtroEstado\u0000$filtroUsuario\u0000$ordenSeleccionado';
    if (identical(_cachedBooks, libros) &&
        identical(_cachedFinishedBooks, finalizados) &&
        _cachedFilterKey == filterKey) {
      return _cachedResult!;
    }
    final result = _calcularResultado(libros: libros, finalizados: finalizados);
    _cachedBooks = libros;
    _cachedFinishedBooks = finalizados;
    _cachedFilterKey = filterKey;
    _cachedResult = result;
    return result;
  }

  List<LibroAgrupado> _calcularResultado({
    required List<Libro> libros,
    required List<LibroFinalizado> finalizados,
  }) {
    List<LibroAgrupado> resultado = [];

    if (filtroEstado != 'TERMINADOS') {
      final librosFiltrados = libros.where((libro) {
        final coincideBusqueda = normalizar(
          libro.libro,
        ).contains(normalizar(filtroBusqueda));

        final coincideUsuario =
            filtroUsuario == 'TODAS' || libro.usuario.trim() == filtroUsuario;

        final coincideEstado =
            filtroEstado == 'TODOS' || libro.estado == filtroEstado;

        return coincideBusqueda && coincideUsuario && coincideEstado;
      }).toList();

      final agrupados = <String, LibroAgrupado>{};

      for (final libro in librosFiltrados) {
        final clave = normalizar(libro.libro);
        agrupados.putIfAbsent(
          clave,
          () => LibroAgrupado(
            libro: libro.libro,
            genero: libro.genero,
            registros: [],
            finalizados: [],
            yaLoTengo: libro.yaLoTengo,
            coverUrl: libro.coverUrl,
          ),
        );

        agrupados[clave]!.registros.add(libro);

        if (agrupados[clave]!.coverUrl.trim().isEmpty &&
            libro.coverUrl.trim().isNotEmpty) {
          agrupados[clave]!.coverUrl = libro.coverUrl;
        }

        if (libro.yaLoTengo) {
          agrupados[clave]!.yaLoTengo = true;
        }
      }

      if (filtroEstado == 'TODOS') {
        final finalizadosFiltrados = finalizados.where((finalizado) {
          final coincideUsuario =
              filtroUsuario == 'TODAS' ||
              finalizado.usuario.trim() == filtroUsuario;
          final coincideBusqueda = normalizar(
            finalizado.libro,
          ).contains(normalizar(filtroBusqueda));
          return coincideUsuario && coincideBusqueda;
        });

        for (final finalizado in finalizadosFiltrados) {
          final clave = normalizar(finalizado.libro);
          final agrupado = agrupados.putIfAbsent(
            clave,
            () => LibroAgrupado(
              libro: finalizado.libro,
              genero: finalizado.genero,
              registros: [],
              finalizados: [],
              yaLoTengo: false,
              coverUrl: finalizado.coverUrl,
            ),
          );

          agrupado.finalizados.add(finalizado);
          if (agrupado.coverUrl.trim().isEmpty &&
              finalizado.coverUrl.trim().isNotEmpty) {
            agrupado.coverUrl = finalizado.coverUrl;
          }
          if (finalizado.yaLoTengo) {
            agrupado.leidoPorMi = true;
            agrupado.yaLoTengo = true;
          }
          final yaExiste = agrupado.registros.any(
            (registro) =>
                registro.usuario.trim().toLowerCase() ==
                finalizado.usuario.trim().toLowerCase(),
          );
          if (!yaExiste) {
            agrupado.registros.add(_registroDesdeFinalizado(finalizado));
          }
        }
      }

      resultado = agrupados.values.toList();

      for (final agrupado in resultado) {
        if (filtroEstado != 'TODOS') {
          agrupado.finalizados.addAll(
            finalizados.where(
              (f) => normalizar(f.libro) == normalizar(agrupado.libro),
            ),
          );
        }
      }

      _aplicarOrden(resultado);

      return resultado;
    }

    final finalizadosFiltrados = finalizados.where((f) {
      final coincideUsuario =
          filtroUsuario == 'TODAS' || f.usuario.trim() == filtroUsuario;

      final coincideBusqueda =
          filtroBusqueda.isEmpty ||
          normalizar(f.libro).contains(normalizar(filtroBusqueda));

      return coincideUsuario && coincideBusqueda;
    }).toList();

    final titulosFinalizados = finalizadosFiltrados
        .map((finalizado) => normalizar(finalizado.libro))
        .toSet();

    final registrosRelacionados = libros.where((libro) {
      return titulosFinalizados.contains(normalizar(libro.libro));
    }).toList();

    final agrupados = <String, LibroAgrupado>{};

    for (final finalizado in finalizadosFiltrados) {
      final clave = normalizar(finalizado.libro);

      agrupados.putIfAbsent(
        clave,
        () => LibroAgrupado(
          libro: finalizado.libro,
          genero: finalizado.genero,
          registros: [],
          finalizados: [],
          yaLoTengo: false,
          coverUrl: finalizado.coverUrl,
        ),
      );

      final agrupado = agrupados[clave]!;
      agrupado.finalizados.add(finalizado);
      if (agrupado.coverUrl.trim().isEmpty &&
          finalizado.coverUrl.trim().isNotEmpty) {
        agrupado.coverUrl = finalizado.coverUrl;
      }
      if (finalizado.yaLoTengo) {
        agrupados[clave]!.leidoPorMi = true;
        agrupados[clave]!.yaLoTengo = true;
      }
      agrupados[clave]!.registros.add(_registroDesdeFinalizado(finalizado));
    }

    for (final registro in registrosRelacionados) {
      final clave = normalizar(registro.libro);
      final agrupado = agrupados[clave];

      if (agrupado == null) continue;

      final yaExiste = agrupado.registros.any(
        (existente) =>
            existente.usuario.trim().toLowerCase() ==
            registro.usuario.trim().toLowerCase(),
      );

      if (!yaExiste) {
        agrupado.registros.add(registro);
      }

      if (registro.yaLoTengo) {
        agrupado.yaLoTengo = true;
      }
    }
    resultado = agrupados.values.toList();
    _aplicarOrden(resultado);

    return resultado;
  }

  void _limpiarFiltros() {
    buscadorController.clear();

    setState(() {
      filtroBusqueda = '';
      filtroEstado = 'TODOS';
      filtroUsuario = 'TODAS';
    });
  }

  Future<void> _confirmarAgregarLibro(LibroAgrupado libro) async {
    final preferencias = await showDialog<({String prioridad, String formato})>(
      context: context,
      builder: (dialogContext) {
        var prioridad = 'MEDIA';
        String? formato;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Añadir a mi biblioteca'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(libro.libro),
                const SizedBox(height: 20),
                const Text('¿Qué prioridad tiene para ti?'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final opcion in const [
                      ('ALTA', '🔴 Alta'),
                      ('MEDIA', '🟡 Media'),
                      ('BAJA', '🟢 Baja'),
                    ])
                      ChoiceChip(
                        label: Text(opcion.$2),
                        selected: prioridad == opcion.$1,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: prioridad == opcion.$1
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: prioridad == opcion.$1
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                        showCheckmark: false,
                        onSelected: (_) =>
                            setDialogState(() => prioridad = opcion.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('¿En qué formato lo tienes?'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final opcion in const [
                      ('FISICO', '📖 Físico'),
                      ('DIGITAL', '📱 Digital'),
                      ('AUDIOLIBRO', '🎧 Audio'),
                    ])
                      ChoiceChip(
                        label: Text(opcion.$2),
                        selected: formato == opcion.$1,
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: formato == opcion.$1
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: formato == opcion.$1
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                        onSelected: (_) =>
                            setDialogState(() => formato = opcion.$1),
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: formato == null
                    ? null
                    : () => Navigator.pop(dialogContext, (
                        prioridad: prioridad,
                        formato: formato!,
                      )),
                child: const Text('Añadir'),
              ),
            ],
          ),
        );
      },
    );

    if (preferencias == null) return;

    final usuario = await UsuarioService().obtenerUsuario();

    if (usuario == null || usuario.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido identificar a la usuaria.'),
        ),
      );
      return;
    }

    final respuesta = await ApiService().anadirLibroExistente(
      usuario: usuario,
      libro: libro.libro,
      prioridad: preferencias.prioridad,
      formato: preferencias.formato,
    );

    if (!mounted) return;

    final ok = respuesta['ok'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Añadido a tu lista'
              : respuesta['mensaje'] ?? 'No se ha podido añadir',
        ),
      ),
    );

    if (ok) {
      LibraryRefreshNotifier.instance.invalidate();
      _recargar();
    }
  }

  String normalizar(String texto) {
    return texto
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }
}

/// Badge compacto para mostrar sobre la portada del libro.
class _CoverBadge extends StatelessWidget {
  const _CoverBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -6,
      right: -6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
