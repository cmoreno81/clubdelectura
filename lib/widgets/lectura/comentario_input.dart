import 'package:flutter/material.dart';

import '../../models/subrayador_categoria.dart';

class ComentarioInput extends StatelessWidget {
  const ComentarioInput({
    super.key,
    required this.controller,
    required this.onEnviar,
    required this.enviando,
    required this.hintText,
    this.esReflexion = false,
    this.onCerrar,
    this.focusNode,
    // Categoría seleccionada: índice en coloresCategorias (null = libre).
    // Determina tanto el color como si es cita (esCita = categoria.esCita).
    this.categoriaSeleccionada,
    this.onCategoriaChanged,
    this.coloresCategorias = const [],
  });

  final TextEditingController controller;
  final VoidCallback onEnviar;
  final bool enviando;
  final String hintText;
  final bool esReflexion;
  final VoidCallback? onCerrar;
  final FocusNode? focusNode;

  /// Índice de la categoría activa (null = comentario libre, sin color).
  final int? categoriaSeleccionada;

  /// Colores del kit (uno por categoría, en el mismo orden que [kSubrayadorCategorias]).
  final List<Color> coloresCategorias;

  /// Callback cuando el usuario cambia de categoría.
  final ValueChanged<int?>? onCategoriaChanged;

  bool get _esCita =>
      categoriaSeleccionada != null &&
      categoriaSeleccionada! < kSubrayadorCategorias.length &&
      kSubrayadorCategorias[categoriaSeleccionada!].esCita;

  Color? get _colorActivo =>
      categoriaSeleccionada != null &&
          categoriaSeleccionada! < coloresCategorias.length
      ? coloresCategorias[categoriaSeleccionada!]
      : null;

  @override
  Widget build(BuildContext context) {
    final quoteColor = _colorActivo != null
        ? _readableQuoteColor(_colorActivo!)
        : const Color(0xFF6F4DBF);

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
              // ── Selector de categoría (solo en capítulos no-reflexión) ──
              if (!esReflexion &&
                  onCategoriaChanged != null &&
                  coloresCategorias.isNotEmpty) ...[
                _CategoriasSelector(
                  colores: coloresCategorias,
                  seleccionada: categoriaSeleccionada,
                  onSeleccionada: onCategoriaChanged!,
                ),
                const SizedBox(height: 8),
              ],

              // ── Encabezado de "Escribir reflexión" ──
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

              // ── Campo de texto ──
              TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: !enviando,
                style: _esCita
                    ? TextStyle(
                        color: quoteColor,
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      )
                    : null,
                minLines: esReflexion ? 4 : 3,
                maxLines: esReflexion ? 10 : 8,
                maxLength: esReflexion
                    ? 2000
                    : _esCita
                    ? 500
                    : 1500,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                autocorrect: true,
                enableSuggestions: true,
                smartDashesType: SmartDashesType.enabled,
                smartQuotesType: SmartQuotesType.enabled,
                buildCounter: (
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
                  hintText: _esCita
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
                              : _esCita
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

/// Selector horizontal de categorías de subrayador.
/// La primera opción es siempre "Libre" (sin categoría, sin color).
class _CategoriasSelector extends StatelessWidget {
  const _CategoriasSelector({
    required this.colores,
    required this.seleccionada,
    required this.onSeleccionada,
  });

  final List<Color> colores;
  final int? seleccionada;
  final ValueChanged<int?> onSeleccionada;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Opción "libre" (sin categoría)
          _CategoriaChip(
            emoji: '✏️',
            nombre: 'Libre',
            color: null,
            seleccionada: seleccionada == null,
            onTap: () => onSeleccionada(null),
          ),
          const SizedBox(width: 6),
          // Opciones de categoría del kit.
          // Las citas van primero (índice 2) porque son el tipo más frecuente;
          // el resto mantiene el orden original.
          for (final i in [
            2,
            0,
            1,
            3,
            4,
          ].where((i) => i < kSubrayadorCategorias.length && i < colores.length)) ...[
            _CategoriaChip(
              emoji: kSubrayadorCategorias[i].emoji,
              nombre: kSubrayadorCategorias[i].nombre,
              color: colores[i],
              seleccionada: seleccionada == i,
              onTap: () => onSeleccionada(i),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _CategoriaChip extends StatelessWidget {
  const _CategoriaChip({
    required this.emoji,
    required this.nombre,
    required this.color,
    required this.seleccionada,
    required this.onTap,
  });

  final String emoji;
  final String nombre;
  final Color? color;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? const Color(0xFF6F4DBF);
    final bgColor = seleccionada
        ? chipColor.withValues(alpha: .18)
        : Colors.transparent;
    final borderColor = seleccionada ? chipColor : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: seleccionada ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              '$emoji $nombre',
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    seleccionada ? FontWeight.w800 : FontWeight.w600,
                color: seleccionada
                    ? (color != null
                        ? _readableColor(chipColor)
                        : const Color(0xFF5B3CA8))
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _readableColor(Color color) {
    if (color.computeLuminance() <= .52) return color;
    return Color.lerp(color, Colors.black, .38)!;
  }
}
