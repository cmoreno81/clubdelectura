import 'package:flutter/material.dart';

import '../../models/amistad.dart';
import '../../navigation/app_page_route.dart';
import '../../pages/configurar_lectura_page.dart';
import '../../pages/lectura_page.dart';
import '../../services/amistades_cambios.dart';
import '../../services/api_service.dart';
import '../../services/club_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../common/club_avatar.dart';
import '../common/club_card.dart';

/// Abre una lectura a la vez con una amistad. Esas lecturas viven en un club
/// privado de la pareja: se activa mientras lees y luego se vuelve al club
/// que tenías activo. Si [configurar] es true (recién creada), primero se
/// prepara la lectura (capítulos, metas) como en cualquier club.
Future<void> abrirLecturaConAmistad(
  BuildContext context, {
  required String clubId,
  required String libro,
  bool configurar = false,
}) async {
  final nav = Navigator.of(context);
  final mensajes = ScaffoldMessenger.of(context);
  final servicio = ClubService();
  String? anterior;
  try {
    anterior = (await servicio.getMyClubs()).activeClubId;
    await servicio.selectClub(clubId);
  } catch (_) {
    mensajes.showSnackBar(
      const SnackBar(content: Text('No se ha podido abrir la lectura.')),
    );
    return;
  }
  try {
    var abrir = true;
    if (configurar) {
      final creada = await nav.push<bool>(
        AppPageRoute(builder: (_) => ConfigurarLecturaPage(libro: libro)),
      );
      abrir = creada == true;
    }
    if (abrir) {
      await nav.push<void>(
        AppPageRoute(builder: (_) => LecturaPage(libro: libro)),
      );
    }
  } finally {
    if (anterior != null && anterior != clubId) {
      try {
        await servicio.selectClub(anterior);
      } catch (_) {}
    }
    AmistadesCambios.avisar();
  }
}

/// Botón de la ficha de un libro para leerlo a la vez con una amistad.
class BotonLeerConAmistad extends StatelessWidget {
  const BotonLeerConAmistad({
    super.key,
    required this.bookId,
    required this.titulo,
    this.espacioDespues = 0,
  });

  final String bookId;
  final String titulo;
  final double espacioDespues;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: espacioDespues),
      child: OutlinedButton.icon(
        onPressed: () =>
            mostrarLeerConAmistad(context, bookId: bookId, titulo: titulo),
        icon: const Icon(Icons.menu_book_rounded),
        label: const Text('Leer a la vez con una amistad'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}

Future<void> mostrarLeerConAmistad(
  BuildContext context, {
  required String bookId,
  required String titulo,
  Future<AmistadesData> Function()? cargar,
  Future<ResultadoAmistad> Function({
    required String bookId,
    required String nombre,
  })?
  crear,
}) async {
  final resultado = await showModalBottomSheet<ResultadoAmistad>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => LeerConAmistadSheet(
      bookId: bookId,
      titulo: titulo,
      cargar: cargar,
      crear: crear,
    ),
  );
  if (resultado == null || !context.mounted) return;
  await abrirLecturaConAmistad(
    context,
    clubId: resultado.clubId,
    libro: resultado.libro.isEmpty ? titulo : resultado.libro,
    configurar: !resultado.yaExistia,
  );
}

class LeerConAmistadSheet extends StatefulWidget {
  const LeerConAmistadSheet({
    super.key,
    required this.bookId,
    required this.titulo,
    this.cargar,
    this.crear,
  });

  final String bookId;
  final String titulo;
  final Future<AmistadesData> Function()? cargar;
  final Future<ResultadoAmistad> Function({
    required String bookId,
    required String nombre,
  })?
  crear;

  @override
  State<LeerConAmistadSheet> createState() => _LeerConAmistadSheetState();
}

class _LeerConAmistadSheetState extends State<LeerConAmistadSheet> {
  late final Future<AmistadesData> _amistades =
      (widget.cargar ?? ApiService().getAmistades)();
  String? _elegida;
  bool _enviando = false;

