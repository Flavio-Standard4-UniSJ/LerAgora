import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leragora/screens/signup_screen.dart';

void main() {
  testWidgets('Campo de e-mail só aceita e-mail válido', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpScreen()));

    // Encontra os campos de entrada
    final emailField = find.byKey(const ValueKey('emailField'));
    final signUpButton = find.byKey(const ValueKey('signupButton'));

    // Envia um e-mail inválido
    await tester.enterText(emailField, 'email_invalido');
    await tester.tap(signUpButton);
    await tester.pump();

    expect(
      find.textContaining('e-mail inválido', findRichText: true),
      findsOneWidget,
    );

    // Envia um e-mail válido
    await tester.enterText(emailField, 'teste@email.com');
    await tester.tap(signUpButton);
    await tester.pump();

    // Erro deve desaparecer (supondo que a validação funcione)
    expect(
      find.textContaining('e-mail inválido', findRichText: true),
      findsNothing,
    );
  });
}
