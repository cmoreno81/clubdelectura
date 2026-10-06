import 'package:club_lectura_app/utils/formato_libro.dart';
import 'package:flutter/material.dart';

import '../../models/libro.dart';
import '../../models/libro_finalizado.dart';
import '../../services/api_service.dart';
import '../../services/library_refresh_notifier.dart';
import '../../services/usuario_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/corregir_finalizacion_utils.dart';
import '../../utils/reading_status_copy.dart';
import '../common/club_avatar.dart';
import '../common/club_card.dart';
import '../common/club_chip.dart';
import 'libro_section.dart';
import 'pausar_lectura_dialog.dart';

/// Selector de opción estilo "pill" — siempre muestra label + valor,
/// nunca tapa el título con el valor seleccionado.
class _OptionSelector<T> extends StatelessWidget {
  const _OptionSelector({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final Color color;
  final T value;
  final List<({T value, String label, String? emoji})> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label siempre visible arriba
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: .3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        // Chips en fila única con scroll horizontal si hacen falta
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                _buildChip(options[i], i),
                if (i < options.length - 1) const SizedBox(width: 7),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(({T value, String label, String? emoji}) opt, int index) {
    final selected = opt.value == value;
    return GestureDetector(
      onTap: () => onChanged(opt.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          // Sin seleccionar: fondo gris neutro para máximo contraste del texto
          color: selected ? color : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? color : AppColors.border),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: .25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (opt.emoji != null) ...[
              Text(opt.emoji!, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
            ],
            Text(
              opt.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                // Seleccionado → blanco; sin seleccionar → texto oscuro
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_rounded,
                size: 13,
                color: Colors.white.withValues(alpha: .9),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LibroInteresadasSection extends StatelessWidget {
  final List<Libro> registros;
  final List<LibroFinalizado> finalizados;
  final Set<String> usuariosConFinalizacion;
  final String? usuarioActual;
  final Future<void> Function(
    Libro libro,
    String nuevoEstado, {
    String? valoracion,
    String? picante,
    String? reflexion,
    String? motivoPausa,
    String? fechaInicio,
    String? fechaFin,
    String? formato,
  })
  onCambiarEstado;
  final Future<void> Function(Libro libro) onQuitarPendientes;
  final Future<void> Function(Libro libro, String prioridad, String formato)
  onActualizarPreferencias;
  final Future<Map<String, String>?> Function(Libro libro) onPedirValoracion;

  const LibroInteresadasSection({
    super.key,
    required this.registros,
    this.finalizados = const [],
    required this.usuariosConFinalizacion,
    required this.usuarioActual,
    required this.onCambiarEstado,
    required this.onQuitarPendientes,
    required this.onActualizarPreferencias,
    required this.onPedirValoracion,
  });

  @override
  Widget build(BuildContext context) {
    if (registros.isEmpty) {
      return const SizedBox.shrink();
    }

    // Solo mostramos como tarjeta propia a quien comparte club contigo (o
    // eres tú misma): son las únicas con nombre y foto reales. El resto
    // llega ya anonimizado desde el backend ("Lectora de otro club") — en
    // vez de apilar una tarjeta completa por cada una, se resumen juntas
    // más abajo.
    final visibles = registros.where((r) => r.mismoClub).toList();
    final anonimos = registros.where((r) => !r.mismoClub).toList();

    // "Tú" sigue siendo la única tarjeta completa y editable de esta
    // sección (prioridad/formato/estado, y valoración/picante/idioma en
    // MiFichaLecturaCard cuando ya la terminaste). El resto de lectoras de
    // tu club, en cambio, no tienen nada que editar aquí — con un club
    // grande, una tarjeta completa (avatar + nombre + chip) por cada una
    // alargaba muchísimo la ficha, así que se agrupan por estado igual que
    // ya hacíamos con las de otros clubes.
    final actualNormalizado = usuarioActual?.trim().toLowerCase();
    final misRegistros = actualNormalizado == null
        ? const <Libro>[]
        : visibles
              .where(
                (r) => r.usuario.trim().toLowerCase() == actualNormalizado,
              )
              .toList();
    final otrosVisibles = actualNormalizado == null
        ? visibles
        : visibles
              .where(
                (r) => r.usuario.trim().toLowerCase() != actualNormalizado,
              )
              .toList();

    // Dentro de las ya visibles, separamos quien de verdad comparte club
    // contigo (su burbuja solo indica en qué club la conoces, por
    // tooltip) de quien se ve solo porque tiene el perfil en público desde
    // otro club (ahí sí se puede ver la reseña de este libro si la
    // escribió, ya que no hay un club en común que mostrar).
    final enTusClubes = otrosVisibles.where((r) => r.enMiClub).toList();
    final enOtrosClubes = otrosVisibles.where((r) => !r.enMiClub).toList();

    void verResenaPublica(Libro registro) {
      final nombreNormalizado = registro.usuario.trim().toLowerCase();
      LibroFinalizado? resena;
      for (final f in finalizados) {
        if (f.usuario.trim().toLowerCase() == nombreNormalizado) {
          resena = f;
          break;
        }
      }
      if (resena == null || resena.resena.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Esta lectora todavía no tiene reseña de este libro.'),
          ),
        );
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ResenaLectoraSheet(finalizado: resena!),
      );
    }

    return LibroSection(
      icon: Icons.people_outline_rounded,
      color: AppColors.info,
      title: 'Lectores interesados',
      subtitle:
          '${registros.length} miembros tienen este libro en su biblioteca',
      child: Column(
        children: [
          for (final registro in misRegistros)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _LectoraCard(
                registro: registro,
                esUsuarioActual: true,
                tieneFinalizaciones: usuariosConFinalizacion.contains(
                  registro.usuario.trim().toLowerCase(),
                ),
                onCambiarEstado: onCambiarEstado,
                onQuitarPendientes: onQuitarPendientes,
                onActualizarPreferencias: onActualizarPreferencias,
                onPedirValoracion: onPedirValoracion,
              ),
            ),
          if (enTusClubes.isNotEmpty) ...[
            _LectoresPorEstado(
              // Título solo si hace falta distinguir del otro grupo.
              titulo: enOtrosClubes.isNotEmpty ? 'En tus clubes' : null,
              registros: enTusClubes,
            ),
            if (enOtrosClubes.isNotEmpty || anonimos.isNotEmpty)
              const SizedBox(height: AppSpacing.sm),
          ],
          if (enOtrosClubes.isNotEmpty) ...[
            _LectoresPorEstado(
              titulo: 'En otros clubes',
              registros: enOtrosClubes,
              onTapLector: verResenaPublica,
            ),
            if (anonimos.isNotEmpty) const SizedBox(height: AppSpacing.sm),
          ],
          if (anonimos.isNotEmpty) _ResumenAnonimos(registros: anonimos),
        ],
      ),
    );
  }
}

/// Lectoras agrupadas por estado — "Leyendo", "Pendiente", etc. — con solo
/// la burbuja de avatar de cada una (varias caben por fila) en vez de una
/// tarjeta completa por persona que no aportaba nada interactivo. Tocar una
/// burbuja dispara [onTapLector] (abrir perfil o ver su reseña, según el
/// grupo). [titulo] solo se muestra cuando hace falta distinguir este
/// bloque de otro grupo hermano (p. ej. "En tus clubes" vs "En otros
/// clubes"); si es null, los grupos de estado van directos.
class _LectoresPorEstado extends StatelessWidget {
  final String? titulo;
  final List<Libro> registros;
  // null cuando la burbuja no es tocable (p. ej. "En tus clubes": el
  // tooltip ya dice en qué club la conoces, no hace falta abrir nada más).
  final ValueChanged<Libro>? onTapLector;

  const _LectoresPorEstado({
    this.titulo,
    required this.registros,
    this.onTapLector,
  });

  @override
  Widget build(BuildContext context) {
    final porEstado = <String, List<Libro>>{};
    for (final registro in registros) {
      porEstado.putIfAbsent(registro.estado, () => []).add(registro);
    }
    final estados = [
      ..._ResumenAnonimos._ordenEstados.where(porEstado.containsKey),
      ...porEstado.keys.where(
        (estado) => !_ResumenAnonimos._ordenEstados.contains(estado),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titulo != null) ...[
          Text(
            titulo!,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              letterSpacing: .3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (var i = 0; i < estados.length; i++) ...[
          _GrupoLectoresEstado(
            estado: estados[i],
            registros: porEstado[estados[i]]!,
            onTapLector: onTapLector,
          ),
          if (i < estados.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _GrupoLectoresEstado extends StatelessWidget {
  final String estado;
  final List<Libro> registros;
  final ValueChanged<Libro>? onTapLector;

  const _GrupoLectoresEstado({
    required this.estado,
    required this.registros,
    this.onTapLector,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClubChip(
                label: _LectoraCard._labelEstado(estado),
                icon: _LectoraCard._iconoEstado(estado),
                variant: _LectoraCard._varianteEstado(estado),
              ),
              const Spacer(),
              Text(
                '${registros.length}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final registro in registros)
                Tooltip(
                  message: registro.clubCompartido.trim().isEmpty
                      ? registro.usuario
                      : '${registro.usuario} · ${registro.clubCompartido}',
                  child: ClubAvatar(
                    nombre: registro.usuario,
                    imageUrl: registro.avatarUrl,
                    size: 40,
                    onTap: onTapLector == null
                        ? null
                        : () => onTapLector!(registro),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Reseña de una lectora con perfil público de otro club — se muestra al
/// tocar su burbuja en el grupo "En otros clubes". A diferencia de
/// [_ValoracionAnonimaCard] (anónima por estrellas), aquí el nombre ya es
/// público, así que se enseña directamente.
class _ResenaLectoraSheet extends StatelessWidget {
  const _ResenaLectoraSheet({required this.finalizado});

  final LibroFinalizado finalizado;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  ClubAvatar(
                    nombre: finalizado.usuario,
                    imageUrl: finalizado.avatarUrl,
                    size: 44,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          finalizado.usuario,
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (finalizado.valoracion.trim().isNotEmpty)
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                finalizado.valoracion,
                                style: AppTextStyles.bodySecondary,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                finalizado.resena.trim(),
                style: AppTextStyles.body,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Resumen compacto de las lectoras de otros clubes: un contador por estado
/// en vez de una tarjeta completa (con avatar y hueco de acciones vacío)
/// por cada una — no aportan nada interactivo, así que no necesitan el
/// mismo espacio que las tarjetas de tu propio club.
class _ResumenAnonimos extends StatelessWidget {
  final List<Libro> registros;

  const _ResumenAnonimos({required this.registros});

  static const _ordenEstados = [
    'LEYENDO',
    'PENDIENTE',
    'PAUSADO',
    'RELECTURA',
    'FINALIZADO',
    'ABANDONADO',
  ];

  @override
  Widget build(BuildContext context) {
    final conteos = <String, int>{};
    for (final registro in registros) {
      conteos[registro.estado] = (conteos[registro.estado] ?? 0) + 1;
    }
    final estados = [
      ..._ordenEstados.where(conteos.containsKey),
      ...conteos.keys.where((estado) => !_ordenEstados.contains(estado)),
    ];

    // Sin la frase larga de antes ("También lo tienen X personas..."),
    // que repetía la cabecera de la sección — pero sí una etiqueta corta,
    // para que no parezca que estos chips son gente de tu propio club.
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups_2_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                'De otros clubes',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: .3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final estado in estados)
                ClubChip(
                  icon: _LectoraCard._iconoEstado(estado),
                  value: '${conteos[estado]}',
                  label: _LectoraCard._labelEstado(estado),
                  variant: _LectoraCard._varianteEstado(estado),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LectoraCard extends StatelessWidget {
  final Libro registro;
  final bool esUsuarioActual;
  final bool tieneFinalizaciones;
  final Future<void> Function(
    Libro libro,
    String nuevoEstado, {
    String? valoracion,
    String? picante,
    String? reflexion,
    String? motivoPausa,
    String? fechaInicio,
    String? fechaFin,
    String? formato,
  })
  onCambiarEstado;
  final Future<void> Function(Libro libro) onQuitarPendientes;
  final Future<void> Function(Libro libro, String prioridad, String formato)
  onActualizarPreferencias;
  final Future<Map<String, String>?> Function(Libro libro) onPedirValoracion;

  const _LectoraCard({
    required this.registro,
    required this.esUsuarioActual,
    required this.tieneFinalizaciones,
    required this.onCambiarEstado,
    required this.onQuitarPendientes,
    required this.onActualizarPreferencias,
    required this.onPedirValoracion,
  });

  /// Opciones de estado como datos planos para el _EstadoSelector
  List<({String value, String label, String? emoji})> get _opcionesEstadoData {
    if (registro.estado == 'FINALIZADO') {
      return [
        (
          value: 'FINALIZADO',
          label: ReadingStatusCopy.label('FINALIZADO'),
          emoji: '✅',
        ),
        (
          value: 'PENDIENTE',
          label: ReadingStatusCopy.label('PENDIENTE'),
          emoji: '📚',
        ),
        (
          value: 'RELECTURA',
          label: ReadingStatusCopy.label('RELECTURA'),
          emoji: '🔁',
        ),
      ];
    }
    return [
      (
        value: 'PENDIENTE',
        label: ReadingStatusCopy.label('PENDIENTE'),
        emoji: '📚',
      ),
      if (!tieneFinalizaciones || registro.estado == 'LEYENDO')
        (
          value: 'LEYENDO',
          label: ReadingStatusCopy.label('LEYENDO'),
          emoji: '📖',
        ),
      (
        value: 'PAUSADO',
        label: ReadingStatusCopy.label('PAUSADO'),
        emoji: '😮‍💨',
      ),
      (
        value: 'RELECTURA',
        label: ReadingStatusCopy.label('RELECTURA'),
        emoji: '🔁',
      ),
      (
        value: 'ABANDONADO',
        label: ReadingStatusCopy.label('ABANDONADO'),
        emoji: '💔',
      ),
      (
        value: 'FINALIZADO',
        label: ReadingStatusCopy.label('FINALIZADO'),
        emoji: '✅',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: esUsuarioActual
          ? AppColors.surfaceSoft
          : AppColors.surface,
      borderColor: esUsuarioActual ? AppColors.primaryLight : AppColors.divider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClubAvatar(
                nombre: registro.usuario,
                imageUrl: registro.avatarUrl,
                size: 48,
              ),
              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            registro.usuario,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (esUsuarioActual) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const ClubChip(
                            label: 'Tú',
                            icon: Icons.person_rounded,
                            variant: ClubChipVariant.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: ClubChip(
                        label: _labelEstado(registro.estado),
                        icon: _iconoEstado(registro.estado),
                        variant: _varianteEstado(registro.estado),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (esUsuarioActual) ...[
            const SizedBox(height: AppSpacing.md),

            _OptionSelector<String>(
              label: 'Prioridad personal',
              icon: Icons.flag_rounded,
              color: AppColors.warning,
              value: registro.prioridad.isEmpty ? 'MEDIA' : registro.prioridad,
              options: const [
                (value: 'ALTA', label: 'Alta', emoji: '🔴'),
                (value: 'MEDIA', label: 'Media', emoji: '🟡'),
                (value: 'BAJA', label: 'Baja', emoji: '🟢'),
              ],
              onChanged: (value) =>
                  onActualizarPreferencias(registro, value, registro.formato),
            ),

            const SizedBox(height: AppSpacing.md),

            _OptionSelector<String>(
              label: 'Mi formato',
              icon: Icons.library_books_rounded,
              color: AppColors.info,
              value: registro.formato.isEmpty ? '' : registro.formato,
              options: const [
                (
                  value: 'FISICO',
                  label: FormatoLibro.papel,
                  emoji: FormatoLibro.emojiPapel,
                ),
                (
                  value: 'DIGITAL',
                  label: FormatoLibro.ebook,
                  emoji: FormatoLibro.emojiEbook,
                ),
                (
                  value: 'AUDIOLIBRO',
                  label: FormatoLibro.audiolibro,
                  emoji: FormatoLibro.emojiAudiolibro,
                ),
              ],
              onChanged: (value) => onActualizarPreferencias(
                registro,
                registro.prioridad.isEmpty ? 'MEDIA' : registro.prioridad,
                value,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            _EstadoSelector(
              estado: registro.estado,
              opciones: _opcionesEstadoData,
              onChanged: (value) async {
                if (value == null || value == registro.estado) {
                  return;
                }

                if (registro.estado == 'FINALIZADO' && value == 'PENDIENTE') {
                  final confirmado = await confirmarCorreccionFinalizacion(
                    context,
                  );
                  if (!confirmado) return;
                }

                Map<String, String>? datosValoracion;
                String? motivoPausa;

                if (value == 'FINALIZADO') {
                  datosValoracion = await onPedirValoracion(registro);

                  if (datosValoracion == null) {
                    return;
                  }
                }

                if (value == 'PAUSADO') {
                  if (!context.mounted) return;

                  motivoPausa = await showDialog<String>(
                    context: context,
                    builder: (_) => const PausarLecturaDialog(),
                  );

                  if (motivoPausa == null) {
                    return;
                  }
                }

                await onCambiarEstado(
                  registro,
                  value,
                  valoracion: datosValoracion?['valoracion'],
                  picante: datosValoracion?['picante'],
                  reflexion: datosValoracion?['reflexion'],
                  fechaInicio: datosValoracion?['fechaInicio'],
                  fechaFin: datosValoracion?['fechaFin'],
                  formato: datosValoracion?['formato'],
                  motivoPausa: motivoPausa,
                );
              },
            ),

            // Botón aparte y con su propio texto — a propósito, para no
            // meterlo como una pastilla más junto a "Otra vuelta" y compañía
            // (una usuaria nos reportó que le dio sin querer a "Otra vuelta"
            // buscando esto mismo, porque las pastillas están muy juntas).
            if (registro.startedAt != null &&
                registro.estado != 'PENDIENTE' &&
                registro.estado != 'FINALIZADO') ...[
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _editarFechaInicio(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(
                    Icons.edit_calendar_outlined,
                    size: 17,
                  ),
                  label: const Text('Editar fecha de inicio'),
                ),
              ),
            ],
          ],
          if (registro.estado == 'PAUSADO') ...[
            const SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF4E0B0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.pause_circle_outline_rounded,
                        color: Color(0xFF9A6B10),
                        size: 20,
                      ),

                      const SizedBox(width: AppSpacing.xs),

                      Expanded(
                        child: Text(
                          _textoFechaPausa(registro.pausedAt),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySecondary.copyWith(
                            color: const Color(0xFF7D5C17),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (registro.pauseReason.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          color: Color(0xFF9A6B10),
                          size: 20,
                        ),

                        const SizedBox(width: AppSpacing.xs),

                        Expanded(
                          child: Text(
                            registro.pauseReason.trim(),
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: AppColors.textPrimary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          // No repetimos la valoración aquí para nadie: con un club grande
          // esta tarjeta ("¿quién tiene o ha leído este libro?") se llenaba
          // de estrellas duplicadas que ya se ven, con más detalle, en la
          // sección "Valoraciones" — y para "Tú" además en la tarjeta "Mi
          // valoración" de MiFichaLecturaCard, justo debajo.

          if (esUsuarioActual && registro.estado == 'PENDIENTE') ...[
            const SizedBox(height: AppSpacing.sm),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  onQuitarPendientes(registro);
                },
                icon: const Icon(
                  Icons.remove_circle_outline_rounded,
                  color: AppColors.danger,
                ),
                label: const Text(
                  'Quitar de mi lista',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _textoFechaPausa(DateTime? fecha) {
    if (fecha == null) {
      return 'Lectura en pausa';
    }

    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays <= 0) {
      return 'Pausada hoy';
    }

    if (diferencia.inDays == 1) {
      return 'Pausada ayer';
    }

    if (diferencia.inDays < 7) {
      return 'En pausa desde hace ${diferencia.inDays} días';
    }

    if (diferencia.inDays < 30) {
      final semanas = (diferencia.inDays / 7).floor();

      return semanas == 1
          ? 'En pausa desde hace 1 semana'
          : 'En pausa desde hace $semanas semanas';
    }

    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    return 'En pausa desde el '
        '${fecha.day} ${meses[fecha.month - 1]}';
  }

  static String _labelEstado(String estado) {
    return ReadingStatusCopy.label(estado);
  }

  static IconData _iconoEstado(String estado) {
    return ReadingStatusCopy.icon(estado);
  }

  static ClubChipVariant _varianteEstado(String estado) {
    switch (estado) {
      case 'LEYENDO':
        return ClubChipVariant.info;
      case 'PAUSADO':
        return ClubChipVariant.warning;
      case 'RELECTURA':
        return ClubChipVariant.primary;
      case 'FINALIZADO':
        return ClubChipVariant.success;
      case 'ABANDONADO':
      case 'ABANDONED':
        return ClubChipVariant.danger;
      default:
        return ClubChipVariant.warning;
    }
  }

  Future<void> _editarFechaInicio(BuildContext context) async {
    final hoy = DateTime.now();
    final inicial = registro.startedAt ?? hoy;
    final elegida = await showDatePicker(
      context: context,
      initialDate: inicial.isAfter(hoy) ? hoy : inicial,
      firstDate: DateTime(1950),
      lastDate: hoy,
      helpText: 'Fecha en que empezaste a leer',
      confirmText: 'Aceptar',
      cancelText: 'Cancelar',
    );
    if (elegida == null || !context.mounted) return;

    final usuario = await UsuarioService().obtenerUsuario();
    if (usuario == null || usuario.trim().isEmpty || !context.mounted) return;

    final ok = await ApiService().editarFechaInicioLectura(
      usuario: usuario,
      libro: registro.libro,
      fechaInicio: elegida,
    );

    if (!context.mounted) return;

    if (ok) {
      LibraryRefreshNotifier.instance.invalidate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fecha de inicio actualizada')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido actualizar la fecha.'),
        ),
      );
    }
  }
}

/// Selector de estado de lectura — versión async-aware que envuelve _OptionSelector.
/// Muestra el label "Estado de lectura" siempre visible sobre los chips.
class _EstadoSelector extends StatelessWidget {
  const _EstadoSelector({
    required this.estado,
    required this.opciones,
    required this.onChanged,
  });

  final String estado;
  final List<({String value, String label, String? emoji})> opciones;
  final Future<void> Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Row(
          children: [
            Icon(Icons.swap_horiz_rounded, size: 14, color: color),
            SizedBox(width: 5),
            Text(
              'Estado de lectura',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: .3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        // Wrap para que todas las opciones sean visibles (pueden ser hasta 6)
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: opciones.map((opt) {
            final selected = opt.value == estado;
            return GestureDetector(
              onTap: () => onChanged(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selected ? color : AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selected ? color : AppColors.border,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: .25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (opt.emoji != null) ...[
                      Text(opt.emoji!, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: Colors.white.withValues(alpha: .9),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
