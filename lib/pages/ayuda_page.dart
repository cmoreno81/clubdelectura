import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/onboarding_tutorial.dart';

// ─────────────────────────────────────────────
// Datos de la ayuda organizada por secciones
// ─────────────────────────────────────────────

class _HelpSection {
  const _HelpSection({
    required this.icono,
    required this.titulo,
    required this.items,
  });

  final String icono;
  final String titulo;
  final List<_HelpItem> items;
}

class _HelpItem {
  const _HelpItem({required this.pregunta, required this.respuesta});

  final String pregunta;
  final String respuesta;
}

const List<_HelpSection> _secciones = [
  _HelpSection(
    icono: '🏛️',
    titulo: 'Clubes',
    items: [
      _HelpItem(
        pregunta: '¿Cómo creo un club?',
        respuesta:
            'En "Mis clubes" pulsa el botón "Crear club". Escribe un nombre '
            'y una descripción. Al crearlo serás la administradora y podrás '
            'invitar a más personas con el código que te genera la app.',
      ),
      _HelpItem(
        pregunta: '¿Cómo invito a alguien a mi club?',
        respuesta:
            'Entra en "Mis clubes", pulsa el icono de invitación (sobre) '
            'del club que administras y comparte el código que aparece. '
            'Quien lo reciba puede unirse desde la misma pantalla.',
      ),
      _HelpItem(
        pregunta: '¿Puedo pertenecer a varios clubes?',
        respuesta:
            'Sí. Puedes estar en tantos clubes como quieras, aunque solo '
            'uno estará activo a la vez. Cambia el activo desde "Mis clubes".',
      ),
    ],
  ),
  _HelpSection(
    icono: '📖',
    titulo: 'Libros',
    items: [
      _HelpItem(
        pregunta: '¿Cómo añado un libro?',
        respuesta:
            'Ve a la pestaña "Libros" y pulsa el botón + (añadir). Rellena '
            'el título, el autor, el género y si pertenece a una saga. '
            'Puedes indicar también el formato (papel, digital, audio) '
            'y la prioridad de lectura.',
      ),
      _HelpItem(
        pregunta: '¿Qué significa "autoconclusivo"?',
        respuesta:
            'Un libro autoconclusivo no pertenece a ninguna saga: tiene '
            'principio y fin en sí mismo. Si desmarcas esta opción, '
            'tendrás que indicar el nombre de la saga y el número de tomo.',
      ),
      _HelpItem(
        pregunta: '¿Cómo marco un libro como terminado?',
        respuesta:
            'Abre el detalle del libro (pulsa sobre él) y busca la opción '
            '"Finalizar lectura". Podrás añadir tu valoración, fechas '
            'y notas personales.',
      ),
      _HelpItem(
        pregunta: '¿Puedo importar mis libros de Goodreads o Bookmory?',
        respuesta:
            'Sí. En Perfil → sección "Más" encontrarás las opciones '
            '"Importar desde Bookmory" e "Importar desde Goodreads". '
            'La importación no sobreescribe los datos que ya tengas en ClubReads.',
      ),
    ],
  ),
  _HelpSection(
    icono: '🗂️',
    titulo: 'Sagas',
    items: [
      _HelpItem(
        pregunta: '¿Cómo aparecen mis sagas?',
        respuesta:
            'Automáticamente. Cuando añades libros que pertenecen a la '
            'misma saga (mismo nombre de saga), la app los agrupa en la '
            'pestaña "Sagas".',
      ),
      _HelpItem(
        pregunta: '¿Qué es "Completar saga"?',
        respuesta:
            'Es una herramienta que busca en el catálogo los volúmenes '
            'que te faltan. Pulsa en una saga y luego en "Completar saga" '
            'para encontrarlos y añadirlos con el orden correcto.',
      ),
      _HelpItem(
        pregunta: '¿Puedo reordenar los tomos de una saga?',
        respuesta:
            'Sí. Entra en el detalle de la saga, pulsa sobre el tomo '
            'que quieras editar y cambia el número de orden.',
      ),
    ],
  ),
  _HelpSection(
    icono: '🗳️',
    titulo: 'Clubvisión',
    items: [
      _HelpItem(
        pregunta: '¿Qué es Clubvisión?',
        respuesta:
            'Es el sistema de votación del club. Los miembros proponen '
            'libros candidatos y votan cuál será la próxima lectura grupal. '
            'La moderadora abre y cierra la votación.',
      ),
      _HelpItem(
        pregunta: '¿Cómo propongo un libro candidato?',
        respuesta:
            'En Clubvisión → pestaña "Candidatas", pulsa el botón + '
            'y busca el libro que quieres proponer. Cada miembro puede '
            'proponer mientras la votación esté abierta.',
      ),
      _HelpItem(
        pregunta: '¿Puedo ver cómo ha votado cada persona?',
        respuesta:
            'Una vez cerrada la votación, la moderadora puede ver el '
            'desglose de votos en "Cómo votaron". El resto de miembros '
            've el resultado final pero no el voto individual.',
      ),
    ],
  ),
  _HelpSection(
    icono: '🎭',
    titulo: 'Lecturas y capítulos',
    items: [
      _HelpItem(
        pregunta: '¿Cómo comento en un capítulo?',
        respuesta:
            'Entra en la lectura activa del club, selecciona el capítulo '
            'y pulsa el campo de comentario al final. Puedes marcar '
            'spoilers para que otros decidan si los leen.',
      ),
      _HelpItem(
        pregunta: '¿Qué son los subrayadores?',
        respuesta:
            'Son frases o citas que destacas mientras lees. Guárdalas en '
            '"Subrayadores" para no perderlas y compartirlas con el club.',
      ),
    ],
  ),
  _HelpSection(
    icono: '🌈',
    titulo: 'Atmósferas y personalización',
    items: [
      _HelpItem(
        pregunta: '¿Qué son las atmósferas?',
        respuesta:
            'Son temas visuales que cambian los colores y el ambiente de '
            'la app según el libro que estás leyendo. La moderadora '
            'puede activar una atmósfera para todo el club.',
      ),
      _HelpItem(
        pregunta: '¿Cómo cambio mi avatar?',
        respuesta:
            'Ve a tu perfil y pulsa sobre tu avatar. Podrás elegir '
            'un color y un icono, o subir una foto desde tu galería.',
      ),
    ],
  ),
];

