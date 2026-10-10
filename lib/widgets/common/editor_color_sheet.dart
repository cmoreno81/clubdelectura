import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Colores habituales de post-it y marcadores (claros y oscuros), para elegir
/// con un toque.
const coloresPostIt = <Color>[
  Color(0xFFF9D71C), // amarillo canario
  Color(0xFFFFE45E), // amarillo pastel
  Color(0xFFFF9F43), // naranja
  Color(0xFFFF6B6B), // coral
  Color(0xFFFF8FB8), // rosa chicle
  Color(0xFFE0457B), // rosa fucsia
  Color(0xFFC13584), // magenta
  Color(0xFF9B6FD1), // morado
  Color(0xFFC3A6E8), // lavanda
  Color(0xFF4F8BD6), // azul
  Color(0xFF8FD3F4), // celeste
  Color(0xFF2BB5A6), // turquesa
  Color(0xFF8EE0B4), // menta
  Color(0xFF5DBB63), // verde
  Color(0xFFC6E64C), // lima
  Color(0xFF9AA3AF), // gris
  // Tonos oscuros, para los libros de portada negra.
  Color(0xFF141416), // negro
  Color(0xFF3B4048), // grafito
  Color(0xFF7B1E2E), // granate
  Color(0xFF4F1022), // burdeos
  Color(0xFF1F2A4D), // azul marino
  Color(0xFF1F4D3A), // verde bosque
  Color(0xFF5A3A2A), // marrón
  Color(0xFF3D1F5C), // morado oscuro
];

/// Convierte «#RRGGBB» (con o sin almohadilla) en color; `null` si no es válido.
Color? colorDesdeHex(String texto) {
  final limpio = texto.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(limpio)) return null;
  return Color(int.parse('FF$limpio', radix: 16));
}

String hexDeColor(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Hoja inferior para cambiar un color: rejilla de colores de post-it y campo
/// para escribir un código HEX exacto. Devuelve `null` si se cancela.
Future<Color?> mostrarEditorColor(
  BuildContext context, {
  required String titulo,
  required Color inicial,
}) {
  return showModalBottomSheet<Color>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _EditorColorSheet(titulo: titulo, inicial: inicial),
  );
}

class _EditorColorSheet extends StatefulWidget {
  const _EditorColorSheet({required this.titulo, required this.inicial});

  final String titulo;
  final Color inicial;

  @override
  State<_EditorColorSheet> createState() => _EditorColorSheetState();
}

class _EditorColorSheetState extends State<_EditorColorSheet> {
  late Color _color = widget.inicial;
  late final TextEditingController _hex = TextEditingController(
    text: hexDeColor(widget.inicial),
  );

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  void _elegir(Color color) {
    setState(() => _color = color);
    _hex.value = TextEditingValue(
      text: hexDeColor(color),
      selection: TextSelection.collapsed(offset: 7),
    );
  }

  void _alEscribir(String texto) {
    final color = colorDesdeHex(texto);
    // Siempre se reconstruye: el aviso y el botón dependen de si el código es válido.
    setState(() {
      if (color != null) _color = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hexValido = colorDesdeHex(_hex.text) != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.titulo,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Elige el color de tu post-it',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in coloresPostIt)
                  Semantics(
                    button: true,
                    label: 'Color ${hexDeColor(color)}',
                    selected: color == _color,
                    child: GestureDetector(
                      onTap: () => _elegir(color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color == _color
                                ? AppColors.primaryDark
                                : Colors.black12,
                            width: color == _color ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _hex,
              onChanged: _alEscribir,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[#0-9a-fA-F]')),
                LengthLimitingTextInputFormatter(7),
              ],
              decoration: InputDecoration(
                labelText: 'Código de color (HEX)',
                hintText: '#F9D71C',
                errorText: hexValido ? null : 'Escribe 6 letras o números',
                suffixIcon: IconButton(
                  tooltip: 'Copiar código',
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: hexDeColor(_color)),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${hexDeColor(_color)} copiado')),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: hexValido
                  ? () => Navigator.pop(context, _color)
                  : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Usar este color'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
