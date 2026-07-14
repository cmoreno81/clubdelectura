import 'package:club_lectura_app/utils/genero_utils.dart';
import 'package:club_lectura_app/widgets/error_view.dart';
import 'package:flutter/material.dart';

import '../models/candidata_clubvision.dart';
import '../models/clubvision.dart';
import '../services/api_service.dart';
import '../services/usuario_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_button.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';

class ClubvisionVotacionPage extends StatefulWidget {
  final String idVotacion;

  const ClubvisionVotacionPage({super.key, required this.idVotacion});

  @override
  State<ClubvisionVotacionPage> createState() => _ClubvisionVotacionPageState();
}

class _ClubvisionVotacionPageState extends State<ClubvisionVotacionPage> {
  late Future<ClubvisionData> future;

  String usuario = '';
  final List<String> seleccionadas = [];

  bool enviando = false;

  static const puntos = [12, 10, 8, 7, 6];

  @override
  void initState() {
    super.initState();

    _recargar();
    _cargarUsuario();
  }

  void _recargar() {
    future = ApiService().getClubvision();
  }

  Future<void> _cargarUsuario() async {
    final value = await UsuarioService().obtenerUsuario();

    if (!mounted) return;

    setState(() {
      usuario = value ?? '';
    });
  }

  Future<void> _refrescar() async {
    setState(_recargar);
    await future;
  }

  List<CandidataClubvision> _votos(ClubvisionData clubvision) {
    return seleccionadas
        .map(
          (titulo) => clubvision.candidatas.firstWhere(
            (candidata) => candidata.libro == titulo,
          ),
        )
        .toList();
  }

  String _etiquetaPuntos(int posicion) {
    return switch (posicion) {
      0 => '12 puntos',
      1 => '10 puntos',
      2 => '8 puntos',
      3 => '7 puntos',
      _ => '6 puntos',
    };
  }

  String _medalla(int posicion) {
    return switch (posicion) {
      0 => '🥇',
      1 => '🥈',
      2 => '🥉',
      3 => '4',
      _ => '5',
    };
  }

  Color _colorPosicion(int posicion) {
    return switch (posicion) {
      0 => const Color(0xFFE4B63F),
      1 => const Color(0xFF9AA3AF),
      2 => const Color(0xFFB77948),
      _ => AppColors.primary,
    };
  }

  void _cambiarSeleccion(CandidataClubvision candidata) {
    setState(() {
      final seleccionada = seleccionadas.contains(candidata.libro);

      if (seleccionada) {
        seleccionadas.remove(candidata.libro);
        return;
      }

      if (seleccionadas.length < 5) {
        seleccionadas.add(candidata.libro);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu papeleta ya tiene cinco libros.')),
      );
    });
  }

  Future<void> _confirmarEnvio(ClubvisionData clubvision) async {
    final votos = _votos(clubvision);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar votación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu clasificación quedará registrada en este orden:',
                ),

                const SizedBox(height: AppSpacing.md),

