import 'package:agrovida_movil/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la base de navegación de AgroVida', (tester) async {
    await tester.pumpWidget(const AgroVidaApp());

    expect(find.text('AgroVida'), findsOneWidget);
    expect(find.text('Cultivo inicial: banano'), findsOneWidget);
    expect(find.text('Terrenos'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);
    expect(find.text('Diagnóstico'), findsOneWidget);
  });
}
