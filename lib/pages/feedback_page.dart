import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _emailController = TextEditingController();

  _Category _category = _Category.bug;
  bool _loading = false;
  String? _ticketKey;

  // Adjunto de imagen
  Uint8List? _imageBytes;
  String? _imageName;

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (xfile == null) return;
    final bytes = await xfile.readAsBytes();
    if (mounted) {
      setState(() {
        _imageBytes = bytes;
        _imageName = xfile.name;
      });
    }
  }

  void _clearImage() => setState(() {
        _imageBytes = null;
        _imageName = null;
      });

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final imageBase64 =
          _imageBytes != null ? base64Encode(_imageBytes!) : null;
      final ticket = await ApiService().enviarFeedback(
        category: _category.apiKey,
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        email: _emailController.text.trim(),
        imageBase64: imageBase64,
        imageFileName: _imageName,
      );
      if (mounted) setState(() => _ticketKey = ticket ?? '✓');
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacto y ayuda')),
      body: _ticketKey != null
          ? _SuccessView(ticketKey: _ticketKey!, onClose: () => Navigator.pop(context))
          : _FormView(
              formKey: _formKey,
              category: _category,
              onCategoryChanged: (c) => setState(() => _category = c),
              tituloController: _tituloController,
              descripcionController: _descripcionController,
              emailController: _emailController,
              loading: _loading,
              onSubmit: _submit,
              imageBytes: _imageBytes,
              imageName: _imageName,
              onPickImage: _pickImage,
              onClearImage: _clearImage,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Formulario
// ─────────────────────────────────────────────────────────────────────────────

class _FormView extends StatelessWidget {
  const _FormView({
    required this.formKey,
    required this.category,
    required this.onCategoryChanged,
    required this.tituloController,
    required this.descripcionController,
    required this.emailController,
    required this.loading,
    required this.onSubmit,
    required this.onPickImage,
    required this.onClearImage,
    this.imageBytes,
    this.imageName,
  });

  final GlobalKey<FormState> formKey;
  final _Category category;
  final ValueChanged<_Category> onCategoryChanged;
  final TextEditingController tituloController;
  final TextEditingController descripcionController;
  final TextEditingController emailController;
  final bool loading;
  final VoidCallback onSubmit;
  final Uint8List? imageBytes;
  final String? imageName;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Intro
          Text(
            'Cuéntanos qué pasó o qué mejorarías. Recibirás un email de confirmación con el número de tu reporte.',
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Categoría
          Text('Tipo de reporte', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          _CategorySelector(selected: category, onChanged: onCategoryChanged),
          const SizedBox(height: AppSpacing.lg),

          // Título
          Text('Resumen breve', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: tituloController,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: _titleHint(category),
              counterText: '',
            ),
            validator: (v) => (v?.trim().isEmpty ?? true)
                ? 'Escribe un resumen breve'
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Descripción
          Text('Descripción detallada', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: descripcionController,
            maxLines: 5,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: _descriptionHint(category),
              alignLabelWithHint: true,
            ),
            validator: (v) => (v?.trim().isEmpty ?? true)
                ? 'Añade más detalles'
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Adjunto de imagen
          Text('Adjuntar evidencia (opcional)', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          _ImagePickerRow(
            imageBytes: imageBytes,
            imageName: imageName,
            onPick: onPickImage,
            onClear: onClearImage,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Email
          Text('Tu email (para enviarte confirmación)', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(
              hintText: 'tu@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              final email = v?.trim() ?? '';
              if (email.isEmpty) return 'El email es necesario para enviarte confirmación';
              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
                return 'Email no válido';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Botón enviar
          FilledButton(
            onPressed: loading ? null : onSubmit,
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Enviar reporte'),
          ),

          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              'Recibirás una respuesta lo antes posible',
              style: AppTextStyles.caption,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _titleHint(_Category cat) => switch (cat) {
        _Category.bug => 'Ej: No puedo marcar un libro como leído',
        _Category.sugerencia => 'Ej: Añadir estadísticas de lecturas',
        _Category.pregunta => 'Ej: ¿Cómo invito a alguien al club?',
      };

  String _descriptionHint(_Category cat) => switch (cat) {
        _Category.bug =>
          'Describe qué pasó, en qué pantalla ocurrió y qué esperabas que sucediera…',
        _Category.sugerencia =>
          'Explica qué te gustaría poder hacer y por qué crees que sería útil para el club…',
        _Category.pregunta => 'Cuéntanos tu duda con el mayor detalle posible…',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Fila de adjunto de imagen
// ─────────────────────────────────────────────────────────────────────────────

class _ImagePickerRow extends StatelessWidget {
  const _ImagePickerRow({
    required this.onPick,
    required this.onClear,
    this.imageBytes,
    this.imageName,
  });

  final Uint8List? imageBytes;
  final String? imageName;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (imageBytes != null) {
      return Row(
        children: [
          // Miniatura
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.memory(
              imageBytes!,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Nombre y botón eliminar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  imageName ?? 'imagen.jpg',
                  style: AppTextStyles.bodySecondary,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Quitar imagen'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return OutlinedButton.icon(
      onPressed: onPick,
      icon: const Icon(Icons.image_outlined),
      label: const Text('Adjuntar captura de pantalla'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selector de categoría
// ─────────────────────────────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.selected,
    required this.onChanged,
  });
  final _Category selected;
  final ValueChanged<_Category> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _Category.values.map((cat) {
        final isSelected = cat == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => onChanged(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? cat.color.withValues(alpha: .12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: isSelected
                        ? cat.color
                        : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      cat.label,
                      style: TextStyle(
                        color: isSelected ? cat.color : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla de éxito
// ─────────────────────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.ticketKey, required this.onClose});
  final String ticketKey;
  final VoidCallback onClose;

  bool get _hasRealKey => ticketKey != '✓' && ticketKey.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📨', style: TextStyle(fontSize: 56)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '¡Reporte enviado!',
              style: AppTextStyles.section,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_hasRealKey) ...[
              Text(
                'Tu número de seguimiento es',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: '#$ticketKey'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.primary.withValues(alpha: .3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#$ticketKey',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(Icons.copy_outlined,
                          size: 18, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Toca el código para copiarlo.\nTe hemos enviado un email de confirmación.',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(
                'Hemos recibido tu mensaje y te responderemos lo antes posible.',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onClose,
              child: const Text('Listo'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Enum de categorías
// ─────────────────────────────────────────────────────────────────────────────

enum _Category {
  bug('bug', '🐛', 'Error', Color(0xFFB84040)),
  sugerencia('sugerencia', '💡', 'Sugerencia', Color(0xFF5E347C)),
  pregunta('pregunta', '❓', 'Pregunta', Color(0xFF2E6DA4));

  const _Category(this.apiKey, this.emoji, this.label, this.color);
  final String apiKey;
  final String emoji;
  final String label;
  final Color color;
}
