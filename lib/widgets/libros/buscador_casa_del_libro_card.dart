import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/colores_compra.dart';
import '../ui/etiqueta_publicidad.dart';

/// «¿No encuentras lo que buscas? Búscalo en Casa del Libro»: abre la búsqueda
/// de la tienda con la campaña de afiliado de ClubReads. Lo escrito solo viaja
/// a la tienda al pulsar «Buscar».
class BuscadorCasaDelLibroCard extends StatefulWidget {
  const BuscadorCasaDelLibroCard({super.key, this.obtenerUrl, this.abrir});

  /// Para pruebas.
  final Future<String?> Function(String texto)? obtenerUrl;
  final Future<bool> Function(Uri url)? abrir;

  @override
  State<BuscadorCasaDelLibroCard> createState() =>
      BuscadorCasaDelLibroCardState();
}

class BuscadorCasaDelLibroCardState extends State<BuscadorCasaDelLibroCard> {
  final _texto = TextEditingController();
  final _foco = FocusNode();

  /// Pone el cursor en el campo (al llegar desde «Ir al buscador»).
  void enfocar() => _foco.requestFocus();
  bool _buscando = false;
  String? _aviso;

  @override
  void dispose() {
    _texto.dispose();
    _foco.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final q = _texto.text.trim();
    if (_buscando) return;
    if (q.length < 2) {
      setState(() => _aviso = 'Escribe el título o la autoría que buscas.');
      return;
    }
    setState(() {
      _buscando = true;
      _aviso = null;
    });
    String? aviso;
    try {
      final url =
          await (widget.obtenerUrl ??
              ApiService().getEnlaceBusquedaCasaDelLibro)(q);
      final uri = url == null ? null : Uri.tryParse(url);
      final abierto =
          uri != null &&
          await (widget.abrir ??
              (u) => launchUrl(u, mode: LaunchMode.externalApplication))(uri);
      if (!abierto) {
        aviso = 'No se ha podido abrir la tienda. Inténtalo de nuevo.';
      }
    } catch (_) {
      aviso = 'No se ha podido abrir la tienda. Inténtalo de nuevo.';
    }
    if (!mounted) return;
    setState(() {
      _buscando = false;
      _aviso = aviso;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('buscador-casa-del-libro'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: ColoresCompra.fondo,
        border: Border.all(color: ColoresCompra.borde),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search_rounded, color: ColoresCompra.verde),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '¿No encuentras lo que buscas?',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const EtiquetaPublicidad(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Búscalo en Casa del Libro. Enlace de afiliado: ClubReads puede '
            'recibir una comisión, sin coste extra para ti.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            key: const Key('buscador-casa-del-libro-texto'),
            controller: _texto,
            focusNode: _foco,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _buscar(),
            maxLength: 120,
            decoration: InputDecoration(
              hintText: 'Título o autoría',
              counterText: '',
              suffixIcon: IconButton(
                key: const Key('buscador-casa-del-libro-buscar'),
                tooltip: 'Buscar en Casa del Libro',
                onPressed: _buscando ? null : _buscar,
                icon: _buscando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ),
          if (_aviso != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_aviso!, style: AppTextStyles.caption),
            ),
          const SizedBox(height: 4),
          Text(
            'Al pulsar «Buscar», lo que escribas se envía a Casa del Libro.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
