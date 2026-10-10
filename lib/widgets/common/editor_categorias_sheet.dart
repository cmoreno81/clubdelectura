import 'package:flutter/material.dart';

import '../../models/subrayador_categoria.dart';
import '../../services/categorias_comentario_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';

/// Hoja para que cada lectora ponga nombre y emoji a sus 5 temas de subrayado.
/// Los nombres se guardan en su cuenta y el resto del club los ve en sus
/// comentarios. La categoría «Cita» sigue siendo una cita aunque se renombre.
Future<void> mostrarEditorCategorias(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _EditorCategoriasSheet(),
  );
}

class _EditorCategoriasSheet extends StatefulWidget {
  const _EditorCategoriasSheet();

  @override
  State<_EditorCategoriasSheet> createState() => _EditorCategoriasSheetState();
}

class _EditorCategoriasSheetState extends State<_EditorCategoriasSheet> {
  late final List<TextEditingController> _emojis;
  late final List<TextEditingController> _nombres;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final actuales = CategoriasComentarioService.categorias.value;
    _emojis = [for (final c in actuales) TextEditingController(text: c.emoji)];
    _nombres = [
      for (final c in actuales) TextEditingController(text: c.nombre),
    ];
  }

  @override
  void dispose() {
    for (final c in [..._emojis, ..._nombres]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valido => _nombres.every((c) => c.text.trim().isNotEmpty);

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final nuevas = [
      for (var i = 0; i < _nombres.length; i++)
        SubrayadorCategoria(
          emoji: _emojis[i].text.trim(),
          nombre: _nombres[i].text.trim(),
          esCita: kSubrayadorCategorias[i].esCita,
        ),
    ];
    final ok = await CategoriasComentarioService.guardar(nuevas);
    if (!mounted) return;
    Navigator.pop(context);
    _aviso(
      ok
          ? 'Tus temas se han guardado'
          : 'Se han guardado en este móvil, pero no en tu cuenta. '
                'Inténtalo de nuevo más tarde.',
    );
  }

  Future<void> _restablecer() async {
    setState(() => _guardando = true);
    final ok = await CategoriasComentarioService.restablecer();
    if (!mounted) return;
    Navigator.pop(context);
    _aviso(
      ok
          ? 'Vuelves a los temas de siempre'
          : 'Restablecidos en este móvil, pero no en tu cuenta.',
    );
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Mis temas de subrayado',
              style: AppTextStyles.body.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ponles el nombre que quieras. Tus compañeras verán estos '
              'nombres en tus comentarios.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 0; i < _nombres.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _emojis[i],
                      textAlign: TextAlign.center,
                      maxLength: CategoriasComentarioService.emojiMax,
                      buildCounter: _sinContador,
                      decoration: const InputDecoration(hintText: '🙂'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _nombres[i],
                      maxLength: CategoriasComentarioService.nombreMax,
                      textCapitalization: TextCapitalization.sentences,
                      buildCounter: _sinContador,
                      decoration: InputDecoration(
                        labelText: kSubrayadorCategorias[i].esCita
                            ? 'Cita (sigue siendo una cita)'
                            : 'Tema ${i + 1}',
                        errorText: _nombres[i].text.trim().isEmpty
                            ? 'Pon un nombre'
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.xs),
            FilledButton(
              onPressed: _valido && !_guardando ? _guardar : null,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Guardar mis temas'),
              ),
            ),
            TextButton(
              onPressed: _guardando ? null : _restablecer,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text('Volver a los temas de siempre'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget? _sinContador(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) => null;
}
