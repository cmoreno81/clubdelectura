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

/// «Lo último»: los libros que tus amigos han terminado hace poco, con su nota
/// (si la comparten) y cuándo. Si no hay nada, no sale.
class LoUltimoAmistades extends StatefulWidget {
  const LoUltimoAmistades({super.key, this.cargar, this.maximo = 5});

  /// Para pruebas.
  final Future<List<ActividadAmistad>> Function()? cargar;
  final int maximo;

  @override
  State<LoUltimoAmistades> createState() => _LoUltimoAmistadesState();
}

class _LoUltimoAmistadesState extends State<LoUltimoAmistades> {
  List<ActividadAmistad> _items = const [];

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
      final todos =
          await (widget.cargar ?? ApiService().getActividadAmistades)();
      final terminados = todos.where((a) => !a.esLectura).toList()
        ..sort(
          (a, b) =>
              (b.fecha ?? DateTime(1970)).compareTo(a.fecha ?? DateTime(1970)),
        );
      if (mounted) {
        setState(() => _items = terminados.take(widget.maximo).toList());
      }
    } catch (_) {
      // Sin red o servidor antiguo: no sale.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: const Key('amigos-lo-ultimo'),
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lo último', style: AppTextStyles.section),
          const SizedBox(height: AppSpacing.sm),
          for (final a in _items)
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _abrirPerfil(context, a.nombre),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    ClubBookCover(
                      title: a.titulo,
                      imageUrl: a.coverUrl,
                      width: 44,
                      height: 64,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${a.nombre} ha terminado',
                            style: AppTextStyles.caption,
                          ),
                          Text(
                            a.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              if (a.valoracion != null) ...[
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: AppColors.gold,
                                ),
                                Text(
                                  ' ${a.valoracion!.toStringAsFixed(a.valoracion! % 1 == 0 ? 0 : 1)}',
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                              ],
                              Text(
                                _hace(a.fecha),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ClubAvatar(
                      nombre: a.nombre,
                      imageUrl: a.avatarUrl,
                      size: 32,
                    ),
                  ],
                ),
              ),
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
