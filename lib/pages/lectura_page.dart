import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';

import '../models/capitulo_lectura.dart';
import '../models/configuracion_lectura.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import '../widgets/ui/club_section_title.dart';
import '../widgets/lectura/capitulo_tile.dart';
import 'capitulo_page.dart';

class LecturaPage extends StatefulWidget {
  final String libro;
  final String coverUrl;

  const LecturaPage({super.key, required this.libro, this.coverUrl = ''});

  @override
  State<LecturaPage> createState() => _LecturaPageState();
}

class _LecturaPageState extends State<LecturaPage> {
  late Future<ConfiguracionLectura> future;

  final ScrollController _scrollController = ScrollController();

  /// Los capítulos que estén dentro de este conjunto aparecen plegados.
  /// Al comenzar está vacío, así que todos aparecen desplegados.
  final Set<String> _capitulosPlegados = <String>{};

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  void _recargar() {
    future = ApiService().getConfiguracionLectura(libro: widget.libro);
  }

  Future<void> _refrescar() async {
    final posicionActual = _posicionActual();

    setState(_recargar);

    await future;

    if (!mounted) return;

    _restaurarPosicion(posicionActual);
  }

  double _posicionActual() {
    if (!_scrollController.hasClients) {
      return 0;
    }

    return _scrollController.offset;
  }

  void _restaurarPosicion(double posicion) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final maximo = _scrollController.position.maxScrollExtent;
      final destino = posicion.clamp(0.0, maximo).toDouble();

      _scrollController.jumpTo(destino);
    });
  }

  void _alternarCapitulo(String nombre) {
    setState(() {
      if (_capitulosPlegados.contains(nombre)) {
        _capitulosPlegados.remove(nombre);
      } else {
        _capitulosPlegados.add(nombre);
      }
    });
  }

  void _plegarTodos(List<CapituloLectura> capitulos) {
    final posicionActual = _posicionActual();

    setState(() {
      _capitulosPlegados
        ..clear()
        ..addAll(capitulos.map((capitulo) => capitulo.nombre));
    });

    _restaurarPosicion(posicionActual);
  }

  void _desplegarTodos() {
    final posicionActual = _posicionActual();

    setState(() {
      _capitulosPlegados.clear();
    });

    _restaurarPosicion(posicionActual);
  }

  Future<void> _abrirCapitulo(CapituloLectura capitulo, String bookId) async {
    final posicionAntesDeEntrar = _posicionActual();

    await Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => CapituloPage(
          libro: widget.libro,
          capitulo: capitulo.nombre,
          bookId: bookId,
        ),
      ),
    );

    if (!mounted) return;

    /*
     * Recargamos para actualizar:
     * - comentarios nuevos;
     * - contadores;
     * - última actividad;
     * - marca de leído.
     *
     * Después devolvemos el scroll al mismo punto.
     */
    setState(_recargar);

    await future;

    if (!mounted) return;

    _restaurarPosicion(posicionAntesDeEntrar);
  }

  bool _estanTodosPlegados(List<CapituloLectura> capitulos) {
    if (capitulos.isEmpty) {
      return false;
    }

    return capitulos.every(
      (capitulo) => _capitulosPlegados.contains(capitulo.nombre),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lectura')),
      body: FutureBuilder<ConfiguracionLectura>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: FilledButton.icon(
                onPressed: () {
                  setState(_recargar);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            );
          }

          final config = snapshot.data!;
          final capitulos = config.capitulosDisponibles;
          final todosPlegados = _estanTodosPlegados(capitulos);

          return RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView(
              key: PageStorageKey<String>('lectura-${widget.libro}'),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                100,
              ),
              children: [
                ClubCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.surfaceSoft, Color(0xFFF0E5FF)],
                  ),
                  borderColor: AppColors.primaryLight,
                  child: Column(
                    children: [
                      Hero(
                        tag: 'book-${widget.libro}',
                        child: ClubBookCover(
                          title: widget.libro,
                          imageUrl: config.coverUrl.isNotEmpty
                              ? config.coverUrl
                              : widget.coverUrl,
                          width: 150,
                          showShadow: true,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Text(
                        widget.libro,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 27,
                          height: 1.15,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      Text(
                        '${capitulos.length} espacios de conversación',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                const ClubSectionTitle(
                  icon: Icons.forum_outlined,
                  color: AppColors.primary,
                  title: 'Capítulos',
                  subtitle:
                      'Comenta la lectura sin perderte ninguna conversación',
                ),

                const SizedBox(height: AppSpacing.md),

                _ControlesCapitulos(
                  todosPlegados: todosPlegados,
                  hayCapitulos: capitulos.isNotEmpty,
                  onPlegarTodos: () {
                    _plegarTodos(capitulos);
                  },
                  onDesplegarTodos: _desplegarTodos,
                ),

                const SizedBox(height: AppSpacing.md),

                ...capitulos.map(
                  (capitulo) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: CapituloTile(
                      capitulo: capitulo,
                      plegado: _capitulosPlegados.contains(capitulo.nombre),
                      onTogglePlegado: () {
                        _alternarCapitulo(capitulo.nombre);
                      },
                      onTap: () {
                        _abrirCapitulo(capitulo, config.bookId);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _ControlesCapitulos extends StatelessWidget {
  final bool todosPlegados;
  final bool hayCapitulos;
  final VoidCallback onPlegarTodos;
  final VoidCallback onDesplegarTodos;

  const _ControlesCapitulos({
    required this.todosPlegados,
    required this.hayCapitulos,
    required this.onPlegarTodos,
    required this.onDesplegarTodos,
  });

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      backgroundColor: AppColors.surfaceSoft,
      borderColor: AppColors.border,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.view_agenda_outlined,
              size: 22,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vista de capítulos',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  todosPlegados
                      ? 'Los capítulos están plegados'
                      : 'Puedes plegarlos individualmente',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          PopupMenuButton<_AccionCapitulos>(
            tooltip: 'Opciones de capítulos',
            enabled: hayCapitulos,
            icon: const Icon(
              Icons.unfold_more_rounded,
              color: AppColors.primary,
            ),
            onSelected: (accion) {
              switch (accion) {
                case _AccionCapitulos.plegarTodos:
                  onPlegarTodos();
                  break;

                case _AccionCapitulos.desplegarTodos:
                  onDesplegarTodos();
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _AccionCapitulos.plegarTodos,
                child: Row(
                  children: [
                    Icon(Icons.unfold_less_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Plegar todos'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _AccionCapitulos.desplegarTodos,
                child: Row(
                  children: [
                    Icon(Icons.unfold_more_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Desplegar todos'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _AccionCapitulos { plegarTodos, desplegarTodos }
