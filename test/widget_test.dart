import 'package:agrovida_movil/data/terreno_repository.dart';
import 'package:agrovida_movil/data/auth_repository.dart';
import 'package:agrovida_movil/main.dart';
import 'package:agrovida_movil/models/terreno.dart';
import 'package:agrovida_movil/state/terreno_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el tablero y permite abrir la lista de terrenos', (
    tester,
  ) async {
    final store = TerrenoStore(_MemoryTerrenoRepository());

    await tester.pumpWidget(
      AgroVidaApp(
        terrenoStore: store,
        authRepository: _SuccessfulAuthRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);

    await _completeLogin(tester);
    await tester.pumpAndSettle();

    expect(find.text('AgroVida'), findsOneWidget);
    expect(find.text('Resumen de campo'), findsOneWidget);
    expect(find.text('Gestión de parcelas'), findsOneWidget);
    expect(find.text('Mapa'), findsOneWidget);

    await tester.tap(find.text('Terrenos'));
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay terrenos'), findsOneWidget);
    expect(find.text('Agregar terreno'), findsOneWidget);

    store.dispose();
  });

  testWidgets('respeta las zonas seguras de una pantalla tipo iPhone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.padding = const FakeViewPadding(top: 141, bottom: 102);
    tester.view.viewPadding = const FakeViewPadding(top: 141, bottom: 102);
    addTearDown(tester.view.reset);

    final store = TerrenoStore(_MemoryTerrenoRepository());
    addTearDown(store.dispose);

    await tester.pumpWidget(
      AgroVidaApp(
        terrenoStore: store,
        authRepository: _SuccessfulAuthRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final loginTitlePosition = tester.getTopLeft(find.text('AgroVida'));
    expect(loginTitlePosition.dy, greaterThanOrEqualTo(47));

    await _completeLogin(tester);
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(
      find.byType(NavigationBar),
    );
    final titlePosition = tester.getTopLeft(find.text('AgroVida'));

    expect(navigationBar.maintainBottomViewPadding, isTrue);
    expect(titlePosition.dy, greaterThanOrEqualTo(47));
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra y oculta la contraseña del login', (tester) async {
    final store = TerrenoStore(_MemoryTerrenoRepository());
    addTearDown(store.dispose);

    await tester.pumpWidget(
      AgroVidaApp(
        terrenoStore: store,
        authRepository: _SuccessfulAuthRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
  });

  testWidgets('valida datos y muestra el error enviado por el servidor', (
    tester,
  ) async {
    final store = TerrenoStore(_MemoryTerrenoRepository());
    addTearDown(store.dispose);

    await tester.pumpWidget(
      AgroVidaApp(terrenoStore: store, authRepository: _FailedAuthRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Ingrese su correo electrónico.'), findsOneWidget);
    expect(find.text('Ingrese su contraseña.'), findsOneWidget);

    await _completeLogin(tester);
    await tester.pumpAndSettle();
    expect(find.text('Usuario o contraseña incorrectos.'), findsOneWidget);
    expect(find.text('Resumen de campo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _completeLogin(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Correo electrónico'),
    'juan@gmail.com',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Contraseña'),
    'MiClave123',
  );
  await tester.tap(find.text('Iniciar sesión'));
  await tester.pump();
}

class _SuccessfulAuthRepository implements AuthRepository {
  @override
  Future<LoginResult> login({
    required String usuario,
    required String contrasena,
  }) async {
    return const LoginResult(isSuccess: true);
  }

  @override
  void dispose() {}
}

class _FailedAuthRepository implements AuthRepository {
  @override
  Future<LoginResult> login({
    required String usuario,
    required String contrasena,
  }) async {
    return const LoginResult(
      isSuccess: false,
      message: 'Usuario o contraseña incorrectos.',
    );
  }

  @override
  void dispose() {}
}

class _MemoryTerrenoRepository implements TerrenoRepository {
  final List<Terreno> _items = [];
  int _nextId = 1;

  @override
  Future<void> actualizar(Terreno terreno) async {
    final index = _items.indexWhere((item) => item.id == terreno.id);
    _items[index] = terreno;
  }

  @override
  Future<Terreno> crear(Terreno terreno) async {
    final created = terreno.copyWith(id: _nextId++);
    _items.add(created);
    return created;
  }

  @override
  Future<void> eliminar(int id) async {
    _items.removeWhere((item) => item.id == id);
  }

  @override
  Future<List<Terreno>> obtenerTodos() async => List.of(_items);
}
