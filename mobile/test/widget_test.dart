// Prueba de humo (smoke test): confirma que la app arranca y muestra
// la pantalla de inicio de sesión.

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('La app arranca en la pantalla de login', (WidgetTester tester) async {
    await tester.pumpWidget(const MenStyleApp());

    expect(find.text('MENSTYLE'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsWidgets);
  });
}
