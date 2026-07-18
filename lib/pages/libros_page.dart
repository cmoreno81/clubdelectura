import 'package:club_lectura_app/services/usuario_service.dart';
import 'package:club_lectura_app/theme/app_colors.dart';
import 'package:club_lectura_app/theme/app_spacing.dart';
import 'package:club_lectura_app/theme/app_text_styles.dart';
import 'package:club_lectura_app/widgets/common/club_book_cover.dart';
import 'package:club_lectura_app/widgets/common/club_card.dart';
import 'package:club_lectura_app/widgets/common/club_chip.dart';
import 'package:club_lectura_app/widgets/common/club_empty_state.dart';
import 'package:club_lectura_app/widgets/error_view.dart';
import 'package:flutter/material.dart';

import '../models/libro_agrupado.dart';
import '../models/libro.dart';
import '../models/libro_finalizado.dart';
import '../models/libros_data.dart';
import '../services/api_service.dart';
import '../utils/genero_utils.dart';
import 'detalle_libro_page.dart';
import 'nuevo_libro_page.dart';
import '../services/atmosfera_scope.dart';

enum OrdenLibros { populares, recientes, tituloAsc, tituloDesc, mejorValorados }

class LibrosPage extends StatefulWidget {
  const LibrosPage({super.key});

  @override
  State<LibrosPage> createState() => _LibrosPageState();
}

class _LibrosPageState extends State<LibrosPage> {
  late Future<LibrosData> librosFuture;

  final TextEditingController buscadorController = TextEditingController();

  String filtroBusqueda = '';
  String filtroEstado = 'TODOS';
  String filtroUsuario = 'TODAS';
  OrdenLibros ordenSeleccionado = OrdenLibros.populares;

  bool _atmosferaRestaurada = false;

  @override
  void initState() {
    super.initState();
    librosFuture = ApiService().getLibrosData();
  }

