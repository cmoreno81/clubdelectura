import 'package:club_lectura_app/models/dashboard.dart';
import 'package:club_lectura_app/theme/app_colors.dart';
import 'package:club_lectura_app/theme/app_radius.dart';
import 'package:club_lectura_app/theme/app_spacing.dart';
import 'package:club_lectura_app/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditarProgresoDialog extends StatefulWidget {
  final LecturaAhoraItem lectura;

  const EditarProgresoDialog({super.key, required this.lectura});

  @override
  State<EditarProgresoDialog> createState() => _EditarProgresoDialogState();
}

enum _ModoProgreso { porcentaje, pagina }

class _EditarProgresoDialogState extends State<EditarProgresoDialog> {
  late double progreso;
  late final TextEditingController comentarioController;
  late final TextEditingController paginaController;
  late final TextEditingController porcentajeController;
  late final TextEditingController totalPaginasController;
  late _ModoProgreso modo;
  String? errorPagina;
  String? errorPorcentaje;
  String? errorTotalPaginas;

  int? get totalPaginas =>
      widget.lectura.paginasTotales ??
      int.tryParse(totalPaginasController.text);

  bool get tienePaginas => (totalPaginas ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    progreso = widget.lectura.progreso.toDouble();
    modo =
        widget.lectura.paginaActual != null &&
            (widget.lectura.paginasTotales ?? 0) > 0
        ? _ModoProgreso.pagina
        : _ModoProgreso.porcentaje;
    totalPaginasController = TextEditingController();
    paginaController = TextEditingController(
      text: widget.lectura.paginaActual?.toString() ?? '',
    );
    porcentajeController = TextEditingController(
      text: widget.lectura.progreso.toString(),
    );
    comentarioController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.lectura.titulo,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.lectura.paginasTotales == null) ...[
              TextField(
                controller: totalPaginasController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Páginas del libro (opcional)',
                  hintText: 'Ej. 420',
                  prefixIcon: const Icon(Icons.menu_book_outlined),
                  errorText: errorTotalPaginas,
                ),
                onChanged: (_) {
                  setState(() {
                    errorTotalPaginas = null;
                    if (!tienePaginas) {
                      modo = _ModoProgreso.porcentaje;
                    }
                  });
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (tienePaginas) ...[
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<_ModoProgreso>(
                  segments: const [
                    ButtonSegment(
                      value: _ModoProgreso.porcentaje,
                      label: Text('Porcentaje'),
                    ),
                    ButtonSegment(
                      value: _ModoProgreso.pagina,
                      label: Text('Página'),
                    ),
                  ],
                  selected: {modo},
                  onSelectionChanged: (seleccion) {
                    setState(() {
                      modo = seleccion.first;
                      errorPagina = null;
                      errorPorcentaje = null;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Center(
              child: Text(
                modo == _ModoProgreso.pagina
                    ? '${progreso.round()}% · $totalPaginas páginas'
                    : '${progreso.round()}%',
                style: AppTextStyles.title.copyWith(color: AppColors.primary),
              ),
            ),
            if (modo == _ModoProgreso.porcentaje) ...[
              Slider(
                value: progreso,
                min: 0,
                max: 100,
                divisions: 100,
                label: '${progreso.round()}%',
                onChanged: (value) {
                  setState(() {
                    progreso = value;
                    porcentajeController.text = value.round().toString();
                    errorPorcentaje = null;
                  });
                },
              ),
              TextField(
                controller: porcentajeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: 'Porcentaje exacto',
                  hintText: 'Ej. 37',
                  suffixText: '%',
                  errorText: errorPorcentaje,
                ),
                onChanged: (value) {
                  final porcentaje = int.tryParse(value);
                  setState(() {
                    errorPorcentaje = null;
                    if (porcentaje != null &&
                        porcentaje >= 0 &&
                        porcentaje <= 100) {
                      progreso = porcentaje.toDouble();
                    }
                  });
                },
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: paginaController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Página actual',
                  suffixText: 'de $totalPaginas',
                  errorText: errorPagina,
                ),
                onChanged: (value) {
                  final pagina = int.tryParse(value);
                  final total = totalPaginas!;
                  setState(() {
                    errorPagina = null;
                    if (pagina != null && pagina >= 0 && pagina <= total) {
                      progreso = pagina / total * 100;
                    }
                  });
                },
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (widget.lectura.comentario.trim().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  'Impresión actual:\n“${widget.lectura.comentario}”\n\n'
                  'Escribe una nueva para sustituirla. Si guardas este '
                  'campo vacío, se eliminará.',
                  style: AppTextStyles.caption.copyWith(height: 1.4),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextField(
              controller: comentarioController,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              smartDashesType: SmartDashesType.enabled,
              smartQuotesType: SmartQuotesType.enabled,
              decoration: const InputDecoration(
                labelText: 'Nueva impresión (opcional)',
                hintText: '¿Qué te está pareciendo ahora?',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }

  void _guardar() {
    if (modo == _ModoProgreso.porcentaje) {
      final porcentaje = int.tryParse(porcentajeController.text);
      if (porcentaje == null || porcentaje < 0 || porcentaje > 100) {
        setState(() => errorPorcentaje = 'Indica un porcentaje entre 0 y 100');
        return;
      }
      progreso = porcentaje.toDouble();
    }

    int? paginasTotales;
    if (widget.lectura.paginasTotales == null &&
        totalPaginasController.text.isNotEmpty) {
      paginasTotales = int.tryParse(totalPaginasController.text);
      if (paginasTotales == null || paginasTotales <= 0) {
        setState(() => errorTotalPaginas = 'Indica un número mayor que 0');
        return;
      }
    }

    int? paginaActual;
    if (modo == _ModoProgreso.pagina) {
      paginaActual = int.tryParse(paginaController.text);
      final total = totalPaginas!;
      if (paginaActual == null || paginaActual < 0 || paginaActual > total) {
        setState(() => errorPagina = 'Indica una página entre 0 y $total');
        return;
      }
    }

    Navigator.pop(context, (
      progreso: progreso.round(),
      comentario: comentarioController.text.trim(),
      paginaActual: paginaActual,
      paginasTotales: paginasTotales,
    ));
  }

  @override
  void dispose() {
    paginaController.dispose();
    porcentajeController.dispose();
    totalPaginasController.dispose();
    comentarioController.dispose();
    super.dispose();
  }
}
