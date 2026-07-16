import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_spacing.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class EditarAvatarDialog extends StatefulWidget {
  final String avatarUrlActual;

  const EditarAvatarDialog({super.key, this.avatarUrlActual = ''});

  @override
  State<EditarAvatarDialog> createState() => _EditarAvatarDialogState();
}

class _EditarAvatarDialogState extends State<EditarAvatarDialog> {
  late final TextEditingController _controller;
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imagenSeleccionada;
  String? _imagenBase64;
  bool _procesandoImagen = false;

  String get _url => _controller.text.trim();

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.avatarUrlActual);

    _controller.addListener(_actualizarVista);
  }

  Future<void> _elegirImagen(ImageSource source) async {
    try {
      final archivo = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (archivo == null) return;

      setState(() {
        _procesandoImagen = true;
      });

      final bytesOriginales = await archivo.readAsBytes();
      final imagenDecodificada = img.decodeImage(bytesOriginales);

      if (imagenDecodificada == null) {
        throw Exception('No se ha podido leer la imagen');
      }

      final lado = imagenDecodificada.width < imagenDecodificada.height
          ? imagenDecodificada.width
          : imagenDecodificada.height;

      final recortada = img.copyCrop(
        imagenDecodificada,
        x: (imagenDecodificada.width - lado) ~/ 2,
        y: (imagenDecodificada.height - lado) ~/ 2,
        width: lado,
        height: lado,
      );

      final redimensionada = img.copyResize(
        recortada,
        width: 800,
        height: 800,
        interpolation: img.Interpolation.average,
      );

      final jpeg = Uint8List.fromList(
        img.encodeJpg(redimensionada, quality: 82),
      );

      final base64 = base64Encode(jpeg);

      if (!mounted) return;

      setState(() {
        _imagenSeleccionada = jpeg;
        _imagenBase64 = 'data:image/jpeg;base64,$base64';
        _controller.clear();
        _procesandoImagen = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _procesandoImagen = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is Exception
                ? error.toString().replaceFirst('Exception: ', '')
                : 'No se ha podido seleccionar la imagen',
          ),
        ),
      );
    }
  }

  void _actualizarVista() {
    if (_controller.text.trim().isNotEmpty &&
        (_imagenSeleccionada != null || _imagenBase64 != null)) {
      _imagenSeleccionada = null;
      _imagenBase64 = null;
    }

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

    setState(() {
      _imagenSeleccionada = null;
      _imagenBase64 = null;
    });

    if (texto.isEmpty) return;

    _controller.text = texto;
    _controller.selection = TextSelection.collapsed(offset: texto.length);
  }

  void _guardar() {
    if (_procesandoImagen) {
      return;
    }

    if (_imagenBase64 != null) {
      Navigator.pop<String>(context, _imagenBase64);
      return;
    }

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
            _AvatarPreview(
              imageUrl: urlValida ? _url : '',
              imageBytes: _imagenSeleccionada,
              loading: _procesandoImagen,
            ),
            const SizedBox(height: AppSpacing.lg),
            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _procesandoImagen
                    ? null
                    : () => _elegirImagen(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Elegir de la galería'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _procesandoImagen
                    ? null
                    : () => _elegirImagen(ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Hacer una foto'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'o pega una URL',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
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
  final Uint8List? imageBytes;
  final bool loading;

  const _AvatarPreview({
    required this.imageUrl,
    required this.imageBytes,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget contenido;

    if (loading) {
      contenido = const Center(child: CircularProgressIndicator());
    } else if (imageBytes != null) {
      contenido = Image.memory(
        imageBytes!,
        fit: BoxFit.cover,
        width: 116,
        height: 116,
      );
    } else if (imageUrl.isNotEmpty) {
      contenido = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 116,
        height: 116,
        errorBuilder: (_, _, _) {
          return const _AvatarFallback();
        },
      );
    } else {
      contenido = const _AvatarFallback();
    }

    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primaryContainer,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.22),
          width: 2,
        ),
      ),
      child: ClipOval(child: contenido),
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
