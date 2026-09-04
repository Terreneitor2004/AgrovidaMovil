import 'dart:convert';

import 'package:agrovida_movil/data/terreno_repository.dart';
import 'package:agrovida_movil/models/terreno.dart';
import 'package:agrovida_movil/screens/mapa_page.dart';
import 'package:agrovida_movil/state/terreno_store.dart';
import 'package:agrovida_movil/widgets/lote_editor_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'dibuja, deshace, guarda y conserva la identidad visual del lote',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
      addTearDown(tester.view.reset);
      final store = TerrenoStore(MapTestRepository());
      addTearDown(store.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapaPage(terrenoStore: store, tileProvider: MapTestTiles()),
            bottomNavigationBar: const SafeArea(
              top: false,
              child: SizedBox(height: 80),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delimitar lote'));
      await tester.pumpAndSettle();
      FilledButton saveButton() => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Guardar lote'),
      );
      LoteEditorPanel panel() =>
          tester.widget<LoteEditorPanel>(find.byType(LoteEditorPanel));
      expect(saveButton().onPressed, isNull);

      for (final point in [
        const Offset(85, 270),
        const Offset(275, 285),
        const Offset(195, 330),
      ]) {
        await tester.tapAt(point);
        await tester.pump(const Duration(milliseconds: 400));
      }
      expect(panel().puntos, 3);
      expect(panel().hectareas, greaterThan(0));
      expect(panel().perimetroMetros, greaterThan(0));
      expect(saveButton().onPressed, isNotNull);

      await tester.tap(find.text('Deshacer'));
      await tester.pumpAndSettle();
      expect(panel().puntos, 2);
      expect(saveButton().onPressed, isNull);
      await tester.tapAt(const Offset(195, 330));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Guardar lote'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre del terreno'),
        'Lote norte',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Propietario o responsable'),
        'Responsable',
      );
      await tester.tap(find.text('Crear terreno'));
      await tester.pumpAndSettle();
      // Esperar a que el aviso de guardado libere los controles del mapa.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(store.terrenos.single.limite.length, 3);
      expect(find.byType(LoteEditorPanel), findsNothing);

      Color savedColor() => tester
          .widget<PolygonLayer>(find.byType(PolygonLayer))
          .polygons
          .last
          .borderColor;
      final firstColor = savedColor();
      await store.actualizar(
        store.terrenos.single.copyWith(nombre: 'Lote renombrado'),
      );
      await tester.pumpAndSettle();
      expect(savedColor(), firstColor);

      await store.crear(store.terrenos.single.copyWith(nombre: 'Lote sur'));
      await tester.pumpAndSettle();
      final polygons = tester
          .widget<PolygonLayer>(find.byType(PolygonLayer))
          .polygons;
      expect(polygons[1].borderColor, isNot(polygons[3].borderColor));

      await tester.tap(find.text('Delimitar lote'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(100, 300));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byTooltip('Cancelar delimitación'));
      await tester.pumpAndSettle();
      expect(find.byType(LoteEditorPanel), findsNothing);
      expect(store.terrenos.length, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}

/// Mosaicos transparentes: la prueba verifica el dibujo sin red ni caché real.
class MapTestTiles extends TileProvider {
  final _image = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _image;
}

class MapTestRepository implements TerrenoRepository {
  final items = <Terreno>[];
  int _nextId = 1;

  @override
  Future<Terreno> crear(Terreno terreno) async {
    final saved = terreno.copyWith(id: _nextId++);
    items.add(saved);
    return saved;
  }

  @override
  Future<void> actualizar(Terreno terreno) async {
    items[items.indexWhere((item) => item.id == terreno.id)] = terreno;
  }

  @override
  Future<void> eliminar(int id) async =>
      items.removeWhere((item) => item.id == id);

  @override
  Future<List<Terreno>> obtenerTodos() async => List.of(items);
}
