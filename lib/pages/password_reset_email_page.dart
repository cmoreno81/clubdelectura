import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../services/auth_service.dart';
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
        MaterialPageRoute(
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
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Te enviaremos un código para crear una contraseña nueva.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Correo'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Enviando…' : 'Enviar código'),
          ),
        ],
      ),
    );
  }
}