  Future<void> _abrirNuevoLibro() async {
    final creado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NuevoLibroPage()),
    );

    if (!mounted) return;

    if (creado == true) {
      setState(() {
        _recargar();
      });
    }
  }

  @override
  void dispose() {
    buscadorController.dispose();
    super.dispose();
  }

  void _recargar() {
    setState(() {
      librosFuture = ApiService().getLibrosData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_atmosferaRestaurada) return;

      _atmosferaRestaurada = true;

      AtmosferaScope.of(context).usarAtmosferaNeutra();
    });

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_library_rounded,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Biblioteca',
              style: AppTextStyles.title.copyWith(
                color: colorScheme.onSurface,
                fontSize: 23,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: colorScheme.primary,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Añadir libro',
                onPressed: _abrirNuevoLibro,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                iconSize: 24,
                splashRadius: 22,
              ),
            ),
          ),
        ],
      ),

      body: FutureBuilder<LibrosData>(
        future: librosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(onRetry: _recargar);
          }

          final data = snapshot.data!;
          final libros = data.libros;
          final finalizados = data.finalizados;

          final usuarios = {
            ...libros.map((e) => e.usuario.trim()).where((u) => u.isNotEmpty),
            ...finalizados
                .map((e) => e.usuario.trim())
                .where((u) => u.isNotEmpty),
          }.toList()..sort();

          final usuariosFiltro = ['TODAS', ...usuarios];

          if (!usuariosFiltro.contains(filtroUsuario)) {
            filtroUsuario = 'TODAS';
          }

          final resultado = _crearResultado(
            libros: libros,
            finalizados: finalizados,
          );

          return Column(
            children: [
              _cabeceraFiltros(
                usuariosFiltro: usuariosFiltro,
                totalResultados: resultado.length,
              ),
              Expanded(
                child: resultado.isEmpty
                    ? ClubEmptyState(
                        icon: Icons.auto_stories_outlined,
                        title: 'No hay libros',
                        message:
                            'No hemos encontrado libros con los filtros seleccionados.',
                        actionLabel:
                            filtroBusqueda.isNotEmpty ||
                                filtroEstado != 'TODOS' ||
                                filtroUsuario != 'TODAS'
                            ? 'Limpiar filtros'
                            : null,
                        onAction:
                            filtroBusqueda.isNotEmpty ||
                                filtroEstado != 'TODOS' ||
                                filtroUsuario != 'TODAS'
                            ? _limpiarFiltros
                            : null,
                      )
                    : ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.xs,
                          AppSpacing.md,
                          110,
                        ),
                        itemCount: resultado.length,
                        itemBuilder: (context, index) {
                          return _libroCard(resultado[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cabeceraFiltros({
    required List<String> usuariosFiltro,
    required int totalResultados,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(color: AppColors.background),
      child: Column(
        children: [
          TextField(
            controller: buscadorController,
            onChanged: (value) {
              setState(() {
                filtroBusqueda = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Buscar en la biblioteca...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: filtroBusqueda.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar búsqueda',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        buscadorController.clear();

                        setState(() {
                          filtroBusqueda = '';
                        });
                      },
                    ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          DropdownButtonFormField<String>(
            initialValue: filtroUsuario,
            decoration: const InputDecoration(
              labelText: 'Lectora',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            items: usuariosFiltro.map((usuario) {
              return DropdownMenuItem(
                value: usuario,
                child: Text(
                  usuario == 'TODAS' ? 'Todas las lectoras' : usuario,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                filtroUsuario = value;
              });
            },
          ),

          const SizedBox(height: AppSpacing.md),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip(
                  estado: 'TODOS',
                  label: 'Todos',
                  icon: Icons.grid_view_rounded,
                ),
                const SizedBox(width: AppSpacing.xs),
                _chip(
                  estado: 'PENDIENTE',
                  label: 'Pendientes',
                  icon: Icons.schedule_rounded,
                ),
                const SizedBox(width: AppSpacing.xs),
                _chip(
                  estado: 'LEYENDO',
                  label: 'Leyendo',
                  icon: Icons.menu_book_rounded,
                ),
                const SizedBox(width: AppSpacing.xs),

                _chip(
                  estado: 'PAUSADO',
                  label: 'En pausa',
                  icon: Icons.pause_circle_outline_rounded,
                ),
                const SizedBox(width: AppSpacing.xs),
                _chip(
                  estado: 'RELECTURA',
                  label: 'Relecturas',
                  icon: Icons.refresh_rounded,
                ),
                const SizedBox(width: AppSpacing.xs),
                _chip(
                  estado: 'TERMINADOS',
                  label: 'Terminados',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: Text(
                  totalResultados == 1 ? '1 libro' : '$totalResultados libros',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              OutlinedButton.icon(
                onPressed: _mostrarOpcionesOrden,
                icon: const Icon(Icons.swap_vert_rounded, size: 19),
                label: Text('Ordenar · $_labelOrden'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String estado,
    required String label,
    required IconData icon,
  }) {
    return ClubChip(
      label: label,
      icon: icon,
      selected: filtroEstado == estado,
      variant: _chipVariant(estado),
      onTap: () {
        setState(() {
          filtroEstado = estado;
        });
      },
    );
  }

  ClubChipVariant _chipVariant(String estado) {
    switch (estado) {
      case 'PENDIENTE':
        return ClubChipVariant.warning;

      case 'LEYENDO':
        return ClubChipVariant.info;

      case 'RELECTURA':
        return ClubChipVariant.primary;

      case 'FINALIZADO':
        return ClubChipVariant.success;

      case 'ABANDONADO':
        return ClubChipVariant.danger;

      case 'PAUSADO':
        return ClubChipVariant.warning;

      default:
        return ClubChipVariant.neutral;
    }
  }

  Widget _libroCard(LibroAgrupado libro) {
    return ClubCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () async {
        await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => DetalleLibroPage(libro: libro)),
        );

        _atmosferaRestaurada = false;

        if (!mounted) return;

        // El estado, la valoración, las fechas o los datos del libro
        // pueden haber cambiado dentro del detalle.
        _recargar();
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClubBookCover(
            title: libro.libro,
            imageUrl: libro.coverUrl,
            width: 92,
            showShadow: false,
            heroTag: 'book-${libro.libro}',
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        libro.libro,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.section.copyWith(fontSize: 19),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.xs),

                    if (libro.yaLoTengo)
                      const Tooltip(
                        message: 'Ya está en tu lista',
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 27,
                        ),
                      )
                    else
                      IconButton(
                        tooltip: 'Añadir a mi lista',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          _confirmarAgregarLibro(libro);
                        },
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xs),

                Row(
                  children: [
                    Text(
                      iconoGenero(libro.genero),
                      style: const TextStyle(fontSize: 17),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        libro.genero,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (libro.esReciente)
                      const ClubChip(
                        label: 'Nuevo',
                        icon: Icons.auto_awesome_rounded,
                        variant: ClubChipVariant.primary,
                      ),
                    ClubChip(
                      label: '${libro.total} interesadas',
                      icon: Icons.people_outline_rounded,
                      variant: ClubChipVariant.info,
                    ),

                    if (libro.totalFinalizados > 0)
                      ClubChip(
                        label: '${libro.totalFinalizados} leídos',
                        icon: Icons.check_circle_outline_rounded,
                        variant: ClubChipVariant.success,
                      ),

                    if (libro.mediaValoracion > 0)
                      ClubChip(
                        label: libro.mediaValoracion.toStringAsFixed(1),
                        icon: Icons.star_rounded,
                        variant: ClubChipVariant.warning,
                      ),
                  ],
                ),

                if (libro.registros.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    libro.registros.map((e) => e.usuario).join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],

                if (libro.total >= 3) ...[
                  const SizedBox(height: AppSpacing.sm),

                  const ClubChip(
                    label: 'Coincidencia del club',
                    icon: Icons.local_fire_department_rounded,
                    variant: ClubChipVariant.danger,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _labelOrden {
    switch (ordenSeleccionado) {
      case OrdenLibros.populares:
        return 'Más populares';

      case OrdenLibros.recientes:
        return 'Más recientes';

      case OrdenLibros.tituloAsc:
        return 'Título A–Z';

      case OrdenLibros.tituloDesc:
        return 'Título Z–A';

      case OrdenLibros.mejorValorados:
        return 'Mejor valorados';
    }
  }

  Future<void> _mostrarOpcionesOrden() async {
    final seleccionado = await showModalBottomSheet<OrdenLibros>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ordenar biblioteca', style: AppTextStyles.section),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  'Elige cómo quieres ver los libros.',
                  style: AppTextStyles.bodySecondary,
                ),

                const SizedBox(height: AppSpacing.md),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _opcionOrden(
                        context: sheetContext,
                        orden: OrdenLibros.populares,
                        titulo: 'Más populares',
                        subtitulo: 'Los que interesan a más lectoras',
                        icono: Icons.local_fire_department_outlined,
                      ),

                      _opcionOrden(
                        context: sheetContext,
                        orden: OrdenLibros.recientes,
                        titulo: 'Añadidos recientemente',
                        subtitulo: 'Las últimas incorporaciones al catálogo',
                        icono: Icons.schedule_rounded,
                      ),

                      _opcionOrden(
                        context: sheetContext,
                        orden: OrdenLibros.tituloAsc,
                        titulo: 'Título: A–Z',
                        subtitulo: 'Orden alfabético ascendente',
                        icono: Icons.sort_by_alpha_rounded,
                      ),

                      _opcionOrden(
                        context: sheetContext,
                        orden: OrdenLibros.tituloDesc,
                        titulo: 'Título: Z–A',
                        subtitulo: 'Orden alfabético descendente',
                        icono: Icons.sort_by_alpha_rounded,
                      ),

                      _opcionOrden(
                        context: sheetContext,
                        orden: OrdenLibros.mejorValorados,
                        titulo: 'Mejor valorados',
                        subtitulo: 'Los favoritos del club primero',
                        icono: Icons.star_outline_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (seleccionado == null || !mounted) {
      return;
    }

    setState(() {
      ordenSeleccionado = seleccionado;
    });
  }

  Widget _opcionOrden({
    required BuildContext context,
    required OrdenLibros orden,
    required String titulo,
    required String subtitulo,
    required IconData icono,
  }) {
    final seleccionada = ordenSeleccionado == orden;
    final color = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        selected: seleccionada,
        selectedTileColor: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: seleccionada
                ? color.withValues(alpha: 0.12)
                : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icono,
            color: seleccionada ? color : AppColors.textSecondary,
          ),
        ),
        title: Text(
          titulo,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitulo, style: AppTextStyles.caption),
        trailing: seleccionada
            ? Icon(Icons.check_circle_rounded, color: color)
            : const Icon(Icons.circle_outlined, color: AppColors.textMuted),
        onTap: () {
          Navigator.pop(context, orden);
        },
      ),
    );
  }

  void _aplicarOrden(List<LibroAgrupado> resultado) {
    resultado.sort((a, b) {
      switch (ordenSeleccionado) {
        case OrdenLibros.populares:
          final popularidadA = a.total + a.totalFinalizados;
          final popularidadB = b.total + b.totalFinalizados;

          final comparacion = popularidadB.compareTo(popularidadA);

          if (comparacion != 0) {
            return comparacion;
          }

          return normalizar(a.libro).compareTo(normalizar(b.libro));

        case OrdenLibros.recientes:
          final fechaA = a.fechaAlta;
          final fechaB = b.fechaAlta;

          if (fechaA == null && fechaB == null) {
            return normalizar(a.libro).compareTo(normalizar(b.libro));
          }

          if (fechaA == null) return 1;
          if (fechaB == null) return -1;

          final comparacion = fechaB.compareTo(fechaA);

          if (comparacion != 0) {
            return comparacion;
          }

          return normalizar(a.libro).compareTo(normalizar(b.libro));

        case OrdenLibros.tituloAsc:
          return normalizar(a.libro).compareTo(normalizar(b.libro));

        case OrdenLibros.tituloDesc:
          return normalizar(b.libro).compareTo(normalizar(a.libro));

        case OrdenLibros.mejorValorados:
          final comparacion = b.mediaValoracion.compareTo(a.mediaValoracion);

          if (comparacion != 0) {
            return comparacion;
          }

          return normalizar(a.libro).compareTo(normalizar(b.libro));
      }
    });
  }

  Libro _registroDesdeFinalizado(LibroFinalizado finalizado) {
    return Libro(
      bookId: finalizado.bookId,
      usuario: finalizado.usuario,
      libro: finalizado.libro,
      genero: finalizado.genero,
      saga: finalizado.saga,
      numSaga: finalizado.numSaga,
      autoconclusivo: finalizado.autoconclusivo,
      prioridad: 'MEDIA',
      estado: 'FINALIZADO',
      valoracion: finalizado.valoracion,
      yaLoTengo: false,
      goodreads: '',
      coverUrl: finalizado.coverUrl,
      fechaAlta: finalizado.fechaAlta,
      startedAt: null,
      pausedAt: null,
      pauseReason: '',
      avatarUrl: finalizado.avatarUrl,
    );
  }

  List<LibroAgrupado> _crearResultado({
    required List<Libro> libros,
    required List<LibroFinalizado> finalizados,
  }) {
    List<LibroAgrupado> resultado = [];

    if (filtroEstado != 'TERMINADOS') {
      final librosFiltrados = libros.where((libro) {
        final coincideBusqueda = normalizar(
          libro.libro,
        ).contains(normalizar(filtroBusqueda));

        final coincideUsuario =
            filtroUsuario == 'TODAS' || libro.usuario.trim() == filtroUsuario;

        final coincideEstado =
            filtroEstado == 'TODOS' || libro.estado == filtroEstado;

        return coincideBusqueda && coincideUsuario && coincideEstado;
      }).toList();

      final agrupados = <String, LibroAgrupado>{};

      for (final libro in librosFiltrados) {
        agrupados.putIfAbsent(
          libro.libro,
          () => LibroAgrupado(
            libro: libro.libro,
            genero: libro.genero,
            registros: [],
            finalizados: [],
            yaLoTengo: libro.yaLoTengo,
            coverUrl: libro.coverUrl,
          ),
        );

        agrupados[libro.libro]!.registros.add(libro);

        if (libro.yaLoTengo) {
          agrupados[libro.libro]!.yaLoTengo = true;
        }
      }

      resultado = agrupados.values.toList();

      for (final agrupado in resultado) {
        agrupado.finalizados.addAll(
          finalizados.where((f) => f.libro.trim() == agrupado.libro.trim()),
        );
      }

      _aplicarOrden(resultado);

      return resultado;
    }

    final finalizadosFiltrados = finalizados.where((f) {
      final coincideUsuario =
          filtroUsuario == 'TODAS' || f.usuario.trim() == filtroUsuario;

      final coincideBusqueda =
          filtroBusqueda.isEmpty ||
          normalizar(f.libro).contains(normalizar(filtroBusqueda));

      return coincideUsuario && coincideBusqueda;
    }).toList();

    final titulosFinalizados = finalizadosFiltrados
        .map((finalizado) => normalizar(finalizado.libro))
        .toSet();

    final registrosRelacionados = libros.where((libro) {
      return titulosFinalizados.contains(normalizar(libro.libro));
    }).toList();

    final agrupados = <String, LibroAgrupado>{};

    for (final finalizado in finalizadosFiltrados) {
      final clave = normalizar(finalizado.libro);

      agrupados.putIfAbsent(
        clave,
        () => LibroAgrupado(
          libro: finalizado.libro,
          genero: finalizado.genero,
          registros: [],
          finalizados: [],
          yaLoTengo: false,
          coverUrl: finalizado.coverUrl,
        ),
      );

      agrupados[clave]!.finalizados.add(finalizado);
      agrupados[clave]!.registros.add(_registroDesdeFinalizado(finalizado));
    }

    for (final registro in registrosRelacionados) {
      final clave = normalizar(registro.libro);
      final agrupado = agrupados[clave];

      if (agrupado == null) continue;

      final yaExiste = agrupado.registros.any(
        (existente) =>
            existente.usuario.trim().toLowerCase() ==
            registro.usuario.trim().toLowerCase(),
      );

      if (!yaExiste) {
        agrupado.registros.add(registro);
      }

      if (registro.yaLoTengo) {
        agrupado.yaLoTengo = true;
      }
    }
    resultado = agrupados.values.toList();
    _aplicarOrden(resultado);

    return resultado;
  }

  void _limpiarFiltros() {
    buscadorController.clear();

    setState(() {
      filtroBusqueda = '';
      filtroEstado = 'TODOS';
      filtroUsuario = 'TODAS';
    });
  }

  Future<void> _confirmarAgregarLibro(LibroAgrupado libro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Añadir libro'),
          content: Text(
            '¿Quieres añadir "${libro.libro}" '
            'a tu lista de pendientes?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Añadir'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final usuario = await UsuarioService().obtenerUsuario();

    if (usuario == null || usuario.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido identificar a la usuaria.'),
        ),
      );
      return;
    }

    final respuesta = await ApiService().anadirLibroExistente(
      usuario: usuario,
      libro: libro.libro,
    );

    if (!mounted) return;

    final ok = respuesta['ok'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Añadido a tu lista'
              : respuesta['mensaje'] ?? 'No se ha podido añadir',
        ),
      ),
    );

    if (ok) {
      _recargar();
    }
  }

  String normalizar(String texto) {
    return texto
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }
}
