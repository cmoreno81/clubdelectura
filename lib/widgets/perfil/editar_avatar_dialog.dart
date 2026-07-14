import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_spacing.dart';

class EditarAvatarDialog extends StatefulWidget {
  final String avatarUrlActual;

  const EditarAvatarDialog({super.key, this.avatarUrlActual = ''});

  @override
  State<EditarAvatarDialog> createState() => _EditarAvatarDialogState();
}

class _EditarAvatarDialogState extends State<EditarAvatarDialog> {
  late final TextEditingController _controller;

  String get _url => _controller.text.trim();

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.avatarUrlActual);

    _controller.addListener(_actualizarVista);
  }

  void _actualizarVista() {
    setState(() {});
  }

  bool _urlValida(String valor) {
    if (valor.isEmpty) return true;

    final uri = Uri.tryParse(valor);

    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  Future<void> _pegar() async {
    final datos = await Clipboard.getData(Clipboard.kTextPlain);
    final texto = datos?.text?.trim() ?? '';

    if (texto.isEmpty) return;

    _controller.text = texto;
    _controller.selection = TextSelection.collapsed(offset: texto.length);
  }

  void _guardar() {
    if (!_urlValida(_url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introduce una URL de imagen válida.')),
      );
      return;
    }

    Navigator.pop<String>(context, _url);
  }

  @override
  Widget build(BuildContext context) {
    final urlValida = _urlValida(_url);

    return AlertDialog(
      title: const Text('Foto de perfil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AvatarPreview(imageUrl: urlValida ? _url : ''),

            const SizedBox(height: AppSpacing.lg),

            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'URL de la imagen',
                hintText: 'https://...',
                prefixIcon: const Icon(Icons.image_outlined),
                suffixIcon: IconButton(
                  tooltip: 'Pegar',
                  onPressed: _pegar,
                  icon: const Icon(Icons.content_paste_rounded),
                ),
                errorText: urlValida ? null : 'La URL no parece válida',
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            const Text(
              'Puedes dejar el campo vacío para eliminar la foto actual.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: _guardar,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_actualizarVista)
      ..dispose();

    super.dispose();
  }
}

class _AvatarPreview extends StatelessWidget {
  final String imageUrl;

  const _AvatarPreview({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.22),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return const _AvatarFallback();
                },
              )
            : const _AvatarFallback(),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.person_rounded,
      size: 54,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
