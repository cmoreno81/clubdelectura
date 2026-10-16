import 'package:flutter/material.dart';

import '../../models/amistad.dart';
import '../../services/amistades_cambios.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_avatar.dart';
import 'aviso_en_hoja.dart';

/// «Retos entre amigos»: una meta de libros común, con una sola barra de
/// progreso y lo que aporta cada persona, sin clasificación.
class RetosAmigosSeccion extends StatefulWidget {
  const RetosAmigosSeccion({
    super.key,
    this.amistades = const [],
    this.cargar,
    this.crear,
    this.responder,
    this.salir,
  });

  /// Con quién se puede crear un reto.
  final List<PersonaAmistad> amistades;

  /// Para pruebas.
  final Future<List<RetoAmigos>> Function()? cargar;
  final Future<ResultadoAmistad> Function({
    required String titulo,
    required int objetivo,
    required String periodo,
    required List<String> nombres,
  })?
  crear;
  final Future<ResultadoAmistad> Function(String id, bool aceptar)? responder;
  final Future<ResultadoAmistad> Function(String id)? salir;

  @override
  State<RetosAmigosSeccion> createState() => _RetosAmigosSeccionState();
}

class _RetosAmigosSeccionState extends State<RetosAmigosSeccion> {
  List<RetoAmigos> _retos = const [];
  String? _aviso;

  @override
  void initState() {
    super.initState();
    AmistadesCambios.cambios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    AmistadesCambios.cambios.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final r = await (widget.cargar ?? ApiService().getRetosAmigos)();
      if (mounted) setState(() => _retos = r);
    } catch (_) {
      // No sale.
    }
  }

  Future<void> _responder(RetoAmigos reto, bool aceptar) async {
    final r = await (widget.responder ?? ApiService().responderRetoAmigos)(
      reto.id,
      aceptar,
    );
    if (!mounted) return;
    setState(() => _aviso = r.ok ? null : r.mensaje);
    await _cargar();
  }

  Future<void> _salir(RetoAmigos reto) async {
    final seguro = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir del reto?'),
        content: Text('Dejarás de formar parte de «${reto.titulo}».'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (seguro != true) return;
    await (widget.salir ?? ApiService().salirRetoAmigos)(reto.id);
    if (mounted) await _cargar();
  }

  Future<void> _crear() async {
    final creado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CrearRetoHoja(
        amistades: widget.amistades,
        crear: widget.crear ?? ApiService().crearRetoAmigos,
      ),
    );
    if (creado == true && mounted) await _cargar();
  }

  @override
  Widget build(BuildContext context) {
    if (_retos.isEmpty && widget.amistades.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      key: const Key('amigos-retos'),
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Retos entre amigos', style: AppTextStyles.section),
              ),
              if (widget.amistades.isNotEmpty)
                TextButton.icon(
                  key: const Key('reto-crear'),
                  onPressed: _crear,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Crear reto'),
                ),
            ],
          ),
          if (_aviso != null) AvisoEnHoja(texto: _aviso),
          if (_retos.isEmpty)
            Text(
              'Poneos una meta de libros entre dos o más: una sola barra para todos, sin clasificación.',
              style: AppTextStyles.caption,
            ),
          for (final r in _retos)
            _TarjetaReto(
              key: ValueKey('reto-${r.id}'),
              reto: r,
              alResponder: (a) => _responder(r, a),
              alSalir: () => _salir(r),
            ),
        ],
      ),
    );
  }
}

String _unir(List<String> nombres) => nombres.length < 2
    ? nombres.join()
    : '${nombres.sublist(0, nombres.length - 1).join(', ')} y ${nombres.last}';

class _TarjetaReto extends StatelessWidget {
  const _TarjetaReto({
    super.key,
    required this.reto,
    required this.alResponder,
    required this.alSalir,
  });

  final RetoAmigos reto;
  final void Function(bool aceptar) alResponder;
  final VoidCallback alSalir;

