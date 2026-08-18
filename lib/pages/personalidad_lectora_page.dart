import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

const _kPrefKey = 'quiz_personalidad_result';

// ── Modelo de datos ───────────────────────────────────────────────────────────

const _archetypes = {
  'nocturna': _Archetype(
    key: 'nocturna',
    emoji: '🌙',
    nombre: 'La Lectora Nocturna',
    descripcion:
        'Vives para las tramas oscuras, los giros inesperados y esas '
        'páginas que te dejan sin palabras a las 2am. El thriller '
        'y la fantasía oscura son tu territorio.',
    gradiente: [Color(0xFF1A0933), Color(0xFF3D1A5E), Color(0xFF5C2E84)],
  ),
  'maratonista': _Archetype(
    key: 'maratonista',
    emoji: '📚',
    nombre: 'La Maratonista de Sagas',
    descripcion:
        'Para ti un libro sin continuación es una oportunidad perdida. '
        'Tu TBR es tu tesoro más preciado y "solo un capítulo más" '
        'es tu mantra favorito.',
    gradiente: [Color(0xFF1A3A1A), Color(0xFF2E6B2E), Color(0xFF4A9E4A)],
  ),
  'romantica': _Archetype(
    key: 'romantica',
    emoji: '💕',
    nombre: 'La Romántica Empedernida',
    descripcion:
        'El slow burn, el enemies-to-lovers y ese momento en el que '
        'por fin se besan… los lees dos veces. El romance es tu '
        'idioma y nadie te va a juzgar.',
    gradiente: [Color(0xFF4A1A2E), Color(0xFF8B3A5E), Color(0xFFBF5480)],
  ),
  'reflexiva': _Archetype(
    key: 'reflexiva',
    emoji: '🧠',
    nombre: 'La Lectora Reflexiva',
    descripcion:
        'Lees con el alma y la mente. Cada libro te deja algo, '
        'necesitas tiempo para asimilarlo y probablemente tienes '
        'un diario de lecturas lleno de subrayados.',
    gradiente: [Color(0xFF1A2A4A), Color(0xFF2E4A8B), Color(0xFF4A6FBF)],
  ),
  'imparable': _Archetype(
    key: 'imparable',
    emoji: '⚡',
    nombre: 'La Lectora Imparable',
    descripcion:
        'Dónde otros ven obstáculos, tú ves páginas. Ningún género '
        'se te resiste, ninguna lista de lecturas te frena. '
        'Tu velocidad lectora es una superpotencia.',
    gradiente: [Color(0xFF3A2A00), Color(0xFF8B6B00), Color(0xFFD4A800)],
  ),
  'estetica': _Archetype(
    key: 'estetica',
    emoji: '🎨',
    nombre: 'La Esteta del Libro',
    descripcion:
        'Tan importante el interior como el exterior. Tu estantería '
        'es una obra de arte, tus fotos de libros son un museo y '
        'una portada bonita puede venderte cualquier historia.',
    gradiente: [Color(0xFF2E1A3A), Color(0xFF5E3A7A), Color(0xFF9E5FBF)],
  ),
};

class _Archetype {
  const _Archetype({
    required this.key,
    required this.emoji,
    required this.nombre,
    required this.descripcion,
    required this.gradiente,
  });
  final String key;
  final String emoji;
  final String nombre;
  final String descripcion;
  final List<Color> gradiente;
}

// ── Preguntas ─────────────────────────────────────────────────────────────────

class _Answer {
  const _Answer(this.label, this.points);
  final String label;
  final Map<String, int> points;
}

class _Question {
  const _Question(this.emoji, this.question, this.answers);
  final String emoji;
  final String question;
  final List<_Answer> answers;
}

