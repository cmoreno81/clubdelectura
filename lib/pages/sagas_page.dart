import 'package:flutter/material.dart';

import '../models/libro_agrupado.dart';
import '../models/perfil_usuario.dart';
import '../navigation/app_page_route.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/series_refresh_notifier.dart';
import '../services/usuario_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/common/club_empty_state.dart';
import '../widgets/common/club_section_title.dart';
import '../widgets/error_view.dart';
import '../widgets/perfil/perfil_saga_card.dart';
import '../widgets/common/onboarding_tutorial.dart';
import 'complete_series_page.dart';
import 'detalle_libro_page.dart';
import 'explore_catalog_page.dart';

class SagasPageController {
  Future<void> Function()? _refresh;

  Future<void> refresh() => _refresh?.call() ?? Future<void>.value();
}

class SagasPage extends StatefulWidget {
  const SagasPage({super.key, this.showBackButton = false, this.controller});

  final bool showBackButton;
  final SagasPageController? controller;

  @override
  State<SagasPage> createState() => _SagasPageState();
}

class _SagasPageState extends State<SagasPage> {
  late Future<PerfilUsuario> _future;
  final _searchController = TextEditingController();
  String _query = '';
  String _filter = 'EN_CURSO';

  @override
  void initState() {
    super.initState();
    widget.controller?._refresh = _reload;
    SeriesRefreshNotifier.instance.addListener(_onSeriesInvalidated);
    _future = _load();
  }

  void _onSeriesInvalidated() => _reload();

  @override
  void dispose() {
    SeriesRefreshNotifier.instance.removeListener(_onSeriesInvalidated);
    if (identical(widget.controller?._refresh, _reload)) {
      widget.controller?._refresh = null;
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<PerfilUsuario> _load() async {
    final usuario = (await UsuarioService().obtenerUsuario())?.trim() ?? '';
    if (usuario.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        message: 'No hay una sesión activa.',
      );
    }
    return ApiService().getPerfilUsuario(usuario);
  }

  Future<void> _reload() async {
    final next = _load();

    if (!mounted) return;

    setState(() {
      _future = next;
    });

    await next;
  }

  Future<void> _openBook(PerfilSagaVolumen volumen) async {
    try {
      final data = await ApiService().getLibrosData();
      if (!mounted) return;

      final title = volumen.titulo.trim().toLowerCase();
      final registros = data.libros
          .where(
            (item) =>
                item.bookId == volumen.bookId ||
                item.libro.trim().toLowerCase() == title,
          )
          .toList();
      final finalizados = data.finalizados
          .where(
            (item) =>
                item.bookId == volumen.bookId ||
                item.libro.trim().toLowerCase() == title,
          )
          .toList();

      if (registros.isEmpty && finalizados.isEmpty) {
        await Navigator.push<void>(
          context,
          AppPageRoute(
            builder: (_) => ExploreCatalogPage(initialQuery: volumen.titulo),
          ),
        );
        if (mounted) await _reload();
        return;
      }

      final libro = LibroAgrupado(
        libro: volumen.titulo,
        genero: registros.isNotEmpty
            ? registros.first.genero
            : finalizados.first.genero,
        registros: registros,
        finalizados: finalizados,
        yaLoTengo: registros.any((item) => item.yaLoTengo),
        leidoPorMi: finalizados.any((item) => item.yaLoTengo),
        coverUrl: volumen.coverUrl.isNotEmpty
            ? volumen.coverUrl
            : registros.isNotEmpty
            ? registros.first.coverUrl
            : finalizados.first.coverUrl,
      );

      await Navigator.push<void>(
        context,
        AppPageRoute(builder: (_) => DetalleLibroPage(libro: libro)),
      );
      if (mounted) await _reload();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido abrir la ficha.')),
      );
    }
  }

