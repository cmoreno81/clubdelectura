import 'package:flutter/material.dart';

class ComentarioInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onEnviar;
  final bool enviando;
  final String hintText;
  final bool esReflexion;
  final VoidCallback? onCerrar;
  final FocusNode? focusNode;

  const ComentarioInput({
    super.key,
    required this.controller,
    required this.onEnviar,
    required this.enviando,
    required this.hintText,
    this.esReflexion = false,
    this.onCerrar,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final tecladoAbierto = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 8,
      shadowColor: Colors.black12,
      child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(
            16,
            tecladoAbierto ? 6 : 14,
            16,
            tecladoAbierto ? 6 : 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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

                /*
                 * Con teclado abierto limitamos la altura.
                 * El texto largo continúa mediante scroll interno.
                 */
                minLines: tecladoAbierto
                    ? 2
                    : esReflexion
                    ? 3
                    : 3,

                maxLines: tecladoAbierto
                    ? esReflexion
                          ? 4
                          : 3
                    : esReflexion
                    ? 6
                    : 6,

                maxLength: 5000,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                scrollPadding: const EdgeInsets.only(bottom: 180),

                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),

                  filled: true,
                  fillColor: const Color(0xFFF7F1FF),
                  alignLabelWithHint: true,

                  prefixIcon: Padding(
                    padding: EdgeInsets.only(
                      left: 14,
                      right: 10,
                      bottom: tecladoAbierto
                          ? 20
                          : esReflexion
                          ? 90
                          : 35,
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFF6F4DBF),
                      size: 26,
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
}