  @override
  Widget build(BuildContext context) {
    final r = reto;
    final otras = r.personas.where((p) => !p.yo).map((p) => p.nombre).toList();
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.titulo,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!r.invitada)
                IconButton(
                  key: Key('reto-salir-${r.id}'),
                  tooltip: 'Salir del reto',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.logout, size: 18),
                  onPressed: alSalir,
                ),
            ],
          ),
          if (r.invitada)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                '${_unir(otras)} te propone${otras.length > 1 ? 'n' : ''} '
                'leer ${r.objetivo} libros entre todos.',
                style: AppTextStyles.caption,
              ),
            ),
          Text(
            r.conseguido
                ? '¡Lo habéis conseguido! ${r.total} libros 🎉'
                : '${r.total} de ${r.objetivo} libros entre todos',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: r.progreso,
              minHeight: 8,
              backgroundColor: Colors.white,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: 6,
            children: [
              for (final p in r.personas)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClubAvatar(
                      nombre: p.nombre,
                      imageUrl: p.avatarUrl,
                      size: 24,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p.aceptado
                          ? '${p.yo ? 'Tú' : p.nombre} · ${p.libros}'
                          : '${p.yo ? 'Tú' : p.nombre} · pendiente',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
            ],
          ),
          if (r.invitada)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                children: [
                  FilledButton(
                    key: Key('reto-aceptar-${r.id}'),
                    onPressed: () => alResponder(true),
                    child: const Text('Me apunto'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    key: Key('reto-rechazar-${r.id}'),
                    onPressed: () => alResponder(false),
                    child: const Text('Ahora no'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CrearRetoHoja extends StatefulWidget {
  const _CrearRetoHoja({required this.amistades, required this.crear});

  final List<PersonaAmistad> amistades;
  final Future<ResultadoAmistad> Function({
    required String titulo,
    required int objetivo,
    required String periodo,
    required List<String> nombres,
  })
  crear;

  @override
  State<_CrearRetoHoja> createState() => _CrearRetoHojaState();
}

class _CrearRetoHojaState extends State<_CrearRetoHoja> {
  final _titulo = TextEditingController(text: 'Nuestro reto');
  final _elegidas = <String>{};
  int _objetivo = 5;
  String _periodo = 'MES';
  bool _enviando = false;
  String? _aviso;

  @override
  void dispose() {
    _titulo.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_elegidas.isEmpty) {
      setState(() => _aviso = 'Elige al menos a un amigo.');
      return;
    }
    setState(() {
      _enviando = true;
      _aviso = null;
    });
    final r = await widget.crear(
      titulo: _titulo.text.trim(),
      objetivo: _objetivo,
      periodo: _periodo,
      nombres: _elegidas.toList(),
    );
    if (!mounted) return;
    if (r.ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _enviando = false;
        _aviso = r.mensaje;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Crear un reto', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('reto-titulo'),
              controller: _titulo,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Nombre del reto'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Meta entre todos: $_objetivo libros',
                    style: AppTextStyles.body,
                  ),
                ),
                IconButton(
                  key: const Key('reto-menos'),
                  onPressed: _objetivo > 1
                      ? () => setState(() => _objetivo--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  key: const Key('reto-mas'),
                  onPressed: _objetivo < 200
                      ? () => setState(() => _objetivo++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'MES', label: Text('Este mes')),
                ButtonSegment(value: 'ANO', label: Text('Este año')),
              ],
              selected: {_periodo},
              onSelectionChanged: (s) => setState(() => _periodo = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('¿Con quién? (hasta 4)', style: AppTextStyles.section),
            const SizedBox(height: 4),
            for (final p in widget.amistades)
              CheckboxListTile(
                key: Key('reto-amiga-${p.nombre}'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.trailing,
                secondary: ClubAvatar(
                  nombre: p.nombre,
                  imageUrl: p.avatarUrl,
                  size: 36,
                ),
                title: Text(p.nombre),
                value: _elegidas.contains(p.nombre),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    if (_elegidas.length < 4) _elegidas.add(p.nombre);
                  } else {
                    _elegidas.remove(p.nombre);
                  }
                }),
              ),
            const SizedBox(height: AppSpacing.sm),
            AvisoEnHoja(texto: _aviso),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('reto-enviar'),
                onPressed: _enviando ? null : _enviar,
                child: const Text('Proponer el reto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Rachas juntas»: días seguidos en que tú y una amistad habéis hecho
/// check-in. Solo salen rachas de dos días o más.
class RachasCompartidasSeccion extends StatefulWidget {
  const RachasCompartidasSeccion({super.key, this.cargar});

  /// Para pruebas.
  final Future<List<RachaCompartida>> Function()? cargar;

  @override
  State<RachasCompartidasSeccion> createState() =>
      _RachasCompartidasSeccionState();
}

class _RachasCompartidasSeccionState extends State<RachasCompartidasSeccion> {
  List<RachaCompartida> _items = const [];

  @override
  void initState() {
    super.initState();
    AmistadesCambios.cambios.addListener(_cargar);
    _cargar();
  }

  @override
  void dispose() {
    AmistadesCambios.cambios.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final r = await (widget.cargar ?? ApiService().getRachasCompartidas)();
      if (mounted) setState(() => _items = r.take(4).toList());
    } catch (_) {
      // No sale.
    }
  }

  String _pista(RachaCompartida r) {
    if (r.yoHoy && r.ellaHoy) return 'Hoy habéis leído los dos';
    if (r.ellaHoy) return 'Hoy ya ha leído ${r.nombre}: te toca';
    if (r.yoHoy) return 'Hoy ya has leído tú: le toca a ${r.nombre}';
    return 'Hoy aún no ha leído ninguna';
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: const Key('amigos-rachas'),
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rachas juntas', style: AppTextStyles.section),
          const SizedBox(height: AppSpacing.sm),
          for (final r in _items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  ClubAvatar(nombre: r.nombre, imageUrl: r.avatarUrl, size: 40),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tú y ${r.nombre}',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(_pista(r), style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Text(
                    '🔥 ${r.dias} días',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
