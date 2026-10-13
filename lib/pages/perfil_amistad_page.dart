import 'package:flutter/material.dart';

import '../models/amistad.dart';
import '../navigation/book_detail_navigation.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/amistades/comentarios_progreso.dart';
import '../widgets/amistades/reacciones_progreso.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import '../widgets/error_view.dart';

/// Lo que una amistad enseña de sí misma: qué lee ahora (con reacciones), lo
/// último que ha terminado, sus pendientes y sus reseñas, según lo que haya
/// decidido compartir.
class PerfilAmistadPage extends StatefulWidget {
  const PerfilAmistadPage({super.key, required this.nombre, this.cargar});

  final String nombre;

  /// Para pruebas.
  final Future<PerfilAmistad> Function(String nombre)? cargar;

  @override
  State<PerfilAmistadPage> createState() => _PerfilAmistadPageState();
}

class _PerfilAmistadPageState extends State<PerfilAmistadPage> {
  PerfilAmistad? _perfil;
  String? _error;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final perfil = await (widget.cargar ?? ApiService().getPerfilAmistad)(
        widget.nombre,
      );
      if (!mounted) return;
      setState(() {
        _perfil = perfil;
        _error = null;
        _cargando = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se ha podido abrir el perfil.';
        _cargando = false;
      });
    }
  }

  Future<void> _abrirLibro(String bookId, String titulo, String coverUrl) =>
      abrirLibroDeTalento(
        context,
        bookId: bookId,
        title: titulo,
        coverUrl: coverUrl,
      );

  @override
  Widget build(BuildContext context) {
    final perfil = _perfil;
    return Scaffold(
      appBar: AppBar(title: Text(widget.nombre)),
      body: _cargando && perfil == null
          ? const Center(child: CircularProgressIndicator())
          : perfil == null
          ? ErrorView(mensaje: _error, onRetry: _cargar)
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: _contenido(perfil),
            ),
    );
  }

  List<Widget> _contenido(PerfilAmistad p) {
    return [
      Row(
        children: [
          ClubAvatar(nombre: p.nombre, imageUrl: p.avatarUrl, size: 64),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nombre, style: AppTextStyles.title),
                if (p.bio.trim().isNotEmpty)
                  Text(p.bio, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      _leyendo(p),
      _terminados(p),
      _pendientes(p),
      _deseos(p),
      _resenas(p),
      const SizedBox(height: AppSpacing.xl),
    ];
  }

  Widget _titulo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.md),
    child: Text(texto, style: AppTextStyles.section),
  );

  Widget _noComparte(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(texto, style: AppTextStyles.bodySecondary),
  );

  Widget _leyendo(PerfilAmistad p) {
    if (!p.compartido.leyendo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo('Leyendo ahora'),
          _noComparte('${p.nombre} no comparte lo que lee por ahora.'),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Leyendo ahora'),
        if (p.leyendo.isEmpty)
          _noComparte('Ahora mismo no está leyendo nada.')
        else
          for (final l in p.leyendo)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ClubCard(
                elevated: false,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _abrirLibro(l.bookId, l.titulo, l.coverUrl),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClubBookCover(
                            title: l.titulo,
                            imageUrl: l.coverUrl,
                            width: 64,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.titulo, style: AppTextStyles.section),
                                if (l.autor.isNotEmpty)
                                  Text(
                                    l.autor,
                                    style: AppTextStyles.bodySecondary,
                                  ),
                                const SizedBox(height: AppSpacing.sm),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: l.progreso / 100,
                                    minHeight: 8,
                                    backgroundColor: AppColors.surfaceSoft,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l.paginaActual != null &&
                                          l.paginasTotales != null
                                      ? 'Pág. ${l.paginaActual} de ${l.paginasTotales} · ${l.progreso}%'
                                      : '${l.progreso}%',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (l.nota.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '“${l.nota.trim()}”',
                        style: AppTextStyles.bodySecondary.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    ReaccionesProgreso(lectura: l),
                    TextButton.icon(
                      onPressed: l.libraryId.isEmpty
                          ? null
                          : () => mostrarComentariosProgreso(
                              context,
                              libraryId: l.libraryId,
                              titulo: l.titulo,
                            ),
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 19,
                      ),
                      label: const Text('Comentarios'),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _tiraDeLibros(List<LibroDeAmistad> libros, {bool deseos = false}) {
    return SizedBox(
      height: deseos ? 272 : 236,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: libros.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final libro = libros[i];
          return InkWell(
            onTap: libro.bookId.isEmpty
                ? null
                : () => _abrirLibro(libro.bookId, libro.titulo, libro.coverUrl),
            child: SizedBox(
              width: 104,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClubBookCover(
                    title: libro.titulo,
                    imageUrl: libro.coverUrl,
                    width: 104,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    libro.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                  if (libro.valoracion != null)
                    Text(
                      '⭐ ${libro.valoracion!.toStringAsFixed(1)}',
                      style: AppTextStyles.caption,
                    ),
                  if (deseos && libro.autor.isNotEmpty)
                    Text(
                      libro.autor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  if (deseos && libro.prioridad == 'HIGH')
                    Text('💜 Prioridad', style: AppTextStyles.caption),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _terminados(PerfilAmistad p) {
    if (!p.compartido.leyendo || p.terminados.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo(
          p.totalTerminados == null
              ? 'Terminados recientemente'
              : 'Terminados (${p.totalTerminados})',
        ),
        _tiraDeLibros(p.terminados),
      ],
    );
  }

  Widget _pendientes(PerfilAmistad p) {
    if (!p.compartido.biblioteca) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo('Pendientes'),
          _noComparte('${p.nombre} no comparte su biblioteca.'),
        ],
      );
    }
    if (p.pendientes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo(
          p.totalPendientes == null
              ? 'Pendientes'
              : 'Pendientes (${p.totalPendientes})',
        ),
        _tiraDeLibros(p.pendientes),
      ],
    );
  }

  Widget _deseos(PerfilAmistad p) {
    if (!p.compartido.deseos) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo('Lista de deseos 🎁'),
          _noComparte('${p.nombre} no comparte su lista de deseos.'),
        ],
      );
    }
    if (p.deseos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Lista de deseos 🎁 (${p.deseos.length})'),
        Text('Ideas para regalar', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        _tiraDeLibros(p.deseos, deseos: true),
      ],
    );
  }

  Widget _resenas(PerfilAmistad p) {
    if (!p.compartido.resenas) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _titulo('Reseñas'),
          _noComparte('${p.nombre} no comparte sus reseñas.'),
        ],
      );
    }
    if (p.resenas.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Reseñas'),
        for (final r in p.resenas)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ClubCard(
              elevated: false,
              onTap: () => _abrirLibro(r.bookId, r.titulo, r.coverUrl),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${r.titulo}${r.valoracion == null ? '' : '  ⭐ ${r.valoracion!.toStringAsFixed(1)}'}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (r.contieneSpoilers)
                    Text(
                      'Contiene spoilers: ábrela desde el libro si quieres leerla.',
                      style: AppTextStyles.caption,
                    )
                  else if (r.texto.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        r.texto.trim(),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
