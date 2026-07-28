import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_exception.dart';
import '../services/auth_service.dart';

enum CodePasswordMode { activation, registration, passwordReset }

class CodePasswordPage extends StatefulWidget {
  const CodePasswordPage({super.key, required this.email, required this.mode});

  final String email;
  final CodePasswordMode mode;

  @override
  State<CodePasswordPage> createState() => _CodePasswordPageState();
}

class _CodePasswordPageState extends State<CodePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  bool _hidden = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      if (widget.mode == CodePasswordMode.activation) {
        await AuthService().activarCuenta(
          email: widget.email,
          codigo: _code.text,
          password: _password.text,
        );
      } else if (widget.mode == CodePasswordMode.registration) {
        await AuthService().completarRegistro(
          email: widget.email,
          codigo: _code.text,
          password: _password.text,
        );
      } else {
        await AuthService().resetPassword(
          email: widget.email,
          codigo: _code.text,
          password: _password.text,
        );
      }
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } on ApiException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) _message('No se ha podido completar la operación.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activation = widget.mode == CodePasswordMode.activation;
    final registration = widget.mode == CodePasswordMode.registration;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          activation || registration ? 'Crear contraseña' : 'Nueva contraseña',
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Código enviado a ${widget.email}'),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('auth-code-field'),
              controller: _code,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                labelText: 'Código de 6 dígitos',
              ),
              validator: (value) =>
                  value?.length == 6 ? null : 'Escribe los seis dígitos',
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('new-password-field'),
              controller: _password,
              obscureText: _hidden,
              autofillHints: const [AutofillHints.newPassword],
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Contraseña nueva',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _hidden = !_hidden),
                  icon: Icon(_hidden ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              validator: (value) => (value?.length ?? 0) < 10
                  ? 'Usa al menos 10 caracteres'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('confirm-password-field'),
              controller: _confirmation,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Repite la contraseña',
              ),
              validator: (value) => value != _password.text
                  ? 'Las contraseñas no coinciden'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Guardando…' : 'Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
