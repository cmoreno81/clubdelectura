import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

/// Foto adjunta a un comentario. Al tocarla se abre a pantalla completa.
class FotoComentarioWidget extends StatelessWidget {
  const FotoComentarioWidget({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      image: true,
      label: 'Foto del comentario. Toca para ampliar',
      child: GestureDetector(
        onTap: () => FotoComentarioVisor.abrir(context, url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: Image.network(
              url,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progreso) => progreso == null
                  ? child
                  : const SizedBox(
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
              errorBuilder: (context, error, stack) => Container(
                height: 120,
                alignment: Alignment.center,
                color: AppColors.surfaceSoft,
                child: const Text('No se ha podido cargar la foto'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FotoComentarioVisor extends StatelessWidget {
  const FotoComentarioVisor({super.key, required this.url});

  final String url;

  static Future<void> abrir(BuildContext context, String url) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, _, _) => FotoComentarioVisor(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) => const Text(
                      'No se ha podido cargar la foto',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
