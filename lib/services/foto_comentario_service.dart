import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Foto lista para adjuntar a un comentario: los bytes para la vista previa y
/// el data URL que se envía al servidor.
class FotoComentario {
  const FotoComentario({required this.bytes, required this.dataUrl});

  final Uint8List bytes;
  final String dataUrl;

  /// El servidor admite 4 MB de base64 (~3 MB de imagen) por foto.
  static const maxBytes = 3 * 1024 * 1024;

  factory FotoComentario.desdeBytes(Uint8List bytes) => FotoComentario(
    bytes: bytes,
    dataUrl: 'data:image/jpeg;base64,${base64Encode(bytes)}',
  );

  bool get cabe => bytes.lengthInBytes <= maxBytes;
}

class FotoComentarioService {
  const FotoComentarioService();

  /// Abre la galería o la cámara. Devuelve `null` si se cancela o no se puede
  /// abrir. La imagen se reduce y se recodifica como JPEG antes de subirla.
  Future<FotoComentario?> elegir(ImageSource origen) async {
    try {
      final archivo = await ImagePicker().pickImage(
        source: origen,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );
      if (archivo == null) return null;
      return FotoComentario.desdeBytes(await archivo.readAsBytes());
    } on PlatformException {
      return null;
    }
  }
}