                for (var index = 0; index < votos.length; index++) ...[
                  _ResumenVotoDialog(
                    posicion: index,
                    libro: votos[index].libro,
                    puntos: puntos[index],
                  ),

                  if (index < votos.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: enviando
                  ? null
                  : () {
                      Navigator.pop(dialogContext, false);
                    },
              child: const Text('Revisar'),
            ),
            FilledButton.icon(
              onPressed: enviando
                  ? null
                  : () {
                      Navigator.pop(dialogContext, true);
                    },
              icon: const Icon(Icons.how_to_vote_rounded),
              label: const Text('Enviar voto'),
            ),
          ],
        );
      },
    );

    if (confirmar != true || enviando) return;

    if (usuario.trim().isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido identificar a la usuaria.'),
        ),
      );
      return;
    }

    setState(() {
      enviando = true;
    });

    try {
      final ok = await ApiService().enviarVotacion(
        usuario: usuario,
        votos: seleccionadas,
      );

      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se ha podido enviar la votación.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu voto ya forma parte de Clubvisión 💜'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ha ocurrido un error al enviar tu voto.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          enviando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Votación')),
      body: FutureBuilder<ClubvisionData>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorView(
              onRetry: () {
                setState(_recargar);
              },
            );
          }

          final clubvision = snapshot.data!;
          final votos = _votos(clubvision);

          final totalIntereses = clubvision.candidatas.fold<int>(
            0,
            (total, candidata) => total + candidata.interesadas,
          );

          return RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                110,
              ),
              children: [
                _CabeceraVotacion(
                  clubvision: clubvision,
                  usuario: usuario,
                  totalIntereses: totalIntereses,
                ),

                const SizedBox(height: AppSpacing.xl),

                if (clubvision.haVotado)
                  const _VotoRegistrado()
                else if (!clubvision.abierta)
                  const _VotacionCerrada()
                else ...[
                  _SectionHeader(
                    icon: Icons.ballot_outlined,
                    color: AppColors.primary,
                    title: 'Tu papeleta',
                    subtitle: seleccionadas.isEmpty
                        ? 'Elige cinco libros en orden de preferencia'
                        : seleccionadas.length == 5
                        ? 'Tu clasificación está completa'
                        : 'Te faltan ${5 - seleccionadas.length} libros',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  _PapeletaCard(
                    votos: votos,
                    seleccionadas: seleccionadas,
                    onEnviar: seleccionadas.length == 5
                        ? () => _confirmarEnvio(clubvision)
                        : null,
                    enviando: enviando,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  const _SectionHeader(
                    icon: Icons.library_books_outlined,
                    color: AppColors.info,
                    title: 'Candidatas',
                    subtitle: 'Toca cada libro para añadirlo a tu papeleta',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  for (
                    var index = 0;
                    index < clubvision.candidatas.length;
                    index++
                  ) ...[
                    _CandidataCard(
                      candidata: clubvision.candidatas[index],
                      rankingPopularidad: index,
                      posicionSeleccionada: seleccionadas.indexOf(
                        clubvision.candidatas[index].libro,
                      ),
                      totalIntereses: totalIntereses,
                      onTap: () =>
                          _cambiarSeleccion(clubvision.candidatas[index]),
                    ),

                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CabeceraVotacion extends StatelessWidget {
  final ClubvisionData clubvision;
  final String usuario;
  final int totalIntereses;

  const _CabeceraVotacion({
    required this.clubvision,
    required this.usuario,
    required this.totalIntereses,
  });

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.surfaceSoft, Color(0xFFF1E8FF)],
      ),
      borderColor: AppColors.primaryLight,
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              clubvision.abierta
                  ? Icons.how_to_vote_rounded
                  : Icons.lock_outline_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            clubvision.abierta ? 'Votación abierta' : 'Votación cerrada',
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 29),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            usuario.trim().isEmpty
                ? 'Elegimos juntas la próxima lectura del club.'
                : 'Hola, $usuario. Elige las historias que más te apetece leer.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(height: 1.45),
          ),

          const SizedBox(height: AppSpacing.lg),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ClubChip(
                label: '${clubvision.candidatas.length} candidatas',
                icon: Icons.library_books_outlined,
                variant: ClubChipVariant.primary,
              ),
              ClubChip(
                label: '$totalIntereses intereses',
                icon: Icons.people_outline_rounded,
                variant: ClubChipVariant.info,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (clubvision.porcentaje / 100).clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: Colors.white.withOpacity(0.75),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            '${clubvision.votosRecibidos} de '
            '${clubvision.totalUsuarios} lectoras han votado',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withOpacity(0.13),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(icon, color: color, size: 27),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.section.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              Text(
                subtitle,
                style: AppTextStyles.bodySecondary.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PapeletaCard extends StatelessWidget {
  final List<CandidataClubvision> votos;
  final List<String> seleccionadas;
  final VoidCallback? onEnviar;
  final bool enviando;

  const _PapeletaCard({
    required this.votos,
    required this.seleccionadas,
    required this.onEnviar,
    required this.enviando,
  });

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF8F3FF), Color(0xFFF2EAFF)],
      ),
      borderColor: AppColors.primaryLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (votos.isEmpty)
            const _PapeletaVacia()
          else
            for (var index = 0; index < votos.length; index++) ...[
              _PapeletaItem(
                posicion: index,
                libro: votos[index].libro,
                genero: votos[index].genero,
              ),

              if (index < votos.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],

          const SizedBox(height: AppSpacing.lg),

          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: seleccionadas.length / 5,
                    minHeight: 9,
                    backgroundColor: Colors.white.withOpacity(0.8),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              Text(
                '${seleccionadas.length}/5',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          if (onEnviar != null)
            ClubButton(
              label: enviando ? 'Enviando...' : 'Enviar mi votación',
              icon: Icons.how_to_vote_rounded,
              onPressed: enviando ? null : onEnviar,
            )
          else
            Text(
              seleccionadas.isEmpty
                  ? 'Empieza seleccionando tu libro favorito.'
                  : 'Selecciona ${5 - seleccionadas.length} '
                        '${5 - seleccionadas.length == 1 ? 'libro' : 'libros'} más.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

class _PapeletaVacia extends StatelessWidget {
  const _PapeletaVacia();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.62),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        children: [
          Icon(Icons.ballot_outlined, color: AppColors.primary, size: 34),

          SizedBox(height: AppSpacing.sm),

          Text(
            'Tu papeleta está vacía',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),

          SizedBox(height: AppSpacing.xs),

          Text(
            'La primera candidata que selecciones recibirá 12 puntos.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}

class _PapeletaItem extends StatelessWidget {
  final int posicion;
  final String libro;
  final String genero;

  const _PapeletaItem({
    required this.posicion,
    required this.libro,
    required this.genero,
  });

  @override
  Widget build(BuildContext context) {
    final puntos = switch (posicion) {
      0 => 12,
      1 => 10,
      2 => 8,
      3 => 7,
      _ => 6,
    };

    final color = switch (posicion) {
      0 => const Color(0xFFE4B63F),
      1 => const Color(0xFF9AA3AF),
      2 => const Color(0xFFB77948),
      _ => AppColors.primary,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.70),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              posicion < 3 ? ['🥇', '🥈', '🥉'][posicion] : '${posicion + 1}',
              style: TextStyle(
                fontSize: posicion < 3 ? 21 : 17,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  libro,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  '${iconoGenero(genero)} $genero',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          ClubChip(
            label: '$puntos puntos',
            icon: Icons.star_outline_rounded,
            variant: ClubChipVariant.primary,
          ),
        ],
      ),
    );
  }
}

class _CandidataCard extends StatelessWidget {
  final CandidataClubvision candidata;
  final int rankingPopularidad;
  final int posicionSeleccionada;
  final int totalIntereses;
  final VoidCallback onTap;

  const _CandidataCard({
    required this.candidata,
    required this.rankingPopularidad,
    required this.posicionSeleccionada,
    required this.totalIntereses,
    required this.onTap,
  });

  bool get seleccionada => posicionSeleccionada >= 0;

  @override
  Widget build(BuildContext context) {
    final color = seleccionada
        ? AppColors.primary
        : rankingPopularidad == 0
        ? const Color(0xFFE4B63F)
        : rankingPopularidad == 1
        ? const Color(0xFF9AA3AF)
        : rankingPopularidad == 2
        ? const Color(0xFFB77948)
        : AppColors.info;

    final progreso = totalIntereses == 0
        ? 0.0
        : candidata.interesadas / totalIntereses;

    return ClubCard(
      elevated: rankingPopularidad < 3,
      padding: const EdgeInsets.all(AppSpacing.lg),
      gradient: seleccionada
          ? const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8F3FF), Color(0xFFF0E5FF)],
            )
          : null,
      backgroundColor: Colors.white,
      borderColor: color.withOpacity(seleccionada ? 0.55 : 0.22),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                alignment: Alignment.center,
                child: seleccionada
                    ? Text(
                        posicionSeleccionada < 3
                            ? ['🥇', '🥈', '🥉'][posicionSeleccionada]
                            : '${posicionSeleccionada + 1}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Icon(Icons.menu_book_outlined, color: color, size: 28),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidata.libro,
                      style: AppTextStyles.section.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      '${iconoGenero(candidata.genero)} '
                      '${candidata.genero}',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.sm),

              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: seleccionada
                      ? AppColors.primary
                      : color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  seleccionada ? Icons.check_rounded : Icons.add_rounded,
                  color: seleccionada ? Colors.white : color,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ClubChip(
                label: '${candidata.interesadas} interesadas',
                icon: Icons.people_outline_rounded,
                variant: ClubChipVariant.info,
              ),

              if (seleccionada)
                ClubChip(
                  label: '${_puntos(posicionSeleccionada)} puntos',
                  icon: Icons.star_outline_rounded,
                  variant: ClubChipVariant.primary,
                )
              else if (rankingPopularidad < 3)
                ClubChip(
                  label: switch (rankingPopularidad) {
                    0 => 'Favorita',
                    1 => 'Segunda favorita',
                    _ => 'Tercera favorita',
                  },
                  icon: Icons.emoji_events_outlined,
                  variant: ClubChipVariant.warning,
                )
              else if (candidata.interesadas >= 4)
                const ClubChip(
                  label: 'Muy popular',
                  icon: Icons.local_fire_department_outlined,
                  variant: ClubChipVariant.danger,
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progreso.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.surfaceSoft,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Icon(
                seleccionada
                    ? Icons.remove_circle_outline
                    : Icons.add_circle_outline,
                color: color,
                size: 18,
              ),

              const SizedBox(width: AppSpacing.xs),

              Expanded(
                child: Text(
                  seleccionada
                      ? 'Quitar de mi papeleta'
                      : 'Añadir a mi papeleta',
                  style: AppTextStyles.body.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ],
      ),
    );
  }

  int _puntos(int posicion) {
    return switch (posicion) {
      0 => 12,
      1 => 10,
      2 => 8,
      3 => 7,
      _ => 6,
    };
  }
}

class _VotoRegistrado extends StatelessWidget {
  const _VotoRegistrado();

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: const Color(0xFFF1FAF5),
      borderColor: AppColors.success.withOpacity(0.24),
      child: const Column(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 56),

          SizedBox(height: AppSpacing.md),

          Text(
            'Tu voto ya forma parte de esta historia',
            textAlign: TextAlign.center,
            style: AppTextStyles.section,
          ),

          SizedBox(height: AppSpacing.sm),

          Text(
            'Ahora solo queda esperar al desenlace.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}

class _VotacionCerrada extends StatelessWidget {
  const _VotacionCerrada();

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: AppColors.surfaceSoft,
      child: const Column(
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: AppColors.textMuted,
            size: 44,
          ),

          SizedBox(height: AppSpacing.md),

          Text(
            'La votación ha terminado',
            textAlign: TextAlign.center,
            style: AppTextStyles.section,
          ),

          SizedBox(height: AppSpacing.sm),

          Text(
            'Muy pronto conoceremos la próxima lectura del club.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }
}

class _ResumenVotoDialog extends StatelessWidget {
  final int posicion;
  final String libro;
  final int puntos;

  const _ResumenVotoDialog({
    required this.posicion,
    required this.libro,
    required this.puntos,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          posicion < 3 ? ['🥇', '🥈', '🥉'][posicion] : '${posicion + 1}.',
          style: const TextStyle(fontSize: 18),
        ),

        const SizedBox(width: AppSpacing.sm),

        Expanded(
          child: Text(
            libro,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        Text(
          '$puntos pt',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
