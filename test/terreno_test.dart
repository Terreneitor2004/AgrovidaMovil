import 'package:agrovida_movil/models/terreno.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conserva los puntos del borde al convertir un terreno en mapa', () {
    final terreno = Terreno(
      nombre: 'Lote Norte',
      propietario: 'Andree',
      latitud: 14.6349,
      longitud: -90.5069,
      creadoEn: DateTime(2026, 9, 1),
      limite: const [
        PuntoBorde(latitud: 14.6349, longitud: -90.5069),
        PuntoBorde(latitud: 14.6351, longitud: -90.5067),
        PuntoBorde(latitud: 14.6347, longitud: -90.5065),
      ],
    );

    final restaurado = Terreno.fromMap(terreno.toMap());

    expect(restaurado.tieneLimite, isTrue);
    expect(restaurado.limite, hasLength(3));
    expect(restaurado.limite[1].longitud, closeTo(-90.5067, 0.000001));
  });
}
