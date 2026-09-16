import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/catalog_book.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_button.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';

class ConfigurarLecturaPage extends StatefulWidget {
  final String libro;
  final String tipo;

  /// Modo edición: la lectura ya existe (alguien se equivocó al
  /// configurarla, o quiere ajustarla más adelante). Cualquier persona del
  /// club puede editarla, igual que puede crearla.
  final bool editando;
  final int capitulosIniciales;
  final bool prologoInicial;
  final bool epilogoInicial;

  const ConfigurarLecturaPage({
    super.key,
    required this.libro,
    this.tipo = 'LIBRE',
    this.editando = false,
    this.capitulosIniciales = 0,
    this.prologoInicial = false,
    this.epilogoInicial = false,
  });

  @override
  State<ConfigurarLecturaPage> createState() => _ConfigurarLecturaPageState();
}

class _ConfigurarLecturaPageState extends State<ConfigurarLecturaPage> {
  final controllerCapitulos = TextEditingController();
  final controllerPaginas = TextEditingController();
  final controllerEdicion = TextEditingController();

  bool prologo = false;
  bool epilogo = false;
  bool creando = false;

  CatalogBook? edicionVinculada;
  List<CatalogBook> resultadosEdicion = [];
  bool buscandoEdicion = false;
  Timer? _debounceEdicion;

