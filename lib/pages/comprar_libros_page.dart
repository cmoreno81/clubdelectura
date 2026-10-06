import 'package:club_lectura_app/theme/colores_compra.dart';
import 'package:club_lectura_app/widgets/ui/etiqueta_publicidad.dart';
import 'package:flutter/material.dart';

import '../models/libro.dart';
import '../models/upcoming_release.dart';
import '../models/wishlist.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../services/upcoming_releases_service.dart';
import '../services/wishlist_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/libros/botones_compra.dart';
import '../widgets/libros/pregunta_compra.dart';

/// Libro de una de las listas de compra, con lo mínimo para pintar la fila.
class _LibroCompra {
  const _LibroCompra({
    required this.bookId,
    required this.titulo,
    this.autora,
    this.portada,
    this.nota,
  });

  final String bookId;
  final String titulo;
  final String? autora;
  final String? portada;
  final String? nota;
}

class _ListasCompra {
  const _ListasCompra({
    required this.deseados,
    required this.pendientes,
    required this.proximos,
    required this.enlaces,
  });

  final List<_LibroCompra> deseados;
  final List<_LibroCompra> pendientes;
  final List<_LibroCompra> proximos;
  final Map<String, EnlaceCompra> enlaces;
}

/// "Tu próxima compra": los libros que quieres (deseados, pendientes y
/// próximos lanzamientos) con acceso directo a Casa del Libro. Enlaces de
/// afiliado (Awin): la página se identifica siempre como publicidad.
class ComprarLibrosPage extends StatefulWidget {
  const ComprarLibrosPage({super.key});

  @override
  State<ComprarLibrosPage> createState() => _ComprarLibrosPageState();
}

