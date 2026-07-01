import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String? titulo;
  final String? mensaje;
  final VoidCallback? onRetry;

  const ErrorView({super.key, this.titulo, this.mensaje, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 72,
              color: Colors.deepPurple,
            ),

            const SizedBox(height: 24),

            Text(
              titulo ?? "Ups... algo ha salido mal",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Text(
              mensaje ??
                  "No hemos podido conectar con el Club de Lectura.\n\n"
                      "Comprueba tu conexión e inténtalo de nuevo.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),

            if (onRetry != null) ...[
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text("Reintentar"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
