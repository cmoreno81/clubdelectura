import 'package:club_lectura_app/pages/code_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el aviso de longitud desaparece al alcanzar diez caracteres', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CodePasswordPage(
          email: 'nueva@example.com',
          mode: CodePasswordMode.registration,
        ),
      ),
    );

    final password = find.byKey(const ValueKey('new-password-field'));
    await tester.enterText(password, 'corta');
    await tester.pump();
    expect(find.text('Usa al menos 10 caracteres'), findsOneWidget);

    await tester.enterText(password, '1234567890');
    await tester.pump();
    expect(find.text('Usa al menos 10 caracteres'), findsNothing);
  });
}