const _questions = [
  _Question('🌙', '¿Cuándo sueles leer más?', [
    _Answer('Por la noche, cuando todo está en silencio', {'nocturna': 3}),
    _Answer('Por la mañana con un café', {'reflexiva': 2, 'estetica': 1}),
    _Answer('En cualquier momento que puedo', {'imparable': 3}),
    _Answer('Los fines de semana me hago maratones', {'maratonista': 3}),
  ]),
  _Question('📖', '¿Cómo eliges tu próximo libro?', [
    _Answer('La portada me tiene que enamorar', {'estetica': 3}),
    _Answer('El siguiente de la saga que estoy leyendo', {'maratonista': 3}),
    _Answer('Lo que recomienda BookTok o una amiga', {
      'romantica': 2,
      'nocturna': 1,
    }),
    _Answer('El que me pida el cuerpo en ese momento', {
      'imparable': 2,
      'reflexiva': 1,
    }),
  ]),
  _Question('✅', '¿Qué haces al terminar un libro?', [
    _Answer('Empiezo el siguiente sin pensarlo', {'imparable': 3}),
    _Answer('Necesito días para asimilarlo', {'reflexiva': 3}),
    _Answer('Busco el siguiente de la misma saga', {'maratonista': 3}),
    _Answer('Me hago una foto con la portada', {'estetica': 3}),
  ]),
  _Question('💭', '¿Qué tipo de historia te engancha más?', [
    _Answer('Oscura y tensa, llena de giros', {'nocturna': 3}),
    _Answer('Romance con tensión máxima', {'romantica': 3}),
    _Answer('Épica con worldbuilding brutal', {'maratonista': 2, 'nocturna': 1}),
    _Answer('Que me haga pensar y sentir', {'reflexiva': 3}),
  ]),
  _Question('📚', '¿Cómo es tu TBR (libros pendientes)?', [
    _Answer('Bajo control, menos de 10 libros', {'reflexiva': 2}),
    _Answer('Incontrolable y me encanta así', {
      'maratonista': 2,
      'estetica': 1,
    }),
    _Answer('Solo tengo saga actual, nada más', {'maratonista': 3}),
    _Answer('La ruleta del TBR es mi mejor amiga', {
      'imparable': 2,
      'nocturna': 1,
    }),
  ]),
  _Question('⭐', 'Eres de las que...', [
    _Answer('Releería sus libros favoritos mil veces', {
      'reflexiva': 2,
      'romantica': 2,
    }),
    _Answer('Nunca repite, siempre quiere algo nuevo', {'imparable': 3}),
    _Answer('Compra el libro aunque lo tenga en digital', {'estetica': 3}),
    _Answer('Espera con ansia cada nuevo tomo de su saga', {
      'maratonista': 3,
    }),
  ]),
];

// ── Página principal ──────────────────────────────────────────────────────────

class PersonalidadLectoraPage extends StatefulWidget {
  const PersonalidadLectoraPage({super.key});

  @override
  State<PersonalidadLectoraPage> createState() =>
      _PersonalidadLectoraPageState();
}

class _PersonalidadLectoraPageState extends State<PersonalidadLectoraPage>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentQ = 0;
  int? _selectedAnswer;
  final Map<String, int> _scores = {
    'nocturna': 0,
    'maratonista': 0,
    'romantica': 0,
    'reflexiva': 0,
    'imparable': 0,
    'estetica': 0,
  };
  _Archetype? _result;
  bool _loadingResult = true; // mientras leemos prefs

  late final AnimationController _revealCtrl;
  late final Animation<double> _revealAnim;

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _revealAnim = CurvedAnimation(
      parent: _revealCtrl,
      curve: Curves.elasticOut,
    );
    _loadSavedResult();
  }

  /// Carga el resultado guardado en prefs. Si existe, salta directamente
  /// a la vista de resultado sin animación de reveal.
  Future<void> _loadSavedResult() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kPrefKey);
    if (!mounted) return;
    setState(() {
      _loadingResult = false;
      if (saved != null && _archetypes.containsKey(saved)) {
        _result = _archetypes[saved];
        _revealCtrl.value = 1.0;
        // Sincroniza con servidor por si se guardó antes de tener conexión
        ApiService().guardarPersonalidadLectora(saved);
      }
    });
  }

  Future<void> _saveResult(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefKey, key);
  }

  Future<void> _clearResult() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPrefKey);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  void _selectAnswer(int questionIndex, int answerIndex) {
    if (_selectedAnswer != null) return;
    setState(() => _selectedAnswer = answerIndex);

    final answer = _questions[questionIndex].answers[answerIndex];
    answer.points.forEach((key, pts) => _scores[key] = (_scores[key] ?? 0) + pts);

    Future.delayed(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      setState(() => _selectedAnswer = null);

      if (questionIndex < _questions.length - 1) {
        _currentQ = questionIndex + 1;
        _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      } else {
        _computeResult();
      }
    });
  }

  void _computeResult() {
    final winnerKey = _scores.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    setState(() => _result = _archetypes[winnerKey]);
    _revealCtrl.forward(from: 0);
    _saveResult(winnerKey); // persiste en local
    ApiService().guardarPersonalidadLectora(winnerKey); // sube al servidor (silencioso)
  }

  void _restart() {
    _clearResult(); // borra la persistencia
    _scores.updateAll((key, value) => 0);
    setState(() {
      _result = null;
      _currentQ = 0;
    });
    _revealCtrl.value = 0;
    _pageCtrl.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    // Mientras cargamos prefs mostramos un scaffold vacío para evitar flash
    if (_loadingResult) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _result != null
          ? _ResultView(
              archetype: _result!,
              revealAnim: _revealAnim,
              onRestart: _restart,
            )
          : _QuizView(
              pageCtrl: _pageCtrl,
              currentQ: _currentQ,
              selectedAnswer: _selectedAnswer,
              onAnswer: _selectAnswer,
            ),
    );
  }
}

