import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/auth_form_header.dart';
import '../widgets/common/club_card.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _entendido = false;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirmarYEliminar() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar tu cuenta?'),
        content: const Text(
          'Esta acción no se puede deshacer. Vas a perder el acceso a tu '
          'perfil, tu biblioteca y tus clubes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    setState(() => _busy = true);
    try {
      await AuthService().eliminarCuenta(password: _password.text);
      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eliminar cuenta')),
      body: Form(
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
            AuthFormHeader(
              icon: Icons.warning_amber_rounded,
              iconBackgroundColor: AppColors.danger,
              eyebrow: 'Zona de peligro',
              title: 'Eliminar tu cuenta',
              message:
                  'Es una acción permanente. Antes de continuar, esto es lo '
                  'que va a pasar:',
            ),
            const SizedBox(height: AppSpacing.md),
            const ClubCard(
              elevated: false,
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Punto(
                    'Tu nombre, tu correo y tu foto de perfil se eliminan. '
                    'No podrás volver a entrar con esta cuenta.',
                  ),
                  SizedBox(height: AppSpacing.sm),
                  _Punto(
                    'Sales de todos tus clubes y se borra tu espacio lector '
                    'personal.',
                  ),
                  SizedBox(height: AppSpacing.sm),
                  _Punto(
                    'Tus comentarios, reseñas y votos ya publicados se '
                    'mantienen para no romper las conversaciones de tu '
                    'club, pero dejan de estar asociados a tu nombre.',
                  ),
                  SizedBox(height: AppSpacing.sm),
                  _Punto(
                    'Si eres propietaria de un club con más gente dentro, '
                    'primero tendrás que eliminarlo tú misma (o dejar que '
                    'otra persona se quede como única integrante).',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClubCard(
              elevated: false,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Confirma tu contraseña',
                      prefixIcon: Icon(Icons.key_rounded),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty
                            ? 'Campo obligatorio'
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CheckboxListTile(
                    value: _entendido,
                    onChanged: (value) =>
                        setState(() => _entendido = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Entiendo que esta acción no se puede deshacer',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                      ),
                      onPressed: (_busy || !_entendido)
                          ? null
                          : _confirmarYEliminar,
                      child: Text(_busy ? 'Eliminando…' : 'Eliminar mi cuenta'),
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

class _Punto extends StatelessWidget {
  const _Punto(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(Icons.circle, size: 6, color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(texto)),
      ],
    );
  }
}
