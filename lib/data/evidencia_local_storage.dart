import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class EvidenciaLocalStorage {
  EvidenciaLocalStorage._();

  static final EvidenciaLocalStorage instance = EvidenciaLocalStorage._();

  Future<String> guardar(XFile imagen, {required int terrenoId}) async {
    final documentos = await getApplicationDocumentsDirectory();
    final directorio = Directory(
      path.join(documentos.path, 'evidencias', 'terreno_$terrenoId'),
    );
    await directorio.create(recursive: true);

    final extension = path.extension(imagen.path).isEmpty
        ? '.jpg'
        : path.extension(imagen.path).toLowerCase();
    final nombre =
        'actividad_${DateTime.now().microsecondsSinceEpoch}$extension';
    final destino = path.join(directorio.path, nombre);
    await File(imagen.path).copy(destino);
    return destino;
  }

  Future<void> eliminar(String? ruta) async {
    if (ruta == null || ruta.trim().isEmpty) return;
    final archivo = File(ruta);
    if (await archivo.exists()) await archivo.delete();
  }
}
