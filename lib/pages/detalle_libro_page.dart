import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/kit_lectura_seleccion.dart';
import '../models/libro.dart';
import '../models/libro_agrupado.dart';
import '../models/libro_finalizado.dart';
import '../models/perfil_usuario.dart';
import '../navigation/book_detail_navigation.dart';
import '../services/api_service.dart';
import '../services/atmosfera_controller.dart';
import '../services/atmosfera_scope.dart';
import '../services/favoritos_service.dart';
import '../services/kit_lectura_service.dart';
import '../services/usuario_service.dart';
import '../services/library_refresh_notifier.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/conversacion_libro_utils.dart';
import '../utils/reading_status_copy.dart';
import '../widgets/common/ancla_de_scroll.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_book_cover.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/common/libro_finalizado_celebration.dart';
import '../widgets/common/screen_hint_banner.dart';
import '../widgets/ui/club_section_title.dart';
import '../widgets/libros/add_book_sheet.dart';
import '../widgets/libros/apply_initial_status.dart';
import '../widgets/libros/conversaciones_libro_card.dart';
import '../widgets/libros/finalizar_libro_dialog.dart';
import '../widgets/libros/kit_lectura_card.dart';
import '../widgets/libros/libro_header.dart';
import '../widgets/libros/comprar_libro_card.dart';
import 'package:club_lectura_app/utils/formato_libro.dart';
import '../widgets/libros/libro_interesadas_section.dart';
import '../widgets/libros/mi_ficha_lectura_card.dart';
import '../widgets/libros/libro_section.dart';
import 'kit_export_page.dart';
import 'kit_lectura_page.dart';
import 'nuevo_libro_page.dart';

class DetalleLibroPage extends StatefulWidget {
  final LibroAgrupado libro;

  /// Tag Hero que coincide con el de la portada en la pantalla de origen.
  final String? heroTag;

  /// Cuando es `true` (abierto desde el dashboard global), sustituye
  /// "Lectores interesados" y "Valoraciones" por estadísticas anónimas
  /// (media, contadores, gráfica de distribución) sin mostrar nombres ni fotos.
  final bool globalStats;

  const DetalleLibroPage({
    super.key,
    required this.libro,
    this.heroTag,
    this.globalStats = false,
  });

  @override
  State<DetalleLibroPage> createState() => _DetalleLibroPageState();
}

class _DetalleLibroPageState extends State<DetalleLibroPage> {
  final KitLecturaService _kitService = KitLecturaService();
  late LibroAgrupado libro;
  late List<Libro> registros;
  late AtmosferaController _atmosferaController;

  String? usuarioActual;

  // Kit de lectura: atmósfera activa (Feature 2)
  KitLecturaSeleccion _kitSeleccion = const KitLecturaSeleccion();

  bool _controllerPreparado = false;
  bool _atmosferaCerrada = false;
  bool _toggling = false;
  bool _anadiendo = false;

  List<PerfilSagaVolumen> _volumenesSaga = const [];
  final Set<String> _anadiendoVolumenSaga = {};

  // Estadísticas de toda la comunidad (ClubReads), independientes del club
  // desde el que se haya abierto esta ficha. Se cargan aparte porque, salvo
  // en widget.globalStats, `libro.registros`/`libro.finalizados` solo traen
  // los datos del club/cuenta desde donde se navegó.
  List<Libro>? _registrosGlobales;
  List<LibroFinalizado>? _finalizadosGlobales;

  bool get _hayEstadisticasComunidad =>
      _registrosGlobales != null &&
      _finalizadosGlobales != null &&
      (_registrosGlobales!.isNotEmpty || _finalizadosGlobales!.isNotEmpty);

  /// `registros` (del club) más, si ya han cargado, quienes de otros
  /// clubes también tienen el libro activo — forzadas a mismoClub=false
  /// aunque el backend las marque como visibles por tener el perfil
  /// público (aquí "mismo club" decide si la tarjeta es interactiva, no
  /// solo si se revela el nombre): sin eso, alguien con perfil público de
  /// otro club se colaría con una tarjeta editable en un club al que no
  /// pertenece. LibroInteresadasSection ya sabe agrupar estas entradas en
  /// el resumen por estados en vez de tarjetas individuales.
  List<Libro> get _registrosParaLectoresInteresados {
    if (!_hayEstadisticasComunidad) return registros;
    final misClub = registros
        .map((r) => r.usuario.trim().toLowerCase())
        .where((u) => u.isNotEmpty)
        .toSet();
    final deOtrosClubes = _registrosGlobales!
        .where(
          (r) => !misClub.contains(r.usuario.trim().toLowerCase()),
        )
        .map((r) => r.mismoClub ? r.copyWith(mismoClub: false) : r);
    return [...registros, ...deOtrosClubes];
  }

