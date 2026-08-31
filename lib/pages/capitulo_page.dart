import 'dart:async';

import 'package:club_lectura_app/models/comentarios_capitulo.dart';
import 'package:club_lectura_app/models/comentario_lectura.dart';
import 'package:club_lectura_app/services/usuario_service.dart';
import 'package:club_lectura_app/services/auth_session_service.dart';
import 'package:club_lectura_app/services/cursor_pagination_controller.dart';
import 'package:club_lectura_app/services/chapter_initialization.dart';
import 'package:club_lectura_app/services/conversation_scroll_policy.dart';
import 'package:club_lectura_app/services/comment_publication.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../models/subrayador_categoria.dart';
import '../services/api_service.dart';
import '../services/kit_lectura_service.dart';
import '../widgets/lectura/comentario_card.dart';
import '../widgets/lectura/comentario_input.dart';
import 'package:club_lectura_app/widgets/common/club_shimmer.dart';

class CapituloPage extends StatefulWidget {
  final String libro;
  final String capitulo;
  final String bookId;

  const CapituloPage({
    super.key,
    required this.libro,
    required this.capitulo,
    this.bookId = '',
  });

  @override
  State<CapituloPage> createState() => _CapituloPageState();
}

class _CapituloPageState extends State<CapituloPage> {
  late Future<void> future;
  late final CursorPaginationController<ComentarioLectura> _pagination;

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode editorFocusNode = FocusNode();

  String? usuario;
  bool enviando = false;
  bool editorReflexionVisible = false;

  /// Key asignada al divisor "Nuevos" para poder hacer scroll automático.
  final GlobalKey _newsDividerKey = GlobalKey();
  bool _scrolledToNew = false; // solo scrolleamos una vez por apertura
  /// Índice de la categoría de subrayador seleccionada (null = libre).
  /// Determina color y si es cita (kSubrayadorCategorias[i].esCita).
  int? _categoriaSeleccionada;

  /// Colores de los subrayadores del kit (uno por categoría).
  List<Color> coloresSubrayadores = const [];
  Timer? _temporizadorBorrador;

  bool get esReflexion => widget.capitulo.trim() == '💭 Reflexión final';

  @override
  void initState() {
    super.initState();

    _pagination = CursorPaginationController(
      loadPage: (cursor) => ApiService().getComentariosCapituloPage(
        libro: widget.libro,
        capitulo: widget.capitulo,
        cursor: cursor,
        // En páginas 2+ propagamos el corte capturado en la primera página.
        cutoff: cursor != null ? _pagination.cutoffDate : null,
      ),
      keyOf: (comment) => comment.id,
    )..addListener(_onPaginationChanged);
    scrollController.addListener(_onScroll);
    controller.addListener(_programarGuardadoBorrador);
    future = _inicializar();
    _cargarColoresKit();
  }

  Future<void> _cargarColoresKit() async {
    final kit = await KitLecturaService().obtener(widget.bookId);
    // Usar los subrayadores (no la paleta base) ya que son los colores
    // diseñados específicamente para anotar el libro.
    final colores = kit.subrayadores
        .map(_colorDesdeHex)
        .whereType<Color>()
        .toList(growable: false);
    if (!mounted) return;
    setState(() {
      coloresSubrayadores = colores;
    });
  }

