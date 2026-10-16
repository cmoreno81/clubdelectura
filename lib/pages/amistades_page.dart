import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/amistad.dart';
import '../services/api_exception.dart';
import '../services/amistades_cambios.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/amistades/lectura_con_amistad.dart';
import '../widgets/amistades/panel_amigos.dart';
import '../widgets/amistades/retos_amigos.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/floating_nav_bar.dart';
import '../widgets/inicio/actividad_amistades_card.dart';
import '../widgets/common/club_card.dart';
import '../widgets/error_view.dart';
import 'perfil_amistad_page.dart';

/// Amistades: buscar a gente, enviar y responder solicitudes, tu código para
/// compartir y la lista de tus amistades.
class AmistadesPage extends StatefulWidget {
  const AmistadesPage({super.key, this.cargar, this.embebida = false});

  /// Como pestaña de la barra de las cuentas personales: sin flecha atrás y
  /// con margen para la barra flotante. El contenido es el mismo que desde Inicio.
  final bool embebida;

  /// Para pruebas: sustituye la carga real.
  final Future<AmistadesData> Function()? cargar;

  @override
  State<AmistadesPage> createState() => _AmistadesPageState();
}

class _AmistadesPageState extends State<AmistadesPage> {
  AmistadesData? _data;
  Object? _error;
  bool _cargando = true;

  final _codigoCtrl = TextEditingController();
  final _buscarCtrl = TextEditingController();
  Timer? _debounce;
  List<PersonaBuscada>? _resultados;
  String? _errorBusqueda;
  bool _buscando = false;
  int _busquedaId = 0;

  /// Destinos de los tres cuadros del resumen.
  final GlobalKey _claveAmigos = GlobalKey();
  final GlobalKey _claveRecibidas = GlobalKey();
  final GlobalKey _claveEnviadas = GlobalKey();