  Future<void> _empezar() async {
    final nombre = _elegida;
    if (nombre == null || _enviando) return;
    setState(() => _enviando = true);
    final r = await (widget.crear ?? ApiService().crearLecturaConAmistad)(
      bookId: widget.bookId,
      nombre: nombre,
    );
    if (!mounted) return;
    if (!r.ok || r.clubId.isEmpty) {
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            r.mensaje.isEmpty
                ? 'No se ha podido crear la lectura. Inténtalo de nuevo.'
                : r.mensaje,
          ),
        ),
      );
      return;
    }
    Navigator.pop(context, r);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leer a la vez con una amistad',
            style: AppTextStyles.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Elige con quién quieres leer «${widget.titulo}». Tendréis vuestro '
            'propio espacio privado con capítulos, comentarios y metas.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: FutureBuilder<AmistadesData>(
              future: _amistades,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No se han podido cargar tus amistades. Inténtalo más tarde.',
                      style: AppTextStyles.bodySecondary,
                    ),
                  );
                }
                final lista =
                    snapshot.data?.amistades ?? const <PersonaAmistad>[];
                if (lista.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Todavía no tienes amistades en ClubReads. Añade alguna '
                      'desde Amistades y vuelve aquí.',
                      style: AppTextStyles.bodySecondary,
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: RadioGroup<String>(
                        groupValue: _elegida,
                        onChanged: (v) {
                          if (!_enviando) setState(() => _elegida = v);
                        },
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            for (final a in lista)
                              RadioListTile<String>(
                                value: a.nombre,
                                title: Text(a.nombre),
                                secondary: ClubAvatar(
                                  nombre: a.nombre,
                                  imageUrl: a.avatarUrl,
                                  size: 32,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: _enviando || _elegida == null
                          ? null
                          : _empezar,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Text(
                        _elegida == null
                            ? 'Elige una amistad'
                            : 'Invitar a $_elegida',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección de Amistades: invitaciones recibidas y lecturas a la vez en curso.
/// No ocupa nada si no hay ni lo uno ni lo otro (o si el servidor es antiguo).
class LecturasConAmistadesSeccion extends StatefulWidget {
  const LecturasConAmistadesSeccion({
    super.key,
    this.cargar,
    this.responder,
    this.abrir,
    this.soloCon,
    this.salir,
    this.titulo = 'Lecturas a la vez 📖',
    this.textoVacio,
  });

  /// Para pruebas: sustituye la llamada para salir o eliminar.
  final Future<ResultadoAmistad> Function(String clubId, bool eliminar)? salir;

  /// Si se indica, solo se enseña lo que hay con esa amistad (en su perfil).
  final String? soloCon;
  final String titulo;

  /// Si se indica, en vez de ocultarse cuando no hay nada, enseña este mensaje.
  final String? textoVacio;

  final Future<LecturasAmistadesData> Function()? cargar;
  final Future<ResultadoAmistad> Function(String clubId, bool aceptar)?
  responder;

  /// Para pruebas: sustituye la apertura real de la lectura.
  final Future<void> Function(String clubId, String libro)? abrir;

  @override
  State<LecturasConAmistadesSeccion> createState() =>
      _LecturasConAmistadesSeccionState();
}

class _LecturasConAmistadesSeccionState
    extends State<LecturasConAmistadesSeccion> {
  LecturasAmistadesData? _data;
  final Set<String> _ocupadas = {};
  bool _verTerminadas = false;

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
      final todo = await (widget.cargar ?? ApiService().getLecturasAmistades)();
      if (!mounted) return;
      final con = widget.soloCon?.toLowerCase();
      setState(
        () => _data = con == null
            ? todo
            : LecturasAmistadesData(
                recibidas: todo.recibidas
                    .where((i) => i.de.toLowerCase() == con)
                    .toList(),
                lecturas: todo.lecturas
                    .where((l) => l.con.toLowerCase() == con)
                    .toList(),
              ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _data = null);
    }
  }

  Future<void> _responder(InvitacionLecturaAmistad i, bool aceptar) async {
    if (_ocupadas.contains(i.clubId)) return;
    setState(() => _ocupadas.add(i.clubId));
    final r = await (widget.responder ?? ApiService().responderLecturaAmistad)(
      i.clubId,
      aceptar,
    );
    if (!mounted) return;
    setState(() => _ocupadas.remove(i.clubId));
    if (!r.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            r.mensaje.isEmpty ? 'No se ha podido responder.' : r.mensaje,
          ),
        ),
      );
    }
    await _cargar();
    if (r.ok && aceptar && mounted) {
      await _abrir(i.clubId, i.libro);
    }
  }

  Future<void> _abrir(String clubId, String libro) {
    final abrir = widget.abrir;
    if (abrir != null) return abrir(clubId, libro);
    return abrirLecturaConAmistad(context, clubId: clubId, libro: libro);
  }

  Future<void> _salir(LecturaConAmistad l, {required bool eliminar}) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(eliminar ? 'Eliminar para las dos' : 'Salir de la lectura'),
        content: Text(
          eliminar
              ? 'Se borrará «${l.libro}» y toda su conversación para ${l.con} '
                    'y para ti. No se puede deshacer.'
              : 'Dejarás de ver «${l.libro}». ${l.con} conservará la '
                    'conversación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(eliminar ? 'Eliminar' : 'Salir'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final r =
        await (widget.salir ??
            (id, borrar) => ApiService().salirLecturaAmistad(
              id,
              eliminar: borrar,
            ))(l.clubId, eliminar);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          r.ok
              ? (eliminar ? 'Lectura eliminada.' : 'Has salido de la lectura.')
              : (r.mensaje.isEmpty ? 'No se ha podido completar.' : r.mensaje),
        ),
      ),
    );
    await _cargar();
    AmistadesCambios.avisar();
  }

  Widget _tarjeta(LecturaConAmistad l) {
    final subtitulo = l.esperando
        ? 'Con ${l.con} · esperando su respuesta'
        : l.salio
        ? '${l.con} ha salido · puedes seguir consultándola'
        : l.terminada
        ? 'Terminada ✓ · Con ${l.con}'
        : 'Con ${l.con}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClubCard(
        elevated: false,
        onTap: () => _abrir(l.clubId, l.libro),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ClubAvatar(nombre: l.con, imageUrl: l.avatarUrl, size: 36),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.libro,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(subtitulo, style: AppTextStyles.caption),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Más opciones',
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (accion) => _salir(l, eliminar: accion == 'eliminar'),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'salir',
                  child: Text(
                    l.esperando ? 'Cancelar invitación' : 'Salir de la lectura',
                  ),
                ),
                if (l.esDuena && !l.esperando)
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Text('Eliminar para las dos'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();
    if (data.vacia && widget.textoVacio == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(widget.titulo, style: AppTextStyles.section),
        ),
        if (data.vacia)
          Text(widget.textoVacio!, style: AppTextStyles.bodySecondary),
        for (final i in data.recibidas)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ClubCard(
              elevated: false,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClubAvatar(nombre: i.de, imageUrl: i.avatarUrl, size: 36),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${i.de} te propone leer «${i.libro}» a la vez',
                          style: AppTextStyles.body,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: _ocupadas.contains(i.clubId)
                            ? null
                            : () => _responder(i, true),
                        child: const Text('Aceptar'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      TextButton(
                        onPressed: _ocupadas.contains(i.clubId)
                            ? null
                            : () => _responder(i, false),
                        child: const Text('Rechazar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        for (final l in data.enCurso) _tarjeta(l),
        if (data.terminadas.isNotEmpty) ...[
          InkWell(
            onTap: () => setState(() => _verTerminadas = !_verTerminadas),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Terminadas ✓ (${data.terminadas.length})',
                      style: AppTextStyles.section,
                    ),
                  ),
                  Icon(
                    _verTerminadas
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (_verTerminadas) ...[
            for (final l in data.terminadas) _tarjeta(l),
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'Sus conversaciones se conservan: tócalo para volver a verlas.',
                style: AppTextStyles.caption,
              ),
            ),
        ],
      ],
    );
  }
}
