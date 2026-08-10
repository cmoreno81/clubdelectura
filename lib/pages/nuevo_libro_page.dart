import 'package:flutter/material.dart';
import '../models/libro.dart';
import '../models/libro_agrupado.dart';
import '../models/nuevo_libro.dart';
import '../services/api_service.dart';
import '../services/usuario_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_button.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/optimized_network_image.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/common/url_text_field.dart';

class NuevoLibroPage extends StatefulWidget {
  final LibroAgrupado? libro;

  const NuevoLibroPage({super.key, this.libro});

  bool get esEdicion => libro != null;

  @override
  State<NuevoLibroPage> createState() => _NuevoLibroPageState();
}

class _NuevoLibroPageState extends State<NuevoLibroPage> {
  final libroController = TextEditingController();
  final autorController = TextEditingController();
  final sagaController = TextEditingController();
  final numSagaController = TextEditingController();
  final goodreadsController = TextEditingController();
  final coverUrlController = TextEditingController();
  final paginasController = TextEditingController();

  String genero = 'Fantasía';
  String prioridad = 'Media';
  String formato = '';
  String autoconclusivo = 'Si';

  bool guardando = false;
  bool mostrarCamposAvanzados = false;

  bool get esEdicion => widget.esEdicion;

  Libro? get referencia => widget.libro?.referencia;

  String get tituloActual => libroController.text.trim();

  String get portadaActual => coverUrlController.text.trim();

  static const List<_GeneroOption> generos = [
    _GeneroOption('🐉', 'Fantasía', 'Fantasía'),
    _GeneroOption('🌹', 'Romantasy', 'Romantasy'),
    _GeneroOption('💕', 'Romance', 'Romance'),
    _GeneroOption('🔪', 'Thriller', 'Thriller'),
    _GeneroOption('🖤', 'Dark Romance', 'Dark Romance'),
    _GeneroOption('🎓', 'Dark Academia', 'Dark Academia'),
    _GeneroOption('🎭', 'Drama', 'Drama'),
    _GeneroOption('📜', 'Clásicos', 'Clásicos'),
    _GeneroOption('🌇', 'Distopía', 'Distopía'),
    _GeneroOption('🏙️', 'Novela contemporánea', 'Contemporánea'),
    _GeneroOption('🏰', 'Novela Histórica', 'Histórica'),
    _GeneroOption('🚀', 'Ciencia Ficción', 'Ciencia ficción'),
    _GeneroOption('👻', 'Terror', 'Terror'),
    _GeneroOption('🕵️', 'Novela Negra', 'Novela negra'),
    _GeneroOption('💬', 'Cómic', 'Cómic'),
    _GeneroOption('🧠', 'No ficción', 'No ficción'),
    _GeneroOption('🎈', 'Infantil', 'Infantil'),
  ];

  @override
  void initState() {
    super.initState();
    _precargarDatos();

    libroController.addListener(_actualizarVistaPrevia);
    coverUrlController.addListener(_actualizarVistaPrevia);
  }

  void _precargarDatos() {
    if (!esEdicion) return;

    final agrupado = widget.libro!;
    final registro = referencia;
    final finalizado = agrupado.finalizados.isNotEmpty
        ? agrupado.finalizados.first
        : null;

    libroController.text = agrupado.libro;
    autorController.text = registro?.autor ?? finalizado?.autor ?? '';

    genero = agrupado.genero.trim().isEmpty
        ? 'Fantasía'
        : agrupado.genero.trim();

    sagaController.text = registro?.saga ?? finalizado?.saga ?? '';

    numSagaController.text = registro?.numSaga ?? finalizado?.numSaga ?? '';

    autoconclusivo =
        registro?.autoconclusivo ?? finalizado?.autoconclusivo ?? 'Si';

    prioridad = registro?.prioridad.isNotEmpty == true
        ? _normalizarPrioridad(registro!.prioridad)
        : 'Media';
    formato = registro?.formato ?? finalizado?.formato ?? '';

    goodreadsController.text = registro?.goodreads ?? '';
    coverUrlController.text = agrupado.coverUrl;
    paginasController.text =
        (registro?.paginas ?? finalizado?.paginas)?.toString() ?? '';

    mostrarCamposAvanzados =
        goodreadsController.text.trim().isNotEmpty ||
        coverUrlController.text.trim().isNotEmpty;
  }

