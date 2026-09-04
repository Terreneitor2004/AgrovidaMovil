import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
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
  static const _urlMapaEstandar =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _urlMapaSatelital =
      'https://services.arcgisonline.com/ArcGIS/rest/services/'
      'World_Imagery/MapServer/tile/{z}/{y}/{x}';
  static const _zoomMaximo = 19.0;
  static const _zoomNativoMapaEstandar = 19;

  // En varias zonas rurales Esri deja de tener imágenes antes del nivel 19.
  // Reutilizar el nivel 18 evita solicitar los mosaicos grises de error.
  static const _zoomNativoMapaSatelital = 18;

  final _mapController = MapController();
  final _reinicioTiles = StreamController<void>.broadcast();
  final List<LatLng> _bordeBorrador = [];
  late final NetworkTileProvider _tileProvider;
  Timer? _temporizadorErrorMapa;
  LatLng? _ubicacionActual;
  double? _precisionUbicacionMetros;
  bool _dibujandoBorde = false;
  bool _sateliteActivo = false;
  bool _mostrarErrorMapa = false;
  bool _actualizacionErrorPendiente = false;
  int _erroresDeTiles = 0;

  @override
  void initState() {
    super.initState();
    _tileProvider = NetworkTileProvider(
      cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
        maxCacheSize: 300 * 1024 * 1024,
      ),
    );
  }

  @override
  void dispose() {
    _temporizadorErrorMapa?.cancel();
    _reinicioTiles.close();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: AnimatedBuilder(
        animation: widget.terrenoStore,
        builder: (context, _) {
          final terrenos = widget.terrenoStore.terrenos;
          final colorPrincipal = Theme.of(context).colorScheme.primary;
          return Stack(
            children: [
              RepaintBoundary(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _guatemala,
                      initialZoom: 7,
                      minZoom: 5,
                      maxZoom: _sateliteActivo
                          ? _zoomNativoMapaSatelital.toDouble()
                          : _zoomMaximo,
                      onTap: (_, point) {
                        if (_dibujandoBorde) {
                          _agregarPuntoAlBorde(point);
                        } else {
                          _createAt(point);
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _sateliteActivo
                            ? _urlMapaSatelital
                            : _urlMapaEstandar,
                        userAgentPackageName: 'com.agrovida.agrovida_movil',
                        tileProvider: _tileProvider,
                        maxNativeZoom: _sateliteActivo
                            ? _zoomNativoMapaSatelital
                            : _zoomNativoMapaEstandar,
                        maxZoom: _sateliteActivo
                            ? _zoomNativoMapaSatelital.toDouble()
                            : _zoomMaximo,
                        panBuffer: 1,
                        keepBuffer: 3,
                        tileDisplay: const TileDisplay.fadeIn(
                          duration: Duration(milliseconds: 140),
                          reloadStartOpacity: 0.35,
                        ),
                        evictErrorTileStrategy:
                            EvictErrorTileStrategy.notVisibleRespectMargin,
                        reset: _reinicioTiles.stream,
                        errorTileCallback: _registrarErrorDeTile,
                      ),
                      PolygonLayer(
                        polygons: [
                          ...terrenos
                              .where((terreno) => terreno.tieneLimite)
                              .map(
                                (terreno) => Polygon(
                                  points: terreno.limite
                                      .map(
                                        (punto) => LatLng(
                                          punto.latitud,
                                          punto.longitud,
                                        ),
                                      )
                                      .toList(growable: false),
                                  color: colorPrincipal.withValues(alpha: 0.16),
                                  borderColor: colorPrincipal,
                                  borderStrokeWidth: 2.5,
                                ),
                              ),
                          if (_bordeBorrador.length >= 3)
                            Polygon(
                              points: _bordeBorrador,
                              color: colorPrincipal.withValues(alpha: 0.25),
                              borderColor: colorPrincipal,
                              borderStrokeWidth: 3,
                            ),
                        ],
                      ),
                      if (_bordeBorrador.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _bordeBorrador,
                              color: colorPrincipal,
                              strokeWidth: 3,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: terrenos.map(_markerForTerreno).toList(),
                      ),
                      if (_ubicacionActual != null)
                        MarkerLayer(
                          markers: [
                            _markerForCurrentLocation(_ubicacionActual!),
                          ],
                        ),
                      if (_bordeBorrador.isNotEmpty)
                        MarkerLayer(
                          markers: [
                            for (
                              var index = 0;
                              index < _bordeBorrador.length;
                              index++
                            )
                              _markerForDraftPoint(
                                point: _bordeBorrador[index],
                                number: index + 1,
                                color: colorPrincipal,
                              ),
                          ],
                        ),
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            _sateliteActivo
                                ? 'Imagery © Esri'
                                : 'OpenStreetMap contributors',
                            onTap: () => launchUrl(
                              Uri.parse(
                                _sateliteActivo
                                    ? 'https://www.esri.com/en-us/legal/terms/full-master-agreement'
                                    : 'https://www.openstreetmap.org/copyright',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (_mostrarErrorMapa)
                Positioned(
                  top: 188,
                  left: 14,
                  right: 14,
                  child: _buildMapErrorBanner(context),
                ),
              Positioned(
                top: 14,
                left: 14,
                right: 68,
                child: Card(
                  color: colorPrincipal,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(
                          _dibujandoBorde
                              ? Icons.add_location_alt_outlined
                              : Icons.touch_app_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _dibujandoBorde
                                ? 'Delimitación activa · agregue los vértices del lote (${_bordeBorrador.length})'
                                : 'Seleccione una ubicación para registrar un terreno · ${terrenos.length} registrados',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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
                  tooltip: 'Vista general',
                  onPressed: () => _mapController.move(_guatemala, 7),
                  child: const Icon(Icons.center_focus_strong),
                ),
              ),
              Positioned(
                top: 70,
                right: 14,
                child: FloatingActionButton.small(
                  heroTag: 'switch_map_layer',
                  tooltip: _sateliteActivo
                      ? 'Usar mapa estándar'
                      : 'Usar vista satelital',
                  onPressed: () {
                    final activarSatelite = !_sateliteActivo;
                    final camara = _mapController.camera;
                    if (activarSatelite &&
                        camara.zoom > _zoomNativoMapaSatelital) {
                      _mapController.move(
                        camara.center,
                        _zoomNativoMapaSatelital.toDouble(),
                      );
                    }
                    _temporizadorErrorMapa?.cancel();
                    setState(() {
                      _sateliteActivo = activarSatelite;
                      _erroresDeTiles = 0;
                      _mostrarErrorMapa = false;
                    });
                  },
                  child: Icon(
                    _sateliteActivo
                        ? Icons.map_outlined
                        : Icons.satellite_alt_outlined,
                  ),
                ),
              ),
              Positioned(
                top: 126,
                right: 14,
                child: FloatingActionButton.small(
                  heroTag: 'my_location_map',
                  tooltip: 'Mi ubicación',
                  onPressed: _irAMiUbicacion,
                  child: const Icon(Icons.my_location),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 16,
                child: _buildBorderControls(context),
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
          onTap: () {
            _enfocarTerreno(terreno);
            _showTerreno(terreno);
          },
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

  Widget _buildMapErrorBanner(BuildContext context) {
    return Material(
      elevation: 3,
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No se pudo cargar el mapa. Revisa tu conexión.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: _reintentarMapa,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _registrarErrorDeTile(TileImage _, Object _, StackTrace? _) {
    _erroresDeTiles++;
    if (_erroresDeTiles < 3 ||
        _mostrarErrorMapa ||
        _actualizacionErrorPendiente) {
      return;
    }

    _actualizacionErrorPendiente = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _actualizacionErrorPendiente = false;
      if (!mounted || _mostrarErrorMapa) return;

      setState(() => _mostrarErrorMapa = true);
      _temporizadorErrorMapa?.cancel();
      _temporizadorErrorMapa = Timer(const Duration(seconds: 10), () {
        if (mounted) setState(() => _mostrarErrorMapa = false);
      });
    });
  }

  void _reintentarMapa() {
    _temporizadorErrorMapa?.cancel();
    setState(() {
      _erroresDeTiles = 0;
      _mostrarErrorMapa = false;
    });
    _reinicioTiles.add(null);
  }

  Marker _markerForCurrentLocation(LatLng ubicacion) {
    return Marker(
      point: ubicacion,
      width: 36,
      height: 36,
      child: Semantics(
        label: _precisionUbicacionMetros == null
            ? 'Mi ubicación actual'
            : 'Mi ubicación actual, precisión aproximada de ${_precisionUbicacionMetros!.round()} metros',
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.person_pin_circle, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBorderControls(BuildContext context) {
    if (!_dibujandoBorde) {
      return Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: _iniciarDibujoDeBorde,
          icon: const Icon(Icons.draw_outlined),
          label: const Text('Delimitar lote'),
        ),
      );
    }

    final hectareas = _hectareasAproximadas(_bordeBorrador);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _bordeBorrador.length < 3
                  ? 'Agregue al menos 3 puntos para cerrar el lote.'
                  : '${_bordeBorrador.length} puntos · área aproximada: ${hectareas.toStringAsFixed(2)} ha',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _bordeBorrador.isEmpty
                      ? null
                      : _deshacerUltimoPunto,
                  icon: const Icon(Icons.undo),
                  label: const Text('Deshacer punto'),
                ),
                OutlinedButton.icon(
                  onPressed: _cancelarDibujoDeBorde,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: _bordeBorrador.length >= 3
                      ? _guardarBordeComoTerreno
                      : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar lote'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Marker _markerForDraftPoint({
    required LatLng point,
    required int number,
    required Color color,
  }) {
    return Marker(
      point: point,
      width: 32,
      height: 32,
      child: IgnorePointer(
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
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

  Future<void> _irAMiUbicacion() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!mounted) return;
      _mostrarUbicacionNoDisponible(
        'Activa la ubicación del teléfono para centrar el mapa.',
        abrirAjustesUbicacion: true,
      );
      return;
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }

    if (!mounted) return;
    if (permiso == LocationPermission.denied) {
      _mostrarUbicacionNoDisponible('No se concedió el permiso de ubicación.');
      return;
    }
    if (permiso == LocationPermission.deniedForever) {
      _mostrarUbicacionNoDisponible(
        'El permiso está bloqueado. Actívalo desde los ajustes de la aplicación.',
        abrirAjustesAplicacion: true,
      );
      return;
    }

    try {
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final ubicacion = LatLng(posicion.latitude, posicion.longitude);
      setState(() {
        _ubicacionActual = ubicacion;
        _precisionUbicacionMetros = posicion.accuracy;
      });
      _mapController.move(ubicacion, 17);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ubicación encontrada (precisión aprox. ${posicion.accuracy.round()} m).',
          ),
        ),
      );
    } on LocationServiceDisabledException {
      if (!mounted) return;
      _mostrarUbicacionNoDisponible(
        'No fue posible obtener la ubicación. Activa el GPS e inténtalo de nuevo.',
        abrirAjustesUbicacion: true,
      );
    } catch (_) {
      if (!mounted) return;
      _mostrarUbicacionNoDisponible(
        'No se pudo obtener la ubicación. Revisa el GPS y vuelve a intentarlo.',
      );
    }
  }

  void _mostrarUbicacionNoDisponible(
    String mensaje, {
    bool abrirAjustesUbicacion = false,
    bool abrirAjustesAplicacion = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        action: abrirAjustesUbicacion || abrirAjustesAplicacion
            ? SnackBarAction(
                label: 'Ajustes',
                onPressed: () {
                  if (abrirAjustesAplicacion) {
                    Geolocator.openAppSettings();
                  } else {
                    Geolocator.openLocationSettings();
                  }
                },
              )
            : null,
      ),
    );
  }

  void _enfocarTerreno(Terreno terreno) {
    _mapController.move(LatLng(terreno.latitud, terreno.longitud), 16);
  }

  void _iniciarDibujoDeBorde() {
    setState(() {
      _dibujandoBorde = true;
      _bordeBorrador.clear();
    });
  }

  void _agregarPuntoAlBorde(LatLng point) {
    setState(() => _bordeBorrador.add(point));
  }

  void _deshacerUltimoPunto() {
    if (_bordeBorrador.isEmpty) return;
    setState(_bordeBorrador.removeLast);
  }

  void _cancelarDibujoDeBorde() {
    setState(() {
      _dibujandoBorde = false;
      _bordeBorrador.clear();
    });
  }

  Future<void> _guardarBordeComoTerreno() async {
    if (_bordeBorrador.length < 3) return;

    final borde = List<LatLng>.from(_bordeBorrador);
    final limite = borde
        .map(
          (punto) =>
              PuntoBorde(latitud: punto.latitude, longitud: punto.longitude),
        )
        .toList(growable: false);
    final centro = _centroDelBorde(borde);
    final terreno = await showTerrenoFormDialog(
      context,
      latitud: centro.latitude,
      longitud: centro.longitude,
      limite: limite,
    );

    if (terreno == null || !mounted) return;

    try {
      await widget.terrenoStore.crear(terreno);
      if (!mounted) return;
      setState(() {
        _dibujandoBorde = false;
        _bordeBorrador.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lote "${terreno.nombre}" guardado con ${limite.length} puntos.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el lote.')),
      );
    }
  }

  LatLng _centroDelBorde(List<LatLng> puntos) {
    final latitud =
        puntos.fold<double>(0, (suma, punto) => suma + punto.latitude) /
        puntos.length;
    final longitud =
        puntos.fold<double>(0, (suma, punto) => suma + punto.longitude) /
        puntos.length;
    return LatLng(latitud, longitud);
  }

  double _hectareasAproximadas(List<LatLng> puntos) {
    if (puntos.length < 3) return 0;

    const radioTierraMetros = 6371000.0;
    final latitudReferencia =
        puntos.map((punto) => punto.latitude).reduce((a, b) => a + b) /
        puntos.length;
    final cosenoReferencia = math.cos(latitudReferencia * math.pi / 180);
    double suma = 0;

    for (var indice = 0; indice < puntos.length; indice++) {
      final actual = puntos[indice];
      final siguiente = puntos[(indice + 1) % puntos.length];
      final xActual =
          actual.longitude *
          math.pi /
          180 *
          radioTierraMetros *
          cosenoReferencia;
      final yActual = actual.latitude * math.pi / 180 * radioTierraMetros;
      final xSiguiente =
          siguiente.longitude *
          math.pi /
          180 *
          radioTierraMetros *
          cosenoReferencia;
      final ySiguiente = siguiente.latitude * math.pi / 180 * radioTierraMetros;
      suma += xActual * ySiguiente - xSiguiente * yActual;
    }

    return suma.abs() / 2 / 10000;
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
            if (terreno.tieneLimite) ...[
              const SizedBox(height: 4),
              Text('Borde registrado: ${terreno.limite.length} puntos'),
            ],
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
