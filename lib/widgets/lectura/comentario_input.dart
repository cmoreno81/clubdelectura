import 'package:flutter/material.dart';

class ComentarioInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onEnviar;
  final bool enviando;
  final String hintText;
  final bool esReflexion;
  final VoidCallback? onCerrar;
  final FocusNode? focusNode;
  final bool esCita;
  final ValueChanged<bool>? onTipoChanged;
  final List<Color> coloresCita;
  final Color? colorCita;
  final ValueChanged<Color>? onColorChanged;

  const ComentarioInput({
    super.key,
    required this.controller,
    required this.onEnviar,
    required this.enviando,
    required this.hintText,
    this.esReflexion = false,
    this.onCerrar,
    this.focusNode,
    this.esCita = false,
    this.onTipoChanged,
    this.coloresCita = const [],
    this.colorCita,
    this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final quoteColor = _readableQuoteColor(
      colorCita ?? Theme.of(context).colorScheme.primary,
    );

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 8,
      shadowColor: Colors.black12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!esReflexion && onTipoChanged != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.chat_bubble_outline_rounded),
                        label: Text('Comentario'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.format_quote_rounded),
                        label: Text('Cita'),
                      ),
                    ],
                    selected: {esCita},
                    onSelectionChanged: (value) {
                      onTipoChanged!(value.first);
                    },
                  ),
                ),
                if (esCita && coloresCita.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Color del kit',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: [
                            for (final color in coloresCita)
                              Semantics(
                                button: true,
                                selected: colorCita == color,
                                label: 'Elegir color de cita',
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => onColorChanged?.call(color),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colorCita == color
                                            ? Colors.black87
                                            : Colors.white,
                                        width: colorCita == color ? 3 : 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
              ],
              if (onCerrar != null) ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Escribir reflexión',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ocultar editor',
                      visualDensity: VisualDensity.compact,
                      onPressed: enviando ? null : onCerrar,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: !enviando,
                style: esCita
                    ? TextStyle(
                        color: quoteColor,
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      )
                    : null,
                // La caja crece con el contenido: empieza en 3 líneas y se
                // expande hasta 8 (10 para reflexiones). A partir de ahí el
                // texto sigue siendo visible cerca del cursor, pero el usuario
                // ya ha podido leer casi todo lo escrito sin scroll interno.
                minLines: esReflexion ? 4 : 3,
                maxLines: esReflexion ? 10 : 8,
                maxLength: esReflexion
                    ? 2000
                    : esCita
                    ? 500
                    : 1500,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                autocorrect: true,
                enableSuggestions: true,
                smartDashesType: SmartDashesType.enabled,
                smartQuotesType: SmartQuotesType.enabled,

                // Contador sutil: aparece solo cuando quedan menos de 200
                // caracteres. No estorba durante la escritura normal.
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) {
                      if (maxLength == null) return null;
                      final restantes = maxLength - currentLength;
                      if (restantes > 200) return null;
                      return Text(
                        '$restantes restantes',
                        style: TextStyle(
                          fontSize: 11,
                          color: restantes < 50
                              ? Colors.red.shade600
                              : Colors.grey.shade500,
                        ),
                      );
                    },

                decoration: InputDecoration(
                  hintText: esCita
                      ? 'Escribe aquí la frase del libro…'
                      : hintText,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),

                  filled: true,
                  fillColor: const Color(0xFFF7F1FF),
                  alignLabelWithHint: true,

                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  prefixIcon: const Align(
                    widthFactor: 1,
                    heightFactor: 1,
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 14),
                      child: Icon(
                        Icons.edit_note_rounded,
                        color: Color(0xFF6F4DBF),
                        size: 26,
                      ),
                    ),
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xFFE1D4F5)),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFF6F4DBF),
                      width: 1.5,
                    ),
                  ),

                  contentPadding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final tieneTexto = value.text.trim().isNotEmpty;
                    return FilledButton.icon(
                      onPressed: enviando || !tieneTexto ? null : onEnviar,
                      icon: enviando
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          enviando
                              ? 'Publicando...'
                              : esReflexion
                              ? 'Publicar reflexión'
                              : esCita
                              ? 'Guardar cita'
                              : 'Publicar comentario',
                          key: ValueKey(enviando),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        backgroundColor: const Color(0xFF6F4DBF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _readableQuoteColor(Color color) {
    if (color.computeLuminance() <= .52) return color;
    return Color.lerp(color, Colors.black, .38)!;
  }
}