  void _actualizarVistaPrevia() {
    if (mounted) {
      setState(() {});
    }
  }

  String _normalizarPrioridad(String value) {
    switch (value.trim().toUpperCase()) {
      case 'ALTA':
        return 'Alta';
      case 'BAJA':
        return 'Baja';
      default:
        return 'Media';
    }
  }

  Future<void> _guardarLibro() async {
    if (guardando) return;

    final usuario = await UsuarioService().obtenerUsuario();

    if (!mounted) return;

    if (usuario == null || usuario.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido identificar a la usuaria.'),
        ),
      );
      return;
    }

    final titulo = libroController.text.trim();
    final paginasTexto = paginasController.text.trim();
    final paginas = paginasTexto.isEmpty ? null : int.tryParse(paginasTexto);

    if (titulo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce el título del libro.')),
      );
      return;
    }

    if (paginasTexto.isNotEmpty && (paginas == null || paginas <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce un número de páginas válido.')),
      );
      return;
    }

    if (autoconclusivo == 'No' && sagaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Introduce el nombre de la saga o marca el libro como autoconclusivo.',
          ),
        ),
      );
      return;
    }

    if (!esEdicion && formato.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el formato del libro.')),
      );
      return;
    }

    setState(() {
      guardando = true;
    });

    try {
      final libro = NuevoLibro(
        bookId: esEdicion ? widget.libro!.bookId : null,
        usuario: usuario.trim(),
        libro: titulo,
        autor: autorController.text.trim(),
        genero: genero,
        saga: autoconclusivo == 'No' ? sagaController.text.trim() : '',
        numSaga: autoconclusivo == 'No' ? numSagaController.text.trim() : '',
        autoconclusivo: autoconclusivo,
        prioridad: prioridad,
        formato: formato,
        goodreads: goodreadsController.text.trim(),
        coverUrl: coverUrlController.text.trim(),
        paginas: paginas,
      );

      final respuesta = esEdicion
          ? await ApiService().editarLibro(libro)
          : await ApiService().crearLibro(libro);

      if (!mounted) return;

      final ok = respuesta['ok'] == true;
      final mensaje = respuesta['mensaje']?.toString();

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              mensaje ??
                  (esEdicion
                      ? 'No se ha podido actualizar el libro.'
                      : 'No se ha podido añadir el libro.'),
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mensaje ??
                (esEdicion
                    ? 'Libro actualizado correctamente.'
                    : 'Libro añadido correctamente.'),
          ),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ha ocurrido un error: '
            '${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Editar libro' : 'Nuevo libro')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            120,
          ),
          children: [
            _cabecera(),

            const SizedBox(height: AppSpacing.lg),

            const _SectionHeader(
              icon: Icons.menu_book_outlined,
              color: AppColors.primary,
              title: 'Información básica',
              subtitle: 'El título y la identidad principal del libro',
            ),

            const SizedBox(height: AppSpacing.md),

            ClubCard(
              elevated: false,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  TextField(
                    controller: libroController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Título del libro',
                      hintText: 'Ej. Hasta que caiga la luna',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  TextField(
                    controller: autorController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Autor/a (opcional)',
                      hintText: 'Ej. Sarah A. Parker',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  TextField(
                    controller: paginasController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Páginas totales (opcional)',
                      hintText: 'Ej. 420',
                      prefixIcon: Icon(Icons.menu_book_outlined),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '¿Es autoconclusivo?',
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  Row(
                    children: [
                      Expanded(
                        child: _SelectorOption(
                          selected: autoconclusivo == 'Si',
                          icon: Icons.book_outlined,
                          title: 'Sí',
                          subtitle: 'Historia cerrada',
                          onTap: () {
                            setState(() {
                              autoconclusivo = 'Si';
                              sagaController.clear();
                              numSagaController.clear();
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: AppSpacing.sm),

                      Expanded(
                        child: _SelectorOption(
                          selected: autoconclusivo == 'No',
                          icon: Icons.collections_bookmark_outlined,
                          title: 'No',
                          subtitle: 'Forma parte de una saga',
                          onTap: () {
                            setState(() {
                              autoconclusivo = 'No';
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  if (autoconclusivo == 'No') ...[
                    const SizedBox(height: AppSpacing.lg),

                    TextField(
                      controller: sagaController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la saga',
                        hintText: 'Ej. Empíreo',
                        prefixIcon: Icon(Icons.collections_bookmark_outlined),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    TextField(
                      controller: numSagaController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Número en la saga',
                        hintText: 'Ej. 2',
                        prefixIcon: Icon(Icons.format_list_numbered_rounded),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            const _SectionHeader(
              icon: Icons.sell_outlined,
              color: Color(0xFFD75784),
              title: 'Género',
              subtitle: 'Elige la categoría que mejor representa la historia',
            ),

            const SizedBox(height: AppSpacing.md),

            ClubCard(
              elevated: false,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final option in generos)
                    ClubChip(
                      label: '${option.emoji} ${option.label}',
                      selected: genero == option.value,
                      variant: genero == option.value
                          ? ClubChipVariant.primary
                          : ClubChipVariant.neutral,
                      onTap: () {
                        setState(() {
                          genero = option.value;
                        });
                      },
                    ),
                ],
              ),
            ),

            if (!esEdicion) ...[
              const SizedBox(height: AppSpacing.xl),

              const _SectionHeader(
                icon: Icons.flag_outlined,
                color: Color(0xFFE98325),
                title: 'Prioridad',
                subtitle: 'Indica cuánto te apetece empezar esta lectura',
              ),

              const SizedBox(height: AppSpacing.md),

              ClubCard(
                elevated: false,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: _PrioridadOption(
                        label: 'Baja',
                        emoji: '🟢',
                        selected: prioridad == 'Baja',
                        onTap: () {
                          setState(() {
                            prioridad = 'Baja';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _PrioridadOption(
                        label: 'Media',
                        emoji: '🟡',
                        selected: prioridad == 'Media',
                        onTap: () {
                          setState(() {
                            prioridad = 'Media';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _PrioridadOption(
                        label: 'Alta',
                        emoji: '🔴',
                        selected: prioridad == 'Alta',
                        onTap: () {
                          setState(() {
                            prioridad = 'Alta';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              const _SectionHeader(
                icon: Icons.auto_stories_outlined,
                color: AppColors.info,
                title: 'Tu formato',
                subtitle: 'Puedes cambiarlo más adelante en la ficha',
              ),

              const SizedBox(height: AppSpacing.md),

              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final opcion in const [
                    ('FISICO', '📖 Físico'),
                    ('DIGITAL', '📱 Digital'),
                    ('AUDIOLIBRO', '🎧 Audiolibro'),
                  ])
                    ChoiceChip(
                      label: Text(opcion.$2),
                      selected: formato == opcion.$1,
                      selectedColor: AppColors.primary,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: formato == opcion.$1
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: formato == opcion.$1
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                      onSelected: (_) => setState(() => formato = opcion.$1),
                    ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

            _SectionHeader(
              icon: Icons.image_outlined,
              color: AppColors.info,
              title: 'Enlaces y portada',
              subtitle: esEdicion
                  ? 'Puedes corregir manualmente la portada o Goodreads'
                  : 'Son opcionales; intentaremos buscar la portada automáticamente',
            ),

            const SizedBox(height: AppSpacing.md),

            ClubCard(
              elevated: false,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    onTap: () {
                      setState(() {
                        mostrarCamposAvanzados = !mostrarCamposAvanzados;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(
                              Icons.link_rounded,
                              color: AppColors.primary,
                            ),
                          ),

                          const SizedBox(width: AppSpacing.md),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Datos opcionales',
                                  style: AppTextStyles.subtitle.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Goodreads y portada manual',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            mostrarCamposAvanzados
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (mostrarCamposAvanzados) ...[
                    const SizedBox(height: AppSpacing.lg),

                    UrlTextField(
                      controller: goodreadsController,
                      textInputAction: TextInputAction.next,
                      labelText: 'Enlace de Goodreads',
                      hintText: 'https://www.goodreads.com/...',
                      prefixIcon: Icons.language_rounded,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    UrlTextField(
                      controller: coverUrlController,
                      textInputAction: TextInputAction.done,
                      labelText: 'Enlace de la portada',
                      hintText: 'https://.../portada.jpg',
                      prefixIcon: Icons.image_outlined,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 19,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              portadaActual.isEmpty
                                  ? 'Si la dejas vacía, el servidor intentará encontrar una portada segura automáticamente.'
                                  : 'La URL manual sustituirá a la portada actual.',
                              style: AppTextStyles.caption.copyWith(
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            ClubButton(
              label: guardando
                  ? esEdicion
                        ? 'Guardando cambios...'
                        : 'Añadiendo libro...'
                  : esEdicion
                  ? 'Guardar cambios'
                  : 'Añadir libro',
              icon: esEdicion ? Icons.save_outlined : Icons.add_rounded,
              onPressed: guardando ? null : _guardarLibro,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cabecera() {
    final colorPrincipal = Theme.of(context).colorScheme.primary;

    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceSoft, colorPrincipal.withValues(alpha: 0.10)],
      ),
      borderColor: colorPrincipal.withValues(alpha: 0.18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 102,
            child: FittedBox(
              fit: BoxFit.fill,
              child: _PortadaPreview(
                title: tituloActual,
                imageUrl: portadaActual,
                color: colorPrincipal,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClubChip(
                  label: esEdicion ? 'Editando libro' : 'Nueva incorporación',
                  icon: esEdicion
                      ? Icons.edit_outlined
                      : Icons.auto_stories_outlined,
                  variant: ClubChipVariant.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  tituloActual.isEmpty
                      ? esEdicion
                            ? 'Edita los datos del libro'
                            : 'Añade una nueva historia'
                      : tituloActual,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.section.copyWith(height: 1.15),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  esEdicion
                      ? 'Actualiza sus datos sin perder el historial.'
                      : 'Completa los datos para añadirla a tu biblioteca.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySecondary.copyWith(height: 1.25),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    libroController.removeListener(_actualizarVistaPrevia);
    coverUrlController.removeListener(_actualizarVistaPrevia);

    libroController.dispose();
    autorController.dispose();
    sagaController.dispose();
    numSagaController.dispose();
    goodreadsController.dispose();
    coverUrlController.dispose();
    paginasController.dispose();

    super.dispose();
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

class _PortadaPreview extends StatelessWidget {
  final String title;
  final String imageUrl;
  final Color color;

  const _PortadaPreview({
    required this.title,
    required this.imageUrl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();

    return Container(
      width: 118,
      height: 168,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: OptimizedNetworkImage(
        url: url,
        width: 118,
        height: 168,
        fallback: _PortadaFallback(
          title: title,
          color: color,
          error: url.isNotEmpty,
        ),
      ),
    );
  }
}

class _PortadaFallback extends StatelessWidget {
  final String title;
  final Color color;
  final bool error;

  const _PortadaFallback({
    required this.title,
    required this.color,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            error ? Icons.broken_image_outlined : Icons.auto_stories_outlined,
            color: color,
            size: 38,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            error
                ? 'No se puede cargar'
                : title.trim().isEmpty
                ? 'Nueva historia'
                : title,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorOption extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SelectorOption({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // Altura fija: el tick se superpone, no empuja el layout
        height: 128,
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: .22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Positioned.fill garantiza que el contenido tiene todo el ancho
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: selected ? Colors.white : AppColors.textMuted,
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.subtitle.copyWith(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: selected
                            ? Colors.white.withValues(alpha: .80)
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tick superpuesto en esquina inferior derecha — no afecta al tamaño
            if (selected)
              const Positioned(
                right: 8,
                bottom: 8,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PrioridadOption extends StatelessWidget {
  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  const _PrioridadOption({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.10)
              : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.38)
                : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 23)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: selected ? color : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GeneroOption {
  final String emoji;
  final String value;
  final String label;

  const _GeneroOption(this.emoji, this.value, this.label);
}
