import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/common/auth_form_header.dart';
import '../widgets/common/club_card.dart';

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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            48,
          ),
          children: [
            AuthFormHeader(
              icon: Icons.mark_email_read_outlined,
              eyebrow: 'Último paso',
              title: activation || registration
                  ? 'Crea tu contraseña'
                  : 'Renueva tu contraseña',
              message:
                  'Hemos enviado un código de seis dígitos a ${widget.email}.',
            ),
            const SizedBox(height: AppSpacing.md),
            ClubCard(
              elevated: false,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
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
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                    validator: (value) =>
                        value?.length == 6 ? null : 'Escribe los seis dígitos',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const ValueKey('new-password-field'),
                    controller: _password,
                    obscureText: _hidden,
                    autofillHints: const [AutofillHints.newPassword],
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Contraseña nueva',
                      prefixIcon: const Icon(Icons.key_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _hidden = !_hidden),
                        icon: Icon(
                          _hidden ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) => (value?.length ?? 0) < 10
                        ? 'Usa al menos 10 caracteres'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const ValueKey('confirm-password-field'),
                    controller: _confirmation,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Repite la contraseña',
                      prefixIcon: Icon(Icons.key_rounded),
                    ),
                    validator: (value) => value != _password.text
                        ? 'Las contraseñas no coinciden'
                        : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Text(_busy ? 'Guardando…' : 'Continuar'),
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
