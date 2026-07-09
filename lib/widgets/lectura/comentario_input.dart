import 'package:flutter/material.dart';

class ComentarioInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onEnviar;
  final bool enviando;
  final String hintText;

  const ComentarioInput({
    super.key,
    required this.controller,
    required this.onEnviar,
    required this.enviando,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !enviando,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(width: 12),

            FilledButton(
              onPressed: onEnviar,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: enviando
                    ? const Row(
                        key: ValueKey("publicando"),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text("Publicando..."),
                        ],
                      )
                    : const Row(
                        key: ValueKey("enviar"),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 6),
                          Text("Enviar"),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