  bool get esOficial => widget.tipo.trim().toUpperCase() == 'OFICIAL';
  @override
  void initState() {
    super.initState();

    if (widget.editando) {
      if (widget.capitulosIniciales > 0) {
        controllerCapitulos.text = '${widget.capitulosIniciales}';
      }
      prologo = widget.prologoInicial;
      epilogo = widget.epilogoInicial;
    }

    controllerCapitulos.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _buscarEdicion(String query) {
    _debounceEdicion?.cancel();
    if (query.trim().length < 3) {
      setState(() => resultadosEdicion = []);
      return;
    }
    _debounceEdicion = Timer(const Duration(milliseconds: 400), () async {
      setState(() => buscandoEdicion = true);
      try {
        final resultados = await ApiService().getCatalogoGeneral(
          query: query.trim(),
        );
        if (!mounted) return;
        setState(() {
          resultadosEdicion = resultados
              .where(
                (libro) =>
                    libro.source == 'CLUBREADS' &&
                    normalizarTitulo(libro.title) !=
                        normalizarTitulo(widget.libro),
              )
              .toList();
        });
      } catch (_) {
        if (mounted) setState(() => resultadosEdicion = []);
      } finally {
        if (mounted) setState(() => buscandoEdicion = false);
      }
    });
  }

  String normalizarTitulo(String value) => value.trim().toLowerCase();

  void _seleccionarEdicion(CatalogBook libro) {
    setState(() {
      edicionVinculada = libro;
      resultadosEdicion = [];
      controllerEdicion.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editando
              ? 'Editar lectura'
              : esOficial
              ? 'Configurar lectura oficial'
              : 'Nueva lectura compartida',
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            110,
          ),
          children: [
            _CabeceraConfiguracion(libro: widget.libro, esOficial: esOficial),

            const SizedBox(height: AppSpacing.xl),

            const _SectionHeader(
              icon: Icons.tune_rounded,
              color: AppColors.primary,
              title: 'Estructura de la lectura',
              subtitle: 'Indica cómo está organizado el libro',
            ),

            const SizedBox(height: AppSpacing.md),

            ClubCard(
              elevated: false,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Número de capítulos',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    'Usaremos este número para crear los espacios de conversación.',
                    style: AppTextStyles.bodySecondary.copyWith(height: 1.4),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  TextField(
                    controller: controllerCapitulos,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Número de capítulos',
                      hintText: 'Ej. 24',
                      prefixIcon: const Icon(
                        Icons.format_list_numbered_rounded,
                      ),
                      suffixText: 'capítulos',
                      filled: true,
                      fillColor: AppColors.surfaceSoft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                  if (!widget.editando) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Número de páginas',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Es opcional y permitirá registrar el progreso por página.',
                    style: AppTextStyles.bodySecondary.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: controllerPaginas,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Número de páginas',
                      hintText: 'Ej. 420',
                      prefixIcon: const Icon(Icons.menu_book_outlined),
                      suffixText: 'páginas',
                      filled: true,
                      fillColor: AppColors.surfaceSoft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            ClubCard(
              elevated: false,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _OpcionLectura(
                    icon: Icons.first_page_rounded,
                    title: 'Tiene prólogo',
                    subtitle: 'Añade un espacio antes del capítulo 1',
                    value: prologo,
                    onChanged: creando
                        ? null
                        : (value) {
                            setState(() {
                              prologo = value;
                            });
                          },
                  ),

                  const Divider(
                    height: 1,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                  ),

                  _OpcionLectura(
                    icon: Icons.last_page_rounded,
                    title: 'Tiene epílogo',
                    subtitle: 'Añade un espacio al final de la lectura',
                    value: epilogo,
                    onChanged: creando
                        ? null
                        : (value) {
                            setState(() {
                              epilogo = value;
                            });
                          },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            const _SectionHeader(
              icon: Icons.link_rounded,
              color: AppColors.primary,
              title: 'Otra edición de este libro',
              subtitle:
                  '¿Alguien lo lee en otro idioma con ficha distinta? '
                  'Vincúlala para compartir la misma conversación.',
            ),

            const SizedBox(height: AppSpacing.md),

            _VincularEdicion(
              controller: controllerEdicion,
              onChanged: creando ? null : _buscarEdicion,
              buscando: buscandoEdicion,
              resultados: resultadosEdicion,
              seleccionada: edicionVinculada,
              onSeleccionar: creando ? null : _seleccionarEdicion,
              onQuitar: creando
                  ? null
                  : () => setState(() => edicionVinculada = null),
            ),

            const SizedBox(height: AppSpacing.xl),

            _VistaPrevia(
              capitulos: int.tryParse(controllerCapitulos.text.trim()) ?? 0,
              prologo: prologo,
              epilogo: epilogo,
            ),

            const SizedBox(height: AppSpacing.xl),

            ClubButton(
              label: creando
                  ? (widget.editando ? 'Guardando...' : 'Creando conversación...')
                  : (widget.editando ? 'Guardar cambios' : 'Crear conversación'),
              icon: Icons.check_circle_outline_rounded,
              onPressed: creando ? null : _guardar,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    final capitulos = int.tryParse(controllerCapitulos.text.trim());
    final paginasTexto = controllerPaginas.text.trim();
    final paginas = paginasTexto.isEmpty ? null : int.tryParse(paginasTexto);

    if (capitulos == null || capitulos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce un número de capítulos válido.'),
        ),
      );
      return;
    }
    if (!widget.editando &&
        paginasTexto.isNotEmpty &&
        (paginas == null || paginas <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce un número de páginas válido.')),
      );
      return;
    }

    setState(() {
      creando = true;
    });

    try {
      if (edicionVinculada != null) {
        final vinculado = await ApiService().vincularEdicionLibro(
          libro: widget.libro,
          otroBookId: edicionVinculada!.id,
        );
        if (!mounted) return;
        if (!vinculado) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se ha podido vincular la otra edición.'),
            ),
          );
          return;
        }
      }

      if (widget.editando) {
        final resultado = await ApiService().editarLectura(
          libro: widget.libro,
          capitulos: capitulos,
          prologo: prologo,
          epilogo: epilogo,
        );

        if (!mounted) return;

        if (resultado['ok'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                resultado['mensaje']?.toString() ??
                    'No se han podido guardar los cambios.',
              ),
            ),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lectura actualizada 💜'),
            backgroundColor: AppColors.success,
          ),
        );

        Navigator.pop(context, true);
        return;
      }

      final ok = await ApiService().crearLectura(
        libro: widget.libro,
        capitulos: capitulos,
        prologo: prologo,
        epilogo: epilogo,
        paginas: paginas,
        tipo: widget.tipo,
      );

      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se ha podido crear la conversación.'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esOficial
                ? 'Lectura oficial creada 💜'
                : 'Lectura compartida creada 💜',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ha ocurrido un error. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          creando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    controllerCapitulos.dispose();
    controllerPaginas.dispose();
    controllerEdicion.dispose();
    _debounceEdicion?.cancel();
    super.dispose();
  }
}

class _CabeceraConfiguracion extends StatelessWidget {
  final String libro;
  final bool esOficial;

  const _CabeceraConfiguracion({required this.libro, required this.esOficial});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceSoft, Color(0xFFF1E8FF)],
      ),
      borderColor: AppColors.primaryLight,
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              esOficial ? Icons.emoji_events_outlined : Icons.groups_2_outlined,
              color: AppColors.primary,
              size: 38,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            libro,
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 28, height: 1.18),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            esOficial
                ? 'Esta será la conversación oficial del club para esta lectura.'
                : 'Configura los espacios donde los miembros compartirán sus impresiones.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(height: 1.45),
          ),

          const SizedBox(height: AppSpacing.lg),

          ClubChip(
            label: esOficial ? 'Lectura oficial' : 'Lectura compartida',
            icon: esOficial
                ? Icons.workspace_premium_outlined
                : Icons.groups_2_outlined,
            variant: esOficial ? ClubChipVariant.primary : ClubChipVariant.info,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(icon, color: color, size: 27),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.section.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                subtitle,
                style: AppTextStyles.bodySecondary.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OpcionLectura extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _OpcionLectura({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: value ? AppColors.primaryLight : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: value ? AppColors.primary : AppColors.textMuted,
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(height: 1.35),
                  ),
                ],
              ),
            ),

            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _VistaPrevia extends StatelessWidget {
  final int capitulos;
  final bool prologo;
  final bool epilogo;

  const _VistaPrevia({
    required this.capitulos,
    required this.prologo,
    required this.epilogo,
  });

  @override
  Widget build(BuildContext context) {
    final total = capitulos + (prologo ? 1 : 0) + (epilogo ? 1 : 0);

    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vista previa',
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            capitulos <= 0
                ? 'Introduce el número de capítulos para ver la estructura.'
                : 'Se crearán $total espacios de conversación.',
            style: AppTextStyles.bodySecondary,
          ),

          if (capitulos > 0) ...[
            const SizedBox(height: AppSpacing.md),

            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (prologo)
                  const ClubChip(
                    label: 'Prólogo',
                    icon: Icons.first_page_rounded,
                    variant: ClubChipVariant.primary,
                  ),

                ClubChip(
                  label: capitulos == 1 ? '1 capítulo' : '$capitulos capítulos',
                  icon: Icons.format_list_numbered_rounded,
                  variant: ClubChipVariant.info,
                ),

                if (epilogo)
                  const ClubChip(
                    label: 'Epílogo',
                    icon: Icons.last_page_rounded,
                    variant: ClubChipVariant.primary,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VincularEdicion extends StatelessWidget {
  const _VincularEdicion({
    required this.controller,
    required this.onChanged,
    required this.buscando,
    required this.resultados,
    required this.seleccionada,
    required this.onSeleccionar,
    required this.onQuitar,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool buscando;
  final List<CatalogBook> resultados;
  final CatalogBook? seleccionada;
  final ValueChanged<CatalogBook>? onSeleccionar;
  final VoidCallback? onQuitar;

  @override
  Widget build(BuildContext context) {
    if (seleccionada != null) {
      return ClubCard(
        elevated: false,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ClubBookCover(
              title: seleccionada!.title,
              imageUrl: seleccionada!.coverUrl,
              width: 44,
              showShadow: false,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seleccionada!.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    seleccionada!.authorLabel,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onQuitar,
              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              tooltip: 'Quitar vínculo',
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: 'Buscar la otra ficha (opcional)',
            hintText: 'Ej. Deep End',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: buscando
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceSoft,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
            ),
          ),
        ),
        if (resultados.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          ClubCard(
            elevated: false,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final libro in resultados) ...[
                  ListTile(
                    leading: ClubBookCover(
                      title: libro.title,
                      imageUrl: libro.coverUrl,
                      width: 36,
                      showShadow: false,
                    ),
                    title: Text(libro.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      libro.authorLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: onSeleccionar == null
                        ? null
                        : () => onSeleccionar!(libro),
                  ),
                  if (libro != resultados.last) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
