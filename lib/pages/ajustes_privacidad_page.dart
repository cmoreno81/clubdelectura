import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_section_title.dart';
import '../widgets/error_view.dart';

/// Nombre legible + descripción de cada tipo de notificación, en el mismo
/// orden en que las devuelve el servidor.
const _etiquetasNotificacion = <String, (String, String, String)>{
  'CLUBVISION_ABIERTA': (
    '🗳️',
    'Clubvisión abierta',
    'Cuando tu club abre una votación de próxima lectura',
  ),
  'CLUBVISION_RESULTADOS': (
    '🏆',
    'Resultados de Clubvisión',
    'Cuando ya hay libro ganador',
  ),
  'LECTURA_NUEVA': (
    '📖',
    'Nueva lectura',
    'Cuando el club empieza una lectura oficial o compartida',
  ),
  'LIBRO_NUEVO_BIBLIOTECA': (
    '✨',
    'Libros nuevos en la biblioteca',
    'Cuando alguien añade libros a la biblioteca del club',
  ),
  'LIBRO_EMPEZADO': (
    '📖',
    'Lecturas personales',
    'Cuando una compañera empieza a leer algo por su cuenta',
  ),
  'LIBRO_TERMINADO': (
    '✅',
    'Libros terminados',
    'Cuando una compañera termina un libro',
  ),
  'COMENTARIO_LECTURA': (
    '💬',
    'Comentarios en lecturas',
    'Cuando comentan en un hilo de lectura en el que participas',
  ),
  'NUEVA_MIEMBRO': (
    '👋',
    'Nuevas miembros',
    'Cuando alguien se une a tu club',
  ),
  'LOGRO_DESBLOQUEADO': (
    '🏅',
    'Logros desbloqueados',
    'Cuando una compañera desbloquea un logro del club',
  ),
  'CLUB_BOOK_OF_YEAR': (
    '📚',
    'Libro del año del club',
    'Novedades sobre el Libro del Año de tu club',
  ),
  'LIGA_RESULTADO': (
    '🏆',
    'Resultado de las Ligas',
    'Cuando termina una temporada y sabes en qué puesto quedaste',
  ),
  'LIGA_CIERRE_PROXIMO': (
    '⏳',
    'Cierre de temporada de Ligas',
    'Un aviso cuando quedan pocas horas para el fin de la temporada',
  ),
};

class AjustesPrivacidadPage extends StatefulWidget {
  const AjustesPrivacidadPage({super.key});

  @override
  State<AjustesPrivacidadPage> createState() => _AjustesPrivacidadPageState();
}

class _AjustesPrivacidadPageState extends State<AjustesPrivacidadPage> {
  late Future<_AjustesData> _future;

  @override
  void initState() {
    super.initState();
    _future = _cargar();
  }

  Future<_AjustesData> _cargar() async {
    final api = ApiService();
    final results = await Future.wait([
      api.getPreferenciasNotificacion(),
      api.getPrivacidadPerfil(),
    ]);
    return _AjustesData(
      tipos: results[0] as List<Map<String, dynamic>>,
      visibilidad: results[1] as String,
    );
  }

  void _recargar() {
    setState(() => _future = _cargar());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad y notificaciones')),
      body: FutureBuilder<_AjustesData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorView(onRetry: _recargar);
          }
          return _AjustesBody(
            data: snapshot.data!,
            onCambio: _recargar,
          );
        },
      ),
    );
  }
}

class _AjustesData {
  const _AjustesData({required this.tipos, required this.visibilidad});
  final List<Map<String, dynamic>> tipos;
  final String visibilidad;
}

class _AjustesBody extends StatefulWidget {
  const _AjustesBody({required this.data, required this.onCambio});
  final _AjustesData data;
  final VoidCallback onCambio;

  @override
  State<_AjustesBody> createState() => _AjustesBodyState();
}

class _AjustesBodyState extends State<_AjustesBody> {
  late Map<String, bool> _activados;
  late String _visibilidad;
  final Set<String> _guardando = {};
  bool _guardandoPrivacidad = false;

  @override
  void initState() {
    super.initState();
    _activados = {
      for (final t in widget.data.tipos)
        t['tipo']?.toString() ?? '': t['activado'] == true,
    };
    _visibilidad = widget.data.visibilidad;
  }

