import 'package:flutter/material.dart';

import '../models/perfil_usuario.dart';
import '../models/libro_agrupado.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../utils/genero_utils.dart';
import '../widgets/common/club_avatar.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';
import '../widgets/common/club_empty_state.dart';
import '../widgets/common/club_section_title.dart';
import '../widgets/error_view.dart';
import '../services/usuario_service.dart';
import '../widgets/perfil/editar_fechas_lectura_dialog.dart';
import '../utils/lectura_fecha_utils.dart';
import '../widgets/perfil/editar_avatar_dialog.dart';
import '../widgets/perfil/perfil_timeline_lectura.dart';
import '../widgets/common/club_rating_stars.dart';
import 'detalle_libro_page.dart';
import 'acerca_de_page.dart';

class PerfilUsuarioPage extends StatefulWidget {
  final String usuario;

  const PerfilUsuarioPage({super.key, required this.usuario});

  @override
  State<PerfilUsuarioPage> createState() => _PerfilUsuarioPageState();
}

class _PerfilUsuarioPageState extends State<PerfilUsuarioPage> {
  late Future<PerfilUsuario> future;
  String? usuarioActual;

  @override
  void initState() {
    super.initState();

    future = _cargarPerfil();
    _cargarUsuarioActual();
  }

  Future<void> _editarAvatar(PerfilUsuario perfil) async {
    if (!esMiPerfil) return;

    final nuevaUrl = await showDialog<String>(
      context: context,
      builder: (_) => EditarAvatarDialog(avatarUrlActual: perfil.avatarUrl),
    );

    if (nuevaUrl == null) return;

    final respuesta = await ApiService().actualizarAvatarPerfil(
      usuario: widget.usuario,
      avatarUrl: nuevaUrl,
    );

    if (!mounted) return;

    final ok = respuesta['ok'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          respuesta['mensaje']?.toString() ??
              (ok
                  ? 'Foto de perfil actualizada'
                  : 'No se ha podido actualizar la foto'),
        ),
      ),
    );

    if (ok) {
      await _recargar();
    }
  }

  Future<void> _editarFechas(PerfilLibroTerminado libro) async {
    if (!esMiPerfil || libro.libraryId.trim().isEmpty) {
      return;
    }

    final resultado = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => EditarFechasLecturaDialog(libro: libro),
    );

    if (resultado == null) return;

    Map<String, dynamic> respuesta;

    try {
      respuesta = await ApiService().actualizarFechasLectura(
        usuario: widget.usuario,
        libraryId: libro.libraryId,
        completionId: libro.completionId,
        fechaInicio: resultado['fechaInicio'] ?? '',
        fechaFin: resultado['fechaFin'] ?? '',
        valoracion: resultado['valoracion'],
        resena: resultado['resena'],
      );
    } catch (_) {
      respuesta = {
        'ok': false,
        'mensaje': 'No se han podido actualizar las fechas.',
      };
    }

    if (!mounted) return;

    final ok = respuesta['ok'] == true;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          respuesta['mensaje']?.toString() ??
              (ok
                  ? 'Fechas actualizadas'
                  : 'No se han podido actualizar las fechas'),
        ),
      ),
    );

    if (ok) {
      await _recargar();
    }
  }

  Future<void> _editarFechaInicio(PerfilLibro libro) async {
    if (!esMiPerfil || libro.libraryId.trim().isEmpty) return;

    final hoy = DateTime.now();
    final actual = LecturaFechaUtils.parse(libro.fechaInicio) ?? hoy;
    final elegida = await showDatePicker(
      context: context,
      initialDate: actual.isAfter(hoy) ? hoy : actual,
      firstDate: DateTime(1950),
      lastDate: hoy,
      helpText: 'Fecha de inicio de la lectura',
    );
    if (elegida == null || !mounted) return;

    final mes = elegida.month.toString().padLeft(2, '0');
    final dia = elegida.day.toString().padLeft(2, '0');
    final respuesta = await ApiService().actualizarFechasLectura(
      usuario: widget.usuario,
      libraryId: libro.libraryId,
      fechaInicio: '${elegida.year}-$mes-$dia',
      fechaFin: '',
    );
    if (!mounted) return;

    final ok = respuesta['ok'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          respuesta['mensaje']?.toString() ??
              (ok
                  ? 'Fecha de inicio actualizada'
                  : 'No se ha podido actualizar la fecha'),
        ),
      ),
    );
    if (ok) await _recargar();
  }

  Future<void> _abrirFichaLibro(PerfilLibro libro) async {
    try {
      final data = await ApiService().getLibrosData();
      if (!mounted) return;

      final registros = data.libros
          .where(
            (item) =>
                (libro.bookId.isNotEmpty && item.bookId == libro.bookId) ||
                item.libro.trim().toLowerCase() ==
                    libro.libro.trim().toLowerCase(),
          )
          .toList();
      final finalizados = data.finalizados
          .where(
            (item) =>
                (libro.bookId.isNotEmpty && item.bookId == libro.bookId) ||
                item.libro.trim().toLowerCase() ==
                    libro.libro.trim().toLowerCase(),
          )
          .toList();

      if (registros.isEmpty && finalizados.isEmpty) return;

      final agrupado = LibroAgrupado(
        libro: libro.libro,
        genero: libro.genero,
        registros: registros,
        finalizados: finalizados,
        yaLoTengo: registros.any((item) => item.yaLoTengo),
        coverUrl: libro.coverUrl.isNotEmpty
            ? libro.coverUrl
            : registros.isNotEmpty
            ? registros.first.coverUrl
            : finalizados.first.coverUrl,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetalleLibroPage(libro: agrupado)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido abrir la ficha.')),
      );
    }
  }

  Future<void> _cargarUsuarioActual() async {
    final usuario = await UsuarioService().obtenerUsuario();

    if (!mounted) return;

    setState(() {
      usuarioActual = usuario?.trim();
    });
  }

  bool get esMiPerfil {
    return usuarioActual != null &&
        usuarioActual!.trim().isNotEmpty &&
        usuarioActual!.toLowerCase() == widget.usuario.trim().toLowerCase();
  }

  Future<PerfilUsuario> _cargarPerfil() {
    return ApiService().getPerfilUsuario(widget.usuario);
  }

  Future<void> _recargar() async {
    setState(() {
      future = _cargarPerfil();
    });

    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil lector')),
      body: FutureBuilder<PerfilUsuario>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorView(onRetry: _recargar);
          }

          final perfil = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _recargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                100,
              ),
              children: [
                _cabeceraPerfil(perfil),

                const SizedBox(height: AppSpacing.lg),

                _resumenLectura(perfil),

                const SizedBox(height: AppSpacing.xl),

                ClubSectionTitle(
                  title: 'Leyendo ahora',
                  subtitle: perfil.leyendo.isEmpty
                      ? 'Ahora mismo no tiene ninguna lectura activa'
                      : 'Las historias que tiene entre manos',
                  icon: Icons.menu_book_rounded,
                  padding: EdgeInsets.zero,
                ),

                const SizedBox(height: AppSpacing.sm),

                if (perfil.leyendo.isEmpty)
                  const ClubEmptyState(
                    icon: Icons.auto_stories_outlined,
                    title: 'Entre lecturas',
                    message: 'Cuando empiece un nuevo libro, aparecerá aquí.',
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  )
                else
                  ...perfil.leyendo.map(
                    (libro) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _libroLeyendo(libro: libro),
                    ),
                  ),

                const SizedBox(height: AppSpacing.lg),
                if (perfil.terminados.isNotEmpty) ...[
                  ClubSectionTitle(
                    title: 'Actividad lectora',
                    subtitle: 'Su recorrido libro a libro',
                    icon: Icons.timeline_rounded,
                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  PerfilTimelineLectura(libros: perfil.terminados),

                  const SizedBox(height: AppSpacing.lg),
                ],
                ClubSectionTitle(
                  title: 'Libros terminados',
                  subtitle: 'Las lecturas más recientes de ${perfil.usuario}',
                  icon: Icons.check_circle_outline_rounded,
                  padding: EdgeInsets.zero,
                ),

                const SizedBox(height: AppSpacing.sm),

                if (perfil.terminados.isEmpty)
                  const ClubEmptyState(
                    icon: Icons.flag_outlined,
                    title: 'Todavía no hay libros terminados',
                    message:
                        'Las próximas lecturas finalizadas aparecerán aquí.',
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  )
                else
                  ...perfil.terminados.map(
                    (libro) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _libroTerminado(libro: libro),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                ClubSectionTitle(
                  title: 'Libros abandonados',
                  subtitle: 'Las lecturas que decidió dejar',
                  icon: Icons.heart_broken_outlined,
                  padding: EdgeInsets.zero,
                ),

                const SizedBox(height: AppSpacing.sm),

                if (perfil.abandonados.isEmpty)
                  const ClubEmptyState(
                    icon: Icons.heart_broken_outlined,
                    title: 'No hay libros abandonados',
                    message: 'Todas sus lecturas siguen adelante.',
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  )
                else
                  ...perfil.abandonados.map(
                    (libro) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _libroAbandonado(libro: libro),
                    ),
                  ),

                if (perfil.generosFavoritos.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),

                  const ClubSectionTitle(
                    title: 'Géneros favoritos',
                    subtitle: 'Los universos que más visita',
                    icon: Icons.favorite_outline_rounded,
                    padding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  ClubCard(
                    elevated: false,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: perfil.generosFavoritos
                          .map(
                            (genero) => ClubChip(
                              label:
                                  '${iconoGenero(genero.genero)} '
                                  '${genero.genero} · '
                                  '${genero.total}',
                              variant: ClubChipVariant.primary,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                if (esMiPerfil) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const ClubSectionTitle(
                    title: 'Más',
                    icon: Icons.settings_outlined,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClubCard(
                    elevated: false,
                    padding: EdgeInsets.zero,
                    child: Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        leading: const Icon(Icons.info_outline_rounded),
                        title: const Text('Acerca de ClubReads'),
                        subtitle: const Text(
                          'Versión, créditos, privacidad y contacto',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AcercaDePage(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cabeceraPerfil(PerfilUsuario perfil) {
    return ClubCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceSoft, Color(0xFFF0E5FF)],
      ),
      borderColor: AppColors.primaryLight,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClubAvatar(
                    nombre: perfil.usuario,
                    imageUrl: perfil.avatarUrl,
                    size: 96,
                    onTap: esMiPerfil
                        ? () {
                            _editarAvatar(perfil);
                          }
                        : null,
                  ),

                  if (esMiPerfil)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Material(
                        color: Theme.of(context).colorScheme.primary,
                        shape: const CircleBorder(),
                        elevation: 3,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            _editarAvatar(perfil);
                          },
                          child: const SizedBox(
                            width: 34,
                            height: 34,
                            child: Icon(
                              Icons.photo_camera_outlined,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Positioned(
                right: -3,
                bottom: -3,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            perfil.usuario,
            textAlign: TextAlign.center,
            style: AppTextStyles.title,
          ),

          const SizedBox(height: AppSpacing.sm),

          /*
           * Sustituiremos este texto por la frase
           * literaria real cuando la conectemos al backend.
           */
          Text(
            'Cada lectora vive mil vidas entre páginas.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          const ClubChip(
            label: 'Miembro del club',
            icon: Icons.local_library_outlined,
            variant: ClubChipVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _resumenLectura(PerfilUsuario perfil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ClubSectionTitle(
          title: 'Su historia lectora',
          subtitle: 'Un vistazo a su recorrido por el club',
          icon: Icons.insights_rounded,
          padding: EdgeInsets.zero,
        ),

        const SizedBox(height: AppSpacing.sm),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.12,
          children: [
            _statCard(
              titulo: 'Terminados',
              valor: perfil.resumen.terminados.toString(),
              icono: Icons.check_circle_outline_rounded,
              background: const Color(0xFFF1F8F3),
              iconBackground: const Color(0xFFDFF0E4),
              foreground: AppColors.success,
            ),
            _statCard(
              titulo: 'Leyendo',
              valor: perfil.resumen.leyendo.toString(),
              icono: Icons.menu_book_rounded,
              background: const Color(0xFFF1F5FC),
              iconBackground: const Color(0xFFDDE8F8),
              foreground: AppColors.info,
            ),
            _statCard(
              titulo: 'Valoración media',
              valor: perfil.resumen.media > 0
                  ? '${perfil.resumen.media.toStringAsFixed(2)} / 5'
                  : 'Sin datos',
              icono: Icons.star_outline_rounded,
              background: const Color(0xFFFFF9EA),
              iconBackground: const Color(0xFFFFEDBA),
              foreground: const Color(0xFFB48113),
            ),
            _statCard(
              titulo: 'Pendientes',
              valor: perfil.resumen.pendientes.toString(),
              icono: Icons.bookmark_border_rounded,
              background: AppColors.surfaceSoft,
              iconBackground: AppColors.primaryLight,
              foreground: AppColors.primary,
            ),
          ],
        ),
        if (perfil.resumen.relecturas > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          ClubChip(
            label:
                '${perfil.resumen.relecturas} ${perfil.resumen.relecturas == 1 ? 'relectura' : 'relecturas'}',
            icon: Icons.refresh_rounded,
            variant: ClubChipVariant.primary,
          ),
        ],
      ],
    );
  }

  Widget _statCard({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color background,
    required Color iconBackground,
    required Color foreground,
  }) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: background,
      borderColor: foreground.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icono, color: foreground, size: 21),
          ),

          const SizedBox(height: AppSpacing.sm),
          const SizedBox(height: AppSpacing.md),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.section.copyWith(fontSize: 20),
          ),

          const SizedBox(height: AppSpacing.xxs),

          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _libroLeyendo({required PerfilLibro libro}) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => _abrirFichaLibro(libro),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.primary,
              size: 27,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  libro.libro,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                ClubChip(
                  label: '${iconoGenero(libro.genero)} ${libro.genero}',
                  variant: ClubChipVariant.primary,
                ),
                if (libro.esRelectura) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const ClubChip(
                    label: 'Relectura',
                    icon: Icons.refresh_rounded,
                    variant: ClubChipVariant.primary,
                  ),
                ],
                if (libro.fechaInicio.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Desde el ${libro.fechaInicio}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.xs),

          if (esMiPerfil)
            IconButton(
              tooltip: 'Editar fecha de inicio',
              onPressed: () => _editarFechaInicio(libro),
              icon: const Icon(Icons.edit_calendar_outlined),
            )
          else
            const Icon(Icons.auto_stories_rounded, color: AppColors.info),
        ],
      ),
    );
  }

  Widget _libroTerminado({required PerfilLibroTerminado libro}) {
    final duracion = LecturaFechaUtils.duracion(
      libro.fechaInicio,
      libro.fechaFin,
    );

    final rangoFechas = LecturaFechaUtils.rango(
      libro.fechaInicio,
      libro.fechaFin,
    );

    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 62,
              height: 88,
              child: libro.coverUrl.trim().isNotEmpty
                  ? Image.network(
                      libro.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return _portadaVacia();
                      },
                    )
                  : _portadaVacia(),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  libro.libro,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  '${iconoGenero(libro.genero)} ${libro.genero}',
                  style: AppTextStyles.bodySecondary,
                ),

                if (libro.esRelectura) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const ClubChip(
                    label: 'Relectura',
                    icon: Icons.refresh_rounded,
                    variant: ClubChipVariant.primary,
                  ),
                ],

                if (libro.valoracion.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),

                  ClubRatingStars(
                    valoracion: libro.valoracion,
                    size: 19,
                    spacing: 1,
                  ),
                ],
                if (duracion.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),

                  Text(
                    duracion,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],

                if (rangoFechas.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Text(
                    rangoFechas,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (esMiPerfil) ...[
            const SizedBox(width: AppSpacing.xs),

            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                tooltip: 'Editar fechas',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                  maxWidth: 44,
                  maxHeight: 44,
                ),
                icon: const Icon(Icons.edit_calendar_outlined),
                onPressed: libro.libraryId.trim().isEmpty
                    ? null
                    : () {
                        _editarFechas(libro);
                      },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _libroAbandonado({required PerfilLibroTerminado libro}) {
    final rangoFechas = LecturaFechaUtils.rango(
      libro.fechaInicio,
      libro.fechaFin,
    );

    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 62,
              height: 88,
              child: libro.coverUrl.trim().isNotEmpty
                  ? Image.network(
                      libro.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) {
                        return _portadaVacia();
                      },
                    )
                  : _portadaVacia(),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  libro.libro,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  '${iconoGenero(libro.genero)} ${libro.genero}',
                  style: AppTextStyles.bodySecondary,
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  '💔 Lectura abandonada',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),

                if (rangoFechas.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Text(
                    rangoFechas,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (esMiPerfil) ...[
            const SizedBox(width: AppSpacing.xs),

            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                tooltip: 'Editar fechas',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                  maxWidth: 44,
                  maxHeight: 44,
                ),
                icon: const Icon(Icons.edit_calendar_outlined),
                onPressed: libro.libraryId.trim().isEmpty
                    ? null
                    : () {
                        _editarFechas(libro);
                      },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _portadaVacia() {
    return Container(
      color: AppColors.surfaceSoft,
      alignment: Alignment.center,
      child: const Icon(
        Icons.menu_book_rounded,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}
