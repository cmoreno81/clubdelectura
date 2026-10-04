import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../ui/club_section_card.dart';

/// "Comprar en Casa del Libro" — enlace de afiliado (Awin). El código de
/// conducta de publicidad exige identificarlo como publicidad y de forma
/// visible, por eso la etiqueta "Publicidad" va siempre en la propia tarjeta.
class ComprarLibroCard extends StatefulWidget {
  const ComprarLibroCard({super.key, required this.bookId});

  final String bookId;

  @override
  State<ComprarLibroCard> createState() => _ComprarLibroCardState();
}

class _ComprarLibroCardState extends State<ComprarLibroCard> {
  bool _abriendo = false;
  EnlaceCompra? _enlace;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant ComprarLibroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId) {
      _enlace = null;
      _cargar();
    }
  }

  Future<EnlaceCompra?> _cargar() async {
    if (widget.bookId.isEmpty) return null;
    final bookId = widget.bookId;
    try {
      final enlace = await ApiService().getEnlaceCompra(bookId);
      if (mounted && bookId == widget.bookId) {
        setState(() => _enlace = enlace);
      }
      return enlace;
    } catch (_) {
      return null;
    }
  }

  Future<void> _abrir([String? url]) async {
    if (_abriendo || widget.bookId.isEmpty) return;
    setState(() => _abriendo = true);
    try {
      final destino = url ?? (_enlace ?? await _cargar())?.url;
      if (!mounted) return;
      final uri = destino == null ? null : Uri.tryParse(destino);
      final abierto = uri != null &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!abierto && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se ha podido abrir la tienda.')),
        );
      }
    } finally {
      if (mounted) setState(() => _abriendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bookId.isEmpty) return const SizedBox.shrink();
    return ClubSectionCard(
      onTap: _abrir,
      backgroundColor: const Color(0xFFF1F7F2),
      borderColor: const Color(0xFFCFE3D3),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFDDEEDF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _abriendo
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF3F7A4D),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Comprar en Casa del Libro',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDEEDF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Publicidad',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3F7A4D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Enlace de afiliado: ClubReads puede recibir una comisión, '
                  'sin coste extra para ti.',
                  style: AppTextStyles.bodySecondary,
                ),
                if ((_enlace?.formatos.length ?? 0) > 1) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final f in _enlace!.formatos)
                        ActionChip(
                          label: Text(f.etiqueta),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: f.formato == _enlace!.formato
                              ? const Color(0xFFDDEEDF)
                              : Colors.white,
                          side: const BorderSide(color: Color(0xFFCFE3D3)),
                          onPressed: () => _abrir(f.url),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF3F7A4D)),
        ],
      ),
    );
  }
}