  Future<void> _completeSeries(PerfilSaga saga) async {
    final linkedBookId = await Navigator.push<String>(
      context,
      AppPageRoute(builder: (_) => CompleteSeriesPage(series: saga)),
    );

    if (linkedBookId == null || !mounted) return;

    PerfilUsuario? latest;

    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 180 * attempt));
      }

      latest = await _load();

      final linked = latest.sagas.any(
        (item) =>
            item.id == saga.id &&
            item.volumenes.any((volume) => volume.bookId == linkedBookId),
      );

      if (linked) break;
    }

    if (!mounted || latest == null) return;

    final linked = latest.sagas.any(
      (item) =>
          item.id == saga.id &&
          item.volumenes.any((volume) => volume.bookId == linkedBookId),
    );

    if (linked) {
      setState(() {
        _future = Future.value(latest);
      });

      return;
    }

    await _reload();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('El libro se guardó y hemos actualizado la saga.'),
      ),
    );
  }

  Future<void> _onGapTap(PerfilSaga saga, PerfilSagaVolumen volumen) async {
    if (volumen.posicion == null) return;

    final current = volumen.estado;

    // Menú con opciones según estado actual
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tomo ${volumen.posicion}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (current != 'LEIDO_EXTERNO')
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F4E8),
                  child: Icon(
                    Icons.history_edu_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                title: const Text('Lo he leído (no está en ClubReads)'),
                subtitle: const Text(
                  'Cuenta como leído en el progreso de la saga',
                ),
                onTap: () => Navigator.pop(context, 'LEIDO_EXTERNO'),
              ),
            if (current != 'OMITIDO')
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[100],
                  child: const Icon(
                    Icons.block_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
                title: const Text('Omitir este tomo'),
                subtitle: const Text(
                  'Para subsagas o tomos que no quieres leer',
                ),
                onTap: () => Navigator.pop(context, 'OMITIDO'),
              ),
            if (current == 'LEIDO_EXTERNO' || current == 'OMITIDO')
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEEEE),
                  child: Icon(Icons.undo_rounded, color: Colors.red, size: 20),
                ),
                title: const Text('Quitar marca'),
                onTap: () => Navigator.pop(context, 'QUITAR'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    try {
      if (result == 'QUITAR') {
        await ApiService().removeSeriesOverride(
          seriesId: saga.id,
          posicion: volumen.posicion!,
        );
      } else {
        await ApiService().setSeriesOverride(
          seriesId: saga.id,
          posicion: volumen.posicion!,
          tipo: result,
        );
      }
      // Recargar sagas
      final latest = await _load();
      if (!mounted) return;
      setState(() {
        _future = Future.value(latest);
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar el cambio')),
        );
      }
    }
  }

  Future<void> _editVolume(PerfilSagaVolumen volumen) async {
    var numeroEditado = volumen.numero;
    final numero = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Corregir número'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(volumen.titulo),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              initialValue: volumen.numero,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) => numeroEditado = value,
              decoration: const InputDecoration(labelText: 'Volumen'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, numeroEditado.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (numero == null || numero.isEmpty || !mounted) return;

    try {
      await ApiService().actualizarNumeroVolumenSaga(
        bookId: volumen.bookId,
        numero: numero,
      );
      if (mounted) await _reload();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _editSeries(PerfilSaga saga) async {
    var status = saga.estadoEditorial;
    var totalText = saga.totalSaga > 0 ? '${saga.totalSaga}' : '';
    final result = await showDialog<(String, int?)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Editar ${saga.nombre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(
                  labelText: 'Estado editorial',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'UNKNOWN',
                    child: Text('Sin confirmar'),
                  ),
                  DropdownMenuItem(
                    value: 'ONGOING',
                    child: Text('En publicación'),
                  ),
                  DropdownMenuItem(
                    value: 'COMPLETED',
                    child: Text('Saga finalizada'),
                  ),
                ],
                onChanged: (value) =>
                    setDialogState(() => status = value ?? 'UNKNOWN'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                initialValue: totalText,
                keyboardType: TextInputType.number,
                onChanged: (value) => totalText = value,
                decoration: const InputDecoration(
                  labelText: 'Total previsto de libros',
                  helperText: 'Déjalo vacío si todavía no se conoce.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final text = totalText.trim();
                Navigator.pop(context, (
                  status,
                  text.isEmpty ? null : int.tryParse(text),
                ));
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    try {
      await ApiService().actualizarEstadoEditorialSaga(
        sagaId: saga.id,
        estadoEditorial: result.$1,
        totalPrevisto: result.$2,
      );
      if (mounted) await _reload();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _hideSeries(PerfilSaga saga) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Ocultar esta saga?'),
        content: Text(
          '${saga.nombre} dejará de aparecer en tus sagas y en las '
          'recomendaciones para continuar.\n\nTus libros, lecturas, fechas, '
          'valoraciones y reseñas no se eliminarán de la biblioteca.\n\n'
          'Podrás recuperarla cuando quieras desde Perfil → Secciones → '
          'Sagas ocultas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.visibility_off_outlined),
            label: const Text('Ocultar saga'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ApiService().ocultarSaga(sagaId: saga.id);
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${saga.nombre} se ha ocultado. Puedes recuperarla desde tu perfil.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _removeSeries(PerfilSaga saga) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta saga?'),
        content: Text(
          '${saga.nombre} desaparecerá de tu lista de sagas.\n\n'
          'Tus libros, lecturas, fechas, valoraciones y reseñas '
          'se conservan intactos en tu biblioteca. '
          'Solo desaparece la agrupación visual de la saga.\n\n',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Eliminar saga'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ApiService().eliminarSaga(sagaId: saga.id);
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${saga.nombre} eliminada. Puedes recuperarla desde tu perfil.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _onAddToLibrary(
    PerfilSaga saga,
    PerfilSagaVolumen volumen,
  ) async {
    final result = await showModalBottomSheet<_LibraryPreferences>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddVolumeToLibrarySheet(titulo: volumen.titulo),
    );
    if (result == null || !mounted) return;

    try {
      // Construimos un CatalogBook mínimo con el bookId del volumen
      await ApiService().importarLibroCatalogo(
        bookId: volumen.bookId,
        prioridad: result.priority,
        formato: result.format,
        estado: result.status,
        fechaInicio: result.startDate,
        fechaFin: result.endDate,
        valoracion: result.rating,
      );
      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${volumen.titulo} añadido a tu biblioteca')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _reorderVolumes(
    PerfilSaga saga,
    List<PerfilSagaVolumen> newOrder,
  ) async {
    final order = [
      for (var i = 0; i < newOrder.length; i++)
        (bookId: newOrder[i].bookId, posicion: i + 1),
    ];

    await ApiService().guardarOrdenPersonalSaga(sagaId: saga.id, order: order);

    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis sagas'),
        automaticallyImplyLeading: widget.showBackButton,
      ),
      body: FutureBuilder<PerfilUsuario>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(onRetry: _reload);
          }

          final sagas = snapshot.data!.sagas;
          if (sagas.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 72),
                  ClubEmptyState(
                    icon: Icons.view_week_outlined,
                    title: 'Tu estantería de sagas está vacía',
                    message:
                        'Cuando añadas un libro de una saga, podrás seguir aquí todo su recorrido.',
                  ),
                ],
              ),
            );
          }

          final pending = _byState(sagas, 'PENDIENTE');
          final active = _byState(sagas, 'EN_CURSO');
          final upToDate = _byState(sagas, 'AL_DIA');
          final completed = _byState(sagas, 'COMPLETADA');
          final abandoned = _byState(sagas, 'ABANDONADA');
          final visibleSagas = _visibleSagas(sagas);
          // Cuando hay búsqueda, visibleSagas ya contiene todas las categorías
          final hayBusqueda = _query.trim().isNotEmpty;
          final visiblePending = _byState(visibleSagas, 'PENDIENTE');
          final visibleActive = _byState(visibleSagas, 'EN_CURSO');
          final visibleUpToDate = _byState(visibleSagas, 'AL_DIA');
          final visibleCompleted = _byState(visibleSagas, 'COMPLETADA');
          final visibleAbandoned = _byState(visibleSagas, 'ABANDONADA');

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                110,
              ),
              children: [
                _SagaOverview(
                  total: sagas.length,
                  active: active.length,
                  upToDate: upToDate.length + completed.length,
                ),
                const SizedBox(height: AppSpacing.md),
                FeatureTooltip(
                  featureKey: 'ft_saga_search',
                  message: 'Busca en todas tus sagas, sin importar el filtro',
                  icon: Icons.search_rounded,
                  child: TextField(
                    controller: _searchController,
                    style: AppTextStyles.body,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      hintText: 'Buscar una saga...',
                      prefixIconConstraints: const BoxConstraints(minWidth: 42),
                      prefixIcon: const Icon(Icons.search_rounded, size: 21),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Borrar búsqueda',
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded, size: 20),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SagaFilters(
                  selected: _filter,
                  active: active.length,
                  pending: pending.length,
                  upToDate: upToDate.length,
                  completed: completed.length,
                  abandoned: abandoned.length,
                  onSelected: (value) => setState(() => _filter = value),
                ),
                if (visibleSagas.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: ClubEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'No encontramos esa saga',
                      message: hayBusqueda
                          ? 'No hay sagas que coincidan con tu búsqueda.'
                          : 'Prueba con otro nombre o cambia el filtro.',
                    ),
                  )
                else ...[
                  // Con búsqueda activa mostramos todas las categorías mezcladas
                  if (hayBusqueda)
                    _section(
                      title: 'Resultados',
                      subtitle:
                          '${visibleSagas.length} '
                          '${visibleSagas.length == 1 ? 'saga encontrada' : 'sagas encontradas'}',
                      icon: Icons.search_rounded,
                      sagas: visibleSagas,
                    )
                  else ...[
                    _section(
                      title: 'En curso',
                      subtitle: 'Universos que ya has empezado',
                      icon: Icons.auto_stories_rounded,
                      sagas: visibleActive,
                    ),
                    _section(
                      title: 'Pendientes',
                      subtitle: 'Sagas guardadas para cuando llegue su momento',
                      icon: Icons.bookmark_border_rounded,
                      sagas: visiblePending,
                    ),
                    _section(
                      title: 'Al día',
                      subtitle: 'Has leído todo lo publicado hasta ahora',
                      icon: Icons.update_rounded,
                      sagas: visibleUpToDate,
                    ),
                    _section(
                      title: 'Completadas',
                      subtitle: 'Historias que ya forman parte de ti',
                      icon: Icons.workspace_premium_outlined,
                      sagas: visibleCompleted,
                    ),
                    _section(
                      title: 'Abandonadas',
                      subtitle: 'Dejadas a medias, por ahora',
                      icon: Icons.heart_broken_outlined,
                      sagas: visibleAbandoned,
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<PerfilSaga> _byState(List<PerfilSaga> sagas, String state) =>
      sagas.where((saga) => saga.estado == state).toList(growable: false);

  List<PerfilSaga> _visibleSagas(List<PerfilSaga> sagas) {
    final query = _query.trim().toLowerCase();

    // Con búsqueda activa: busca en TODAS las categorías, ignorando el filtro
    if (query.isNotEmpty) {
      return sagas
          .where(
            (saga) =>
                saga.nombre.toLowerCase().contains(query) ||
                saga.volumenes.any(
                  (volume) => volume.titulo.toLowerCase().contains(query),
                ),
          )
          .toList(growable: false);
    }

    // Sin búsqueda: muestra solo la categoría del filtro activo
    return sagas
        .where((saga) => saga.estado == _filter)
        .toList(growable: false);
  }

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<PerfilSaga> sagas,
  }) {
    if (sagas.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClubSectionTitle(
            title: title,
            subtitle: subtitle,
            icon: icon,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final saga in sagas)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: // En el método _section, dentro del for (final saga in sagas):
              PerfilSagaCard(
                saga: saga,
                onContinue: _openBook,
                onCompleteCatalog: () => _completeSeries(saga),
                onGapTap: (volumen) => _onGapTap(saga, volumen),
                onEditVolume: _editVolume,
                onAddToLibrary: (volumen) =>
                    _onAddToLibrary(saga, volumen), // ← nuevo
                onEditSeries: () => _editSeries(saga),
                onHideSeries: () => _hideSeries(saga),
                onRemoveSeries: () => _removeSeries(saga),
                onReorderVolumes: (newOrder) => _reorderVolumes(saga, newOrder),
              ),
            ),
        ],
      ),
    );
  }
}

class _SagaOverview extends StatelessWidget {
  const _SagaOverview({
    required this.total,
    required this.active,
    required this.upToDate,
  });

  final int total;
  final int active;
  final int upToDate;

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceSoft, Color(0xFFF0E5FF)],
      ),
      borderColor: AppColors.primaryLight,
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.view_week_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu mapa de sagas', style: AppTextStyles.section),
                const SizedBox(height: 4),
                Text(
                  '$total ${total == 1 ? 'saga' : 'sagas'} · '
                  '$active en curso',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 5),
                Text(
                  '$upToDate ${upToDate == 1 ? 'saga al día' : 'sagas al día'}',
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

class _SagaFilters extends StatelessWidget {
  const _SagaFilters({
    required this.selected,
    required this.active,
    required this.pending,
    required this.upToDate,
    required this.completed,
    required this.abandoned,
    required this.onSelected,
  });

  final String selected;
  final int active;
  final int pending;
  final int upToDate;
  final int completed;
  final int abandoned;
  final ValueChanged<String> onSelected;

  ClubChipVariant _variant(String estado) {
    return switch (estado) {
      'EN_CURSO' => ClubChipVariant.info,
      'PENDIENTE' => ClubChipVariant.warning,
      'AL_DIA' => ClubChipVariant.success,
      'COMPLETADA' => ClubChipVariant.primary,
      'ABANDONADA' => ClubChipVariant.danger,
      _ => ClubChipVariant.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      ('EN_CURSO', 'En curso $active', Icons.auto_stories_outlined),
      ('PENDIENTE', 'Pendientes $pending', Icons.bookmark_border_rounded),
      ('AL_DIA', 'Al día $upToDate', Icons.update_rounded),
      (
        'COMPLETADA',
        'Completadas $completed',
        Icons.workspace_premium_outlined,
      ),
      if (abandoned > 0)
        ('ABANDONADA', 'Abandonadas $abandoned', Icons.heart_broken_outlined),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            ClubChip(
              label: options[i].$2,
              icon: options[i].$3,
              selected: selected == options[i].$1,
              variant: _variant(options[i].$1),
              onTap: () => onSelected(options[i].$1),
            ),
            if (i < options.length - 1) const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _LibraryPreferences {
  const _LibraryPreferences({
    required this.priority,
    required this.format,
    required this.status,
    this.startDate,
    this.endDate,
    this.rating,
  });
  final String priority;
  final String format;
  final String status;
  final String? startDate;
  final String? endDate;
  final String? rating;
}

class _AddVolumeToLibrarySheet extends StatefulWidget {
  const _AddVolumeToLibrarySheet({required this.titulo});
  final String titulo;

  @override
  State<_AddVolumeToLibrarySheet> createState() =>
      _AddVolumeToLibrarySheetState();
}

class _AddVolumeToLibrarySheetState extends State<_AddVolumeToLibrarySheet> {
  String _priority = 'MEDIA';
  String _format = '';
  String _status = 'PENDIENTE';
  String _rating = '';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<DateTime?> _pickDate(DateTime? current) => showDatePicker(
    context: context,
    initialDate: current ?? DateTime.now(),
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
  );

  String _fmt(DateTime? d) {
    if (d == null) return '';
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Añadir a mi biblioteca',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.titulo,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Estado
            const Text('Estado'),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final opt in const [
                  ('PENDIENTE', 'Pendiente'),
                  ('LEYENDO', 'Leyendo'),
                  ('FINALIZADO', 'Terminado'),
                ])
                  ChoiceChip(
                    label: Text(opt.$2),
                    selected: _status == opt.$1,
                    selectedColor: AppColors.primaryDark,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _status == opt.$1
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: _status == opt.$1
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                    onSelected: (_) => setState(() {
                      _status = opt.$1;
                      if (_status != 'FINALIZADO') {
                        _rating = '';
                        _endDate = null;
                      }
                      if (_status == 'PENDIENTE') _startDate = null;
                    }),
                  ),
              ],
            ),

            // Fecha inicio — si leyendo o finalizado
            if (_status == 'LEYENDO' || _status == 'FINALIZADO') ...[
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de inicio (opcional)'),
                subtitle: Text(
                  _startDate == null
                      ? 'Sin fecha'
                      : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                ),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final d = await _pickDate(_startDate);
                  if (d != null) setState(() => _startDate = d);
                },
              ),
            ],

            // Fecha fin + valoración — si finalizado
            if (_status == 'FINALIZADO') ...[
              const SizedBox(height: AppSpacing.xs),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de fin (opcional)'),
                subtitle: Text(
                  _endDate == null
                      ? 'Sin fecha'
                      : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                ),
                trailing: const Icon(Icons.calendar_month_rounded),
                onTap: () async {
                  final d = await _pickDate(_endDate);
                  if (d != null) setState(() => _endDate = d);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Valoración'),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final v in const ['1', '2', '3', '4', '5'])
                    ChoiceChip(
                      label: Text('$v ★'),
                      selected: _rating == v,
                      selectedColor: AppColors.primaryDark,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _rating == v
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: _rating == v
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                      onSelected: (_) => setState(() => _rating = v),
                    ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            // Prioridad
            const Text('Prioridad'),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: ['ALTA', 'MEDIA', 'BAJA']
                  .map(
                    (v) => ChoiceChip(
                      label: Text(v[0] + v.substring(1).toLowerCase()),
                      selected: _priority == v,
                      selectedColor: AppColors.primaryDark,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _priority == v
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: _priority == v
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                      onSelected: (_) => setState(() => _priority = v),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: AppSpacing.md),

            // Formato
            const Text('Formato (puedes decidirlo más tarde)'),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children:
                  const {
                        '': 'Sin decidir',
                        'FISICO': 'Físico',
                        'DIGITAL': 'Digital',
                        'AUDIOLIBRO': 'Audiolibro',
                      }.entries
                      .map(
                        (e) => ChoiceChip(
                          label: Text(e.value),
                          selected: _format == e.key,
                          selectedColor: AppColors.primaryDark,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: _format == e.key
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: _format == e.key
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                          onSelected: (_) => setState(() => _format = e.key),
                        ),
                      )
                      .toList(),
            ),

            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(
                  context,
                  _LibraryPreferences(
                    priority: _priority,
                    format: _format,
                    status: _status,
                    startDate: _fmt(_startDate),
                    endDate: _fmt(_endDate),
                    rating: _rating.isEmpty ? null : _rating,
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
