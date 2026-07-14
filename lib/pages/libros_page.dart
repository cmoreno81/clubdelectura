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
              size: 27,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Biblioteca',
              style: AppTextStyles.title.copyWith(
                color: colorScheme.onSurface,
                fontSize: 25,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _abrirNuevoLibro,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Añadir'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
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
              _cabeceraFiltros(usuariosFiltro: usuariosFiltro),

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

  Widget _cabeceraFiltros({required List<String> usuariosFiltro}) {
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

      case 'TERMINADOS':
        return ClubChipVariant.success;

      default:
        return ClubChipVariant.neutral;
    }
  }

  Widget _libroCard(LibroAgrupado libro) {
    return ClubCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () async {
        final refrescar = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => DetalleLibroPage(libro: libro)),
        );
        _atmosferaRestaurada = false;

        if (!mounted) return;

        if (refrescar == true) {
          _recargar();
        }
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

      resultado.sort((a, b) => b.total.compareTo(a.total));

      return resultado;
    }

    final finalizadosFiltrados = finalizados.where((f) {
      final coincideUsuario =
          filtroUsuario == 'TODAS' || f.usuario.trim() == filtroUsuario;

      final coincideBusqueda =
          filtroBusqueda.isEmpty ||
          normalizar(f.libro).contains(normalizar(filtroBusqueda));

      return coincideUsuario && coincideBusqueda;
    });

    final agrupados = <String, LibroAgrupado>{};

    for (final finalizado in finalizadosFiltrados) {
      agrupados.putIfAbsent(
        finalizado.libro,
        () => LibroAgrupado(
          libro: finalizado.libro,
          genero: finalizado.genero,
          registros: [],
          finalizados: [],
          yaLoTengo: false,
          coverUrl: finalizado.coverUrl,
        ),
      );

      agrupados[finalizado.libro]!.finalizados.add(finalizado);
    }

    resultado = agrupados.values.toList();

    resultado.sort((a, b) => b.totalFinalizados.compareTo(a.totalFinalizados));

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
