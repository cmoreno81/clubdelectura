import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../navigation/book_detail_navigation.dart';

import '../models/perfil_usuario.dart';
import '../models/libro_agrupado.dart';
import '../services/api_service.dart';
import '../services/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/genero_utils.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/common/club_empty_state.dart';
import '../widgets/common/club_section_title.dart';
import '../widgets/error_view.dart';
import '../services/usuario_service.dart';
import '../widgets/perfil/editar_fechas_lectura_dialog.dart';
import '../utils/lectura_fecha_utils.dart';
import '../widgets/perfil/editar_avatar_dialog.dart';
import '../widgets/perfil/perfil_timeline_lectura.dart';
import '../widgets/perfil/perfil_saga_card.dart';
import '../widgets/perfil/perfil_estanteria_mes.dart';
import '../widgets/common/club_rating_stars.dart';
import 'detalle_libro_page.dart';
import 'acerca_de_page.dart';
import 'change_password_page.dart';
import 'goodreads_import_page.dart';
import '../services/auth_service.dart';

class PerfilUsuarioPage extends StatefulWidget {
  final String usuario;
  final bool focusUpToDateSeries;

  const PerfilUsuarioPage({
    super.key,
    required this.usuario,
    this.focusUpToDateSeries = false,
  });

  @override
  State<PerfilUsuarioPage> createState() => _PerfilUsuarioPageState();
}

class _ProfileMenuOption extends StatelessWidget {
  const _ProfileMenuOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            icon,
            size: 21,
            color: selected ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        if (selected) ...[
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.check_circle_rounded,
            size: 19,
            color: AppColors.primary,
          ),
        ],
      ],
    );
  }
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
          child: ExpansionTile(
            key: PageStorageKey('finalizados-${year ?? 'sin-fecha'}'),
            initiallyExpanded: false,
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
    );
  }
}

class _SagaProfileTabs extends StatelessWidget {
  const _SagaProfileTabs({
    required this.selected,
    required this.upToDate,
    required this.completed,
    required this.active,
    required this.pending,
    required this.onSelected,
  });

  final String selected;
  final int upToDate;
  final int completed;
  final int active;
  final int pending;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = [
      ('AL_DIA', 'Al día', upToDate),
      ('COMPLETADA', 'Finalizadas', completed),
      ('EN_CURSO', 'En curso', active),
      ('PENDIENTE', 'Pendientes', pending),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: selected == option.$1,
                label: '${option.$2}, ${option.$3} sagas',
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: () => onSelected(option.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected == option.$1
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            option.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected == option.$1
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: selected == option.$1
                                ? Colors.white.withValues(alpha: .18)
                                : AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '${option.$3}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected == option.$1
                                  ? Colors.white
                                  : AppColors.primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PerfilUsuarioPageState extends State<PerfilUsuarioPage> {
  late Future<PerfilUsuario> future;
  String? usuarioActual;
  String _menuPerfil = 'RESUMEN';
  String _sagaFilter = 'AL_DIA';
  final GlobalKey _upToDateSeriesKey = GlobalKey();
  bool _didFocusUpToDateSeries = false;

  @override
  void initState() {
    super.initState();

    future = _cargarPerfil();
    _cargarUsuarioActual();
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

  Future<void> _abrirFichaSaga(PerfilSagaVolumen volumen) async {
    try {
      final data = await ApiService().getLibrosData();
      if (!mounted) return;

      final registros = data.libros
          .where(
            (item) =>
                item.bookId == volumen.bookId ||
                item.libro.trim().toLowerCase() ==
                    volumen.titulo.trim().toLowerCase(),
          )
          .toList();
      final finalizados = data.finalizados
          .where(
            (item) =>
                item.bookId == volumen.bookId ||
                item.libro.trim().toLowerCase() ==
                    volumen.titulo.trim().toLowerCase(),
          )
          .toList();

      if (registros.isEmpty && finalizados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este volumen todavía no está disponible en el club activo.',
            ),
          ),
        );
        return;
      }

      final agrupado = LibroAgrupado(
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
        AppPageRoute(builder: (_) => DetalleLibroPage(libro: agrupado)),
      );
      if (mounted) await _recargar();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido abrir la ficha.')),
      );
    }
  }

