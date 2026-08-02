import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common/club_card.dart';
import '../widgets/common/onboarding_tutorial.dart';

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
            'Entra en "Mis clubes", pulsa el icono de invitación del club '
            'que administras y comparte el código que aparece. '
            'Quien lo reciba puede unirse desde la misma pantalla pulsando '
            '"Entrar con invitación" e introduciendo el código.',
      ),
      _HelpItem(
        pregunta: '¿Puedo pertenecer a varios clubes?',
        respuesta:
            'Sí. Puedes estar en tantos clubes como quieras, aunque solo '
            'uno estará activo a la vez. Cambia el activo desde "Mis clubes".',
      ),
      _HelpItem(
        pregunta: '¿Cómo edito el club o añado una foto?',
        respuesta:
            'En "Mis clubes" pulsa el icono de ajustes ⚙️ del club. '
            'Desde ahí puedes editar el nombre y la descripción, y cambiar la foto '
            'del club desde la galería o con una URL. '
            'Solo la propietaria y las administradoras pueden editar el club.',
      ),
      _HelpItem(
        pregunta: '¿Cómo veo quién está en el club?',
        respuesta:
            'En los ajustes del club encontrarás la opción "Miembros", '
            'que muestra a todas las personas del club con su rol. '
            'El número de miembros también aparece en el propio menú.',
      ),
      _HelpItem(
        pregunta: '¿Puedo salir de un club?',
        respuesta:
            'Sí, desde los ajustes del club verás la opción "Salir del club". '
            'Perderás acceso a las lecturas y conversaciones de ese club. '
            'La propietaria no puede salir — tendría que transferir la propiedad primero.',
      ),
      _HelpItem(
        pregunta: '¿Qué diferencia hay entre administradora y miembro?',
        respuesta:
            'La administradora puede abrir y cerrar votaciones de Clubvisión, '
            'gestionar la lectura activa del club y obtener el código de invitación. '
            'Los miembros pueden votar, comentar y proponer libros según las '
            'reglas de cada sección.',
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
            'Hay dos formas. La primera: en la pestaña "Libros" pulsa el botón + '
            'y rellena los datos manualmente (título, autor, género, saga, formato '
            'y prioridad). La segunda: explora la biblioteca global desde "Mi universo '
            'lector" → "Explorar la biblioteca", busca el libro y añádelo desde ahí '
            'sin tener que introducir los datos a mano.',
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
            'Abre el detalle del libro y cambia su estado a "Historia terminada" '
            'en el selector de estado. Podrás añadir tu valoración, '
            'las fechas de lectura y una reseña personal.',
      ),
      _HelpItem(
        pregunta: '¿Qué estados puede tener un libro?',
        respuesta:
            '"En mi estantería" (pendiente), "Leyendo" (en curso), '
            '"Necesito un respiro" (pausado), "Otra vuelta" (relectura), '
            '"No era para mí" (abandonado) e "Historia terminada" (finalizado). '
            'Puedes cambiar el estado en cualquier momento desde la ficha del libro.',
      ),
      _HelpItem(
        pregunta: '¿Qué es la biblioteca global?',
        respuesta:
            'Es el catálogo compartido de todos los libros que existen en ClubReads. '
            'Puedes explorarla desde "Mi universo lector" usando el icono de búsqueda. '
            'Desde ahí puedes añadir cualquier libro directamente a tu biblioteca '
            'personal sin introducir los datos manualmente.',
      ),
    ],
  ),
  _HelpSection(
    icono: '📥',
    titulo: 'Importaciones',
    items: [
      _HelpItem(
        pregunta: '¿Cómo importo desde Bookmory o Goodreads?',
        respuesta:
            'Ve a Perfil → Más y elige "Importar desde Bookmory" o '
            '"Importar desde Goodreads". Para Bookmory selecciona el archivo '
            '.xlsx exportado directamente por la aplicación; para Goodreads, '
            'su archivo .csv. ClubReads revisará el contenido antes de guardar '
            'nada y te permitirá confirmar los libros seleccionados.',
      ),
      _HelpItem(
        pregunta: '¿Qué libros se importan?',
        respuesta:
            'Solo se importan los libros terminados que tengan valoración. '
            'Los pendientes, los que estás leyendo y los terminados sin valorar '
            'se omiten. Si falta la fecha de finalización, ClubReads asigna una '
            'fecha segura para poder conservar el libro en tu historial.',
      ),
      _HelpItem(
        pregunta: '¿Qué significan "Nuevos" y "Para añadir"?',
        respuesta:
            '"Nuevos" son libros que todavía no existen en el catálogo: se '
            'crearán y se añadirán a tu biblioteca. "Para añadir" ya existen '
            'en ClubReads, pero no están en tu biblioteca: se reutilizará su '
            'ficha. Ambos aparecen seleccionados automáticamente; puedes '
            'desmarcar cualquier libro que no quieras importar.',
      ),
      _HelpItem(
        pregunta: '¿Qué significa "Protegidos"?',
        respuesta:
            'Son libros que ya tienes en ClubReads. No tienes que hacer nada: '
            'la importación no sustituirá tus estados, fechas, valoraciones, '
            'reseñas, prioridades, formatos, sagas ni historial guardado. Por '
            'eso no se incluyen entre los libros seleccionados para importar.',
      ),
      _HelpItem(
        pregunta: '¿Qué hago con los libros "Para revisar"?',
        respuesta:
            'ClubReads ha encontrado varias coincidencias posibles y no puede '
            'decidir con seguridad cuál es la correcta. Esos libros no se '
            'importan automáticamente. Termina primero la importación y después '
            'búscalos en la biblioteca global para añadir la ficha correcta. '
            'Si ninguna coincide, puedes crear el libro manualmente.',
      ),
      _HelpItem(
        pregunta: '¿Qué significa "Pendientes o sin valorar"?',
        respuesta:
            'Son filas que no cumplen las condiciones de importación, que no '
            'tienen título o autor, o que están repetidas dentro del archivo. '
            'Se omiten y no modifican tu biblioteca.',
      ),
      _HelpItem(
        pregunta: '¿Qué hago si una importación grande da error?',
        respuesta:
            'Puedes volver a seleccionar el mismo archivo sin perder lo ya '
            'guardado. Si hay muchos libros, pulsa "Ninguno", selecciona grupos '
            'de unos 20 o 30 e impórtalos por tandas. Al abrir de nuevo el archivo, '
            'los libros ya incorporados aparecerán como protegidos.',
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
            'Es una herramienta para buscar los volúmenes que faltan en el '
            'catálogo global. Entra en una saga, pulsa "Completar saga", busca '
            'el libro y confirma que pertenece a ella antes de añadirlo.',
      ),
      _HelpItem(
        pregunta: '¿Qué tengo que indicar al completar una saga?',
        respuesta:
            'Indica el número que ocupa el libro en la saga y elige su estado: '
            'Pendiente, Leyendo o Terminado. También puedes seleccionar el '
            'formato. Si estás leyendo, puedes indicar la fecha de inicio; si lo '
            'has terminado, puedes añadir las fechas y debes elegir una valoración.',
      ),
      _HelpItem(
        pregunta: '¿Se añade también a mi biblioteca?',
        respuesta:
            'Sí. Al confirmar, el volumen se vincula a la saga y se añade a '
            'tu biblioteca con el estado y formato elegidos, todo en una sola '
            'operación. La Biblioteca se actualiza automáticamente; no necesitas '
            'deslizar la pantalla ni volver a añadir el libro.',
      ),
      _HelpItem(
        pregunta: '¿Qué pasa si el libro ya existe?',
        respuesta:
            'ClubReads reutiliza la ficha existente y la vincula a la saga. '
            'No debe crear otra copia del mismo libro. Si el número elegido ya '
            'pertenece a otro volumen, la app te avisará para que lo revises.',
      ),
      _HelpItem(
        pregunta: '¿Y si un tomo no está en ClubReads o no quiero leerlo?',
        respuesta:
            'Desde el hueco correspondiente de la saga puedes marcarlo como '
            '"Leído fuera de ClubReads" u "Omitido". Si más adelante añades '
            'el volumen real con "Completar saga", esa marca se elimina '
            'automáticamente.',
      ),
      _HelpItem(
        pregunta: '¿Puedo reordenar los tomos de una saga?',
        respuesta:
            'Sí. Entra en el detalle de la saga, pulsa sobre el tomo '
            'que quieras editar y cambia el número de orden.',
      ),
      _HelpItem(
        pregunta: '¿Qué significa que una saga esté "abandonada"?',
        respuesta:
            'Si marcas algún libro de la saga como "No era para mí" (abandonado), '
            'la saga completa pasa automáticamente al estado Abandonada. '
            'En la pestaña "Sagas" aparece un filtro específico para verlas. '
            'Siempre puedes retomarla cambiando el estado del libro.',
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
            'Es el sistema de votación del club para elegir el próximo libro '
            'de lectura grupal. Funciona por ediciones: se abre una votación, '
            'las miembros votan entre las candidatas y la ganadora se convierte '
            'en la siguiente lectura del club.',
      ),
      _HelpItem(
        pregunta: '¿Cómo se eligen las candidatas?',
        respuesta:
            'Las candidatas se generan automáticamente. Para que un libro '
            'aparezca como candidata tiene que cumplir tres condiciones: '
            'que al menos 2 miembros del club lo tengan en su biblioteca personal, '
            'que no haya sido ya leído por el club, y que no haya ganado '
            'una edición anterior de Clubvisión.',
      ),
      _HelpItem(
        pregunta: '¿Cómo voto?',
        respuesta:
            'Cuando la administradora abre la votación, entra en Clubvisión '
            'y ordena las candidatas según tus preferencias. '
            'Tu voto se guarda al confirmar. Solo puedes votar una vez por edición.',
      ),
      _HelpItem(
        pregunta: '¿Puedo ver cómo ha votado cada persona?',
        respuesta:
            'Sí, pero solo una vez cerrada la votación. Cuando la administradora '
            'cierra la edición, cualquier miembro puede ver el desglose completo '
            'de votos en "Cómo votaron" — quién votó qué y en qué orden. '
            'Durante la votación activa, los votos son privados.',
      ),
      _HelpItem(
        pregunta: '¿Quién abre y cierra la votación?',
        respuesta:
            'Solo la administradora del club puede abrir y cerrar cada edición '
            'de Clubvisión. El resto de miembros solo pueden votar mientras '
            'la votación esté abierta.',
      ),
    ],
  ),
  _HelpSection(
    icono: '📚',
    titulo: 'Lecturas y citas',
    items: [
      _HelpItem(
        pregunta: '¿Cómo sigo la lectura activa del club?',
        respuesta:
            'En la pestaña "Lecturas" encontrarás el libro actual del club '
            'dividido por capítulos. Pulsa en un capítulo para leer los '
            'comentarios de las demás miembros y añadir el tuyo.',
      ),
      _HelpItem(
        pregunta: '¿Cómo comento en un capítulo?',
        respuesta:
            'Entra en la lectura activa, selecciona el capítulo '
            'y pulsa el campo de comentario al final. '
            'Puedes responder a comentarios de otras miembros '
            'y reaccionar con emojis.',
      ),
      _HelpItem(
        pregunta: '¿Qué son las citas?',
        respuesta:
            'Las citas son frases o fragmentos que destacas mientras lees. '
            'Puedes guardarlas en la sección "Citas" para no perderlas '
            'y compartirlas con el club. Son tu cuaderno de frases favoritas.',
      ),
      _HelpItem(
        pregunta: '¿Qué es el Kit de lectura?',
        respuesta:
            'El Kit de lectura es una selección de recursos para preparar '
            'la lectura del club: playlist musical, paleta de colores '
            'y otros elementos ambientales para enriquecer la experiencia lectora.',
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
            'la app según el libro que está leyendo el club. La administradora '
            'puede activar una atmósfera para toda la comunidad desde '
            'la sección Atmósferas dentro de la lectura activa.',
      ),
      _HelpItem(
        pregunta: '¿Cómo cambio mi avatar?',
        respuesta:
            'Ve a tu perfil y pulsa sobre tu avatar. Podrás elegir '
            'un color y un icono, o subir una foto desde tu galería.',
      ),
      _HelpItem(
        pregunta: '¿Puedo personalizar mi perfil?',
        respuesta:
            'Sí. En tu perfil puedes editar tu avatar, ver tus estadísticas '
            'lectoras, tu timeline de lecturas, los géneros favoritos '
            'y todos los libros que has terminado o abandonado.',
      ),
    ],
  ),
  _HelpSection(
    icono: '📊',
    titulo: 'Estadísticas y perfil',
    items: [
      _HelpItem(
        pregunta: '¿Qué muestra "Mi universo lector"?',
        respuesta:
            'Es tu pantalla principal con un resumen de todo: libros que estás '
            'leyendo, sagas en curso, la estantería del mes, tu calendario '
            'de lectura, las tendencias de la comunidad y el acceso a tus clubes.',
      ),
      _HelpItem(
        pregunta: '¿Qué es la estantería del mes?',
        respuesta:
            'Una representación visual en forma de librería de madera con todos '
            'los libros que has terminado durante el mes actual. Los libros '
            'caen y se colocan animados cada vez que entras en la pantalla. '
            'Si el libro tiene valoración, aparece una estrella sobre la portada.',
      ),
      _HelpItem(
        pregunta: '¿Qué es la biblioteca 2026?',
        respuesta:
            'La estantería anual con todos los libros que has terminado en '
            'el año en curso. La encontrarás en tu perfil lector, '
            'en la sección Resumen. También se anima al entrar.',
      ),
      _HelpItem(
        pregunta: '¿Qué son las secciones del perfil?',
        respuesta:
            '"Resumen" muestra tus métricas, la biblioteca anual y tus géneros favoritos. '
            '"Timeline" muestra tu historial de lecturas ordenado por fecha. '
            '"Finalizados" lista todos los libros terminados y abandonados '
            'agrupados por año. '
            '"Meses lectores" muestra un calendario por cada mes en el que has '
            'leído algún libro, con las portadas colocadas en los días que las terminaste.',
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

          ..._secciones.map((seccion) => _SeccionAyuda(seccion: seccion)),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sección expandible
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
// Pregunta / respuesta
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
