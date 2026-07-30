import 'package:flutter/material.dart';

import '../models/libro_agrupado.dart';
import '../models/perfil_usuario.dart';
import '../navigation/app_page_route.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/usuario_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_empty_state.dart';
import '../widgets/common/club_section_title.dart';
import '../widgets/error_view.dart';
import '../widgets/perfil/perfil_saga_card.dart';
import 'complete_series_page.dart';
import 'detalle_libro_page.dart';
import 'explore_catalog_page.dart';
import 'perfil_usuario_page.dart';

class SagasPage extends StatefulWidget {
  const SagasPage({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  State<SagasPage> createState() => _SagasPageState();
}

class _SagasPageState extends State<SagasPage> {
  late Future<PerfilUsuario> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
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
    setState(() => _future = next);
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
    setState(() => _future = Future.value(latest));

    final linked = latest.sagas.any(
      (item) =>
          item.id == saga.id &&
          item.volumenes.any((volume) => volume.bookId == linkedBookId),
    );
    if (!linked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El libro se guardó, pero la saga todavía no se ha actualizado. '
            'Desliza hacia abajo para volver a cargarla.',
          ),
        ),
      );
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

  Future<void> _openUpToDateProfile() async {
    final userName = (await UsuarioService().obtenerUsuario())?.trim() ?? '';
    if (!mounted || userName.isEmpty) return;
    await Navigator.push<void>(
      context,
      AppPageRoute(
        builder: (_) =>
            PerfilUsuarioPage(usuario: userName, focusUpToDateSeries: true),
      ),
    );
    if (mounted) await _reload();
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
                  onUpToDateTap: _openUpToDateProfile,
                ),
                _section(
                  title: 'En curso',
                  subtitle: 'Universos que ya has empezado',
                  icon: Icons.auto_stories_rounded,
                  sagas: active,
                ),
                _section(
                  title: 'Pendientes',
                  subtitle: 'Sagas guardadas para cuando llegue su momento',
                  icon: Icons.bookmark_border_rounded,
                  sagas: pending,
                ),
                _section(
                  title: 'Al día',
                  subtitle: 'Has leído todo lo publicado hasta ahora',
                  icon: Icons.update_rounded,
                  sagas: upToDate,
                ),
                _section(
                  title: 'Completadas',
                  subtitle: 'Historias que ya forman parte de ti',
                  icon: Icons.workspace_premium_outlined,
                  sagas: completed,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PerfilSaga> _byState(List<PerfilSaga> sagas, String state) =>
      sagas.where((saga) => saga.estado == state).toList(growable: false);

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
              child: PerfilSagaCard(
                saga: saga,
                onContinue: _openBook,
                onCompleteCatalog: () => _completeSeries(saga),
                onEditVolume: _editVolume,
                onEditSeries: () => _editSeries(saga),
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
    required this.onUpToDateTap,
  });

  final int total;
  final int active;
  final int upToDate;
  final VoidCallback onUpToDateTap;

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
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onUpToDateTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$upToDate ${upToDate == 1 ? 'saga al día' : 'sagas al día'}',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.primaryDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
