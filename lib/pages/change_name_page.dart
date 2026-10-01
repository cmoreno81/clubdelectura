import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/usuario_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/auth_form_header.dart';
import '../widgets/common/club_card.dart';

class ChangeNamePage extends StatefulWidget {
  const ChangeNamePage({super.key});

  @override
  State<ChangeNamePage> createState() => _ChangeNamePageState();
}

class _ChangeNamePageState extends State<ChangeNamePage> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  bool _busy = false;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarNombreActual();
  }

  Future<void> _cargarNombreActual() async {
    final actual = await UsuarioService().obtenerUsuario();
    if (!mounted) return;
    setState(() {
      _nombre.text = actual ?? '';
      _cargando = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await AuthService().cambiarNombre(nombre: _nombre.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nombre actualizado.')));
      Navigator.pop(context);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar nombre')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  48,
                ),
                children: [
                  const AuthFormHeader(
                    icon: Icons.badge_outlined,
                    eyebrow: 'Identidad',
                    title: 'Así te verán en ClubReads',
                    message:
                        'Este nombre aparece en tus clubes, comentarios y '
                        'reseñas. Debe ser único: si ya lo usa otra persona, '
                        'tendrás que elegir otro.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClubCard(
                    elevated: false,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nombre,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) {
                            final trimmed = value?.trim() ?? '';
                            if (trimmed.length < 2 || trimmed.length > 60) {
                              return 'Entre 2 y 60 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: Text(_busy ? 'Guardando…' : 'Guardar nombre'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