  Future<void> _toggle(String tipo, bool valor) async {
    setState(() {
      _activados[tipo] = valor;
      _guardando.add(tipo);
    });
    final ok = await ApiService().actualizarPreferenciaNotificacion(
      tipo: tipo,
      activado: valor,
    );
    if (!mounted) return;
    setState(() => _guardando.remove(tipo));
    if (!ok) {
      setState(() => _activados[tipo] = !valor);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido guardar el cambio')),
      );
    }
  }

  Future<void> _cambiarVisibilidad(String valor) async {
    if (valor == _visibilidad) return;
    final anterior = _visibilidad;
    setState(() {
      _visibilidad = valor;
      _guardandoPrivacidad = true;
    });
    final ok = await ApiService().actualizarPrivacidadPerfil(
      visibilidad: valor,
    );
    if (!mounted) return;
    setState(() => _guardandoPrivacidad = false);
    if (!ok) {
      setState(() => _visibilidad = anterior);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido guardar el cambio')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const ClubSectionTitle(
          title: 'Privacidad',
          subtitle: 'Quién puede ver tu perfil y tus estadísticas',
          icon: Icons.lock_outline_rounded,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        ClubCard(
          elevated: false,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _VisibilidadOption(
                titulo: 'Miembros de mi club',
                subtitulo:
                    'Solo las personas de tu club actual pueden ver tu '
                    'perfil, tu biblioteca y tus estadísticas',
                icon: Icons.groups_outlined,
                selected: _visibilidad == 'CLUB',
                onTap: () => _cambiarVisibilidad('CLUB'),
              ),
              const Divider(height: 1),
              _VisibilidadOption(
                titulo: 'Solo yo',
                subtitulo:
                    'Nadie más podrá ver tu perfil, ni siquiera tu club. '
                    'Tú sigues viendo todo con normalidad',
                icon: Icons.lock_person_outlined,
                selected: _visibilidad == 'PRIVADO',
                onTap: () => _cambiarVisibilidad('PRIVADO'),
              ),
            ],
          ),
        ),
        if (_guardandoPrivacidad)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.sm),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        const ClubSectionTitle(
          title: 'Notificaciones',
          subtitle: 'Elige qué avisos quieres recibir en la campanita',
          icon: Icons.notifications_outlined,
          padding: EdgeInsets.zero,
        ),
        const SizedBox(height: AppSpacing.sm),
        ClubCard(
          elevated: false,
          padding: EdgeInsets.zero,
          child: Material(
            // ClubCard ya pinta su propio fondo con un DecoratedBox: sin
            // este Material intermedio, el ripple/highlight del switch
            // queda oculto detrás (aviso de Flutter "ListTile background
            // color or ink splashes may be invisible").
            color: Colors.transparent,
            child: Builder(
              builder: (context) {
                final visibles = widget.data.tipos
                    .where((entry) => entry['tipo'] != null)
                    .toList(growable: false);
                return Column(
                  children: [
                    for (final entry in visibles) ...[
                      _NotificacionSwitch(
                        tipo: entry['tipo'].toString(),
                        activado: _activados[entry['tipo'].toString()] ?? true,
                        guardando: _guardando.contains(
                          entry['tipo'].toString(),
                        ),
                        onChanged: (v) => _toggle(entry['tipo'].toString(), v),
                      ),
                      if (entry != visibles.last) const Divider(height: 1),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _VisibilidadOption extends StatelessWidget {
  const _VisibilidadOption({
    required this.titulo,
    required this.subtitulo,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String titulo;
  final String subtitulo;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.surfaceSoft,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      style: AppTextStyles.caption.copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificacionSwitch extends StatelessWidget {
  const _NotificacionSwitch({
    required this.tipo,
    required this.activado,
    required this.guardando,
    required this.onChanged,
  });

  final String tipo;
  final bool activado;
  final bool guardando;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final info = _etiquetasNotificacion[tipo];
    final emoji = info?.$1 ?? '🔔';
    final titulo = info?.$2 ?? tipo;
    final subtitulo = info?.$3;

    return SwitchListTile(
      value: activado,
      onChanged: guardando ? null : onChanged,
      secondary: Text(emoji, style: const TextStyle(fontSize: 22)),
      title: Text(
        titulo,
        style: AppTextStyles.subtitle.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitulo == null
          ? null
          : Text(subtitulo, style: AppTextStyles.caption),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 0,
      ),
      activeTrackColor: AppColors.primary,
    );
  }
}