  /// Lleva a la sección; si no hay nada que enseñar, lo dice.
  void _irA(GlobalKey clave, {required String vacio}) {
    final destino = clave.currentContext;
    if (destino == null) {
      _aviso(vacio);
      return;
    }
    Scrollable.ensureVisible(
      destino,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  /// Nombres con una acción en curso, para desactivar sus botones.
  final Set<String> _ocupadas = {};

  @override
  void initState() {
    super.initState();
    _cargar();
    // Como pestaña, otras partes de la app (entrar en la pestaña, aceptar
    // desde un aviso…) pueden cambiar las amistades: se recarga sin parpadeo.
    if (widget.embebida) {
      AmistadesCambios.cambios.addListener(_recargarSilencioso);
    }
  }

  void _recargarSilencioso() => _cargar(silencioso: true);

  @override
  void dispose() {
    AmistadesCambios.cambios.removeListener(_recargarSilencioso);
    _debounce?.cancel();
    _codigoCtrl.dispose();
    _buscarCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso) setState(() => _cargando = true);
    try {
      final data = await (widget.cargar ?? ApiService().getAmistades)();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _cargando = false;
      });
    }
  }

  void _aviso(String texto) {
    if (!mounted || texto.isEmpty) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  // ── Buscar ───────────────────────────────────────────────────────────────

  void _alEscribirBusqueda(String texto) {
    _debounce?.cancel();
    final limpio = texto.trim();
    if (limpio.length < 3) {
      setState(() {
        _resultados = null;
        _errorBusqueda = null;
        _buscando = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _buscar(limpio));
  }

  Future<void> _buscar(String texto) async {
    final id = ++_busquedaId;
    setState(() {
      _buscando = true;
      _errorBusqueda = null;
    });
    try {
      final resultados = await ApiService().buscarPersonas(texto);
      if (!mounted || id != _busquedaId) return;
      setState(() {
        _resultados = resultados;
        _buscando = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _busquedaId) return;
      setState(() {
        _errorBusqueda = e.message;
        _buscando = false;
      });
    } catch (_) {
      if (!mounted || id != _busquedaId) return;
      setState(() {
        _errorBusqueda = 'No se ha podido buscar. Inténtalo de nuevo.';
        _buscando = false;
      });
    }
  }

  // ── Acciones ─────────────────────────────────────────────────────────────

  Future<void> _ejecutar(
    String nombre,
    Future<ResultadoAmistad> Function() accion, {
    String? okPorDefecto,
    void Function(ResultadoAmistad)? alTerminar,
  }) async {
    if (_ocupadas.contains(nombre)) return;
    setState(() => _ocupadas.add(nombre));
    final resultado = await accion();
    if (!mounted) return;
    setState(() => _ocupadas.remove(nombre));
    if (!resultado.ok) {
      _aviso(resultado.mensaje);
      return;
    }
    alTerminar?.call(resultado);
    AmistadesCambios.avisar();
    final texto = resultado.mensaje.isNotEmpty
        ? resultado.mensaje
        : (okPorDefecto ?? '');
    _aviso(texto);
    await _cargar(silencioso: true);
  }

  void _marcarEnBusqueda(String nombre, EstadoAmistad estado) {
    final lista = _resultados;
    if (lista == null) return;
    setState(() {
      _resultados = [
        for (final p in lista)
          p.nombre == nombre
              ? PersonaBuscada(
                  nombre: p.nombre,
                  avatarUrl: p.avatarUrl,
                  estado: estado,
                )
              : p,
      ];
    });
  }

  Future<void> _solicitar(PersonaBuscada persona) => _ejecutar(
    persona.nombre,
    () => ApiService().solicitarAmistad(nombre: persona.nombre),
    okPorDefecto: 'Solicitud enviada.',
    alTerminar: (r) =>
        _marcarEnBusqueda(persona.nombre, r.estado ?? EstadoAmistad.enviada),
  );

  Future<void> _aceptar(String nombre) => _ejecutar(
    nombre,
    () => ApiService().responderAmistad(nombre, true),
    okPorDefecto: '¡Ya sois amigos! 🎉',
  );

  Future<void> _rechazar(String nombre) =>
      _ejecutar(nombre, () => ApiService().responderAmistad(nombre, false));

  Future<void> _cancelar(String nombre) => _ejecutar(
    nombre,
    () => ApiService().cancelarSolicitudAmistad(nombre),
    okPorDefecto: 'Solicitud cancelada.',
  );

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
    if (confirmar != true || !mounted) return;
    await _ejecutar(
      nombre,
      () => ApiService().quitarAmistad(nombre),
      okPorDefecto: 'Amigo eliminado.',
    );
  }

  Future<void> _anadirPorCodigo() async {
    final codigo = _codigoCtrl.text.trim();
    if (codigo.isEmpty) {
      _aviso('Escribe el código que te han pasado.');
      return;
    }
    FocusScope.of(context).unfocus();
    await _ejecutar(
      '__codigo__',
      () => ApiService().solicitarAmistad(codigo: codigo),
      okPorDefecto: 'Solicitud enviada.',
      alTerminar: (_) => _codigoCtrl.clear(),
    );
  }

  Future<void> _copiarCodigo(String codigo) async {
    await Clipboard.setData(ClipboardData(text: codigo));
    _aviso('Código copiado.');
  }

  Future<void> _compartirCodigo(String codigo) async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Añádeme en ClubReads 📚 Abre la app, entra en Amigos y escribe '
            'mi código: $codigo',
      ),
    );
  }

  // ── Interfaz ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embebida
          ? AppBar(
              title: const Text('Amigos'),
              automaticallyImplyLeading: false,
            )
          : AppBar(title: const Text('Amigos')),
      body: _cargando && _data == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _data == null
          ? ErrorView(onRetry: _cargar)
          : RefreshIndicator(
              onRefresh: () => _cargar(silencioso: true),
              child: LayoutBuilder(
                builder: (context, restricciones) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Se construye todo el panel para poder saltar a cualquier
                  // sección desde los cuadros del resumen.
                  cacheExtent: 8000,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    widget.embebida ? kFloatingNavClearance : AppSpacing.md,
                  ),
                  children: _secciones(
                    _data ?? const AmistadesData(),
                    dosColumnas: restricciones.maxWidth >= 720,
                  ),
                ),
              ),
            ),
    );
  }

  List<Widget> _secciones(AmistadesData data, {bool dosColumnas = false}) {
    // En tablet, el panel se reparte en dos columnas (actividad a un lado,
    // descubrir y retos al otro).
    final cuerpo = dosColumnas
        ? <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const FeedAmistades(),
                      const LecturasConAmistadesSeccion(),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    children: [
                      const ResumenSemanalAmigosCard(),
                      const AfinidadAmigosSeccion(),
                      const RachasCompartidasSeccion(),
                      RetosAmigosSeccion(amistades: data.amistades),
                      const IdeasParaRegalar(),
                    ],
                  ),
                ),
              ],
            ),
          ]
        : <Widget>[
            const ResumenSemanalAmigosCard(),
            const AfinidadAmigosSeccion(),
            const RachasCompartidasSeccion(),
            RetosAmigosSeccion(amistades: data.amistades),
            const FeedAmistades(),
            const LecturasConAmistadesSeccion(),
            const IdeasParaRegalar(),
          ];
    return [
      // Lo mismo en las cuentas con club (se llega desde Inicio) que en las
      // personales (pestaña): solo cambia cómo se entra.
      _resumen(data),
      const SizedBox(height: AppSpacing.md),
      const ActividadAmistadesCard(mostrarVerTodas: false),
      ...cuerpo,
      const SizedBox(height: AppSpacing.lg),
      _bloqueBuscar(),
      if (data.recibidas.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        _titulo(
          'Solicitudes recibidas',
          data.recibidas.length,
          _claveRecibidas,
        ),
        for (final p in data.recibidas) _filaRecibida(p),
      ],
      if (data.enviadas.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        _titulo('Solicitudes enviadas', data.enviadas.length, _claveEnviadas),
        for (final p in data.enviadas) _filaEnviada(p),
      ],
      const SizedBox(height: AppSpacing.lg),
      _titulo('Tus amigos', data.amistades.length, _claveAmigos),
      if (data.amistades.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            'Todavía no tienes amigos en ClubReads. Busca a alguien por su '
            'nombre o comparte tu código.',
            style: AppTextStyles.bodySecondary,
          ),
        )
      else
        for (final p in data.amistades) _filaAmistad(p),
      const SizedBox(height: AppSpacing.lg),
      _tarjetaCodigo(data.miCodigo),
      const SizedBox(height: AppSpacing.lg),
      _bloquePrivacidad(data.privacidad),
      const SizedBox(height: AppSpacing.xl),
    ];
  }

  /// Resumen visual de un vistazo: amigos, solicitudes por responder y
  /// solicitudes enviadas.
  Widget _resumen(AmistadesData data) {
    Widget dato(
      IconData icono,
      String valor,
      String etiqueta,
      Color color,
      VoidCallback alPulsar,
    ) {
      return Expanded(
        child: Material(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            key: Key('resumen-$etiqueta'),
            borderRadius: BorderRadius.circular(18),
            onTap: alPulsar,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.sm,
              ),
              child: Column(
                children: [
                  Icon(icono, color: color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    valor,
                    style: AppTextStyles.title.copyWith(
                      fontSize: 22,
                      color: color,
                    ),
                  ),
                  Text(
                    etiqueta,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      key: const Key('amistades-resumen'),
      children: [
        dato(
          Icons.groups_rounded,
          '${data.amistades.length}',
          'amigos',
          AppColors.primary,
          () => _irA(_claveAmigos, vacio: 'Todavía no tienes amigos.'),
        ),
        const SizedBox(width: AppSpacing.sm),
        dato(
          Icons.mark_email_unread_rounded,
          '${data.recibidas.length}',
          'por responder',
          AppColors.inkCoral,
          () => _irA(
            _claveRecibidas,
            vacio: 'No tienes solicitudes por responder.',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        dato(
          Icons.send_rounded,
          '${data.enviadas.length}',
          'enviadas',
          AppColors.info,
          () => _irA(_claveEnviadas, vacio: 'No tienes solicitudes enviadas.'),
        ),
      ],
    );
  }

  Future<void> _cambiarPrivacidad(PrivacidadAmistades nueva) async {
    final anterior = _data;
    if (anterior == null) return;
    setState(() => _data = anterior.conPrivacidad(nueva));
    final r = await ApiService().guardarPrivacidadAmistades(nueva);
    if (!mounted) return;
    if (!r.ok) {
      setState(() => _data = anterior);
      _aviso('No se ha podido guardar. Inténtalo de nuevo.');
    }
  }

  Widget _bloquePrivacidad(PrivacidadAmistades p) {
    Widget interruptor(
      String titulo,
      String detalle,
      bool valor,
      PrivacidadAmistades Function(bool) alCambiar,
    ) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(titulo),
      subtitle: Text(detalle, style: AppTextStyles.caption),
      value: valor,
      onChanged: (v) => _cambiarPrivacidad(alCambiar(v)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Qué ven tus amigos de ti'),
        interruptor(
          'Lo que estoy leyendo',
          'Tu lectura actual, tu progreso y lo que has terminado',
          p.leyendo,
          (v) => p.copyWith(leyendo: v),
        ),
        interruptor(
          'Mi biblioteca',
          'Tus pendientes y cuántos libros llevas',
          p.biblioteca,
          (v) => p.copyWith(biblioteca: v),
        ),
        interruptor(
          'Mis reseñas y valoraciones',
          'Las que escribes en los libros (las que tienen spoilers no se enseñan)',
          p.resenas,
          (v) => p.copyWith(resenas: v),
        ),
        interruptor(
          'Mi lista de deseos',
          'Qué libros quieres, para que sepan qué regalarte (sin precios ni notas)',
          p.deseos,
          (v) => p.copyWith(deseos: v),
        ),
      ],
    );
  }

  Widget _titulo(String texto, [int? total, GlobalKey? clave]) => Padding(
    key: clave,
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      total == null ? texto : '$texto ($total)',
      style: AppTextStyles.section,
    ),
  );

  Widget _tarjetaCodigo(String codigo) {
    return ClubCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.primary.withValues(alpha: 0.06),
      borderColor: AppColors.primary.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tu código de amigo', style: AppTextStyles.section),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Compártelo para que te añadan sin tener que buscarte.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: SelectableText(
              codigo.isEmpty ? '········' : codigo,
              style: AppTextStyles.title.copyWith(letterSpacing: 4),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: codigo.isEmpty
                      ? null
                      : () => _copiarCodigo(codigo),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copiar'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: codigo.isEmpty
                      ? null
                      : () => _compartirCodigo(codigo),
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: const Text('Compartir'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bloqueBuscar() {
    final ocupadoCodigo = _ocupadas.contains('__codigo__');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titulo('Añadir amigos'),
        TextField(
          controller: _buscarCtrl,
          onChanged: _alEscribirBusqueda,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Busca por nombre (mínimo 3 letras)',
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Solo aparecen personas con el perfil público. Si alguien no '
          'sale, pídele su código.',
          style: AppTextStyles.caption,
        ),
        if (_buscando)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        if (_errorBusqueda != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              _errorBusqueda!,
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.danger,
              ),
            ),
          ),
        if (_resultados != null && !_buscando) ...[
          const SizedBox(height: AppSpacing.sm),
          if (_resultados!.isEmpty)
            Text(
              'No hemos encontrado a nadie con ese nombre.',
              style: AppTextStyles.bodySecondary,
            )
          else
            for (final p in _resultados!) _filaBusqueda(p),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _codigoCtrl,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _anadirPorCodigo(),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                  hintText: '¿Tienes un código?',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton(
              onPressed: ocupadoCodigo ? null : _anadirPorCodigo,
              child: const Text('Añadir'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fila({
    required PersonaAmistad persona,
    required Widget accion,
    String? subtitulo,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClubCard(
        elevated: false,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            ClubAvatar(
              nombre: persona.nombre,
              imageUrl: persona.avatarUrl,
              size: 44,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    persona.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (subtitulo != null)
                    Text(subtitulo, style: AppTextStyles.caption),
                ],
              ),
            ),
            accion,
          ],
        ),
      ),
    );
  }

  Widget _filaBusqueda(PersonaBuscada p) {
    final ocupada = _ocupadas.contains(p.nombre);
    return _fila(
      persona: p,
      subtitulo: p.clubEnComun.isNotEmpty && p.estado == EstadoAmistad.ninguna
          ? 'Ya compartís el club «${p.clubEnComun}». Podéis ser amigos '
                'igualmente: regalos, lecturas a la vez…'
          : null,
      accion: switch (p.estado) {
        EstadoAmistad.ninguna => FilledButton(
          onPressed: ocupada ? null : () => _solicitar(p),
          child: const Text('Añadir'),
        ),
        EstadoAmistad.enviada => const Text('Solicitud enviada'),
        EstadoAmistad.recibida => FilledButton(
          onPressed: ocupada ? null : () => _aceptar(p.nombre),
          child: const Text('Aceptar'),
        ),
        EstadoAmistad.amiga => const Text('Amigo ✓'),
      },
    );
  }

  Widget _filaRecibida(PersonaAmistad p) {
    final ocupada = _ocupadas.contains(p.nombre);
    return _fila(
      persona: p,
      subtitulo: 'Te ha enviado una solicitud',
      accion: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: ocupada ? null : () => _rechazar(p.nombre),
            child: const Text('Rechazar'),
          ),
          FilledButton(
            onPressed: ocupada ? null : () => _aceptar(p.nombre),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Widget _filaEnviada(PersonaAmistad p) => _fila(
    persona: p,
    subtitulo: 'Esperando respuesta',
    accion: TextButton(
      onPressed: _ocupadas.contains(p.nombre)
          ? null
          : () => _cancelar(p.nombre),
      child: const Text('Cancelar'),
    ),
  );

  Widget _filaAmistad(PersonaAmistad p) => _fila(
    persona: p,
    subtitulo: p.clubEnComun.isEmpty ? null : 'De tu club «${p.clubEnComun}»',
    onTap: () => Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => PerfilAmistadPage(nombre: p.nombre)),
    ),
    accion: IconButton(
      tooltip: 'Quitar amigo',
      icon: const Icon(Icons.person_remove_outlined),
      onPressed: _ocupadas.contains(p.nombre) ? null : () => _quitar(p.nombre),
    ),
  );
}