  Future<void> _editarNumeroSaga(PerfilSagaVolumen volumen) async {
    final controller = TextEditingController(text: volumen.numero);
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
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (numero == null || numero.isEmpty || !mounted) return;
    try {
      await ApiService().actualizarNumeroVolumenSaga(
        bookId: volumen.bookId,
        numero: numero,
      );
      if (mounted) await _recargar();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _cargarUsuarioActual() async {
    final usuario = await UsuarioService().obtenerUsuario();

    if (!mounted) return;

    setState(() {
      usuarioActual = usuario?.trim();
    });
  }

  bool get esMiPerfil {
    return usuarioActual != null &&
        usuarioActual!.trim().isNotEmpty &&
        usuarioActual!.toLowerCase() == widget.usuario.trim().toLowerCase();
  }

  Future<PerfilUsuario> _cargarPerfil() {
    return ApiService().getPerfilUsuario(widget.usuario);
  }

  Future<void> _recargar() async {
    setState(() {
      future = _cargarPerfil();
    });

    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil lector'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Secciones del perfil',
            initialValue: _menuPerfil,
            position: PopupMenuPosition.under,
            constraints: const BoxConstraints(minWidth: 250, maxWidth: 290),
            child: Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: .65),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: .22),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.grid_view_rounded,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Secciones',
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.primaryDark,
                  ),
                ],
              ),
            ),
            onSelected: (value) => setState(() => _menuPerfil = value),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'RESUMEN',
                height: 70,
                child: _ProfileMenuOption(
                  icon: Icons.view_week_outlined,
                  title: 'Mis sagas',
                  subtitle: 'Estantería, sagas y preferencias',
                  selected: _menuPerfil == 'RESUMEN',
                ),
              ),
              PopupMenuItem(
                value: 'TIMELINE',
                height: 70,
                child: _ProfileMenuOption(
                  icon: Icons.timeline_rounded,
                  title: 'Timeline',
                  subtitle: 'Tu historia lectora por fechas',
                  selected: _menuPerfil == 'TIMELINE',
                ),
              ),
              PopupMenuItem(
                value: 'LIBROS',
                height: 70,
                child: _ProfileMenuOption(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Finalizados',
                  subtitle: 'Terminados y abandonados',
                  selected: _menuPerfil == 'LIBROS',
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<PerfilUsuario>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(onRetry: _recargar);
          }

          final perfil = snapshot.data!;
          final upToDateSeries = perfil.sagas
              .where((saga) => saga.alDia)
              .toList(growable: false);
          final completedSeries = perfil.sagas
              .where((saga) => saga.completada)
              .toList(growable: false);
          final activeSeries = perfil.sagas
              .where((saga) => saga.estado == 'EN_CURSO')
              .toList(growable: false);
          final pendingSeries = perfil.sagas
              .where((saga) => saga.pendiente)
              .toList(growable: false);
          final selectedSeries = switch (_sagaFilter) {
            'COMPLETADA' => completedSeries,
            'EN_CURSO' => activeSeries,
            'PENDIENTE' => pendingSeries,
            _ => upToDateSeries,
          };
          final hasUpToDateSeries = upToDateSeries.isNotEmpty;
          final hasSeries = perfil.sagas.isNotEmpty;
          if (widget.focusUpToDateSeries &&
              hasUpToDateSeries &&
              !_didFocusUpToDateSeries) {
            _didFocusUpToDateSeries = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final sectionContext = _upToDateSeriesKey.currentContext;
              if (sectionContext != null) {
                Scrollable.ensureVisible(
                  sectionContext,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  alignment: .08,
                );
              }
            });
          }

          return RefreshIndicator(
            onRefresh: _recargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                100,
              ),
              children: [
                _cabeceraPerfil(perfil),

                const SizedBox(height: AppSpacing.lg),

                _resumenLectura(perfil),

                const SizedBox(height: AppSpacing.xl),
                PerfilEstanteriaMes(
                  usuario: perfil.usuario,
                  libros: perfil.terminados,
                  esMiPerfil: esMiPerfil,
                  onBookTap: (libro) => openBookDetail(
                    context,
                    title: libro.libro,
                    bookId: libro.bookId,
                    coverUrl: libro.coverUrl,
                    genre: libro.genero,
                  ),
                ),

                if (_menuPerfil == 'RESUMEN' && hasSeries) ...[
                  const SizedBox(height: AppSpacing.xl),
                  KeyedSubtree(
                    key: _upToDateSeriesKey,
                    child: ClubSectionTitle(
                      title: 'Mis sagas',
                      subtitle: esMiPerfil
                          ? 'Tu recorrido por cada universo'
                          : 'Su recorrido por cada universo',
                      icon: Icons.view_week_outlined,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _SagaProfileTabs(
                    selected: _sagaFilter,
                    upToDate: upToDateSeries.length,
                    completed: completedSeries.length,
                    active: activeSeries.length,
                    pending: pendingSeries.length,
                    onSelected: (value) {
                      if (_sagaFilter == value) return;
                      setState(() => _sagaFilter = value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (selectedSeries.isEmpty)
                    ClubEmptyState(
                      icon: _sagaFilter == 'AL_DIA'
                          ? Icons.update_rounded
                          : _sagaFilter == 'COMPLETADA'
                          ? Icons.workspace_premium_outlined
                          : _sagaFilter == 'EN_CURSO'
                          ? Icons.auto_stories_rounded
                          : Icons.bookmark_border_rounded,
                      title: _sagaFilter == 'AL_DIA'
                          ? 'Todavía no hay sagas al día'
                          : _sagaFilter == 'COMPLETADA'
                          ? 'Todavía no hay sagas finalizadas'
                          : _sagaFilter == 'EN_CURSO'
                          ? 'No hay sagas en curso'
                          : 'No hay sagas pendientes',
                      message: _sagaFilter == 'EN_CURSO'
                          ? 'Las sagas con alguna lectura empezada aparecerán aquí.'
                          : 'Esta sección se actualizará con su biblioteca.',
                    )
                  else
                    ...selectedSeries.map(
                      (saga) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: PerfilSagaCard(
                          saga: saga,
                          onContinue: _abrirFichaSaga,
                          onCompleteCatalog: null,
                          onEditVolume: esMiPerfil ? _editarNumeroSaga : null,
                        ),
                      ),
                    ),
                ],

                if (_menuPerfil == 'TIMELINE' &&
                    perfil.terminados.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  ClubSectionTitle(
                    title: 'Actividad lectora',
                    subtitle: 'Su recorrido libro a libro',
                    icon: Icons.timeline_rounded,
                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  PerfilTimelineLectura(
                    libros: perfil.terminados,
                    onBookTap: (libro) => openBookDetail(
                      context,
                      title: libro.libro,
                      bookId: libro.bookId,
                      coverUrl: libro.coverUrl,
                      genre: libro.genero,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                ],
                if (_menuPerfil == 'TIMELINE' && perfil.terminados.isEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const ClubEmptyState(
                    icon: Icons.timeline_rounded,
                    title: 'Todavía no hay actividad',
                    message: 'El recorrido lector aparecerá aquí.',
                  ),
                ],
                if (_menuPerfil == 'LIBROS') ...[
                  const SizedBox(height: AppSpacing.xl),
                  ClubSectionTitle(
                    title: 'Libros terminados',
                    subtitle: 'Las lecturas más recientes de ${perfil.usuario}',
                    icon: Icons.check_circle_outline_rounded,
                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  if (perfil.terminados.isEmpty)
                    const ClubEmptyState(
                      icon: Icons.flag_outlined,
                      title: 'Todavía no hay libros terminados',
                      message:
                          'Las próximas lecturas finalizadas aparecerán aquí.',
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    )
                  else
                    _finalizadosAgrupados(perfil.terminados),
                  const SizedBox(height: AppSpacing.lg),

                  ClubSectionTitle(
                    title: 'Libros abandonados',
                    subtitle: 'Las lecturas que decidió dejar',
                    icon: Icons.heart_broken_outlined,
                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  if (perfil.abandonados.isEmpty)
                    const ClubEmptyState(
                      icon: Icons.heart_broken_outlined,
                      title: 'No hay libros abandonados',
                      message: 'Todas sus lecturas siguen adelante.',
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    )
                  else
                    ...perfil.abandonados.map(
                      (libro) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _libroAbandonado(libro: libro),
                      ),
                    ),
                ],

                if (perfil.generosFavoritos.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),

                  const ClubSectionTitle(
                    title: 'Géneros favoritos',
                    subtitle: 'Los universos que más visita',
                    icon: Icons.favorite_outline_rounded,
                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  ClubCard(
                    elevated: false,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: perfil.generosFavoritos
                          .map(
                            (genero) => ClubChip(
                              label:
                                  '${iconoGenero(genero.genero)} '
                                  '${genero.genero} · '
                                  '${genero.total}',
                              variant: ClubChipVariant.primary,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                if (esMiPerfil) ...[
                  const SizedBox(height: AppSpacing.xl),
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
                        leading: const Icon(Icons.import_export_rounded),
                        title: const Text('Importar desde Goodreads'),
                        subtitle: const Text(
                          'Trae tus libros sin sobrescribir ClubReads',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          final imported = await Navigator.push<bool>(
                            context,
                            AppPageRoute(
                              builder: (_) => const GoodreadsImportPage(),
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
                        leading: const Icon(Icons.info_outline_rounded),
                        title: const Text('Acerca de ClubReads'),
                        subtitle: const Text(
                          'Versión, créditos, privacidad y contacto',
                        ),
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
                              AppPageRoute(
                                builder: (_) => const ChangePasswordPage(),
                              ),
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

          /*
           * Sustituiremos este texto por la frase
           * literaria real cuando la conectemos al backend.
           */
          Text(
            'Cada lectora vive mil vidas entre páginas.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          const ClubChip(
            label: 'Miembro del club',
            icon: Icons.local_library_outlined,
            variant: ClubChipVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _resumenLectura(PerfilUsuario perfil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ClubSectionTitle(
          title: 'Su historia lectora',
          subtitle: 'Un vistazo a su recorrido por el club',
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
          childAspectRatio: 1.12,
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
            _statCard(
              titulo: 'Clubes',
              valor: perfil.resumen.clubes.toString(),
              icono: Icons.groups_2_outlined,
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
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: background,
      borderColor: foreground.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icono, color: foreground, size: 21),
          ),

          const SizedBox(height: AppSpacing.sm),
          const SizedBox(height: AppSpacing.md),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.section.copyWith(fontSize: 20),
          ),

          const SizedBox(height: AppSpacing.xxs),

          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
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
              child: libro.coverUrl.trim().isNotEmpty
                  ? Image.network(
                      libro.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return _portadaVacia();
                      },
                    )
                  : _portadaVacia(),
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
              child: libro.coverUrl.trim().isNotEmpty
                  ? Image.network(
                      libro.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return _portadaVacia();
                      },
                    )
                  : _portadaVacia(),
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
