import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';

import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/auth_form_header.dart';
import '../widgets/common/club_card.dart';
import 'code_password_page.dart';

class PasswordResetEmailPage extends StatefulWidget {
  const PasswordResetEmailPage({super.key});

  @override
  State<PasswordResetEmailPage> createState() => _PasswordResetEmailPageState();
}

class _PasswordResetEmailPageState extends State<PasswordResetEmailPage> {
  final _email = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      _message('Escribe un correo válido.');
      return;
    }
    setState(() => _busy = true);
    try {
      final message = await AuthService().solicitarResetPassword(email);
      if (!mounted) return;
      _message(message);
      await Navigator.push<void>(
        context,
        AppPageRoute(
          builder: (_) => CodePasswordPage(
            email: email,
            mode: CodePasswordMode.passwordReset,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          48,
        ),
        children: [
          const AuthFormHeader(
            icon: Icons.key_rounded,
            eyebrow: 'Recupera tu acceso',
            title: 'Crea una contraseña nueva',
            message:
                'Te enviaremos un código de seguridad al correo de tu cuenta.',
          ),
          const SizedBox(height: AppSpacing.md),
          ClubCard(
            elevated: false,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Correo',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? 'Enviando…' : 'Enviar código'),
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
