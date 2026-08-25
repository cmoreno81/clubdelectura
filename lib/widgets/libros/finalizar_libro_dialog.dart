import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../common/club_rating_selector.dart';

/// Sheet de "Finalizar lectura". Se muestra como bottom sheet para que el
/// teclado empuje el contenido hacia arriba y la caja de reseña siempre
/// sea visible mientras se escribe.
class FinalizarLibroDialog extends StatefulWidget {
  final DateTime? fechaInicioActual;
  final String formatoActual;

  const FinalizarLibroDialog({
    super.key,
    this.fechaInicioActual,
    this.formatoActual = '',
  });

  /// Muestra el sheet y devuelve el mismo Map que antes devolvía showDialog.
  static Future<Map<String, String>?> show(
    BuildContext context, {
    DateTime? fechaInicioActual,
    String formatoActual = '',
  }) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,   // ocupa hasta el 90 % de la pantalla
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FinalizarLibroDialog(
        fechaInicioActual: fechaInicioActual,
        formatoActual: formatoActual,
      ),
    );
  }

  @override
  State<FinalizarLibroDialog> createState() => _FinalizarLibroDialogState();
}

class _FinalizarLibroDialogState extends State<FinalizarLibroDialog> {
  double? valoracion;
  late String formato;
  late DateTime fechaInicio;
  late DateTime fechaFin;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _resenaFocus = FocusNode();

  bool get esDecepcion => valoracion == 0;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    final actual = widget.fechaInicioActual;
    fechaInicio = actual == null || actual.isAfter(hoy) ? hoy : actual;
    fechaFin = hoy;
    formato = widget.formatoActual;

    // Cuando la caja de reseña gana el foco, desplázate hasta el final
    // para que nunca quede oculta bajo el teclado.
    _resenaFocus.addListener(() {
      if (_resenaFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (_scroll.hasClients) {
            _scroll.animateTo(
              _scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  // ── Helpers de fecha ────────────────────────────────────────────────────────

  String _fechaTexto(DateTime fecha) {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    return '$d/$m/${fecha.year}';
  }

  String _fechaApi(DateTime fecha) {
    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    return '${fecha.year}-$m-$d';
  }

  // ── Selectores ──────────────────────────────────────────────────────────────

  Future<void> _seleccionarFechaInicio() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: fechaInicio,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'Fecha de inicio de la lectura',
    );
    if (elegida != null && mounted) {
      setState(() {
        fechaInicio = elegida;
        if (fechaFin.isBefore(fechaInicio)) fechaFin = fechaInicio;
      });
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: fechaFin.isBefore(fechaInicio) ? fechaInicio : fechaFin,
      firstDate: fechaInicio,
      lastDate: DateTime.now(),
      helpText: 'Fecha de finalización de la lectura',
    );
    if (elegida != null && mounted) setState(() => fechaFin = elegida);
  }

  void _seleccionarValoracion(double nueva) {
    final primera = valoracion == null;
    setState(() => valoracion = nueva);
    if (primera) _scrollToResena();
  }

  void _scrollToResena() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // ── Texto de valoración ─────────────────────────────────────────────────────

  String get valoracionTexto {
    final v = valoracion;
    if (v == null) return 'Selecciona una valoración';
    if (v == 0) return 'No era para mí';
    final txt = v % 1 == 0
        ? v.toInt().toString()
        : v.toStringAsFixed(1).replaceAll('.', ',');
    return '$txt de 5';
  }

  // ── Confirmación ────────────────────────────────────────────────────────────

  void _finalizar() {
    if (valoracion == null || formato.isEmpty) return;
    HapticFeedback.mediumImpact();
    Navigator.pop<Map<String, String>>(context, {
      'valoracion': valoracion.toString(),
      'reflexion': _controller.text.trim(),
      'fechaInicio': _fechaApi(fechaInicio),
      'fechaFin': _fechaApi(fechaFin),
      'formato': formato,
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // viewInsets.bottom sube con el teclado → el contenido sube con él.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Padding bottom = teclado + safe area, para que nada quede tapado.
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ────────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Título ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  'Finalizar lectura',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // ── Contenido scrollable ──────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fechas
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_calendar_outlined),
                    title: const Text('Fecha de inicio'),
                    subtitle: Text(_fechaTexto(fechaInicio)),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: _seleccionarFechaInicio,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_available_outlined),
                    title: const Text('Fecha de finalización'),
                    subtitle: Text(_fechaTexto(fechaFin)),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: _seleccionarFechaFin,
                  ),

                  const SizedBox(height: 20),

                  // Formato
                  const Text(
                    '¿En qué formato lo has leído?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final opcion in const [
                        ('FISICO', '📖 Físico'),
                        ('DIGITAL', '📱 Digital'),
                        ('AUDIOLIBRO', '🎧 Audiolibro'),
                      ])
                        ChoiceChip(
                          label: Text(
                            opcion.$2,
                            style: TextStyle(
                              color: formato == opcion.$1
                                  ? cs.onPrimary
                                  : cs.onSurface,
                              fontWeight: formato == opcion.$1
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                          selected: formato == opcion.$1,
                          selectedColor: cs.primary,
                          checkmarkColor: cs.onPrimary,
                          onSelected: (_) =>
                              setState(() => formato = opcion.$1),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Valoración
                  const Text(
                    '¿Qué valoración le das al libro?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Puedes seleccionar estrellas completas o medias estrellas.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ClubRatingSelector(
                      valoracion: valoracion ?? 0,
                      enabled: !esDecepcion,
                      onChanged: _seleccionarValoracion,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        valoracionTexto,
                        key: ValueKey(valoracionTexto),
                        style: TextStyle(
                          color: valoracion == null
                              ? cs.onSurfaceVariant
                              : cs.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ChoiceChip(
                      avatar: const Text('😞', style: TextStyle(fontSize: 18)),
                      label: const Text('No era para mí'),
                      selected: esDecepcion,
                      selectedColor: cs.primary,
                      checkmarkColor: cs.onPrimary,
                      labelStyle: TextStyle(
                        color: esDecepcion ? cs.onPrimary : cs.onSurface,
                        fontWeight:
                            esDecepcion ? FontWeight.w800 : FontWeight.w500,
                      ),
                      onSelected: (sel) {
                        final primera = valoracion == null;
                        setState(() => valoracion = sel ? 0 : null);
                        if (sel && primera) _scrollToResena();
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reseña — la caja que antes quedaba tapada
                  const Text(
                    '💭 Tu reseña (opcional)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    focusNode: _resenaFocus,
                    minLines: 4,
                    maxLines: 12,
                    maxLength: 5000,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    autocorrect: true,
                    enableSuggestions: true,
                    smartDashesType: SmartDashesType.enabled,
                    smartQuotesType: SmartQuotesType.enabled,
                    decoration: InputDecoration(
                      hintText:
                          '¿Qué te ha parecido el libro?\n\n'
                          'Esta reseña aparecerá en la ficha del libro.',
                      filled: true,
                      fillColor: const Color(0xFFF7F1FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide:
                            const BorderSide(color: Color(0xFFE1D4F5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(
                          color: Color(0xFF6F4DBF),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Botones fijos en la parte inferior ───────────────────────────
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed:
                        valoracion == null || formato.isEmpty ? null : _finalizar,
                    icon: const Icon(Icons.check),
                    label: const Text('Finalizar'),
                  ),
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
    _controller.dispose();
    _scroll.dispose();
    _resenaFocus.dispose();
    super.dispose();
  }
}
