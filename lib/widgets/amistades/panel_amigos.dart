import 'package:flutter/material.dart';

import '../../models/amistad.dart';
import '../../pages/perfil_amistad_page.dart';
import '../../services/amistades_cambios.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_avatar.dart';
import '../common/club_book_cover.dart';
import 'comentarios_progreso.dart';
import 'reacciones_progreso.dart';

String _hace(DateTime? fecha) {
  if (fecha == null) return '';
  final dias = DateTime.now().difference(fecha).inDays;
  if (dias <= 0) return 'hoy';
  if (dias == 1) return 'ayer';
  if (dias < 7) return 'hace $dias días';
  if (dias < 30) return 'hace ${dias ~/ 7} sem.';
  return 'hace ${dias ~/ 30} meses';
}

void _abrirPerfil(BuildContext context, String nombre) => Navigator.push<void>(
  context,
  MaterialPageRoute(builder: (_) => PerfilAmistadPage(nombre: nombre)),
);

/// «Lo que hacen tus amigos»: el feed de actividad (empezó, relee o terminó un
/// libro, con su nota y un trozo de su reseña si la comparte). Se puede reaccionar
/// y comentar sin salir. Si no hay nada, no sale.
class FeedAmistades extends StatefulWidget {
  const FeedAmistades({super.key, this.cargar, this.maximo = 15});

  /// Para pruebas.
  final Future<List<FeedAmistad>> Function()? cargar;
  final int maximo;

  @override
  State<FeedAmistades> createState() => _FeedAmistadesState();
}

class _FeedAmistadesState extends State<FeedAmistades> {
  List<FeedAmistad> _items = const [];

  @override
  void initState() {
    super.initState();
    AmistadesCambios.cambios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    AmistadesCambios.cambios.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final todos = await (widget.cargar ?? ApiService().getFeedAmistades)();
      if (mounted) setState(() => _items = todos.take(widget.maximo).toList());
    } catch (_) {
      // Sin red o servidor antiguo: no sale.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: const Key('amigos-feed'),
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lo que hacen tus amigos', style: AppTextStyles.section),
          const SizedBox(height: AppSpacing.sm),
          for (final item in _items)
            _SucesoFeed(
              key: ValueKey('${item.libraryId}-${item.tipo}'),
              item: item,
            ),
        ],
      ),
    );
  }
}

class _SucesoFeed extends StatefulWidget {
  const _SucesoFeed({super.key, required this.item});

  final FeedAmistad item;

  @override
  State<_SucesoFeed> createState() => _SucesoFeedState();
}

class _SucesoFeedState extends State<_SucesoFeed> {
  late int _comentarios = widget.item.comentarios;

  Future<void> _comentar() async {
    await mostrarComentariosProgreso(
      context,
      libraryId: widget.item.libraryId,
      titulo: widget.item.titulo,
    );
    if (!mounted) return;
    AmistadesCambios.avisar();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.item;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _abrirPerfil(context, a.nombre),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClubBookCover(
                  title: a.titulo,
                  imageUrl: a.coverUrl,
                  width: 52,
                  height: 76,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClubAvatar(
                            nombre: a.nombre,
                            imageUrl: a.avatarUrl,
                            size: 24,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${a.nombre} ${a.verbo}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption,
                            ),
                          ),
                          Text(_hace(a.fecha), style: AppTextStyles.caption),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (a.termino && a.valoracion != null)
                        Row(
                          children: [
                            for (var i = 1; i <= 5; i++)
                              Icon(
                                a.valoracion! >= i
                                    ? Icons.star_rounded
                                    : a.valoracion! >= i - 0.5
                                    ? Icons.star_half_rounded
                                    : Icons.star_outline_rounded,
                                size: 16,
                                color: AppColors.gold,
                              ),
                          ],
                        ),
                      if (a.resena.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '«${a.resena}»',
                            style: AppTextStyles.bodySecondary.copyWith(
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                            ),
                          ),
                        )
                      else if (a.contieneSpoilers)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Su reseña tiene spoilers: ábrela desde el libro.',
                            style: AppTextStyles.caption,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(child: ReaccionesProgreso(lectura: a.lectura)),
              TextButton.icon(
                key: const Key('feed-comentarios'),
                onPressed: _comentar,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(_comentarios > 0 ? '$_comentarios' : 'Comentar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// «Ideas para regalar»: libros de las listas de deseos de tus amigos que aún
/// nadie ha reservado. Al tocar uno se abre el perfil, donde está «Lo regalo
/// yo». Mira como mucho a [maxPersonas] amigos para no cargar de más.
class IdeasParaRegalar extends StatefulWidget {
  const IdeasParaRegalar({super.key, this.cargar, this.maxPersonas = 4});

  /// Para pruebas: devuelve (nombre, deseos) por amigo.
  final Future<List<(String, List<LibroDeAmistad>)>> Function()? cargar;
  final int maxPersonas;

  @override
  State<IdeasParaRegalar> createState() => _IdeasParaRegalarState();
}

class _IdeasParaRegalarState extends State<IdeasParaRegalar> {
  List<(String, LibroDeAmistad)> _ideas = const [];

  @override
  void initState() {
    super.initState();
    AmistadesCambios.cambios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    AmistadesCambios.cambios.removeListener(_cargar);
    super.dispose();
  }

  Future<List<(String, List<LibroDeAmistad>)>> _cargaReal() async {
    final data = await ApiService().getAmistades();
    final amigos = data.amistades.take(widget.maxPersonas).toList();
    final perfiles = await Future.wait(
      amigos.map(
        (p) => ApiService()
            .getPerfilAmistad(p.nombre)
            .then<PerfilAmistad?>((x) => x)
            .catchError((_) => null),
      ),
    );
    return [
      for (var i = 0; i < amigos.length; i++)
        if (perfiles[i] != null) (amigos[i].nombre, perfiles[i]!.deseos),
    ];
  }

  Future<void> _cargar() async {
    try {
      final listas = await (widget.cargar ?? _cargaReal)();
      final ideas = <(String, LibroDeAmistad)>[
        for (final (nombre, deseos) in listas)
          for (final d in deseos.where((d) => !d.reservado).take(3))
            (nombre, d),
      ];
      if (mounted) setState(() => _ideas = ideas);
    } catch (_) {
      // No sale.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ideas.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: const Key('amigos-ideas-regalo'),
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ideas para regalar 🎁', style: AppTextStyles.section),
          Text(
            'Libros de las listas de deseos de tus amigos que nadie ha '
            'reservado. Entra en su perfil para «Lo regalo yo».',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _ideas.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) {
                final (nombre, libro) = _ideas[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _abrirPerfil(context, nombre),
                  child: SizedBox(
                    width: 96,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClubBookCover(
                          title: libro.titulo,
                          imageUrl: libro.coverUrl,
                          width: 96,
                          height: 140,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Para $nombre',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