// ── Vista del quiz ────────────────────────────────────────────────────────────

class _QuizView extends StatelessWidget {
  const _QuizView({
    required this.pageCtrl,
    required this.currentQ,
    required this.selectedAnswer,
    required this.onAnswer,
  });

  final PageController pageCtrl;
  final int currentQ;
  final int? selectedAnswer;
  final void Function(int questionIndex, int answerIndex) onAnswer;

  @override
  Widget build(BuildContext context) {
    final total = _questions.length;
    final progress = (currentQ + 1) / total;

    return SafeArea(
      child: Column(
        children: [
          // ── AppBar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '¿Qué tipo de lectora eres?',
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          builder: (context, value, child) =>
                              LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                                backgroundColor: AppColors.surfaceMuted,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40), // balance for close button
              ],
            ),
          ),

          // ── Preguntas ────────────────────────────────────────────────────
          Expanded(
            child: PageView.builder(
              controller: pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _questions.length,
              itemBuilder: (context, index) => _QuestionPage(
                question: _questions[index],
                questionIndex: index,
                selectedAnswer: index == currentQ ? selectedAnswer : null,
                onAnswer: onAnswer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionPage extends StatelessWidget {
  const _QuestionPage({
    required this.question,
    required this.questionIndex,
    required this.selectedAnswer,
    required this.onAnswer,
  });

  final _Question question;
  final int questionIndex;
  final int? selectedAnswer;
  final void Function(int questionIndex, int answerIndex) onAnswer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 1),
          Text(question.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.md),
          Text(
            question.question,
            style: AppTextStyles.title.copyWith(
              fontSize: 26,
              height: 1.15,
              letterSpacing: -.5,
            ),
          ),
          const Spacer(flex: 1),
          ...question.answers.asMap().entries.map((e) {
            final i = e.key;
            final answer = e.value;
            final isSelected = selectedAnswer == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _AnswerCard(
                label: answer.label,
                selected: isSelected,
                onTap: () => onAnswer(questionIndex, i),
              ),
            );
          }),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: selected ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Vista del resultado ───────────────────────────────────────────────────────

class _ResultView extends StatefulWidget {
  const _ResultView({
    required this.archetype,
    required this.revealAnim,
    required this.onRestart,
  });

  final _Archetype archetype;
  final Animation<double> revealAnim;
  final VoidCallback onRestart;

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  final GlobalKey _captureKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Vista no disponible');
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('No se pudo crear la imagen');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/clubreads_personalidad.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              'Soy ${widget.archetype.emoji} ${widget.archetype.nombre} '
              '¿Y tú? Descúbrelo en ClubReads 📚',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo compartir')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final arch = widget.archetype;
    return SafeArea(
      child: Column(
        children: [
          // AppBar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.onRestart,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Repetir'),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ── Etiqueta "Tu personalidad lectora" ────────────────────────
          FadeTransition(
            opacity: widget.revealAnim,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                children: [
                  Text(
                    'Tu personalidad lectora es',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      letterSpacing: .4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    arch.nombre,
                    style: TextStyle(
                      color: arch.gradiente.last,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tarjeta del resultado (capturada al compartir) ────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ScaleTransition(
              scale: widget.revealAnim,
              child: RepaintBoundary(
                key: _captureKey,
                child: _ArchetypeCard(archetype: arch),
              ),
            ),
          ),

          const Spacer(),

          // ── Botones ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sharing ? null : _share,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    icon: _sharing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.ios_share_rounded),
                    label: Text(
                      _sharing
                          ? 'Generando imagen…'
                          : 'Compartir mi personalidad lectora',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchetypeCard extends StatelessWidget {
  const _ArchetypeCard({required this.archetype});

  final _Archetype archetype;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: archetype.gradiente,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: archetype.gradiente.last.withValues(alpha: .45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Círculos decorativos
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .06),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Branding
                Row(
                  children: [
                    const Text('📚', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      'ClubReads · Quiz Lector',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .60),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Emoji grande
                Text(
                  archetype.emoji,
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Nombre
                Text(
                  archetype.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -.5,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Separador
                Container(
                  height: 2,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Descripción
                Text(
                  archetype.descripcion,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .85),
                    fontSize: 15,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Tagline
                Text(
                  '¿Y tú? Descúbrelo en ClubReads 📚',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .50),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
