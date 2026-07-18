import 'dart:async';

import 'package:club_lectura_app/models/comentarios_capitulo.dart';
import 'package:club_lectura_app/services/usuario_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../services/api_service.dart';
import '../widgets/lectura/comentario_card.dart';
import '../widgets/lectura/comentario_input.dart';

class CapituloPage extends StatefulWidget {
  final String libro;
  final String capitulo;

  const CapituloPage({super.key, required this.libro, required this.capitulo});

  @override
  State<CapituloPage> createState() => _CapituloPageState();
}

class _CapituloPageState extends State<CapituloPage> {
  late Future<ComentariosCapitulo> future;

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode editorFocusNode = FocusNode();

  String? usuario;
  bool enviando = false;
  bool editorReflexionVisible = false;
  Timer? _temporizadorBorrador;

  bool get esReflexion => widget.capitulo.trim() == '💭 Reflexión final';

  @override
  void initState() {
    super.initState();

    controller.addListener(_programarGuardadoBorrador);
    future = _inicializar();
  }

  Future<ComentariosCapitulo> _inicializar() async {
    final u = await UsuarioService().obtenerUsuario();

    usuario = u;

    await _restaurarBorrador();

    if (u != null && u.trim().isNotEmpty) {
      await ApiService().marcarConversacionVista(
        libro: widget.libro,
        capitulo: widget.capitulo,
        usuario: u,
      );
    }

    if (mounted) {
      setState(() {});
    }

    return ApiService().getComentariosCapitulo(
      libro: widget.libro,
      capitulo: widget.capitulo,
    );
  }

  String? get _claveBorrador {
    final nombreUsuario = usuario?.trim() ?? '';

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

  void _recargar() {
    future = ApiService().getComentariosCapitulo(
      libro: widget.libro,
      capitulo: widget.capitulo,
    );
  }

  Future<void> _publicar() async {
    final texto = controller.text.trim();

    if (texto.isEmpty || enviando) return;

    if (usuario == null || usuario!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido identificar a la usuaria.'),
        ),
      );
      return;
    }

    setState(() {
      enviando = true;
    });

    try {
      await ApiService().guardarComentarioLectura(
        libro: widget.libro,
        capitulo: widget.capitulo,
        usuario: usuario!,
        comentario: texto,
      );

      if (!mounted) return;

      await _borrarBorrador();

      if (!mounted) return;

      controller.clear();
      FocusScope.of(context).unfocus();

      setState(() {
        if (esReflexion) editorReflexionVisible = false;
        _recargar();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esReflexion ? 'Reflexión publicada 💜' : 'Comentario publicado 💜',
          ),
        ),
      );
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceSoft, Color(0xFFF0E5FF)],
        ),
        borderColor: AppColors.primaryLight,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                esReflexion
                    ? Icons.psychology_alt_outlined
                    : Icons.forum_outlined,
                color: AppColors.primary,
                size: 29,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              widget.libro,
              textAlign: TextAlign.center,
              style: AppTextStyles.section.copyWith(fontSize: 23, height: 1.2),
            ),

            const SizedBox(height: AppSpacing.xs),

            Text(
              widget.capitulo,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _contenidoComentarios(AsyncSnapshot<ComentariosCapitulo> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(child: _cabecera()),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (snapshot.hasError || !snapshot.hasData) {
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
                        setState(() {
                          _recargar();
                        });
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

    final data = snapshot.data!;

    return CustomScrollView(
      controller: scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(child: _cabecera()),

        if (data.comentarios.isEmpty)
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
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final comentarioCard = ComentarioCard(
                  comentario: data.comentarios[index],
                  usuarioActual: usuario ?? '',
                  onActualizar: () {
                    if (!mounted) return;

                    setState(() {
                      _recargar();
                    });
                  },
                );

                if (!esReflexion) return comentarioCard;

                return _ReflexionProtegida(
                  key: ValueKey(data.comentarios[index].id),
                  child: comentarioCard,
                );
              }, childCount: data.comentarios.length),
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
              child: FutureBuilder<ComentariosCapitulo>(
                future: future,
                builder: (context, snapshot) {
                  return _contenidoComentarios(snapshot);
                },
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
    editorFocusNode.dispose();
    super.dispose();
  }
}

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