  @override
  void initState() {
    super.initState();

    libro = widget.libro;

    registros = List<Libro>.from(libro.registros);

    _cargarUsuarioActual();
    unawaited(FavoritosService.instance.cargar());
    if (libro.bookId.isNotEmpty) unawaited(_cargarVolumenesSaga());
    if (!widget.globalStats && libro.bookId.isNotEmpty) {
      unawaited(_cargarEstadisticasComunidad());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _atmosferaController = AtmosferaScope.of(context);
      _controllerPreparado = true;

      _cargarAtmosferaDelLibro();
    });
  }

  Future<void> _cargarVolumenesSaga() async {
    final volumenes = await ApiService().getVolumenesSaga(libro.bookId);
    if (!mounted) return;
    setState(() => _volumenesSaga = volumenes);
  }

  /// Carga las estadísticas de toda la comunidad (todos los clubes y cuentas
  /// personales) para esta ficha, al margen del club desde el que se abrió.
  /// Silenciosa ante fallos: si no hay datos, la sección simplemente no se
  /// muestra en vez de romper la ficha.
  Future<void> _cargarEstadisticasComunidad() async {
    try {
      final data = await ApiService().getLibroPorId(
        libro.bookId,
        global: true,
      );
      if (!mounted || data['ok'] != true) return;

      final registrosGlobales = (data['libros'] as List? ?? [])
          .map((e) => Libro.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final finalizadosGlobales = (data['finalizados'] as List? ?? [])
          .map(
            (e) => LibroFinalizado.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _registrosGlobales = registrosGlobales;
        _finalizadosGlobales = finalizadosGlobales;
      });
    } catch (_) {
      // Sin estadísticas de la comunidad: la ficha sigue funcionando igual.
    }
  }

  Future<void> _cargarUsuarioActual() async {
    final usuario = await UsuarioService().obtenerUsuario();

    if (!mounted) return;

    setState(() {
      usuarioActual = usuario?.trim();
    });
  }

  Future<void> _cargarAtmosferaDelLibro() async {
    if (!_controllerPreparado) return;

    final bookId = libro.bookId.trim();

    if (bookId.isEmpty) {
      _atmosferaController.usarAtmosferaNeutra();
      return;
    }

    try {
      final seleccion = await _kitService.obtener(bookId);

      if (!mounted || _atmosferaCerrada) return;

      setState(() => _kitSeleccion = seleccion);

      _atmosferaController.entrarEnLibro(
        bookId: bookId,
        atmosferaId: seleccion.atmosferaId,
      );
    } catch (error) {
      if (!mounted || _atmosferaCerrada) return;

      _atmosferaController.entrarEnLibro(bookId: bookId, atmosferaId: '');
    }
  }

  /// Cierra la atmósfera del libro de forma segura.
  ///
  /// Puede llamarse desde el botón de volver, el gesto de iOS,
  /// una salida programática o dispose sin aplicar el cierre dos veces.
  void _cerrarAtmosferaDelLibro() {
    if (_atmosferaCerrada) return;

    _atmosferaCerrada = true;

    if (!_controllerPreparado) return;

    final bookId = libro.bookId.trim();

    _atmosferaController.salirDelLibro(bookId: bookId.isEmpty ? null : bookId);
  }

  void _volver() {
    _cerrarAtmosferaDelLibro();
    Navigator.pop(context);
  }

  Future<void> _cambiarEstado(
    Libro libro,
    String nuevoEstado, {
    String? valoracion,
    String? picante,
    String? reflexion,
    String? motivoPausa,
    String? fechaInicio,
    String? fechaFin,
    String? formato,
  }) async {
    try {
      final bool ok;

      if (nuevoEstado == 'LEYENDO') {
        ok = await ApiService().iniciarLectura(
          usuario: libro.usuario,
          libro: libro.libro,
        );
      } else {
        ok = await ApiService().actualizarEstado(
          usuario: libro.usuario,
          libro: libro.libro,
          estado: nuevoEstado,
          valoracion: valoracion,
          picante: picante,
          reflexion: reflexion,
          motivoPausa: motivoPausa,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
          formato: formato,
        );
      }

      if (!ok) {
        throw Exception('No se ha podido guardar el estado');
      }

      if (!mounted) return;

      LibraryRefreshNotifier.instance.invalidate();

      final index = registros.indexOf(libro);

      if (index == -1) {
        throw Exception('No se ha encontrado el registro del libro');
      }

      setState(() {
        registros[index] = libro.copyWith(
          estado: nuevoEstado,
          valoracion: nuevoEstado == 'FINALIZADO'
              ? (valoracion ?? libro.valoracion)
              : '',
          formato: formato ?? libro.formato,
        );
      });
    } catch (error) {
      if (!mounted) return;

      final mensaje = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $mensaje')));
      return;
    }

    if (!mounted) return;

    // A partir de aquí el estado ya se guardó y está reflejado en pantalla:
    // si falla algo de lo que sigue (celebración, prompts del kit), NO debe
    // reportarse como si el guardado hubiera fallado.
    try {
      if (nuevoEstado == 'FINALIZADO') {
        // Vibración + pantalla de celebración
        await mostrarCelebracionFinalizado(
          context,
          titulo: libro.libro,
          coverUrl: libro.coverUrl,
        );

        // Feature 4: prompt para compartir story si tiene kit con paleta
        if (!mounted) return;
        final bookId = widget.libro.bookId.trim();
        if (bookId.isNotEmpty) {
          final kit = await _kitService.obtener(bookId);
          if (!mounted) return;
          if (kit.tienePaleta) {
            await _mostrarPromptStory(libro, kit, finalizado: true);
          }
        }

        // El parche optimista de arriba deja el registro como FINALIZADO
        // dentro de "registros" (no lo mueve a "finalizados"), así que la
        // ficha seguiría mostrando el selector de estado antiguo en vez de
        // "Mi valoración" hasta recargar a mano. Recargamos de verdad para
        // que ya se vea bien sin tener que salir y volver a entrar.
        if (!mounted) return;
        await _recargarDesdeServidor();
      } else if (nuevoEstado == 'LEYENDO') {
        // Feature 3: prompt para preparar el kit si aún no lo tiene
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Estado actualizado')));

        final bookId = widget.libro.bookId.trim();
        if (bookId.isNotEmpty && !mounted) return;
        if (bookId.isNotEmpty) {
          final kit = await _kitService.obtener(bookId);
          if (!mounted) return;
          if (!kit.tienePaleta) {
            await _mostrarPromptKit(libro);
          }
        }

        // Feature: prompt para abrir conversación si aún no hay ninguna.
        // Encadenado DESPUÉS del prompt del kit (no a la vez), y solo si el
        // libro todavía no tiene ninguna lectura/conversación configurada
        // — así no se repite cada vez que alguien vuelve a marcarlo.
        if (!mounted) return;
        final yaTieneConversacion = await existeConversacionParaLibro(
          libro.libro,
        );
        if (!mounted || yaTieneConversacion) return;
        await _mostrarPromptConversacion(libro);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Estado actualizado')));
      }
    } catch (_) {
      // Silencioso a propósito: el estado ya se guardó correctamente.
    }
  }

  // ── Feature 3: prompt kit al empezar a leer ────────────────────────────
  Future<void> _mostrarPromptKit(Libro libro) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('✨', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(
              '¿Preparamos tu kit de lectura?',
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Paleta, subrayadores, atmósfera y playlist — todo listo en 2 minutos para que esta historia se convierta en una experiencia.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _abrirKitLectura();
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Preparar mi kit'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Más tarde'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Prompt para abrir conversación al empezar a leer ───────────────────
  Future<void> _mostrarPromptConversacion(Libro libro) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('💬', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(
              '¿Abrimos una conversación sobre esta lectura?',
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Empieza a comentar tus impresiones ya, sin esperar a que '
              'nadie más se sume a la lectura.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                abrirNuevaConversacion(
                  context,
                  libro: libro.libro,
                  coverUrl: this.libro.coverUrl,
                );
              },
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Abrir conversación'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Más tarde'),
            ),
            Text(
              'Podrás abrirla cuando quieras desde la ficha del libro.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }

  // ── Feature 4: prompt story al terminar ────────────────────────────────
  Future<void> _mostrarPromptStory(
    Libro libro,
    KitLecturaSeleccion kit, {
    bool finalizado = false,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).padding.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('🎉', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(
              '¡Has terminado ${libro.libro}!',
              textAlign: TextAlign.center,
              style: AppTextStyles.title.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Tienes tu kit de lectura preparado. ¿Compartes tu story con la comunidad?',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _abrirExportacion(KitExportTipo.story, kit, finalizado: finalizado, valoracionStr: libro.valoracion);
              },
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Compartir mi story'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ahora no'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Convierte una cadena de valoración a double (1.0–5.0, admite medias) ─
  // Formatos soportados: "⭐⭐⭐⭐½", "4.5", "4,5"
  static double? _parseStarsCount(String? valoracion) {
    if (valoracion == null || valoracion.isEmpty) return null;
    final texto = valoracion.trim().replaceAll('⭐️', '⭐').replaceAll(',', '.');
    if (texto == '😞') return null;
    final num = double.tryParse(texto);
    if (num != null) {
      final v = ((num.clamp(0, 5)) * 2).round() / 2;
      return v > 0 ? v : null;
    }
    final stars = '⭐'.allMatches(texto).length;
    final half = texto.contains('½');
    final v = (((stars + (half ? 0.5 : 0)).clamp(0, 5)) * 2).round() / 2;
    return v > 0 ? v : null;
  }

  // ── Abre la exportación de story/wallpaper desde fuera del kit ─────────
  Future<void> _abrirExportacion(
    KitExportTipo tipo,
    KitLecturaSeleccion kit, {
    bool finalizado = false,
    String? valoracionStr,
  }) async {
    await Navigator.push<void>(
      context,
      AppPageRoute(
        builder: (_) => KitExportPage(
          tipo: tipo,
          libro: widget.libro.libro,
          coverUrl: widget.libro.coverUrl,
          colores: kit.paleta.map(_colorDesdeHex).toList(),
          subrayadores: kit.subrayadores.map(_colorDesdeHex).toList(),
          atmosferaTitulo: kit.atmosferaTitulo,
          atmosferaIcono: kit.atmosferaIcono,
          etiquetaStory: finalizado ? 'YA LO HE LEÍDO' : 'ESTOY LEYENDO',
          valoracion: _parseStarsCount(valoracionStr),
        ),
      ),
    );
  }

  Color _colorDesdeHex(String hex) {
    final limpio = hex.replaceAll('#', '').replaceAll('0x', '').trim();
    final valor = limpio.length == 6 ? 'FF$limpio' : limpio.padLeft(8, 'F');
    return Color(int.parse(valor, radix: 16));
  }

  Future<void> _actualizarPreferencias(
    Libro libro,
    String prioridad,
    String formato,
  ) async {
    // Si falla (sin conexión, servidor…) se avisa y el cambio no se aplica en
    // pantalla: antes la excepción quedaba sin capturar, no se veía ningún
    // mensaje y Crashlytics la contaba como una caída.
    var ok = false;
    try {
      ok = await ApiService().actualizarPreferenciasLibro(
        libro: libro.libro,
        prioridad: prioridad,
        formato: formato,
      );
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se han podido guardar tus preferencias. Inténtalo de nuevo.',
          ),
        ),
      );
      return;
    }
    final index = registros.indexOf(libro);
    if (index < 0) return;
    setState(() {
      registros[index] = libro.copyWith(prioridad: prioridad, formato: formato);
    });
  }

  Future<void> _quitarPendientes(Libro libro) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🗑️ Quitar libro'),
        content: Text(
          "¿Quieres quitar '${libro.libro}' de tus pendientes?\n\n"
          'Si nadie más lo tiene pendiente y nunca se ha leído, '
          'desaparecerá del catálogo.',
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

    if (confirmar != true) return;

    final respuesta = await ApiService().quitarLibroPendientes(
      usuario: libro.usuario,
      libro: libro.libro,
      bookId: libro.bookId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          respuesta['mensaje']?.toString() ?? 'Operación realizada',
        ),
      ),
    );

    if (respuesta['ok'] == true) {
      LibraryRefreshNotifier.instance.invalidate();
      _cerrarAtmosferaDelLibro();

      if (!mounted) return;

      Navigator.pop(context, true);
    }
  }

  Future<void> _abrirGoodreads() async {
    var url = libro.goodreads;

    if (url.isEmpty) return;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.parse(url);

    final abierto = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!abierto) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Future<void> _toggleFavorito() async {
    if (_toggling || libro.bookId.isEmpty) return;
    setState(() => _toggling = true);
    final resultado = await FavoritosService.instance.toggle(
      libro.bookId,
      libro.libro,
      coverUrl: libro.coverUrl.isNotEmpty ? libro.coverUrl : null,
    );
    if (!mounted) return;
    setState(() => _toggling = false);
    if (!resultado.ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(resultado.mensaje)));
    }
  }

  Future<void> _editarLibro() async {
    if (libro.bookId.isEmpty) return;

    // Antes de abrir el formulario, pedimos la saga real del catálogo: si
    // nadie del club tiene aún este libro en su biblioteca, `libro.registros`
    // y `libro.finalizados` vienen vacíos y el formulario no tendría de
    // dónde precargarla — guardaría el libro como autoconclusivo y le
    // borraría la saga a todo el mundo aunque solo se cambiara la portada.
    var libroParaEditar = libro;
    try {
      final data = await ApiService().getLibroPorId(
        libro.bookId,
        global: widget.globalStats,
      );
      if (data['ok'] == true && data['libro'] is Map) {
        final catalogo = Map<String, dynamic>.from(data['libro'] as Map);
        libroParaEditar = LibroAgrupado(
          libro: libro.libro,
          genero: libro.genero,
          registros: libro.registros,
          finalizados: libro.finalizados,
          yaLoTengo: libro.yaLoTengo,
          leidoPorMi: libro.leidoPorMi,
          coverUrl: libro.coverUrl,
          bookId: libro.bookId,
          sagaCatalogo: catalogo['saga']?.toString(),
          numSagaCatalogo: catalogo['numSaga']?.toString(),
          standaloneCatalogo: catalogo['autoconclusivo'] == null
              ? null
              : catalogo['autoconclusivo'].toString() == 'Si',
        );
      }
    } catch (_) {
      // Si falla, seguimos con los datos que ya teníamos.
    }

    if (!mounted) return;

    final actualizado = await Navigator.push<bool>(
      context,
      AppPageRoute(builder: (_) => NuevoLibroPage(libro: libroParaEditar)),
    );

    if (!mounted) return;

    if (actualizado == true) {
      _cerrarAtmosferaDelLibro();
      if (!mounted) return;

      // Recargar datos frescos del libro para mostrar los cambios (portada,
      // género…) sin depender del timing del refresco asíncrono de la
      // biblioteca. Si la recarga falla, retrocedemos con pop como antes.
      try {
        // Siempre con global:true: la ficha puede haberse abierto desde la
        // vista "De ClubReads" (con lectoras de otros clubes) aunque
        // widget.globalStats sea false (esa flag controla el modo de
        // estadísticas anónimas, no el alcance de los datos). El backend ya
        // anonimiza aquí a quien no comparte club, igual que en esa vista.
        final data = await ApiService().getLibroPorId(
          libro.bookId,
          global: true,
        );
        if (!mounted) return;

        if (data['ok'] == true) {
          final librosActualizados = (data['libros'] as List? ?? [])
              .map((e) => Libro.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          final finalizadosActualizados = (data['finalizados'] as List? ?? [])
              .map(
                (e) => LibroFinalizado.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList();

          // Resolver portada y género frescos
          String coverFresh = librosActualizados.isNotEmpty
              ? librosActualizados.first.coverUrl
              : '';
          if (coverFresh.isEmpty && finalizadosActualizados.isNotEmpty) {
            coverFresh = finalizadosActualizados.first.coverUrl;
          }
          if (coverFresh.isEmpty) coverFresh = libro.coverUrl;

          String generoFresh = librosActualizados.isNotEmpty
              ? librosActualizados.first.genero
              : '';
          if (generoFresh.isEmpty) generoFresh = libro.genero;

          String tituloFresh = librosActualizados.isNotEmpty
              ? librosActualizados.first.libro
              : '';
          if (tituloFresh.isEmpty && finalizadosActualizados.isNotEmpty) {
            tituloFresh = finalizadosActualizados.first.libro;
          }
          if (tituloFresh.isEmpty) tituloFresh = libro.libro;

          setState(() {
            libro = LibroAgrupado(
              libro: tituloFresh,
              genero: generoFresh,
              registros: librosActualizados,
              finalizados: finalizadosActualizados,
              yaLoTengo: librosActualizados.any((l) => l.yaLoTengo),
              leidoPorMi: finalizadosActualizados.any((l) => l.yaLoTengo),
              coverUrl: coverFresh,
              bookId: libro.bookId,
            );
            registros = List<Libro>.from(libro.registros);
          });
          // No hacemos pop: el usuario ve la ficha actualizada y puede
          // volver atrás cuando quiera.
        } else {
          Navigator.pop(context, true);
        }
      } catch (_) {
        if (mounted) Navigator.pop(context, true);
      }
    }
  }

  /// Recarga esta ficha desde el servidor y reemplaza `libro`/`registros`
  /// con datos reales. Usado tras editar valoración/picante/idioma de mi
  /// propia lectura terminada, para no reconstruir el estado a mano.
  Future<void> _recargarDesdeServidor() async {
    if (libro.bookId.isEmpty) return;
    try {
      final data = await ApiService().getLibroPorId(
        libro.bookId,
        global: widget.globalStats,
      );
      if (!mounted || data['ok'] != true) return;
      final librosActualizados = (data['libros'] as List? ?? [])
          .map((e) => Libro.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final finalizadosActualizados = (data['finalizados'] as List? ?? [])
          .map(
            (e) => LibroFinalizado.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
      setState(() {
        libro = LibroAgrupado(
          libro: libro.libro,
          genero: libro.genero,
          registros: librosActualizados,
          finalizados: finalizadosActualizados,
          yaLoTengo: librosActualizados.any((l) => l.yaLoTengo),
          leidoPorMi: finalizadosActualizados.any((l) => l.yaLoTengo),
          coverUrl: libro.coverUrl,
          bookId: libro.bookId,
        );
        registros = List<Libro>.from(libro.registros);
      });
    } catch (_) {
      // Si falla, el snackbar de éxito del propio control ya informó del
      // cambio; la próxima entrada a la ficha traerá los datos frescos.
    }
  }

  /// Mi propia finalización de este libro (si la tengo), para la tarjeta
  /// editable de valoración/picante/idioma. `registros` no la incluye porque
  /// solo cubre lecturas activas/pendientes.
  LibroFinalizado? get _miFinalizado {
    for (final f in libro.finalizados) {
      if (f.yaLoTengo) return f;
    }
    return null;
  }

  // ── Añadir a mi biblioteca desde la ficha ───────────────────────────────
  //
  // Cubre el caso de llegar a la ficha de un libro que otras compañeras del
  // club ya tienen (p. ej. desde el Ranking) pero que la usuaria actual
  // todavía no ha registrado: sin esto, la ficha no ofrecía ninguna forma de
  // añadirlo ni de fijar su estado (leyendo/leído) en un solo paso.
  Future<void> _anadirABiblioteca() async {
    if (_anadiendo) return;
    final usuario = usuarioActual;
    if (usuario == null || usuario.isEmpty) return;

    final referencia = registros.isNotEmpty ? registros.first : null;
    final preferencias = await showAddBookSheet(
      context,
      title: libro.libro,
      author: referencia?.autor ?? '',
      coverUrl: libro.coverUrl,
      showStatusPicker: true,
    );
    if (preferencias == null || !mounted) return;

    setState(() => _anadiendo = true);
    try {
      final respuesta = await ApiService().anadirLibroExistente(
        usuario: usuario,
        libro: libro.libro,
        prioridad: preferencias.priority,
        formato: preferencias.format,
        idioma: preferencias.idioma,
      );
      if (respuesta['ok'] != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              respuesta['mensaje']?.toString() ?? 'No se ha podido añadir',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;

      final estadoFinal = await aplicarEstadoInicial(
        context,
        usuario: usuario,
        libro: libro.libro,
        estadoElegido: preferencias.status,
        formato: preferencias.format,
      );

      if (!mounted) return;
      LibraryRefreshNotifier.instance.invalidate();

      // Recargamos desde el servidor (igual que al editar la ficha) para
      // reflejar el nuevo registro con datos reales en vez de reconstruirlo
      // localmente. Respetamos widget.globalStats: si esta ficha se abrió
      // desde una vista global (p. ej. sin club activo), el endpoint de club
      // fallaría con 409 y la recarga se perdería en el catch de abajo.
      if (libro.bookId.isNotEmpty) {
        try {
          final data = await ApiService().getLibroPorId(
            libro.bookId,
            global: widget.globalStats,
          );
          if (mounted && data['ok'] == true) {
            final librosActualizados = (data['libros'] as List? ?? [])
                .map(
                  (e) => Libro.fromJson(Map<String, dynamic>.from(e as Map)),
                )
                .toList();
            final finalizadosActualizados = (data['finalizados'] as List? ?? [])
                .map(
                  (e) => LibroFinalizado.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList();
            setState(() {
              libro = LibroAgrupado(
                libro: libro.libro,
                genero: libro.genero,
                registros: librosActualizados,
                finalizados: finalizadosActualizados,
                yaLoTengo: librosActualizados.any((l) => l.yaLoTengo),
                leidoPorMi: finalizadosActualizados.any((l) => l.yaLoTengo),
                coverUrl: libro.coverUrl,
                bookId: libro.bookId,
              );
              registros = List<Libro>.from(libro.registros);
            });
          }
        } catch (_) {
          // Si la recarga falla, el snackbar de confirmación sigue siendo
          // correcto; la próxima entrada a la ficha traerá los datos frescos.
        }
      }

      if (!mounted) return;
      if (estadoFinal == 'FINALIZADO') {
        await mostrarCelebracionFinalizado(
          context,
          titulo: libro.libro,
          coverUrl: libro.coverUrl,
        );
      } else if (noSeAplicoEstadoElegido(
        estadoElegido: preferencias.status,
        estadoFinal: estadoFinal,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeEstadoNoAplicado(libro.libro))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Añadido a tu biblioteca')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se ha podido añadir')),
        );
      }
    } finally {
      if (mounted) setState(() => _anadiendo = false);
    }
  }

  // ── Añadir otro volumen de la misma saga desde el panel de sugerencias ──
  Future<void> _anadirVolumenSaga(PerfilSagaVolumen volumen) async {
    if (_anadiendoVolumenSaga.contains(volumen.bookId)) return;
    final usuario = usuarioActual;
    if (usuario == null || usuario.isEmpty) return;

    final preferencias = await showAddBookSheet(
      context,
      title: volumen.titulo,
      coverUrl: volumen.coverUrl,
      showStatusPicker: true,
    );
    if (preferencias == null || !mounted) return;

    setState(() => _anadiendoVolumenSaga.add(volumen.bookId));
    try {
      final respuesta = await ApiService().anadirLibroExistente(
        usuario: usuario,
        libro: volumen.bookId,
        prioridad: preferencias.priority,
        formato: preferencias.format,
        idioma: preferencias.idioma,
      );
      if (respuesta['ok'] != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              respuesta['mensaje']?.toString() ?? 'No se ha podido añadir',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;

      final estadoFinal = await aplicarEstadoInicial(
        context,
        usuario: usuario,
        libro: volumen.titulo,
        estadoElegido: preferencias.status,
        formato: preferencias.format,
      );

      if (!mounted) return;
      LibraryRefreshNotifier.instance.invalidate();
      await _cargarVolumenesSaga();

      if (!mounted) return;
      if (estadoFinal == 'FINALIZADO') {
        await mostrarCelebracionFinalizado(
          context,
          titulo: volumen.titulo,
          coverUrl: volumen.coverUrl,
        );
      } else if (noSeAplicoEstadoElegido(
        estadoElegido: preferencias.status,
        estadoFinal: estadoFinal,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeEstadoNoAplicado(volumen.titulo))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${volumen.titulo} añadido a tu biblioteca')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se ha podido añadir')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _anadiendoVolumenSaga.remove(volumen.bookId));
      }
    }
  }

  Future<void> _abrirKitLectura({bool finalizado = false, double? valoracion}) async {
    await Navigator.push(
      context,
      AppPageRoute(
        builder: (_) => KitLecturaPage(
          bookId: libro.bookId,
          libro: libro.libro,
          coverUrl: libro.coverUrl,
          finalizado: finalizado,
          valoracion: valoracion,
        ),
      ),
    );

    if (!mounted || !_controllerPreparado || _atmosferaCerrada) {
      return;
    }

    /*
     * Al volver del kit, recargamos la selección porque la lectora
     * podría haber cambiado la atmósfera del libro.
     */
    await _cargarAtmosferaDelLibro();
  }

  @override
  Widget build(BuildContext context) {
    final referencia = registros.isNotEmpty ? registros.first : null;

    // Calculamos el estado personal del usuario buscando primero en registros
    // (PENDIENTE/LEYENDO/PAUSADO…) y luego en finalizados: `registros` puede
    // traer datos de TODOS los miembros del club (p. ej. al abrir la ficha
    // desde el Ranking vía openBookDetail, que no filtra por usuario), así
    // que asumir que `registros.first` es "mi" registro daba un estado ajeno
    // como propio — o, peor, ocultaba la tarjeta de "añadir a mi biblioteca"
    // cuando la usuaria en realidad no tenía el libro.
    //
    // Preferimos `yaLoTengo` (comparación por id de usuario, calculada en el
    // servidor) sobre comparar nombres como texto: ese nombre puede venir
    // ligeramente distinto entre lo que el backend tiene guardado y lo que
    // el cliente cacheó localmente (espacios, mayúsculas, un cambio de
    // nombre reciente…), y entonces el Kit de lectura y "Lectores
    // interesados" desaparecían pese a que el libro sí era tuyo — mientras
    // que MiFichaLecturaCard, que sí usa yaLoTengo, lo seguía mostrando bien.
    final String? miEstado;
    final enRegistrosPorId = registros.where((r) => r.yaLoTengo).firstOrNull;
    if (enRegistrosPorId != null) {
      miEstado = enRegistrosPorId.estado;
    } else {
      final enFinalizadosPorId = libro.finalizados
          .where((f) => f.yaLoTengo)
          .firstOrNull;
      if (enFinalizadosPorId != null) {
        miEstado = 'FINALIZADO';
      } else if (usuarioActual != null) {
        // Red de seguridad por nombre, por si yaLoTengo no viniera
        // informado en algún camino antiguo.
        final normalizado = usuarioActual!.trim().toLowerCase();
        final enRegistros = registros
            .where((r) => r.usuario.trim().toLowerCase() == normalizado)
            .firstOrNull;
        if (enRegistros != null) {
          miEstado = enRegistros.estado;
        } else {
          final enFinalizados = libro.finalizados
              .where((f) => f.usuario.trim().toLowerCase() == normalizado)
              .firstOrNull;
          miEstado = enFinalizados != null ? 'FINALIZADO' : null;
        }
      } else {
        miEstado = !widget.globalStats ? referencia?.estado : null;
      }
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _cerrarAtmosferaDelLibro();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: _volver,
          ),
          title: Text(
            libro.libro,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (libro.bookId.isNotEmpty) ...[
              // ── Corazón de favorito ───────────────────────────────────────
              ListenableBuilder(
                listenable: FavoritosService.instance,
                builder: (context, _) {
                  final esFavorito = FavoritosService.instance.isFavorito(
                    libro.bookId,
                  );
                  return IconButton(
                    tooltip: esFavorito
                        ? 'Quitar de favoritos'
                        : 'Añadir a favoritos',
                    onPressed: _toggling ? null : _toggleFavorito,
                    icon: _toggling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            esFavorito
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: esFavorito ? const Color(0xFFD4537E) : null,
                          ),
                  );
                },
              ),
              // ── Editar ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Editar'),
                    onPressed: _editarLibro,
                  ),
                ),
              ),
            ],
          ],
        ),
        body: SafeArea(
          // Scroll normal en vez de ListView: la ficha tiene pocas secciones
          // de alturas muy distintas, y una ListView las estima mientras no
          // están en pantalla; al subir, cada una que reaparecía medía distinto
          // y la lista corregía la posición a saltos ("cuesta volver a subir").
          // Con todo medido, el scroll es suave en los dos sentidos.
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LibroHeader(
                  libro: libro,
                  referencia: referencia,
                  heroTag: widget.heroTag,
                  onAbrirGoodreads: _abrirGoodreads,
                  globalStats: widget.globalStats,
                  miEstado: miEstado,
                ),

                // Aparece tarde (espera al servidor): el ancla evita que empuje
                // lo que se está leyendo más abajo.
                if (libro.bookId.isNotEmpty)
                  AnclaDeScroll(
                    child: ComprarLibroCard(
                      bookId: libro.bookId,
                      espacioAntes: AppSpacing.md,
                    ),
                  ),

                // Banner de sugerencia: anima a completar la ficha del libro
                // Aparece cuando el libro tiene bookId (se puede editar) y le falta portada o género
                if (libro.bookId.isNotEmpty &&
                    (libro.coverUrl.isEmpty ||
                        libro.genero.isEmpty ||
                        libro.genero.trim().toLowerCase() == 'sin género')) ...[
                  const SizedBox(height: AppSpacing.md),
                  ScreenHintBanner(
                    featureKey: 'hint_editar_ficha_v1',
                    titulo: '¿Le falta información a este libro?',
                    tips: const [
                      ScreenHintTip(
                        '🖊️',
                        'Pulsa "Editar" para añadir portada, género, enlace a Goodreads y más.',
                      ),
                      ScreenHintTip(
                        '📸',
                        'Si importaste desde Goodreads u otra app, la info puede venir incompleta: ¡complétala tú!',
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Añadir a mi biblioteca: aparece cuando la usuaria actual no
                // tiene aún este libro (ni en curso ni finalizado), típicamente
                // al llegar desde el Ranking a un libro que solo otras
                // compañeras del club han leído/valorado.
                AnclaDeScroll(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (miEstado == null && libro.bookId.isNotEmpty) ...[
                        ClubCard(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.06),
                          borderColor: AppColors.primary.withValues(alpha: 0.25),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '¿Tienes este libro?',
                                      style: AppTextStyles.subtitle.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      'Añádelo a tu biblioteca y cuéntanos en qué punto vas.',
                                      style: AppTextStyles.bodySecondary,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              FilledButton.icon(
                                onPressed: _anadiendo ? null : _anadirABiblioteca,
                                icon: _anadiendo
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Añadir'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ],
                  ),
                ),

                // Otros libros de la saga: solo si hay más volúmenes conocidos
                // en el catálogo además de este (si es el primero, no hay nada
                // que sugerir todavía).
                AnclaDeScroll(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_volumenesSaga.isNotEmpty) ...[
                        _OtrosVolumenesSagaSection(
                          volumenes: _volumenesSaga,
                          anadiendo: _anadiendoVolumenSaga,
                          onAnadir: _anadirVolumenSaga,
                          onAbrir: (volumen) => openBookDetail(
                            context,
                            title: volumen.titulo,
                            bookId: volumen.bookId,
                            coverUrl: volumen.coverUrl,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ],
                  ),
                ),

                // Kit de lectura: solo tiene sentido si la usuaria tiene el
                // libro en su biblioteca. Antes se mostraba igualmente en modo
                // club (!widget.globalStats) sin comprobar miEstado, lo cual
                // era seguro mientras solo se llegaba aquí con el libro ya
                // propio; desde que el Ranking abre esta ficha para libros que
                // la usuaria no tiene (miEstado == null, globalStats == false),
                // hace falta la misma condición en los dos modos.
                AnclaDeScroll(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (miEstado != null) ...[
                        // Feature 2: banner de atmósfera activa cuando está configurada
                        if (_kitSeleccion.tieneAtmosfera) ...[
                          _AtmosferaBanner(seleccion: _kitSeleccion),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        KitLecturaCard(
                          bookId: libro.bookId,
                          onTap: () => _abrirKitLectura(
                            finalizado: miEstado == 'FINALIZADO',
                            valoracion: _parseStarsCount(referencia?.valoracion),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Sección de lectores / estadísticas ────────────────────────
                if (widget.globalStats) ...[
                  // Vista global: estadísticas anónimas sin nombres ni fotos
                  const SizedBox(height: AppSpacing.lg),
                  _EstadisticasGlobalesSection(libro: libro),
                ] else ...[
                  // Ya lo terminaste: "registros" (más abajo) solo cubre
                  // lecturas activas/pendientes, así que un libro finalizado
                  // necesita su propia tarjeta para poder editar
                  // valoración/picante/idioma sin pasar por "Otra vuelta" (que
                  // crearía una relectura). Va primero: es tu contenido
                  // editable, y ahora también lo es el de "Lectores
                  // interesados" (donde tu tarjeta ya se ordena la primera),
                  // así que todo lo tuyo se ve antes que el resto del club.
                  AnclaDeScroll(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_miFinalizado != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          MiFichaLecturaCard(
                            finalizado: _miFinalizado!,
                            onCambiado: _recargarDesdeServidor,
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnclaDeScroll(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_registrosParaLectoresInteresados.isNotEmpty) ...[
                          // Vista de club: tarjetas de cada lector con controles
                          // (+ resumen de otros clubes, ver
                          // _registrosParaLectoresInteresados)
                          const SizedBox(height: AppSpacing.lg),
                          LibroInteresadasSection(
                            registros: _registrosParaLectoresInteresados,
                            finalizados: libro.finalizados,
                            usuariosConFinalizacion: libro.finalizados
                                .map(
                                  (finalizado) =>
                                      finalizado.usuario.trim().toLowerCase(),
                                )
                                .where((usuario) => usuario.isNotEmpty)
                                .toSet(),
                            usuarioActual: usuarioActual,
                            onCambiarEstado: _cambiarEstado,
                            onQuitarPendientes: _quitarPendientes,
                            onActualizarPreferencias: _actualizarPreferencias,
                            onPedirValoracion: (registro) {
                              return FinalizarLibroDialog.show(
                                context,
                                fechaInicioActual: registro.startedAt,
                                formatoActual: registro.formato,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                ConversacionesLibroCard(
                  libro: libro.libro,
                  coverUrl: libro.coverUrl,
                  // Solo tiene sentido ofrecer abrir una conversación desde
                  // cero cuando la usuaria está leyendo el libro ahora mismo;
                  // para el resto de estados (pendiente, pausado, terminado…)
                  // no hay nada que comentar todavía.
                  permiteAbrirConversacion: miEstado == 'LEYENDO',
                ),

                // En vista global las estadísticas ya están integradas más
                // arriba; en modo club mostramos aquí la misma sección de
                // estadísticas (media, distribución, picante, formato...),
                // que sustituye a "Valoraciones" porque la incluye. Se ve
                // desde el primer instante con los datos que ya tenemos del
                // club (síncronos, sin esperar red) y, en cuanto termina de
                // cargar _cargarEstadisticasComunidad, se actualiza sola con
                // los de toda la comunidad — así la ficha nunca se queda sin
                // nada que mostrar mientras esa petición está en curso o si
                // falla (p.ej. sin conexión).
                if (!widget.globalStats &&
                    (libro.registros.isNotEmpty ||
                        libro.finalizados.isNotEmpty ||
                        _hayEstadisticasComunidad)) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _EstadisticasGlobalesSection(
                    libro: _hayEstadisticasComunidad
                        ? LibroAgrupado(
                            libro: libro.libro,
                            genero: libro.genero,
                            registros: _registrosGlobales!,
                            finalizados: _finalizadosGlobales!,
                            yaLoTengo: libro.yaLoTengo,
                            coverUrl: libro.coverUrl,
                            bookId: libro.bookId,
                          )
                        : libro,
                  ),
                ],

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cerrarAtmosferaDelLibro();
    super.dispose();
  }
}

// ─── Otros libros de la saga ────────────────────────────────────────────────────
//
// Sugiere el resto de volúmenes de la saga que ya existen en el catálogo
// (los haya añadido quien sea) para poder guardarlos directamente sin salir
// de la ficha. No se muestra nada si este es el único volumen conocido.

// Los tomos marcados en Sagas como "leído fuera de la app" u "omitido" no
// tienen registro en Library, así que no encajan en el vocabulario de
// ReadingStatusCopy (pensado para estados de lectura reales): sin este
// helper caerían en su rama por defecto y se verían como "En mi estantería".
String _labelVolumenSaga(String estado) {
  switch (estado) {
    case 'LEIDO_EXTERNO':
      return 'Leído fuera de la app';
    case 'OMITIDO':
      return 'Omitido';
    case 'PENDIENTE':
      // "En mi estantería" (la etiqueta compartida de ReadingStatusCopy) no
      // cabe en la columna estrecha de este carrusel sin truncarse a medio
      // palabra; aquí, y solo aquí, usamos la versión corta.
      return 'Pendiente';
    default:
      return ReadingStatusCopy.label(estado);
  }
}

IconData _iconVolumenSaga(String estado) {
  switch (estado) {
    case 'LEIDO_EXTERNO':
      return Icons.history_edu_rounded;
    case 'OMITIDO':
      return Icons.block_rounded;
    default:
      return ReadingStatusCopy.icon(estado);
  }
}

ClubChipVariant _chipVariantVolumenSaga(String estado) {
  switch (estado) {
    case 'LEIDO':
    case 'FINALIZADO':
    case 'LEIDO_EXTERNO':
      return ClubChipVariant.primary;
    case 'LEYENDO':
    case 'RELECTURA':
      return ClubChipVariant.info;
    case 'PAUSADO':
      return ClubChipVariant.warning;
    case 'ABANDONADO':
      return ClubChipVariant.danger;
    case 'OMITIDO':
      return ClubChipVariant.neutral;
    default:
      return ClubChipVariant.warning;
  }
}

class _OtrosVolumenesSagaSection extends StatelessWidget {
  const _OtrosVolumenesSagaSection({
    required this.volumenes,
    required this.anadiendo,
    required this.onAnadir,
    required this.onAbrir,
  });

  final List<PerfilSagaVolumen> volumenes;
  final Set<String> anadiendo;
  final ValueChanged<PerfilSagaVolumen> onAnadir;
  final ValueChanged<PerfilSagaVolumen> onAbrir;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ClubSectionTitle(
          icon: Icons.collections_bookmark_rounded,
          color: AppColors.primary,
          title: 'Otros libros de la saga',
          subtitle: 'Guarda el resto de tomos sin salir de la ficha',
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: volumenes.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final volumen = volumenes[index];
              final yaLoTiene = volumen.estado != 'NO_ANADIDO';
              final estaAnadiendo = anadiendo.contains(volumen.bookId);
              return SizedBox(
                width: 112,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClubBookCover(
                      title: volumen.titulo,
                      imageUrl: volumen.coverUrl,
                      width: 112,
                      height: 158,
                      // Tocable siempre: si aún no lo tiene, openBookDetail
                      // cae a la ficha de catálogo para poder verlo antes
                      // de decidir añadirlo.
                      onTap: () => onAbrir(volumen),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      volumen.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (yaLoTiene)
                      ClubChip(
                        icon: _iconVolumenSaga(volumen.estado),
                        label: _labelVolumenSaga(volumen.estado),
                        variant: _chipVariantVolumenSaga(volumen.estado),
                        maxLines: 1,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: estaAnadiendo
                              ? null
                              : () => onAnadir(volumen),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            minimumSize: const Size(0, 32),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: estaAnadiendo
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_rounded, size: 14),
                          label: const Text(
                            'Añadir',
                            style: TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Estadísticas globales anónimas ────────────────────────────────────────────
//
// Muestra media de valoración, número de personas que lo tienen en biblioteca
// y número de lecturas finalizadas, más una gráfica de barras con la
// distribución de puntuaciones. No expone nombres ni fotos de ningún usuario.

class _EstadisticasGlobalesSection extends StatelessWidget {
  const _EstadisticasGlobalesSection({required this.libro});

  final LibroAgrupado libro;

  /// Convierte la cadena de valoración a double (misma lógica que LibroAgrupado).
  static double _parseRating(String valoracion) {
    final texto = valoracion.trim().replaceAll('⭐️', '⭐').replaceAll(',', '.');
    if (texto.isEmpty || texto == '😞') return 0;
    final num = double.tryParse(texto);
    if (num != null) return ((num.clamp(0, 5)) * 2).round() / 2;
    final stars = RegExp('⭐').allMatches(texto).length;
    final half = texto.contains('½');
    return (((stars + (half ? 0.5 : 0)).clamp(0, 5)) * 2).round() / 2;
  }

  @override
  Widget build(BuildContext context) {
    final media = libro.mediaValoracion;
    final totalBiblioteca = libro.registros.length;
    final totalLeidos = libro.finalizados.length;

    // ── Distribución de puntuaciones ────────────────────────────────────────
    final counts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final fin in libro.finalizados) {
      final val = _parseRating(fin.valoracion);
      if (val > 0) {
        final rounded = val.round().clamp(1, 5);
        counts[rounded] = (counts[rounded] ?? 0) + 1;
      }
    }
    final maxCount = counts.values.fold(0, math.max);
    final hayPuntuaciones = maxCount > 0;

    // ── Nivel picante (opcional) ─────────────────────────────────────────────
    final mediaPicante = libro.mediaPicante;
    final conPicante = libro.finalizados
        .where((f) => f.picante.trim().isNotEmpty)
        .length;
    final hayPicante = mediaPicante > 0;

    // ── Formato de lectura ───────────────────────────────────────────────────
    // Combinamos registros (no finalizados) y finalizados para ver el formato
    // en el que cada persona tiene o leyó el libro.
    final formatCounts = <String, int>{};
    for (final r in libro.registros) {
      final f = r.formato.trim().toUpperCase();
      if (f.isNotEmpty) formatCounts[f] = (formatCounts[f] ?? 0) + 1;
    }
    for (final f in libro.finalizados) {
      final fmt = f.formato.trim().toUpperCase();
      if (fmt.isNotEmpty) formatCounts[fmt] = (formatCounts[fmt] ?? 0) + 1;
    }
    final hayFormatos = formatCounts.isNotEmpty;

    // ── Reseñas públicas ─────────────────────────────────────────────────────
    // Solo las que se pueden ver: de quien comparte club o tiene el perfil
    // en público (el servidor ya no envía el texto de las demás). Las más
    // recientes primero.
    final resenas = libro.finalizados
        .where((f) => f.mismoClub && f.resena.trim().isNotEmpty)
        .toList()
      ..sort((a, b) {
        final fa = a.finishedAt;
        final fb = b.finishedAt;
        if (fa == null && fb == null) return 0;
        if (fa == null) return 1;
        if (fb == null) return -1;
        return fb.compareTo(fa);
      });

    return LibroSection(
      icon: Icons.bar_chart_rounded,
      color: AppColors.primary,
      title: 'Estadísticas',
      subtitle: 'Datos globales de la comunidad',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Chips de resumen ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.star_rounded,
                  iconColor: AppColors.gold,
                  value: media > 0 ? media.toStringAsFixed(1) : '—',
                  label: 'Valoración\nmedia',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatChip(
                  icon: Icons.bookmark_outline_rounded,
                  iconColor: AppColors.info,
                  value: '$totalBiblioteca',
                  label: 'En\nbiblioteca',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatChip(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppColors.success,
                  value: '$totalLeidos',
                  label: 'Han\nleído',
                ),
              ),
            ],
          ),

          // ── Gráfica de distribución de puntuaciones ──────────────────────
          if (hayPuntuaciones) ...[
            const SizedBox(height: AppSpacing.lg),
            _RatingBarChart(
              counts: counts,
              maxCount: maxCount,
              onTapStars: (stars) => _mostrarValoracionesPorEstrellas(
                context,
                stars: stars,
                finalizados: libro.finalizados,
              ),
            ),
          ],

          // ── Nivel picante ─────────────────────────────────────────────────
          if (hayPicante) ...[
            const SizedBox(height: AppSpacing.lg),
            _PicanteSection(media: mediaPicante, total: conPicante),
          ],

          // ── Formato de lectura ────────────────────────────────────────────
          if (hayFormatos) ...[
            const SizedBox(height: AppSpacing.lg),
            _FormatoSection(formatCounts: formatCounts),
          ],

          // ── Reseñas ───────────────────────────────────────────────────────
          if (resenas.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _ResenasPublicasSection(resenas: resenas),
          ],
        ],
      ),
    );
  }
}

/// Abre la lista de valoraciones de ClubReads con la puntuación [stars]
/// pulsada en la gráfica de distribución. Igual que el resto de la vista
/// global, cada valoración llega ya anonimizada desde el backend salvo que
/// [LibroFinalizado.mismoClub] sea true (comparte algún club con quien mira).
void _mostrarValoracionesPorEstrellas(
  BuildContext context, {
  required int stars,
  required List<LibroFinalizado> finalizados,
}) {
  final filtradas = finalizados.where((f) {
    final val = _EstadisticasGlobalesSection._parseRating(f.valoracion);
    return val > 0 && val.round().clamp(1, 5) == stars;
  }).toList();

  if (filtradas.isEmpty) return;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ValoracionesPorEstrellaSheet(
      stars: stars,
      valoraciones: filtradas,
    ),
  );
}

class _ValoracionesPorEstrellaSheet extends StatelessWidget {
  const _ValoracionesPorEstrellaSheet({
    required this.stars,
    required this.valoraciones,
  });

  final int stars;
  final List<LibroFinalizado> valoraciones;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const SizedBox(width: AppSpacing.lg),
                  Row(
                    children: List.generate(
                      stars,
                      (_) => const Icon(
                        Icons.star_rounded,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      valoraciones.length == 1
                          ? '1 lector'
                          : '${valoraciones.length} lectores',
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: valoraciones.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) =>
                      _ValoracionAnonimaCard(valoracion: valoraciones[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ValoracionAnonimaCard extends StatefulWidget {
  const _ValoracionAnonimaCard({required this.valoracion});

  final LibroFinalizado valoracion;

  @override
  State<_ValoracionAnonimaCard> createState() =>
      _ValoracionAnonimaCardState();
}

class _ValoracionAnonimaCardState extends State<_ValoracionAnonimaCard> {
  bool _resenaVisible = false;

  @override
  Widget build(BuildContext context) {
    final valoracion = widget.valoracion;
    final nombre = valoracion.mismoClub
        ? valoracion.usuario
        : 'Lector de otro club';
    final resena = valoracion.resena.trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClubAvatar(
                // Para anónimas, nombre vacío + neutralWhenUnnamed fuerza el
                // icono de persona genérico en vez de sacar iniciales de
                // "Lector de otro club" (que parecían las de alguien real).
                // Con perfil público o mismo club, se ve la foto real.
                nombre: valoracion.mismoClub ? nombre : '',
                imageUrl: valoracion.mismoClub ? valoracion.avatarUrl : '',
                neutralWhenUnnamed: true,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (resena.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _resenaVisible
                  ? Text(
                      key: const ValueKey('resena-visible'),
                      resena,
                      style: AppTextStyles.bodySecondary.copyWith(
                        height: 1.35,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : InkWell(
                      key: const ValueKey('resena-oculta'),
                      onTap: () => setState(() => _resenaVisible = true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.midnight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Reflexión oculta · toca para revelar posibles spoilers',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chip de estadística con icono, valor grande y etiqueta pequeña.
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.section.copyWith(
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formato de lectura ────────────────────────────────────────────────────────

class _FormatoSection extends StatelessWidget {
  const _FormatoSection({required this.formatCounts});

  final Map<String, int> formatCounts;

  static const _formatos = [
    (key: 'FISICO', emoji: FormatoLibro.emojiPapel, label: FormatoLibro.papel),
    (key: 'DIGITAL', emoji: FormatoLibro.emojiEbook, label: FormatoLibro.ebook),
    (
      key: 'AUDIOLIBRO',
      emoji: FormatoLibro.emojiAudiolibro,
      label: FormatoLibro.audiolibro,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final total = formatCounts.values.fold(0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formato de lectura',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: .3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            // Sin crossAxisAlignment.stretch: esta Row está dentro de un
            // Column sin altura acotada (le llega altura infinita desde
            // arriba), y pedirle que estire sus hijos a esa altura
            // provocaba un error de layout en cada frame durante el scroll.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _formatos
                .where((f) => (formatCounts[f.key] ?? 0) > 0)
                .map((f) {
              final count = formatCounts[f.key]!;
              final pct = total > 0 ? (count / total * 100).round() : 0;
              // Anchos iguales para cada pastilla: con flex proporcional al
              // recuento, un formato minoritario (p.ej. 1 audiolibro frente
              // a 5 físicos) se quedaba con una columna tan estrecha que su
              // etiqueta ("Audiolibro") se partía letra a letra.
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _FormatoPill(
                    emoji: f.emoji,
                    label: f.label,
                    count: count,
                    pct: pct,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FormatoPill extends StatelessWidget {
  const _FormatoPill({
    required this.emoji,
    required this.label,
    required this.count,
    required this.pct,
  });

  final String emoji;
  final String label;
  final int count;
  final int pct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            '$pct%',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          Text(
            count == 1 ? '1 lector' : '$count lectores',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nivel picante ──────────────────────────────────────────────────────────────

class _PicanteSection extends StatelessWidget {
  const _PicanteSection({required this.media, required this.total});

  final double media;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌶️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Nivel picante',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: .3,
                  ),
                ),
              ),
              Text(
                total == 1 ? '1 valoración' : '$total valoraciones',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${media.toStringAsFixed(1)} / 5',
            style: AppTextStyles.section.copyWith(
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reseñas públicas ──────────────────────────────────────────────────────────

/// Vista previa de las reseñas más recientes visibles para quien mira, para
/// leerlas de un vistazo. Muestra solo las últimas [_maximo]: para ver todas
/// están las barras de puntuación de arriba (cada una abre sus reseñas), así
/// que la ficha no se alarga aunque el libro tenga cientos. Las marcadas con
/// spoilers siguen ocultas hasta tocarlas.
class _ResenasPublicasSection extends StatelessWidget {
  const _ResenasPublicasSection({required this.resenas});

  /// Ya ordenadas de más reciente a más antigua.
  final List<LibroFinalizado> resenas;

  static const _maximo = 3;

  @override
  Widget build(BuildContext context) {
    final total = resenas.length;
    final visibles = resenas.take(_maximo).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('💬', style: TextStyle(fontSize: 18)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                total > _maximo ? 'Últimas reseñas' : 'Reseñas',
                style: AppTextStyles.subtitle.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$total',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final r in visibles) ...[
          _ResenaCard(resena: r),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (total > _maximo)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              'Mostramos las $_maximo más recientes. Toca una puntuación de '
              'arriba para leer todas las reseñas de esa nota.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

class _ResenaCard extends StatefulWidget {
  const _ResenaCard({required this.resena});

  final LibroFinalizado resena;

  @override
  State<_ResenaCard> createState() => _ResenaCardState();
}

class _ResenaCardState extends State<_ResenaCard> {
  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic', //
  ];

  late bool _oculta = widget.resena.contieneSpoilers;
  bool _expandida = false;

  Widget _estrellas(double valor) {
    final icons = <Widget>[];
    for (var i = 1; i <= 5; i++) {
      final IconData icono;
      if (valor >= i) {
        icono = Icons.star_rounded;
      } else if (valor >= i - 0.5) {
        icono = Icons.star_half_rounded;
      } else {
        icono = Icons.star_outline_rounded;
      }
      icons.add(Icon(icono, size: 15, color: AppColors.gold));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: icons);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resena;
    final valor = _EstadisticasGlobalesSection._parseRating(r.valoracion);
    final fecha = r.finishedAt;
    final cuando = fecha == null
        ? null
        : '${_meses[fecha.month - 1]} ${fecha.year}';
    final texto = r.resena.trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClubAvatar(
                nombre: r.usuario,
                imageUrl: r.avatarUrl,
                neutralWhenUnnamed: true,
                size: 36,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.usuario,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (valor > 0) _estrellas(valor),
                  ],
                ),
              ),
              if (cuando != null)
                Text(cuando, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_oculta)
            InkWell(
              onTap: () => setState(() => _oculta = false),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.midnight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.visibility_off_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Contiene spoilers · toca para leerla',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => setState(() => _expandida = !_expandida),
              child: Text(
                texto,
                maxLines: _expandida ? null : 6,
                overflow: _expandida
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: AppTextStyles.bodySecondary.copyWith(height: 1.35),
              ),
            ),
        ],
      ),
    );
  }
}

/// Gráfica de barras horizontal con la distribución de puntuaciones 1-5.
class _RatingBarChart extends StatelessWidget {
  const _RatingBarChart({
    required this.counts,
    required this.maxCount,
    this.onTapStars,
  });

  final Map<int, int> counts;
  final int maxCount;
  final ValueChanged<int>? onTapStars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución de puntuaciones',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: .3,
            ),
          ),
          if (onTapStars != null) ...[
            const SizedBox(height: 2),
            Text(
              'Toca una puntuación para ver esas reseñas',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          for (int stars = 5; stars >= 1; stars--) ...[
            _BarRow(
              stars: stars,
              count: counts[stars] ?? 0,
              maxCount: maxCount,
              onTap: onTapStars == null || (counts[stars] ?? 0) == 0
                  ? null
                  : () => onTapStars!(stars),
            ),
            if (stars > 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.stars,
    required this.count,
    required this.maxCount,
    this.onTap,
  });

  final int stars;
  final int count;
  final int maxCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = maxCount > 0 ? count / maxCount : 0.0;
    // Barra simplificada (sin LayoutBuilder/Stack/AnimatedContainer ni
    // InkWell): esa combinación, recién insertada de golpe en el árbol al
    // llegar los datos de la comunidad, disparaba un assert de semantics
    // de Flutter ('!semantics.parentDataDirty') que bloqueaba el scroll de
    // toda la ficha. GestureDetector + FractionallySizedBox evitan el
    // problema manteniendo el mismo aspecto visual, sin animación.
    final row = Row(
      children: [
        // Etiqueta de estrellas
        SizedBox(
          width: 28,
          child: Row(
            children: [
              Text(
                '$stars',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.star_rounded, color: AppColors.gold, size: 12),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Barra
        Expanded(
          child: Container(
            height: 18,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: AppColors.border.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(9),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: ratio.clamp(0, 1),
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: .75),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Contador
        SizedBox(
          width: 24,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: count > 0 ? AppColors.textSecondary : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );

    if (onTap == null) return row;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: row,
      ),
    );
  }
}

// ── Feature 2: banner de atmósfera en la ficha del libro ──────────────────
class _AtmosferaBanner extends StatelessWidget {
  final KitLecturaSeleccion seleccion;

  const _AtmosferaBanner({required this.seleccion});

  @override
  Widget build(BuildContext context) {
    final icono = seleccion.atmosferaIcono.trim().isEmpty
        ? '✨'
        : seleccion.atmosferaIcono;
    final titulo = seleccion.atmosferaTitulo.trim().isEmpty
        ? 'Atmósfera activa'
        : seleccion.atmosferaTitulo;
    final descripcion = seleccion.atmosferaDescripcion.trim().isEmpty
        ? null
        : seleccion.atmosferaDescripcion;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(icono, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: AppTextStyles.subtitle.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                if (descripcion != null)
                  Text(
                    descripcion,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            'Tu atmósfera',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
