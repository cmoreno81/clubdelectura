import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';

import '../services/api_exception.dart';
import '../services/auth_service.dart';
import 'code_password_page.dart';

class ActivationEmailPage extends StatefulWidget {
  const ActivationEmailPage({super.key});

  @override
  State<ActivationEmailPage> createState() => _ActivationEmailPageState();
}

class _ActivationEmailPageState extends State<ActivationEmailPage> {
  final _email = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim())) {
      _message('Escribe un correo válido.');
      return;
    }
    setState(() => _busy = true);
    try {
      final message = await AuthService().solicitarActivacion(_email.text);
      if (!mounted) return;
      _message(message);
      await Navigator.push<void>(
        context,
        AppPageRoute(
          builder: (_) => CodePasswordPage(
            email: _email.text.trim(),
            mode: CodePasswordMode.activation,
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
      appBar: AppBar(title: const Text('Activar cuenta')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Escribe el correo asociado a tu cuenta del club. Te enviaremos un código de seis dígitos.',
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
