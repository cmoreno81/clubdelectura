import 'package:flutter/material.dart';

import '../models/libro.dart';
import '../models/upcoming_release.dart';
import '../models/wishlist.dart';
import '../services/api_service.dart';
import '../services/upcoming_releases_service.dart';
import '../services/wishlist_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/libros/botones_compra.dart';

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

class _ComprarLibrosPageState extends State<ComprarLibrosPage> {
  late Future<_ListasCompra> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
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

    final pendientes = <_LibroCompra>[
      for (final l in libros)
        if (l.estado.toUpperCase() == 'PENDIENTE' && l.bookId.isNotEmpty)
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
                  tabs: [
                    Tab(text: 'Deseados (${d.deseados.length})'),
                    Tab(text: 'Pendientes (${d.pendientes.length})'),
                    Tab(text: 'Próximos (${d.proximos.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _Lista(
                        libros: d.deseados,
                        enlaces: d.enlaces,
                        vacio:
                            'Ninguno de tus deseos está a la venta en Casa del Libro ahora mismo.',
                      ),
                      _Lista(
                        libros: d.pendientes,
                        enlaces: d.enlaces,
                        vacio:
                            'Ninguno de tus pendientes está a la venta en Casa del Libro.',
                      ),
                      _Lista(
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
          colors: [Color(0xFF4C9560), Color(0xFF2B5C3A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B5C3A).withValues(alpha: .28),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .22),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PUBLICIDAD',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
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
  });

  final List<_LibroCompra> libros;
  final Map<String, EnlaceCompra> enlaces;
  final String vacio;

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
        return _FilaCompra(libro: libro, enlace: enlaces[libro.bookId]);
      },
    );
  }
}

class _FilaCompra extends StatelessWidget {
  const _FilaCompra({required this.libro, required this.enlace});

  final _LibroCompra libro;
  final EnlaceCompra? enlace;

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
                if (e != null) BotonesCompra(enlace: e),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
