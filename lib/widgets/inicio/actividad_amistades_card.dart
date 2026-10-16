import 'package:flutter/material.dart';
import '../../navigation/app_page_route.dart';
import '../tablet/detalle_lateral.dart';

import '../../models/amistad.dart';
import '../../pages/amistades_page.dart';
import '../../pages/perfil_amistad_page.dart';
import '../../services/amistades_cambios.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../amistades/reacciones_progreso.dart';
import '../common/club_avatar.dart';
import '../common/club_book_cover.dart';

/// «Qué leen tus amigos» (dentro de la pantalla Amigos): un carrusel con una tarjeta por
/// persona (portada grande, su avatar y lo último que hace). Como mucho
/// [maxPersonas] tarjetas, así que ocupa lo mismo con 3 amistades que con 100;
/// «Ver todas» lleva a la pantalla de Amistades. Si no hay nada, no sale.
class ActividadAmistadesCard extends StatefulWidget {
  const ActividadAmistadesCard({
    super.key,
    this.cargar,
    this.abrirPerfil,
    this.maxPersonas = 12,
    this.mostrarVerTodas = true,
  });

  /// En la pestaña Amigos ya estás en «todas»: se oculta el enlace.
  final bool mostrarVerTodas;

  /// Para pruebas.
  final Future<List<ActividadAmistad>> Function()? cargar;
  final void Function(BuildContext context, String nombre)? abrirPerfil;
  final int maxPersonas;

  @override
  State<ActividadAmistadesCard> createState() => _ActividadAmistadesCardState();
}

class _ActividadAmistadesCardState extends State<ActividadAmistadesCard>
    with AutomaticKeepAliveClientMixin {
  List<ActividadAmistad> _items = const [];

  @override
  bool get wantKeepAlive => true;

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

  /// Lo más reciente de cada persona (el servidor ya lo manda por fecha).
  List<ActividadAmistad> _unaPorPersona(List<ActividadAmistad> items) {
    final vistas = <String>{};
    return [
      for (final item in items)
        if (vistas.add(item.nombre.toLowerCase())) item,
    ].take(widget.maxPersonas).toList();
  }

  Future<void> _cargar() async {
    try {
      final items =
          await (widget.cargar ?? ApiService().getActividadAmistades)();
      if (mounted) setState(() => _items = _unaPorPersona(items));
    } catch (_) {
      // Sin red o servidor antiguo: simplemente no sale.
    }
  }

  void _abrirPerfil(BuildContext context, String nombre) {
    if (widget.abrirPerfil != null) {
      widget.abrirPerfil!(context, nombre);
      return;
    }
    empujarDetalle<void>(
      context,
      AppPageRoute(builder: (_) => PerfilAmistadPage(nombre: nombre)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Qué leen tus amigos',
                  style: AppTextStyles.section,
                ),
              ),
              if (widget.mostrarVerTodas)
                TextButton(
                  onPressed: () => Navigator.push<void>(
                    context,
                    AppPageRoute(builder: (_) => const AmistadesPage()),
                  ),
                  child: const Text('Ver todas'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, i) => _Tarjeta(
                item: _items[i],
                alAbrir: () => _abrirPerfil(context, _items[i].nombre),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.item, required this.alAbrir});

  final ActividadAmistad item;
  final VoidCallback alAbrir;

  static const double ancho = 138;
  static const double altoPortada = 196;

  @override
  Widget build(BuildContext context) {
    final lectura = item.lectura;
    return SizedBox(
      width: ancho,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: altoPortada,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: alAbrir,
                  child: ClubBookCover(
                    title: item.titulo,
                    imageUrl: item.coverUrl,
                    width: ancho,
                    height: altoPortada,
                  ),
                ),
                // Degradado para que se lea lo que va encima.
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, 0.25, 0.7, 1],
                          colors: [
                            Colors.black.withValues(alpha: 0.35),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.45),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: alAbrir,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClubAvatar(
                        nombre: item.nombre,
                        imageUrl: item.avatarUrl,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                if (lectura != null) ...[
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: lectura.progreso / 100,
                        minHeight: 6,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 24,
                    child: ReaccionesProgreso(lectura: lectura, compacto: true),
                  ),
                ] else if (item.valoracion != null)
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '⭐ ${item.valoracion!.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            onTap: alAbrir,
            behavior: HitTestBehavior.opaque,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  lectura != null
                      ? 'Leyendo · ${lectura.progreso}%'
                      : 'Ha terminado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: lectura != null ? AppColors.primary : null,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
