import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/terreno.dart';
import '../state/terreno_store.dart';
import '../widgets/terreno_form_dialog.dart';
import 'terreno_detalle_page.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key, required this.terrenoStore});

  final TerrenoStore terrenoStore;

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  static const _guatemala = LatLng(14.6349, -90.5069);
  final _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: widget.terrenoStore,
        builder: (context, _) {
          final terrenos = widget.terrenoStore.terrenos;
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _guatemala,
                  initialZoom: 7,
                  minZoom: 5,
                  maxZoom: 19,
                  onTap: (_, point) => _createAt(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.agrovida.agrovida_movil',
                  ),
                  MarkerLayer(
                    markers: terrenos.map(_markerForTerreno).toList(),
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => launchUrl(
                          Uri.parse('https://www.openstreetmap.org/copyright'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 14,
                left: 14,
                right: 68,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Toca el mapa para registrar un terreno · ${terrenos.length} guardados',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: FloatingActionButton.small(
                  heroTag: 'recenter_map',
                  tooltip: 'Centrar en Guatemala',
                  onPressed: () => _mapController.move(_guatemala, 7),
                  child: const Icon(Icons.center_focus_strong),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Marker _markerForTerreno(Terreno terreno) {
    return Marker(
      point: LatLng(terreno.latitud, terreno.longitud),
      width: 48,
      height: 48,
      child: Semantics(
        label: 'Terreno ${terreno.nombre}',
        button: true,
        child: GestureDetector(
          onTap: () => _showTerreno(terreno),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.eco, color: Colors.white, size: 25),
          ),
        ),
      ),
    );
  }

  Future<void> _createAt(LatLng point) async {
    final terreno = await showTerrenoFormDialog(
      context,
      latitud: point.latitude,
      longitud: point.longitude,
    );
    if (terreno == null || !mounted) return;

    try {
      await widget.terrenoStore.crear(terreno);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('“${terreno.nombre}” fue guardado.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el terreno.')),
      );
    }
  }

  Future<void> _showTerreno(Terreno terreno) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              terreno.nombre,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('Responsable: ${terreno.propietario}'),
            const SizedBox(height: 4),
            Text(
              'Coordenadas: ${terreno.latitud.toStringAsFixed(6)}, '
              '${terreno.longitud.toStringAsFixed(6)}',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (context) =>
                          TerrenoDetallePage(terreno: terreno),
                    ),
                  );
                },
                icon: const Icon(Icons.notes_outlined),
                label: const Text('Ver observaciones'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _editTerreno(terreno);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar terreno'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editTerreno(Terreno terreno) async {
    final updated = await showTerrenoFormDialog(context, terreno: terreno);
    if (updated == null || !mounted) return;
    await widget.terrenoStore.actualizar(updated);
  }
}