  Color? _colorDesdeHex(String value) {
    final limpio = value.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(limpio)) return null;
    return Color(int.parse('FF$limpio', radix: 16));
  }

  String _colorAHex(Color? color) {
    if (color == null) return '';
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  void _onPaginationChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    if (scrollController.position.extentAfter < 500) {
      _pagination.loadMore();
    }
  }

  Future<void> _inicializar() async {
    await ChapterInitialization.run(
      loadComments: _pagination.loadFirst,
      loadUser: UsuarioService().obtenerUsuario,
      onUserLoaded: (value) => usuario = value,
      restoreDraft: _restaurarBorrador,
      markSeen: (value) => ApiService().marcarConversacionVista(
        libro: widget.libro,
        capitulo: widget.capitulo,
        usuario: value,
      ),
    );

    if (mounted) {
      setState(() {});
      _scrollToFirstNew();
    }
  }

  /// Desplaza la lista hasta el divisor "Nuevos" si hay comentarios nuevos.
  ///
  /// SliverList es siempre lazy: solo asigna contexto a los widgets visibles
  /// o dentro del cacheExtent. Si el divisor está fuera del viewport inicial,
  /// _newsDividerKey.currentContext es null y ensureVisible no hace nada.
  ///
  /// Estrategia en dos fases:
  ///   1. Si el divisor ya está en viewport → ensureVisible directo.
  ///   2. Si no → animamos hasta la posición aproximada por ratio de índice
  ///      (lo que lleva el divisor al viewport), luego ensureVisible refina.
  void _scrollToFirstNew() {
    if (_scrolledToNew) return;
    final items = _pagination.items;
    final firstNewIndex = items.indexWhere((c) => c.esNuevo);
    if (firstNewIndex < 0) return;
    _scrolledToNew = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !scrollController.hasClients) return;

      // Fase 1: el divisor ya está cerca del viewport (pocos comentarios previos)
      final ctx = _newsDividerKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          alignment: 0.0,
        );
        return;
      }

      // Fase 2: el divisor está fuera del viewport.
      // Hacemos un scroll aproximado por ratio para acercarnos.
      final max = scrollController.position.maxScrollExtent;
      if (max <= 0) return;

      // El divisor se inserta antes del comentario en firstNewIndex,
      // por eso restamos un poco para no pasarnos.
      final ratio = ((firstNewIndex - 0.5) / (items.length + 1)).clamp(0.0, 0.95);
      await scrollController.animateTo(
        max * ratio,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );

      if (!mounted || !scrollController.hasClients) return;

      // Refinamos con ensureVisible ahora que el divisor debería estar en viewport
      // Capturamos el contexto antes del siguiente punto de suspensión.
      final ctx2 = _newsDividerKey.currentContext;
      if (ctx2 != null && ctx2.mounted) {
        // ignore: use_build_context_synchronously — ctx2 verificado con ctx2.mounted
        Scrollable.ensureVisible(
          ctx2,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: 0.0,
        );
      }
    });
  }

  String? get _claveBorrador {
    final nombreUsuario =
        AuthSessionService.instance.user?.id.trim() ?? usuario?.trim() ?? '';

    if (nombreUsuario.isEmpty) return null;

    return [
      'borrador_comentario',
      Uri.encodeComponent(nombreUsuario),
      Uri.encodeComponent(widget.libro.trim()),
      Uri.encodeComponent(widget.capitulo.trim()),
    ].join('_');
  }

  Future<void> _restaurarBorrador() async {
    final clave = _claveBorrador;

    if (clave == null) return;

    final prefs = await SharedPreferences.getInstance();
    final borrador = prefs.getString(clave) ?? '';

    if (!mounted || borrador.isEmpty) return;

    controller.value = TextEditingValue(
      text: borrador,
      selection: TextSelection.collapsed(offset: borrador.length),
    );
  }

  void _programarGuardadoBorrador() {
    _temporizadorBorrador?.cancel();
    _temporizadorBorrador = Timer(const Duration(milliseconds: 300), () {
      unawaited(_guardarBorrador(controller.text));
    });
  }

  Future<void> _guardarBorrador(String texto) async {
    final clave = _claveBorrador;

    if (clave == null) return;

    final prefs = await SharedPreferences.getInstance();

    if (texto.trim().isEmpty) {
      await prefs.remove(clave);
    } else {
      await prefs.setString(clave, texto);
    }
  }

  Future<void> _borrarBorrador() async {
    _temporizadorBorrador?.cancel();

    final clave = _claveBorrador;

    if (clave == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(clave);
  }

  Future<void> _recargar() => _pagination.loadFirst();

  Future<void> _publicar() async {
    final texto = controller.text.trim();

    if (texto.isEmpty || enviando) return;

    if (usuario == null || usuario!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido identificar al usuario.'),
        ),
      );
      return;
    }

    final estabaCercaDelFinal = shouldAutoScrollAfterPublishing(
      hasScrollPosition: scrollController.hasClients,
      extentAfter: scrollController.hasClients
          ? scrollController.position.extentAfter
          : 0,
    );

    setState(() {
      enviando = true;
    });

    try {
      await publishConfirmedComment(
        publish: () => ApiService().guardarComentarioLectura(
          libro: widget.libro,
          capitulo: widget.capitulo,
          usuario: usuario!,
          comentario: texto,
          tipo: (_categoriaSeleccionada != null &&
                  _categoriaSeleccionada! < kSubrayadorCategorias.length &&
                  kSubrayadorCategorias[_categoriaSeleccionada!].esCita)
              ? 'QUOTE'
              : 'COMMENT',
          color: (_categoriaSeleccionada != null &&
                  _categoriaSeleccionada! < coloresSubrayadores.length)
              ? _colorAHex(coloresSubrayadores[_categoriaSeleccionada!])
              : '',
        ),
        onConfirmed: _pagination.appendLocal,
        clearDraft: _borrarBorrador,
      );

      if (!mounted) return;

      controller.clear();
      FocusScope.of(context).unfocus();

      setState(() {
        if (esReflexion) editorReflexionVisible = false;
      });
      if (estabaCercaDelFinal) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !scrollController.hasClients) return;
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              esReflexion
                  ? 'Reflexión publicada 💜'
                  : 'Comentario publicado 💜',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Comentario publicado'),
            action: SnackBarAction(label: 'Ir al final', onPressed: _irAlFinal),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido publicar. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          enviando = false;
        });
      }
    }
  }

  void _irAlFinal() {
    if (!scrollController.hasClients) return;
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _abrirEditorReflexion() {
    setState(() => editorReflexionVisible = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) editorFocusNode.requestFocus();
    });
  }

  void _cerrarEditorReflexion() {
    editorFocusNode.unfocus();
    setState(() => editorReflexionVisible = false);
  }

  Widget _cabecera() {
    if (esReflexion) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xs,
        ),
        child: ClubCard(
          elevated: false,
          padding: const EdgeInsets.all(AppSpacing.md),
          borderColor: AppColors.primaryLight,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_alt_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.libro,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Color(0xFFB48113),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Reflexiones con spoilers',
                          style: TextStyle(
                            color: Color(0xFF8B650F),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: ClubCard(
        elevated: false,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        borderColor: AppColors.primaryLight,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.forum_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.capitulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subtitle.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.libro,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenidoComentarios() {
    if (_pagination.showInitialLoader) {
      return CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(child: _cabecera()),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: CardListSkeleton(),
          ),
        ],
      );
    }

    if (_pagination.showInitialError) {
      return CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(child: _cabecera()),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color: Colors.deepPurple,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'No se han podido cargar los comentarios.',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 16),

                    FilledButton.icon(
                      onPressed: () {
                        _recargar();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final data = ComentariosCapitulo(
      capitulo: widget.capitulo,
      comentarios: _pagination.items,
    );

    return CustomScrollView(
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(child: _cabecera()),

        if (_pagination.refreshing)
          const SliverToBoxAdapter(
            child: LinearProgressIndicator(minHeight: 2),
          ),

        if (_pagination.showEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 80),
                child: Text(
                  esReflexion
                      ? 'Todavía nadie ha compartido su reflexión '
                            'sobre el libro.\n\n'
                            'Sé la primera en abrir el debate 💜'
                      : 'Todavía nadie ha comentado este capítulo.'
                            '\n\n'
                            'Sé la primera en romper el hielo 💜',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, height: 1.4),
                ),
              ),
            ),
          )
        else
          _ComentariosList(
            comentarios: data.comentarios,
            usuarioActual: usuario ?? '',
            esReflexion: esReflexion,
            newsDividerKey: _newsDividerKey,
            onRecargar: _recargar,
            onEdited: (id, text) => _pagination.replace(
              id,
              (comment) => comment.copyWith(comentario: text, editado: true),
            ),
            onDeleted: _pagination.remove,
          ),
        if (_pagination.loadingMore || _pagination.loadMoreError != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: _pagination.loadingMore
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : TextButton.icon(
                        onPressed: _pagination.loadMore,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('No se pudo cargar más. Reintentar'),
                      ),
              ),
            ),
          ),
        if (_pagination.hasContentError)
          SliverToBoxAdapter(
            child: Center(
              child: TextButton.icon(
                onPressed: _recargar,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('No se pudo actualizar. Reintentar'),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      appBar: AppBar(title: Text(widget.capitulo)),

      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<void>(
                future: future,
                builder: (context, snapshot) => _contenidoComentarios(),
              ),
            ),

            const Divider(height: 1),

            if (esReflexion && !editorReflexionVisible)
              Material(
                color: Theme.of(context).scaffoldBackgroundColor,
                elevation: 8,
                shadowColor: Colors.black12,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _abrirEditorReflexion,
                        icon: const Icon(Icons.edit_note_rounded),
                        label: Text(
                          controller.text.trim().isEmpty
                              ? 'Escribir reflexión'
                              : 'Continuar reflexión',
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              ComentarioInput(
                controller: controller,
                onEnviar: _publicar,
                enviando: enviando,
                esReflexion: esReflexion,
                onCerrar: esReflexion ? _cerrarEditorReflexion : null,
                focusNode: esReflexion ? editorFocusNode : null,
                categoriaSeleccionada: esReflexion
                    ? null
                    : _categoriaSeleccionada,
                coloresCategorias: esReflexion ? const [] : coloresSubrayadores,
                onCategoriaChanged: esReflexion
                    ? null
                    : (i) => setState(() => _categoriaSeleccionada = i),
                hintText: esReflexion
                    ? 'Comparte tu reflexión sobre el libro, '
                          'el desenlace, los personajes...'
                    : '¿Qué te ha parecido este capítulo?',
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _temporizadorBorrador?.cancel();
    controller.removeListener(_programarGuardadoBorrador);
    unawaited(_guardarBorrador(controller.text));
    controller.dispose();
    scrollController.dispose();
    _pagination
      ..removeListener(_onPaginationChanged)
      ..dispose();
    editorFocusNode.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Lista de comentarios con divisor "Nuevos"
// ---------------------------------------------------------------------------

class _ComentariosList extends StatelessWidget {
  const _ComentariosList({
    required this.comentarios,
    required this.usuarioActual,
    required this.esReflexion,
    required this.newsDividerKey,
    required this.onRecargar,
    required this.onEdited,
    required this.onDeleted,
  });

  final List<ComentarioLectura> comentarios;
  final String usuarioActual;
  final bool esReflexion;
  final GlobalKey newsDividerKey;
  final VoidCallback onRecargar;
  final void Function(String id, String text) onEdited;
  final void Function(String id) onDeleted;

  @override
  Widget build(BuildContext context) {
    // Construimos la lista de items intercalando el divisor antes del primer
    // comentario marcado como nuevo.
    final items = <Widget>[];
    bool divisorInsertado = false;

    for (final comentario in comentarios) {
      if (!divisorInsertado && comentario.esNuevo) {
        divisorInsertado = true;
        items.add(_NuevosDivisor(key: newsDividerKey));
      }

      final card = ComentarioCard(
        key: ValueKey(comentario.id),
        comentario: comentario,
        usuarioActual: usuarioActual,
        onActualizar: onRecargar,
        onEdited: (text) => onEdited(comentario.id, text),
        onDeleted: () => onDeleted(comentario.id),
      );

      items.add(
        esReflexion
            ? _ReflexionProtegida(key: ValueKey('p_${comentario.id}'), child: card)
            : card,
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 20),
      sliver: SliverList(
        // SliverChildListDelegate construye todos los hijos de forma eager,
        // lo que garantiza que el GlobalKey del divisor "Nuevos" tenga
        // contexto desde el primer frame y el scroll automático funcione.
        delegate: SliverChildListDelegate(items),
      ),
    );
  }
}

class _NuevosDivisor extends StatelessWidget {
  const _NuevosDivisor({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: color.withValues(alpha: .35), height: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: color.withValues(alpha: .28)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fiber_new_rounded, size: 16, color: color),
                  const SizedBox(width: 4),
                  Text(
                    'Nuevos desde tu última visita',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Divider(color: color.withValues(alpha: .35), height: 1),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ReflexionProtegida extends StatefulWidget {
  final Widget child;

  const _ReflexionProtegida({super.key, required this.child});

  @override
  State<_ReflexionProtegida> createState() => _ReflexionProtegidaState();
}

class _ReflexionProtegidaState extends State<_ReflexionProtegida> {
  bool visible = false;

  @override
  Widget build(BuildContext context) {
    if (visible) return widget.child;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClubCard(
        elevated: false,
        padding: EdgeInsets.zero,
        backgroundColor: AppColors.midnight,
        borderColor: AppColors.midnight,
        onTap: () => setState(() => visible = true),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              Icon(
                Icons.visibility_off_outlined,
                color: Colors.white,
                size: 32,
              ),
              SizedBox(height: 12),
              Text(
                'Reflexión oculta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Puede revelar el final del libro. Toca para leerla.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFD9D4E5), height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