class _ComprarLibrosPageState extends State<ComprarLibrosPage>
    with WidgetsBindingObserver {
  late Future<_ListasCompra> _future;

  // Deseos sin comprar, por id de libro: la pregunta "¿Has comprado…?" solo
  // se hace si el libro está en la lista de deseos (ahí consta la compra).
  Map<String, WishlistItem> _deseosPorLibro = {};

  // Último botón de compra que abrió la tienda; al volver a la app se
  // pregunta si se compró. Todo local, no se envía nada a la tienda.
  ({WishlistItem item, EnlaceCompraFormato formato})? _compraPendiente;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _future = _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _alAbrirTienda(_LibroCompra libro, EnlaceCompraFormato formato) {
    final deseo = _deseosPorLibro[libro.bookId];
    _compraPendiente = deseo == null ? null : (item: deseo, formato: formato);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _preguntarCompra();
  }

  Future<void> _preguntarCompra() async {
    final pendiente = _compraPendiente;
    if (pendiente == null || !mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    _compraPendiente = null;
    final item = pendiente.item;

    final comprado = await preguntarSiLoHasComprado(
      context,
      titulo: item.title,
      formato: pendiente.formato.etiqueta,
    );
    if (!comprado || !mounted) return;

    final service = WishlistService();
    final formato = switch (pendiente.formato.formato) {
      'ebook' => WishlistFormat.digital,
      'audio' => WishlistFormat.audiobook,
      _ => WishlistFormat.physical,
    };
    try {
      // Se guarda el formato que se abrió, por si era distinto al del deseo.
      if (formato != item.format) {
        await service.updateItem(item.id, format: formato);
      }
      await service.markPurchased(item.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ "${item.title}" marcado como comprado'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () async {
            await service.unmarkPurchased(item.id);
            // Si al marcarlo se cambió el formato, también se devuelve.
            if (formato != item.format) {
              await service.updateItem(item.id, format: item.format);
            }
            _recargar();
          },
        ),
      ),
    );
    _recargar();
  }

  Future<_ListasCompra> _cargar() async {
    final resultados = await Future.wait<Object?>([
      WishlistService()
          .getWishlist()
          .then<Object?>((d) => d)
          .catchError((_) => WishlistData.empty),
      ApiService()
          .getLibros()
          .then<Object?>((d) => d)
          .catchError((_) => <Libro>[]),
      UpcomingReleasesService()
          .load(limit: 40)
          .then<Object?>((d) => d)
          .catchError((_) => <UpcomingRelease>[]),
    ]);
    final wishlist = resultados[0] as WishlistData;
    final libros = resultados[1] as List<Libro>;
    final lanzamientos = resultados[2] as List<UpcomingRelease>;

    final sinComprar = wishlist.items.where((i) => i.purchasedAt == null);
    _deseosPorLibro = {
      for (final i in sinComprar)
        if ((i.bookId ?? '').isNotEmpty) i.bookId!: i,
    };
    final deseados = <_LibroCompra>[
      for (final i in sinComprar)
        if ((i.bookId ?? '').isNotEmpty)
          _LibroCompra(
            bookId: i.bookId!,
            titulo: i.title,
            autora: i.author,
            portada: i.coverUrl,
          ),
    ];

    // getLibros() trae la biblioteca de todo el club (una fila por cada
    // usuaria+libro), así que hay que quedarse solo con las propias
    // (yaLoTengo) y, por si un mismo libro aparece más de una vez en la
    // respuesta, no repetirlo en la lista.
    final pendientesVistos = <String>{};
    final pendientes = <_LibroCompra>[
      for (final l in libros)
        if (l.yaLoTengo &&
            l.estado.toUpperCase() == 'PENDIENTE' &&
            l.bookId.isNotEmpty &&
            pendientesVistos.add(l.bookId))
          _LibroCompra(
            bookId: l.bookId,
            titulo: l.libro,
            autora: l.autor,
            portada: l.coverUrl,
          ),
    ];

    final ahora = DateTime.now();
    final proximos = <_LibroCompra>[
      for (final r in lanzamientos)
        if (r.id.isNotEmpty)
          _LibroCompra(
            bookId: r.id,
            titulo: r.title,
            autora: r.author,
            portada: r.coverUrl,
            nota: _notaLanzamiento(r.publicationDate, ahora),
          ),
    ];

    final enlaces = await ApiService().getEnlacesCompraLote([
      ...deseados.map((l) => l.bookId),
      ...pendientes.map((l) => l.bookId),
      ...proximos.map((l) => l.bookId),
    ]);
    // Solo se muestran los libros que se pueden comprar de verdad: los que la
    // tienda no tiene localizados no llevan a ninguna ficha.
    List<_LibroCompra> comprables(List<_LibroCompra> l) =>
        l.where((x) => enlaces[x.bookId]?.exacto == true).toList();
    return _ListasCompra(
      deseados: comprables(deseados),
      pendientes: comprables(pendientes),
      proximos: comprables(proximos),
      enlaces: enlaces,
    );
  }

  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic', //
  ];

  String _notaLanzamiento(DateTime fecha, DateTime ahora) {
    final texto = '${fecha.day} ${_meses[fecha.month - 1]} ${fecha.year}';
    return fecha.isAfter(ahora)
        ? 'Sale el $texto · preventa'
        : 'Salió el $texto';
  }

  void _recargar() => setState(() => _future = _cargar());

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(title: const Text('Tu próxima compra')),
        body: FutureBuilder<_ListasCompra>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || snap.data == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 40),
                    const SizedBox(height: AppSpacing.sm),
                    const Text('No hemos podido cargar tus listas'),
                    TextButton(
                      onPressed: _recargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }
            final d = snap.data!;
            return Column(
              children: [
                const _AvisoPublicidad(),
                TabBar(
                  labelColor: AppColors.primary,
                  indicatorColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  // En móviles estrechos (iPhone de 6,1") el texto con el
                  // contador no cabía y se cortaba: se reduce para que quepa.
                  tabs: [
                    for (final etiqueta in [
                      'Deseados (${d.deseados.length})',
                      'Pendientes (${d.pendientes.length})',
                      'Próximos (${d.proximos.length})',
                    ])
                      Tab(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(etiqueta, maxLines: 1),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _Lista(
                        onAbierto: _alAbrirTienda,
                        libros: d.deseados,
                        enlaces: d.enlaces,
                        vacio:
                            'Ninguno de tus deseos está a la venta en Casa del Libro ahora mismo.',
                      ),
                      _Lista(
                        onAbierto: _alAbrirTienda,
                        libros: d.pendientes,
                        enlaces: d.enlaces,
                        vacio:
                            'Ninguno de tus pendientes está a la venta en Casa del Libro.',
                      ),
                      _Lista(
                        onAbierto: _alAbrirTienda,
                        libros: d.proximos,
                        enlaces: d.enlaces,
                        vacio:
                            'No hay próximos lanzamientos a la venta ahora mismo.',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AvisoPublicidad extends StatelessWidget {
  const _AvisoPublicidad();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ColoresCompra.degradadoClaro, ColoresCompra.degradadoOscuro],
        ),
        boxShadow: [
          BoxShadow(
            color: ColoresCompra.degradadoOscuro.withValues(alpha: .28),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EtiquetaPublicidad(sobreFondoOscuro: true),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enlaces de afiliado a Casa del Libro: ClubReads puede '
                  'recibir una comisión si compras, sin coste extra para ti.',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withValues(alpha: .92),
                    height: 1.3,
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

class _Lista extends StatelessWidget {
  const _Lista({
    required this.libros,
    required this.enlaces,
    required this.vacio,
    this.onAbierto,
  });

  final List<_LibroCompra> libros;
  final Map<String, EnlaceCompra> enlaces;
  final String vacio;
  final void Function(_LibroCompra, EnlaceCompraFormato)? onAbierto;

  @override
  Widget build(BuildContext context) {
    if (libros.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            vacio,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: libros.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final libro = libros[i];
        return _FilaCompra(
          libro: libro,
          enlace: enlaces[libro.bookId],
          onAbierto: onAbierto == null ? null : (f) => onAbierto!(libro, f),
        );
      },
    );
  }
}

class _FilaCompra extends StatelessWidget {
  const _FilaCompra({
    required this.libro,
    required this.enlace,
    this.onAbierto,
  });

  final _LibroCompra libro;
  final EnlaceCompra? enlace;
  final ValueChanged<EnlaceCompraFormato>? onAbierto;

  @override
  Widget build(BuildContext context) {
    final e = enlace;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClubBookCover(
            title: libro.titulo,
            imageUrl: libro.portada,
            width: 56,
            height: 84,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  libro.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if ((libro.autora ?? '').isNotEmpty)
                  Text(libro.autora!, style: AppTextStyles.caption),
                if (libro.nota != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      libro.nota!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.inkCoral,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                if (e != null) BotonesCompra(enlace: e, onAbierto: onAbierto),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
