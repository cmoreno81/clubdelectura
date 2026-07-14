import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_button.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/club_chip.dart';

class ConfigurarLecturaPage extends StatefulWidget {
  final String libro;
  final String tipo;

  const ConfigurarLecturaPage({
    super.key,
    required this.libro,
    this.tipo = 'LIBRE',
  });

  @override
  State<ConfigurarLecturaPage> createState() => _ConfigurarLecturaPageState();
}

class _ConfigurarLecturaPageState extends State<ConfigurarLecturaPage> {
  final controllerCapitulos = TextEditingController();

  bool prologo = false;
  bool epilogo = false;
  bool creando = false;

  bool get esOficial => widget.tipo.trim().toUpperCase() == 'OFICIAL';
  @override
  void initState() {
    super.initState();

    controllerCapitulos.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          esOficial ? 'Configurar lectura oficial' : 'Nueva lectura compartida',
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            110,
          ),
          children: [
            _CabeceraConfiguracion(libro: widget.libro, esOficial: esOficial),

            const SizedBox(height: AppSpacing.xl),

            const _SectionHeader(
              icon: Icons.tune_rounded,
              color: AppColors.primary,
              title: 'Estructura de la lectura',
              subtitle: 'Indica cómo está organizado el libro',
            ),

            const SizedBox(height: AppSpacing.md),

            ClubCard(
              elevated: false,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Número de capítulos',
                    style: AppTextStyles.subtitle.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    'Usaremos este número para crear los espacios de conversación.',
                    style: AppTextStyles.bodySecondary.copyWith(height: 1.4),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  TextField(
                    controller: controllerCapitulos,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Número de capítulos',
                      hintText: 'Ej. 24',
                      prefixIcon: const Icon(
                        Icons.format_list_numbered_rounded,
                      ),
                      suffixText: 'capítulos',
                      filled: true,
                      fillColor: AppColors.surfaceSoft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            ClubCard(
              elevated: false,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _OpcionLectura(
                    icon: Icons.first_page_rounded,
                    title: 'Tiene prólogo',
                    subtitle: 'Añade un espacio antes del capítulo 1',
                    value: prologo,
                    onChanged: creando
                        ? null
                        : (value) {
                            setState(() {
                              prologo = value;
                            });
                          },
                  ),

                  const Divider(
                    height: 1,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                  ),

                  _OpcionLectura(
                    icon: Icons.last_page_rounded,
                    title: 'Tiene epílogo',
                    subtitle: 'Añade un espacio al final de la lectura',
                    value: epilogo,
                    onChanged: creando
                        ? null
                        : (value) {
                            setState(() {
                              epilogo = value;
                            });
                          },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            _VistaPrevia(
              capitulos: int.tryParse(controllerCapitulos.text.trim()) ?? 0,
              prologo: prologo,
              epilogo: epilogo,
            ),

            const SizedBox(height: AppSpacing.xl),

            ClubButton(
              label: creando ? 'Creando conversación...' : 'Crear conversación',
              icon: Icons.check_circle_outline_rounded,
              onPressed: creando ? null : _crearLectura,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _crearLectura() async {
    final capitulos = int.tryParse(controllerCapitulos.text.trim());

    if (capitulos == null || capitulos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduce un número de capítulos válido.'),
        ),
      );
      return;
    }

    setState(() {
      creando = true;
    });

    try {
      final ok = await ApiService().crearLectura(
        libro: widget.libro,
        capitulos: capitulos,
        prologo: prologo,
        epilogo: epilogo,
        tipo: widget.tipo,
      );

      if (!mounted) return;

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se ha podido crear la conversación.'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esOficial
                ? 'Lectura oficial creada 💜'
                : 'Lectura compartida creada 💜',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ha ocurrido un error. Inténtalo de nuevo.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          creando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    controllerCapitulos.dispose();
    super.dispose();
  }
}

class _CabeceraConfiguracion extends StatelessWidget {
  final String libro;
  final bool esOficial;

  const _CabeceraConfiguracion({required this.libro, required this.esOficial});

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
              esOficial ? Icons.emoji_events_outlined : Icons.groups_2_outlined,
              color: AppColors.primary,
              size: 38,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            libro,
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 28, height: 1.18),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            esOficial
                ? 'Esta será la conversación oficial del club para esta lectura.'
                : 'Configura los espacios donde las lectoras compartirán sus impresiones.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary.copyWith(height: 1.45),
          ),

          const SizedBox(height: AppSpacing.lg),

          ClubChip(
            label: esOficial ? 'Lectura oficial' : 'Lectura compartida',
            icon: esOficial
                ? Icons.workspace_premium_outlined
                : Icons.groups_2_outlined,
            variant: esOficial ? ClubChipVariant.primary : ClubChipVariant.info,
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

class _OpcionLectura extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _OpcionLectura({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: value ? AppColors.primaryLight : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: value ? AppColors.primary : AppColors.textMuted,
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(height: 1.35),
                  ),
                ],
              ),
            ),

            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _VistaPrevia extends StatelessWidget {
  final int capitulos;
  final bool prologo;
  final bool epilogo;

  const _VistaPrevia({
    required this.capitulos,
    required this.prologo,
    required this.epilogo,
  });

  @override
  Widget build(BuildContext context) {
    final total = capitulos + (prologo ? 1 : 0) + (epilogo ? 1 : 0);

    return ClubCard(
      elevated: false,
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppColors.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vista previa',
            style: AppTextStyles.subtitle.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            capitulos <= 0
                ? 'Introduce el número de capítulos para ver la estructura.'
                : 'Se crearán $total espacios de conversación.',
            style: AppTextStyles.bodySecondary,
          ),

          if (capitulos > 0) ...[
            const SizedBox(height: AppSpacing.md),

            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (prologo)
                  const ClubChip(
                    label: 'Prólogo',
                    icon: Icons.first_page_rounded,
                    variant: ClubChipVariant.primary,
                  ),

                ClubChip(
                  label: capitulos == 1 ? '1 capítulo' : '$capitulos capítulos',
                  icon: Icons.format_list_numbered_rounded,
                  variant: ClubChipVariant.info,
                ),

                if (epilogo)
                  const ClubChip(
                    label: 'Epílogo',
                    icon: Icons.last_page_rounded,
                    variant: ClubChipVariant.primary,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
