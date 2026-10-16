import 'package:flutter/material.dart';

import '../models/amistad.dart';
import '../navigation/app_page_route.dart';
import '../services/amistades_cambios.dart';
import '../services/api_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_card.dart';
import '../widgets/tablet/detalle_lateral.dart';
import 'perfil_amistad_page.dart';

/// Desde cuántos amigos aparece el buscador de la lista.
const int amigosParaBuscar = 8;

/// La lista completa de tus amigos: se abre al pulsar el cuadro «amigos» de
/// la pantalla Amigos. Pulsar a alguien abre su perfil; el icono lo quita.
class ListaAmigosPage extends StatefulWidget {
  const ListaAmigosPage({super.key, required this.amistades, this.quitar});

  final List<PersonaAmistad> amistades;

  /// Para sustituir la llamada al servidor (pruebas).
  final Future<ResultadoAmistad> Function(String nombre)? quitar;

  @override
  State<ListaAmigosPage> createState() => _ListaAmigosPageState();
}

class _ListaAmigosPageState extends State<ListaAmigosPage> {
  late final List<PersonaAmistad> _amistades = List.of(widget.amistades);
  final TextEditingController _filtroCtrl = TextEditingController();
  final Set<String> _ocupadas = {};
  String _filtro = '';

  @override
  void dispose() {
    _filtroCtrl.dispose();
    super.dispose();
  }

  void _aviso(String texto) {
    if (!mounted || texto.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _quitar(String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Quitar a $nombre de tus amigos?'),
        content: const Text(
          'Dejaréis de veros lo que leéis. Si quieres, podéis volver a '
          'añadiros más adelante.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted || _ocupadas.contains(nombre)) return;
    setState(() => _ocupadas.add(nombre));
    final resultado = await (widget.quitar ?? ApiService().quitarAmistad)(
      nombre,
    );
    if (!mounted) return;
    setState(() => _ocupadas.remove(nombre));
    if (!resultado.ok) {
      _aviso(resultado.mensaje);
      return;
    }
    setState(() => _amistades.removeWhere((p) => p.nombre == nombre));
    AmistadesCambios.avisar();
    _aviso(
      resultado.mensaje.isNotEmpty ? resultado.mensaje : 'Amigo eliminado.',
    );
  }

  List<PersonaAmistad> get _visibles {
    final f = _filtro.trim().toLowerCase();
    if (f.isEmpty) return _amistades;
    return _amistades.where((p) => p.nombre.toLowerCase().contains(f)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _visibles;
    return Scaffold(
      appBar: AppBar(title: const Text('Tus amigos')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (_amistades.length >= amigosParaBuscar) ...[
            TextField(
              key: const Key('lista-amigos-filtro'),
              controller: _filtroCtrl,
              onChanged: (v) => setState(() => _filtro = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar entre tus amigos',
                suffixIcon: _filtro.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Borrar',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _filtroCtrl.clear();
                          setState(() => _filtro = '');
                        },
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_amistades.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'Todavía no tienes amigos en ClubReads. Busca a alguien por su '
                'nombre o comparte tu código.',
                style: AppTextStyles.bodySecondary,
              ),
            )
          else if (visibles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'Nadie se llama así entre tus amigos.',
                style: AppTextStyles.bodySecondary,
              ),
            )
          else
            for (final p in visibles) _fila(p),
        ],
      ),
    );
  }

  Widget _fila(PersonaAmistad p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClubCard(
        elevated: false,
        onTap: () => empujarDetalle<void>(
          context,
          AppPageRoute(builder: (_) => PerfilAmistadPage(nombre: p.nombre)),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            ClubAvatar(nombre: p.nombre, imageUrl: p.avatarUrl, size: 44),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (p.clubEnComun.isNotEmpty)
                    Text(
                      'De tu club «${p.clubEnComun}»',
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Quitar amigo',
              icon: const Icon(Icons.person_remove_outlined),
              onPressed: _ocupadas.contains(p.nombre)
                  ? null
                  : () => _quitar(p.nombre),
            ),
          ],
        ),
      ),
    );
  }
}
