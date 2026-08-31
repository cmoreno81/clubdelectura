import 'dart:async';

import 'package:club_lectura_app/services/libros_data_cache.dart';
import 'package:club_lectura_app/services/usuario_service.dart';
import 'package:club_lectura_app/theme/app_colors.dart';
import 'package:club_lectura_app/theme/app_radius.dart';
import 'package:club_lectura_app/theme/app_spacing.dart';
import 'package:club_lectura_app/theme/app_text_styles.dart';
import 'package:club_lectura_app/widgets/common/club_book_cover.dart';
import 'package:club_lectura_app/widgets/common/club_card.dart';
import 'package:club_lectura_app/widgets/common/club_chip.dart';
import 'package:club_lectura_app/widgets/common/club_empty_state.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';
import 'package:club_lectura_app/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/app_page_route.dart';
import '../navigation/book_detail_page_route.dart';
import '../widgets/libros/finalizar_libro_dialog.dart';
import '../widgets/libros/libro_acciones_sheet.dart';
import '../widgets/common/libro_finalizado_celebration.dart';
import '../widgets/libros/add_book_sheet.dart';
import '../widgets/libros/pausar_lectura_dialog.dart';

import '../models/libro_agrupado.dart';
import '../models/libro.dart';
import '../models/libro_finalizado.dart';
import '../models/libros_data.dart';
import '../services/api_service.dart';
import '../services/auth_session_service.dart';
import '../services/library_order_preferences.dart';
import '../services/library_refresh_notifier.dart';
import '../utils/genero_utils.dart';
import '../utils/lector_count_utils.dart';
import '../utils/reading_status_copy.dart';
import 'detalle_libro_page.dart';
import 'nuevo_libro_page.dart';
import '../services/atmosfera_scope.dart';
import '../widgets/common/onboarding_tutorial.dart';
import '../widgets/common/screen_hint_banner.dart';

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
    this.esPersonal = false,
    this.clubId,
  });

  final VoidCallback? onBackToClub;
  final LibrosPageController? controller;
  final LibraryDataLoader? loadData;
  /// true cuando el usuario está en modo lector solitario (sin club).
  final bool esPersonal;
  /// ID del club activo — se usa para aislar el caché entre clubs.
  final String? clubId;

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
  Timer? _debounce;

  String filtroBusqueda = '';
  String filtroEstado = 'TODOS';
  String filtroOrigen = 'DEL_CLUB'; // 'DEL_CLUB' | 'CLUBREADS'
  String filtroUsuario = 'TODAS';
  String? filtroVibe; // null = sin filtro de vibe
  // Lista de miembros del club — se actualiza solo con datos DEL_CLUB
  List<String> _miembrosClub = [];
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

  Future<LibrosData> _fetchData() {
    if (widget.loadData != null) return widget.loadData!();
    if (filtroOrigen == 'CLUBREADS') {
      // Vista global: no se usa caché de club
      return ApiService().getLibrosDataGlobal();
    }
    return LibrosDataCache.instance.get(
      () => ApiService().getLibrosData(),
      clubId: widget.clubId,
    );
  }

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
    _debounce?.cancel();
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
              position: FeatureTooltipPosition.below,
              align: FeatureTooltipAlign.end,
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

          // La lista de lectores solo se actualiza con datos del club propio,
          // nunca con datos globales de ClubReads (que incluirían todos los usuarios).
          if (filtroOrigen == 'DEL_CLUB') {
            final miembros = {
              ...libros.map((e) => e.usuario.trim()).where((u) => u.isNotEmpty),
              ...finalizados
                  .map((e) => e.usuario.trim())
                  .where((u) => u.isNotEmpty),
            }.toList()..sort();
            _miembrosClub = miembros;
          }

          final usuariosFiltro = ['TODAS', ..._miembrosClub];

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
                  ScreenHintBanner(
                    featureKey: 'hint_biblioteca_v2',
                    titulo: 'Cómo sacar el máximo a tu biblioteca',
                    tips: const [
                      ScreenHintTip('📖', 'Mantén pulsado un libro para ver acciones rápidas'),
                      ScreenHintTip('✅', 'Marca "Finalizar" cuando termines un libro para registrarlo en tu historial'),
                      ScreenHintTip('🔍', 'Filtra por estado: leyendo, pausado, pendiente o finalizado'),
                      ScreenHintTip('⭐', 'Puntúa y añade reseñas a los libros que terminas'),
                      ScreenHintTip('🌈', 'En la pestaña Pendientes aparece el Vibe Reader para filtrar por estado de ánimo lector'),
                    ],
                  ),
                  _cabeceraFiltros(
                    usuariosFiltro: usuariosFiltro,
                    totalResultados: resultado.length,
                  ),
                  // ── Vibe Reader (solo en modo PENDIENTE) ───────────────
                  if (filtroEstado == 'PENDIENTE')
                    _VibeBanner(
                      vibeSeleccionado: filtroVibe,
                      onVibeChanged: (vibe) =>
                          setState(() => filtroVibe = vibe),
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
                                    filtroUsuario != 'TODAS' ||
                                    filtroOrigen != 'DEL_CLUB'
                                ? 'Limpiar filtros'
                                : null,
                            onAction:
                                filtroBusqueda.isNotEmpty ||
                                    filtroEstado != 'TODOS' ||
                                    filtroUsuario != 'TODAS' ||
                                    filtroOrigen != 'DEL_CLUB'
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
            textInputAction: TextInputAction.search,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                if (mounted) setState(() => filtroBusqueda = value);
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
            key: ValueKey('biblioteca_$filtroOrigen'),
            initialValue: filtroOrigen,
            isDense: true,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
              labelText: 'Biblioteca',
              prefixIconConstraints: BoxConstraints(minWidth: 42),
              prefixIcon: Icon(Icons.collections_bookmark_outlined, size: 21),
            ),
            items: [
              DropdownMenuItem(
                value: 'DEL_CLUB',
                child: Text(widget.esPersonal ? 'Mi biblioteca' : 'Del club'),
              ),
              const DropdownMenuItem(
                value: 'CLUBREADS',
                child: Text('De ClubReads'),
              ),
            ],
            onChanged: (value) {
              if (value == null || value == filtroOrigen) return;
              HapticFeedback.selectionClick();
              setState(() {
                filtroOrigen = value;
                filtroEstado = 'TODOS';
                filtroUsuario = 'TODAS';
                filtroVibe = null;
                librosFuture = _startReload(notify: false);
              });
            },
          ),

          // El selector de Lector solo aparece en modo DEL_CLUB de club social.
          // En ClubReads (libros globales) o en cuenta personal no aplica.
          if (filtroOrigen == 'DEL_CLUB' && !widget.esPersonal) ...[
            const SizedBox(height: AppSpacing.xs),

            DropdownButtonFormField<String>(
              initialValue: filtroUsuario,
              isDense: true,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                labelText: 'Lector',
                prefixIconConstraints: BoxConstraints(minWidth: 42),
                prefixIcon: Icon(Icons.person_outline_rounded, size: 21),
              ),
              items: usuariosFiltro.map((usuario) {
                return DropdownMenuItem(
                  value: usuario,
                  child: Text(
                    usuario == 'TODAS' ? 'Todos los lectores' : usuario,
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
          ],

          const SizedBox(height: AppSpacing.sm),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // ── Chips de estado ────────────────────────────────────────
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
        HapticFeedback.selectionClick();
        setState(() {
          filtroEstado = estado;
          // Limpiar vibe al cambiar de estado (solo aplica en PENDIENTE)
          if (estado != 'PENDIENTE') filtroVibe = null;
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

    final heroTag =
        'book-cover-${libro.bookId.isNotEmpty ? libro.bookId : libro.libro.hashCode}';

    // ── Fondo visible al deslizar hacia la izquierda ──────────────────────────
    const cardRadius = BorderRadius.only(
      topLeft: Radius.circular(24),
      topRight: Radius.circular(12),
      bottomRight: Radius.circular(24),
      bottomLeft: Radius.circular(16),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Dismissible(
        key: ValueKey(
          'libro-${libro.bookId.isNotEmpty ? libro.bookId : libro.libro.hashCode}',
        ),
        direction: DismissDirection.endToStart,
        dismissThresholds: const {DismissDirection.endToStart: 0.25},
        confirmDismiss: (_) async {
          HapticFeedback.mediumImpact();
          await _mostrarAcciones(libro);
          return false;
        },
        background: const SizedBox.shrink(),
        secondaryBackground: ClipRRect(
          borderRadius: cardRadius,
          child: ColoredBox(
            color: AppColors.primary.withValues(alpha: 0.10),
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Acciones',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        child: ClubCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          onTap: () async {
            HapticFeedback.lightImpact();
            await _navegarAlDetalle(libro);
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

                  return GestureDetector(
                    onLongPress: () {
                      HapticFeedback.mediumImpact();
                      _mostrarAcciones(libro);
                    },
                    child: Stack(
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
                    ), // Stack
                  ); // GestureDetector
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
                          label:
                              '${libro.total} ${lectoresInteresadosLabel(libro.total)}',
                          icon: Icons.people_outline_rounded,
                          variant: ClubChipVariant.info,
                        ),

                        if (libro.totalFinalizados > 0)
                          ClubChip(
                            label:
                                '${libro.totalFinalizados} ${librosLeidosLabel(libro.totalFinalizados)}',
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
          ), // Row
        ), // ClubCard
      ), // Dismissible
    ); // Padding
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
                        subtitulo: 'Los que interesan a más lectores',
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
      goodreads: finalizado.goodreads,
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
    final filterKeyFull = '$filterKey|${filtroVibe ?? ''}';
    if (identical(_cachedBooks, libros) &&
        identical(_cachedFinishedBooks, finalizados) &&
        _cachedFilterKey == filterKeyFull) {
      return _cachedResult!;
    }
    final result = _calcularResultado(libros: libros, finalizados: finalizados);
    _cachedBooks = libros;
    _cachedFinishedBooks = finalizados;
    _cachedFilterKey = filterKeyFull;
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

        final coincideVibe = filtroVibe == null ||
            _vibeGeneros(filtroVibe!).any(
              (g) => normalizar(libro.genero).contains(g),
            );

        return coincideBusqueda && coincideUsuario && coincideEstado && coincideVibe;
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

  /// Devuelve las palabras clave de género (normalizadas) que corresponden
  /// al vibe seleccionado. Se compara con `contains` en el género del libro.
  static List<String> _vibeGeneros(String vibe) {
    switch (vibe) {
      case '🌙 Oscuro':
        return ['thriller', 'terror', 'misterio', 'crimen', 'horror', 'noir', 'suspense', 'policíac', 'policiaco'];
      case '☀️ Ligero':
        return ['comedia', 'humor', 'cozy', 'chick', 'ligero', 'contemporary', 'contemporan'];
      case '💕 Romántico':
        return ['romance', 'amor', 'romantico', 'erotico', 'erotica'];
      case '🌟 Aventura':
        return ['fantasia', 'aventura', 'accion', 'ciencia ficcion', 'sci-fi', 'distopia', 'epico', 'epica', 'fantasyado'];
      case '🧠 Reflexivo':
        return ['ensayo', 'psicolog', 'filosofia', 'no ficcion', 'autobiograf', 'memorias', 'historic', 'biograf'];
      case '💔 Emotivo':
        return ['drama', 'literaria', 'literario', 'ficcion literaria', 'contemporan', 'realista'];
      default:
        return [];
    }
  }

  void _limpiarFiltros() {
    buscadorController.clear();
    final origenAnterior = filtroOrigen;
    setState(() {
      filtroBusqueda = '';
      filtroEstado = 'TODOS';
      filtroUsuario = 'TODAS';
      filtroVibe = null;
      filtroOrigen = 'DEL_CLUB';
    });
    // Recargar solo si el origen cambió (ClubReads → Del club)
    if (origenAnterior != 'DEL_CLUB') {
      librosFuture = _startReload(notify: false);
    }
  }

  Future<void> _confirmarAgregarLibro(LibroAgrupado libro) async {
    final referencia = libro.referencia;
    final preferencias = await showAddBookSheet(
      context,
      title: libro.libro,
      author: referencia?.autor ?? '',
      coverUrl: libro.coverUrl,
    );

    if (preferencias == null) return;

    final usuario = await UsuarioService().obtenerUsuario();

    if (usuario == null || usuario.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido identificar al usuario.'),
        ),
      );
      return;
    }

    final respuesta = await ApiService().anadirLibroExistente(
      usuario: usuario,
      libro: libro.libro,
      prioridad: preferencias.priority,
      formato: preferencias.format,
    );

    if (!mounted) return;

    final ok = respuesta['ok'] == true;
    if (ok) HapticFeedback.mediumImpact();

    if (ok) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: const Text('📚 Añadido a tu lista'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () async {
              final u = await UsuarioService().obtenerUsuario();
              if (u == null || u.trim().isEmpty) return;
              await ApiService().quitarLibroPendientes(
                usuario: u,
                libro: libro.libro,
              );
              if (!mounted) return;
              LibraryRefreshNotifier.instance.invalidate();
              _recargar();
            },
          ),
        ),
      );
      LibraryRefreshNotifier.instance.invalidate();
      _recargar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(respuesta['mensaje'] ?? 'No se ha podido añadir'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Navegación al detalle con restauración de scroll ──────────────────────
  Future<void> _navegarAlDetalle(LibroAgrupado libro) async {
    final heroTag =
        'book-cover-${libro.bookId.isNotEmpty ? libro.bookId : libro.libro.hashCode}';
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

    _pendingScrollOffset = scrollOffset;
    _recargar();
    await librosFuture;
    if (!mounted) return;

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
  }

  // ── Bottom sheet de acciones + handler ────────────────────────────────────
  Future<void> _mostrarAcciones(LibroAgrupado libro) async {
    if (!mounted) return;
    final accion = await mostrarLibroAccionesSheet(context, libro);
    if (!mounted || accion == null) return;

    switch (accion) {
      case LibroAccion.anadir:
        await _confirmarAgregarLibro(libro);
      case LibroAccion.empezar:
        await _iniciarLectura(libro);
      case LibroAccion.reanudar:
        await _reanudarLectura(libro);
      case LibroAccion.pausar:
        await _pausarLectura(libro);
      case LibroAccion.finalizar:
        await _finalizarLectura(libro);
      case LibroAccion.releer:
        await _releer(libro);
      case LibroAccion.quitar:
        await _quitarPendientes(libro);
      case LibroAccion.verFicha:
        await _navegarAlDetalle(libro);
      case LibroAccion.editarFechaInicio:
        await _editarFechaInicio(libro);
    }
  }

  Future<void> _editarFechaInicio(LibroAgrupado libro) async {
    final registroActivo = libro.registros
        .where((r) => r.yaLoTengo)
        .firstOrNull;
    final fechaActual = registroActivo?.startedAt ?? DateTime.now();
    if (!mounted) return;

    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate:
          fechaActual.isAfter(DateTime.now()) ? DateTime.now() : fechaActual,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'Fecha en que empezaste a leer',
      confirmText: 'Guardar',
      cancelText: 'Cancelar',
    );
    if (nuevaFecha == null || !mounted) return;

    final usuario = await UsuarioService().obtenerUsuario();
    if (usuario == null || usuario.trim().isEmpty || !mounted) return;

    final ok = await ApiService().editarFechaInicioLectura(
      usuario: usuario,
      libro: libro.libro,
      fechaInicio: nuevaFecha,
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Fecha de inicio actualizada' : 'No se ha podido actualizar',
        ),
      ),
    );
    if (ok) setState(() {});
  }

  Future<void> _iniciarLectura(LibroAgrupado libro) async {
    final usuario = await UsuarioService().obtenerUsuario();
    if (usuario == null || usuario.trim().isEmpty || !mounted) return;

    final ok = await ApiService().iniciarLectura(
      usuario: usuario,
      libro: libro.libro,
    );
    if (!mounted) return;

    if (ok) HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '📖 ¡Empezando «${libro.libro}»!'
              : 'No se ha podido iniciar la lectura',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) {
      LibraryRefreshNotifier.instance.invalidate();
      _recargar();
    }
  }

  Future<void> _reanudarLectura(LibroAgrupado libro) async {
    final usuario = await UsuarioService().obtenerUsuario();
    if (usuario == null || usuario.trim().isEmpty || !mounted) return;

    final ok = await ApiService().actualizarEstado(
      usuario: usuario,
      libro: libro.libro,
      estado: 'LEYENDO',
    );
    if (!mounted) return;

    if (ok) HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? '📖 ¡Lectura reanudada!' : 'No se ha podido reanudar',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) {
      LibraryRefreshNotifier.instance.invalidate();
      _recargar();
    }
  }

  Future<void> _pausarLectura(LibroAgrupado libro) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const PausarLecturaDialog(),
    );
    if (motivo == null || !mounted) return;

    final usuario = await UsuarioService().obtenerUsuario();
    if (usuario == null || usuario.trim().isEmpty || !mounted) return;

    final ok = await ApiService().actualizarEstado(
      usuario: usuario,
      libro: libro.libro,
      estado: 'PAUSADO',
      motivoPausa: motivo.isNotEmpty ? motivo : null,
    );
    if (!mounted) return;

    if (ok) HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? '🌙 Lectura pausada' : 'No se ha podido pausar'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) {
      LibraryRefreshNotifier.instance.invalidate();
      _recargar();
    }
  }

  Future<void> _finalizarLectura(LibroAgrupado libro) async {
    final resultado = await FinalizarLibroDialog.show(context);
    if (resultado == null || !mounted) return;

    final usuario = await UsuarioService().obtenerUsuario();
    if (usuario == null || usuario.trim().isEmpty || !mounted) return;

    final ok = await ApiService().actualizarEstado(
      usuario: usuario,
      libro: libro.libro,
      estado: 'FINALIZADO',
      valoracion: resultado['valoracion'],
      reflexion: resultado['reflexion'],
      fechaInicio: resultado['fechaInicio'],
      fechaFin: resultado['fechaFin'],
      formato: resultado['formato'],
    );
    if (!mounted) return;

    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido finalizar'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    LibraryRefreshNotifier.instance.invalidate();
    _recargar();

    if (!mounted) return;
    await mostrarCelebracionFinalizado(
      context,
      titulo: libro.libro,
      coverUrl: libro.coverUrl,
    );
  }

  Future<void> _releer(LibroAgrupado libro) async {
    final usuario = await UsuarioService().obtenerUsuario();
    if (usuario == null || usuario.trim().isEmpty || !mounted) return;

    final ok = await ApiService().actualizarEstado(
      usuario: usuario,
      libro: libro.libro,
      estado: 'RELECTURA',
    );
    if (!mounted) return;

    if (ok) HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '🔄 ¡Empezando relectura!'
              : 'No se ha podido iniciar la relectura',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) {
      LibraryRefreshNotifier.instance.invalidate();
      _recargar();
    }
  }

  Future<void> _quitarPendientes(LibroAgrupado libro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Quitar de pendientes?'),
        content: Text(
          '«${libro.libro}» se eliminará de tu lista de pendientes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    final usuario = await UsuarioService().obtenerUsuario();
    if (usuario == null || usuario.trim().isEmpty || !mounted) return;

    final respuesta = await ApiService().quitarLibroPendientes(
      usuario: usuario,
      libro: libro.libro,
    );
    if (!mounted) return;

    final ok = respuesta['ok'] == true;
    if (ok) HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Eliminado de pendientes'
              : respuesta['mensaje']?.toString() ?? 'No se ha podido quitar',
        ),
        behavior: SnackBarBehavior.floating,
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

// ─────────────────────────────────────────────────────────────────────────────
// _VibeBanner — selector de «vibe lector» para filtrar libros pendientes
// ─────────────────────────────────────────────────────────────────────────────

class _VibeBanner extends StatelessWidget {
  const _VibeBanner({
    required this.vibeSeleccionado,
    required this.onVibeChanged,
  });

  final String? vibeSeleccionado;
  final void Function(String? vibe) onVibeChanged;

  static const _vibes = [
    ('🌙 Oscuro', '🌙'),
    ('☀️ Ligero', '☀️'),
    ('💕 Romántico', '💕'),
    ('🌟 Aventura', '🌟'),
    ('🧠 Reflexivo', '🧠'),
    ('💔 Emotivo', '💔'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5EDF8),
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: .8),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '¿Qué te apetece leer hoy?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.1,
                ),
              ),
              if (vibeSeleccionado != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () => onVibeChanged(null),
                  child: Text(
                    'Quitar filtro',
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: .65),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _vibes.map((pair) {
                final (label, emoji) = pair;
                final selected = vibeSeleccionado == label;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _VibeChip(
                    emoji: emoji,
                    label: label.replaceFirst('$emoji ', ''),
                    selected: selected,
                    onTap: () =>
                        onVibeChanged(selected ? null : label),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _VibeChip extends StatelessWidget {
  const _VibeChip({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.border,
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: .25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