// ─────────────────────────────────────────────
// Página de Ayuda
// ─────────────────────────────────────────────

class AyudaPage extends StatelessWidget {
  const AyudaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayuda'),
        actions: [
          IconButton(
            tooltip: 'Ver tutorial de inicio',
            icon: const Icon(Icons.play_circle_outline_rounded),
            onPressed: () => mostrarOnboardingTutorial(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        children: [
          // ── Cabecera ──
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('💬', style: TextStyle(fontSize: 28)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿En qué te podemos ayudar?',
                        style: AppTextStyles.title.copyWith(
                          fontSize: 15,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Aquí encontrarás explicaciones de todas las partes de ClubReads.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Botón para relanzar tutorial ──
          ClubCard(
            elevated: false,
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.play_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Ver tutorial de bienvenida',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Repasa los conceptos clave de la app'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => mostrarOnboardingTutorial(context),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Secciones de ayuda ──
          ..._secciones.map((seccion) => _SeccionAyuda(seccion: seccion)),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widget de sección expandible
// ─────────────────────────────────────────────

class _SeccionAyuda extends StatelessWidget {
  const _SeccionAyuda({required this.seccion});

  final _HelpSection seccion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClubCard(
        elevated: false,
        padding: EdgeInsets.zero,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  seccion.icono,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            title: Text(
              seccion.titulo,
              style: AppTextStyles.title.copyWith(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.textMuted,
            children: seccion.items
                .map((item) => _PreguntaRespuesta(item: item))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widget de pregunta / respuesta
// ─────────────────────────────────────────────

class _PreguntaRespuesta extends StatelessWidget {
  const _PreguntaRespuesta({required this.item});

  final _HelpItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 2,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.textMuted,
            title: Text(
              item.pregunta,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
            children: [
              Text(
                item.respuesta,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
