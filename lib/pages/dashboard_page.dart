import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dev/dev_settings.dart';
import '../models/dashboard_view_data.dart';
import '../models/dashboard.dart';
import '../models/ranking_item.dart';
import '../services/api_service.dart';
import '../services/club_narrador.dart';
import '../services/usuario_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import '../widgets/club/clubvision_card.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/common/club_empty_state.dart';
import '../widgets/common/club_section_title.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/error_view.dart';
import '../widgets/info_card.dart';
import 'mood_club_page.dart';
import 'perfil_usuario_page.dart';
import 'ranking_page.dart';
import 'tendencias_club_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<DashboardViewData> dashboardFuture;

  String? usuarioActual;
  String avatarUrlActual = '';

  @override
  void initState() {
    super.initState();

    dashboardFuture = _cargarDashboard();
    _cargarUsuarioActual();
  }

  @override
  void reassemble() {
    super.reassemble();

    // En desarrollo, un hot reload puede conservar un DashboardViewData
    // anterior que todavía no incluía el top 3. Volvemos a pedirlo para que
    // el podio se reconstruya completo sin necesitar reiniciar la app.
    dashboardFuture = _cargarDashboard();
  }

  Future<DashboardViewData> _cargarDashboard() async {
    final dashboardFuture = ApiService().getDashboard();
    final clubvisionFuture = ApiService().getClubvision();
    final topLectorasFuture = ApiService().getTopLectorasMes();

    final dashboard = await dashboardFuture;
    final clubvision = await clubvisionFuture;
    List<RankingItem> topLectoras;

    try {
      topLectoras = await topLectorasFuture;
    } catch (_) {
      topLectoras = const [];
    }

    return DashboardViewData(
      dashboard: dashboard,
      haVotado: clubvision.haVotado,
      topLectoras: topLectoras,
    );
  }

  Future<void> _cargarUsuarioActual() async {
    final usuario = await UsuarioService().obtenerUsuario();
    final nombre = usuario?.trim() ?? '';

    if (!mounted) return;

    if (nombre.isEmpty) {
      setState(() {
        usuarioActual = '';
        avatarUrlActual = '';
      });

      return;
    }

    try {
      final perfil = await ApiService().getPerfilUsuario(nombre);

      if (!mounted) return;

      setState(() {
        usuarioActual = nombre;
        avatarUrlActual = perfil.avatarUrl;
      });
    } catch (error) {
      debugPrint('No se pudo cargar el avatar del dashboard: $error');

      if (!mounted) return;

      setState(() {
        usuarioActual = nombre;
        avatarUrlActual = '';
      });
    }
  }

  Future<void> _recargar() async {
    setState(() {
      dashboardFuture = _cargarDashboard();
    });

    await dashboardFuture;
  }

  void _abrirPerfil(String usuario) {
    final limpio = usuario.trim();

    if (limpio.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PerfilUsuarioPage(usuario: limpio)),
    );
  }

  void _abrirRanking({int initialTab = 0}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RankingPage(initialTab: initialTab)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.primary,
              size: 28,
            ),

            const SizedBox(width: AppSpacing.xs),

            Text(
              'ClubReads',
              style: AppTextStyles.title.copyWith(fontSize: 27),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: ClubAvatar(
              nombre: usuarioActual ?? '',
              imageUrl: avatarUrlActual,
              size: 46,
              onTap: () async {
                final nombre = usuarioActual?.trim() ?? '';

                if (nombre.isEmpty) return;

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PerfilUsuarioPage(usuario: nombre),
                  ),
                );

                if (!mounted) return;

                // Recargamos por si la usuaria cambió su foto en el perfil.
                await _cargarUsuarioActual();
              },
            ),
          ),
        ],
      ),

      body: FutureBuilder<DashboardViewData>(
        future: dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(onRetry: _recargar);
          }

          final viewData = snapshot.data!;
          final data = viewData.dashboard;

          final estadoClub = ClubNarrador().narrar(
            estado: DevSettings.estadoForzado ?? data.clubvision.estado,
          );

          return RefreshIndicator(
            onRefresh: _recargar,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                110,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _podioLectoras(
                    lectoras: viewData.topLectoras ?? const [],
                    usuarioMes: data.resumen.usuarioMes,
                    librosUsuarioMes: data.resumen.librosUsuarioMes,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  ClubvisionCard(
                    dashboard: data,
                    estadoClub: estadoClub,
                    haVotado: viewData.haVotado,
                    onActualizar: _recargar,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  const ClubSectionTitle(
                    title: 'Así está el club',
                    subtitle: 'El pulso lector de este mes',
                    icon: Icons.auto_awesome_rounded,
                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  InfoCard(
                    title: 'Pulso del club',
                    value: data.mood,
                    icon: Icons.psychology_alt_outlined,
                    variant: InfoCardVariant.blush,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MoodClubPage()),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),

                  InfoCard(
                    title: 'Tendencia',
                    value: data.tendencia,
                    icon: Icons.trending_up_rounded,
                    variant: InfoCardVariant.sage,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TendenciasClubPage(),
                        ),
                      );
                    },
                  ),

                  if (data.libroMes.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),

                    InfoCard(
                      title: 'Libro del mes',
                      value:
                          '${data.libroMes.first.libro}\n'
                          '${data.libroMes.first.puntos} puntos',
                      icon: Icons.workspace_premium_outlined,
                      variant: InfoCardVariant.primary,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  _estadisticasMes(
                    actividad: data.resumen.actividadMes,
                    valoracion: data.resumen.valoracionMedia,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  const ClubSectionTitle(
                    title: 'Leyendo ahora',
                    subtitle: 'Qué tienen entre manos las lectoras',
                    icon: Icons.menu_book_rounded,
                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  if (data.leyendoAhora.isEmpty)
                    const ClubEmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'El club está entre lecturas',
                      message:
                          'Cuando alguna lectora empiece un libro, aparecerá aquí.',
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    )
                  else
                    ...data.leyendoAhora.map(
                      (usuario) => _lectoraLeyendoCard(
                        nombre: usuario.usuario,
                        lecturas: usuario.lecturas,
                        total: usuario.total,
                        avatarUrl: usuario.avatarUrl,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _podioLectoras({
    required List<RankingItem> lectoras,
    required String usuarioMes,
    required int librosUsuarioMes,
  }) {
    final participantes = lectoras.isNotEmpty
        ? lectoras
        : usuarioMes.trim().isNotEmpty
        ? [RankingItem(nombre: usuarioMes, total: librosUsuarioMes)]
        : const <RankingItem>[];

    return ClubCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceSoft, Color(0xFFF0E5FF)],
      ),
      borderColor: AppColors.primaryLight,
      onTap: participantes.isNotEmpty
          ? () => _abrirRanking(initialTab: 1)
          : null,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 28,
                color: AppColors.gold,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Lectoras del mes',
                style: AppTextStyles.section.copyWith(fontSize: 20),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxs),

          Text(
            participantes.isEmpty
                ? 'Aún no hay lectoras en el podio'
                : 'Las que más historias han conquistado',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),

          if (participantes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: participantes.length > 1
                      ? _PodioPuesto(
                          item: participantes[1],
                          posicion: 2,
                          altura: 44,
                          color: const Color(0xFF9AA3AD),
                          onTap: () => _abrirPerfil(participantes[1].nombre),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(width: AppSpacing.xs),

                Expanded(
                  child: _PodioPuesto(
                    item: participantes.first,
                    posicion: 1,
                    altura: 60,
                    color: AppColors.gold,
                    destacado: true,
                    onTap: () => _abrirPerfil(participantes.first.nombre),
                  ),
                ),

                const SizedBox(width: AppSpacing.xs),

                Expanded(
                  child: participantes.length > 2
                      ? _PodioPuesto(
                          item: participantes[2],
                          posicion: 3,
                          altura: 36,
                          color: const Color(0xFFB77A4A),
                          onTap: () => _abrirPerfil(participantes[2].nombre),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Ver ranking completo',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _estadisticasMes({
    required int actividad,
    required String valoracion,
  }) {
    return Row(
      children: [
        Expanded(
          child: InfoCard(
            title: 'Actividad',
            value: '$actividad ${actividad == 1 ? 'libro' : 'libros'}',
            icon: Icons.local_fire_department_outlined,
            variant: InfoCardVariant.warning,
            compact: true,
            onTap: () {
              _abrirRanking(initialTab: 1);
            },
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: InfoCard(
            title: 'Valoración',
            value: valoracion == '0' ? 'Sin datos' : '$valoracion / 5',
            icon: Icons.star_outline_rounded,
            variant: InfoCardVariant.gold,
            compact: true,
            onTap: () {
              _abrirRanking(initialTab: 2);
            },
          ),
        ),
      ],
    );
  }

  Widget _lectoraLeyendoCard({
    required String nombre,
    required List<LecturaAhoraItem> lecturas,
    required int total,
    required String avatarUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ClubCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        elevated: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => _abrirPerfil(nombre),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Row(
                children: [
                  ClubAvatar(nombre: nombre, imageUrl: avatarUrl, size: 48),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      nombre,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ClubChip(
                    label: '$total ${total == 1 ? 'lectura' : 'lecturas'}',
                    icon: Icons.menu_book_outlined,
                    variant: ClubChipVariant.info,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var index = 0; index < lecturas.length; index++) ...[
              _LecturaProgresoCard(
                lectura: lecturas[index],
                editable:
                    usuarioActual?.trim().toLowerCase() ==
                    nombre.trim().toLowerCase(),
                onEditar: () => _editarProgreso(nombre, lecturas[index]),
              ),
              if (index < lecturas.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _editarProgreso(String usuario, LecturaAhoraItem lectura) async {
    final resultado =
        await showDialog<
          ({
            int progreso,
            String comentario,
            int? paginaActual,
            int? paginasTotales,
          })
        >(
          context: context,
          builder: (_) => _EditarProgresoDialog(lectura: lectura),
        );
    if (resultado == null) return;

    final ok = await ApiService().actualizarProgresoLectura(
      usuario: usuario,
      libro: lectura.titulo,
      progreso: resultado.progreso,
      comentario: resultado.comentario,
      paginaActual: resultado.paginaActual,
      paginasTotales: resultado.paginasTotales,
    );
    if (!mounted) return;
    if (ok) {
      await _recargar();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido guardar el progreso.')),
      );
    }
  }
}

class _LecturaProgresoCard extends StatelessWidget {
  final LecturaAhoraItem lectura;
  final bool editable;
  final VoidCallback onEditar;

  const _LecturaProgresoCard({
    required this.lectura,
    required this.editable,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClubBookCover(
            title: lectura.titulo,
            imageUrl: lectura.coverUrl,
            width: 52,
            showShadow: false,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lectura.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (editable)
                      IconButton(
                        tooltip: 'Actualizar progreso',
                        visualDensity: VisualDensity.compact,
                        onPressed: onEditar,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: lectura.progreso / 100,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      lectura.paginaActual != null &&
                              lectura.paginasTotales != null
                          ? 'Pág. ${lectura.paginaActual} de '
                                '${lectura.paginasTotales} · '
                                '${lectura.progreso}%'
                          : '${lectura.progreso}%',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (lectura.comentario.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '“${lectura.comentario}”',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditarProgresoDialog extends StatefulWidget {
  final LecturaAhoraItem lectura;

  const _EditarProgresoDialog({required this.lectura});

  @override
  State<_EditarProgresoDialog> createState() => _EditarProgresoDialogState();
}

enum _ModoProgreso { porcentaje, pagina }

class _EditarProgresoDialogState extends State<_EditarProgresoDialog> {
  late double progreso;
  late final TextEditingController comentarioController;
  late final TextEditingController paginaController;
  late final TextEditingController totalPaginasController;
  late _ModoProgreso modo;
  String? errorPagina;
  String? errorTotalPaginas;

  int? get totalPaginas =>
      widget.lectura.paginasTotales ??
      int.tryParse(totalPaginasController.text);

  bool get tienePaginas => (totalPaginas ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    progreso = widget.lectura.progreso.toDouble();
    modo =
        widget.lectura.paginaActual != null &&
            (widget.lectura.paginasTotales ?? 0) > 0
        ? _ModoProgreso.pagina
        : _ModoProgreso.porcentaje;
    totalPaginasController = TextEditingController();
    paginaController = TextEditingController(
      text: widget.lectura.paginaActual?.toString() ?? '',
    );
    comentarioController = TextEditingController(
      text: widget.lectura.comentario,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.lectura.titulo,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.lectura.paginasTotales == null) ...[
              TextField(
                controller: totalPaginasController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Páginas del libro (opcional)',
                  hintText: 'Ej. 420',
                  prefixIcon: const Icon(Icons.menu_book_outlined),
                  errorText: errorTotalPaginas,
                ),
                onChanged: (_) {
                  setState(() {
                    errorTotalPaginas = null;
                    if (!tienePaginas) {
                      modo = _ModoProgreso.porcentaje;
                    }
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (tienePaginas) ...[
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<_ModoProgreso>(
                  segments: const [
                    ButtonSegment(
                      value: _ModoProgreso.porcentaje,
                      label: Text('Porcentaje'),
                    ),
                    ButtonSegment(
                      value: _ModoProgreso.pagina,
                      label: Text('Página'),
                    ),
                  ],
                  selected: {modo},
                  onSelectionChanged: (seleccion) {
                    setState(() {
                      modo = seleccion.first;
                      errorPagina = null;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Center(
              child: Text(
                modo == _ModoProgreso.pagina
                    ? '${progreso.round()}% · $totalPaginas páginas'
                    : '${progreso.round()}%',
                style: AppTextStyles.title.copyWith(color: AppColors.primary),
              ),
            ),
            if (modo == _ModoProgreso.porcentaje)
              Slider(
                value: progreso,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${progreso.round()}%',
                onChanged: (value) => setState(() => progreso = value),
              )
            else ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: paginaController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Página actual',
                  suffixText: 'de $totalPaginas',
                  errorText: errorPagina,
                ),
                onChanged: (value) {
                  final pagina = int.tryParse(value);
                  final total = totalPaginas!;
                  setState(() {
                    errorPagina = null;
                    if (pagina != null && pagina >= 0 && pagina <= total) {
                      progreso = pagina / total * 100;
                    }
                  });
                },
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: comentarioController,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Impresiones hasta ahora',
                hintText: '¿Qué te está pareciendo?',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }

  void _guardar() {
    int? paginasTotales;
    if (widget.lectura.paginasTotales == null &&
        totalPaginasController.text.isNotEmpty) {
      paginasTotales = int.tryParse(totalPaginasController.text);
      if (paginasTotales == null || paginasTotales <= 0) {
        setState(() => errorTotalPaginas = 'Indica un número mayor que 0');
        return;
      }
    }

    int? paginaActual;
    if (modo == _ModoProgreso.pagina) {
      paginaActual = int.tryParse(paginaController.text);
      final total = totalPaginas!;
      if (paginaActual == null || paginaActual < 0 || paginaActual > total) {
        setState(() => errorPagina = 'Indica una página entre 0 y $total');
        return;
      }
    }

    Navigator.pop(context, (
      progreso: progreso.round(),
      comentario: comentarioController.text.trim(),
      paginaActual: paginaActual,
      paginasTotales: paginasTotales,
    ));
  }

  @override
  void dispose() {
    paginaController.dispose();
    totalPaginasController.dispose();
    comentarioController.dispose();
    super.dispose();
  }
}

class _PodioPuesto extends StatelessWidget {
  final RankingItem item;
  final int posicion;
  final double altura;
  final Color color;
  final bool destacado;
  final VoidCallback onTap;

  const _PodioPuesto({
    required this.item,
    required this.posicion,
    required this.altura,
    required this.color,
    required this.onTap,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Puesto $posicion, ${item.nombre}, ${item.total} libros',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (destacado)
              Icon(Icons.emoji_events_rounded, color: color, size: 18)
            else
              const SizedBox(height: 18),

            const SizedBox(height: AppSpacing.xxs),

            ClubAvatar(
              nombre: item.nombre,
              imageUrl: item.avatarUrl,
              size: destacado ? 52 : 46,
            ),
            const SizedBox(height: AppSpacing.xxs),

            Text(
              item.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),

            Text(
              '${item.total} ${item.total == 1 ? 'libro' : 'libros'}',
              maxLines: 1,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: AppSpacing.xxs),

            Container(
              height: altura,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.88),
                    color.withValues(alpha: 0.58),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: Text(
                '$posicion',
                style: AppTextStyles.title.copyWith(
                  color: Colors.white,
                  fontSize: destacado ? 25 : 21,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
