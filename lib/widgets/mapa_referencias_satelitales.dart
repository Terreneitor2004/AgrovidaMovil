import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Referencias transparentes de Esri sobre la imagen y debajo de los lotes.
/// Solo se monta en modo satelital, para no cargar capas innecesarias.
class MapaReferenciasSatelitales extends StatefulWidget {
  const MapaReferenciasSatelitales({
    super.key,
    required this.maxNativeZoom,
    required this.reset,
    required this.onTileError,
    this.tileProviderFactory,
  });

  final int maxNativeZoom;
  final Stream<void> reset;
  final ErrorTileCallBack onTileError;
  final TileProvider Function()? tileProviderFactory;

  @override
  State<MapaReferenciasSatelitales> createState() =>
      _MapaReferenciasSatelitalesState();
}

class _MapaReferenciasSatelitalesState
    extends State<MapaReferenciasSatelitales> {
  static const _urlReferencias =
      'https://services.arcgisonline.com/ArcGIS/rest/services/Reference/';

  late final TileProvider _viasProvider;
  late final TileProvider _nombresProvider;

  @override
  void initState() {
    super.initState();
    _viasProvider = _crearProveedor();
    _nombresProvider = _crearProveedor();
  }

  TileProvider _crearProveedor() =>
      widget.tileProviderFactory?.call() ??
      NetworkTileProvider(
        cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
          maxCacheSize: 300 * 1024 * 1024,
        ),
      );

  // TileLayer libera su proveedor al desmontarse. No se comparte con la imagen
  // base ni se reutiliza uno cerrado al volver a activar la vista satelital.
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          _capa('World_Transportation', _viasProvider),
          _capa('World_Boundaries_and_Places', _nombresProvider),
        ],
      ),
    );
  }

  TileLayer _capa(String servicio, TileProvider provider) => TileLayer(
    key: ValueKey(servicio),
    urlTemplate: '$_urlReferencias$servicio/MapServer/tile/{z}/{y}/{x}',
    userAgentPackageName: 'com.agrovida.agrovida_movil',
    tileProvider: provider,
    maxNativeZoom: widget.maxNativeZoom,
    maxZoom: widget.maxNativeZoom.toDouble(),
    panBuffer: 1,
    keepBuffer: 2,
    // Las etiquetas aparecen sin fundido para mantener su contraste al cargar.
    tileDisplay: const TileDisplay.instantaneous(),
    evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
    reset: widget.reset,
    errorTileCallback: widget.onTileError,
  );
}
