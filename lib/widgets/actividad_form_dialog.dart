import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

import '../models/actividad.dart';

class ActividadFormResult {
  const ActividadFormResult({
    required this.tipo,
    required this.descripcion,
    required this.estado,
    required this.fecha,
    this.evidencia,
  });

  final String tipo;
  final String descripcion;
  final EstadoActividad estado;
  final DateTime fecha;
  final XFile? evidencia;
}

Future<ActividadFormResult?> showActividadFormDialog(BuildContext context) {
  return showDialog<ActividadFormResult>(
    context: context,
    builder: (_) => const _ActividadFormDialog(),
  );
}

class _ActividadFormDialog extends StatefulWidget {
  const _ActividadFormDialog();

  @override
  State<_ActividadFormDialog> createState() => _ActividadFormDialogState();
}

class _ActividadFormDialogState extends State<_ActividadFormDialog> {
  static const _tipos = [
    'Inspección',
    'Riego',
    'Fertilización',
    'Control de plaga',
    'Otro',
  ];

  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _picker = ImagePicker();
  String _tipo = _tipos.first;
  EstadoActividad _estado = EstadoActividad.pendiente;
  DateTime _fecha = DateTime.now();
  XFile? _evidencia;

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fechaTexto =
        '${_fecha.day.toString().padLeft(2, '0')}/'
        '${_fecha.month.toString().padLeft(2, '0')}/${_fecha.year}';
    return AlertDialog(
      title: const Text('Nueva actividad'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de actividad',
                ),
                items: [
                  for (final tipo in _tipos)
                    DropdownMenuItem(value: tipo, child: Text(tipo)),
                ],
                onChanged: (tipo) {
                  if (tipo != null) setState(() => _tipo = tipo);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción o resultado',
                  alignLabelWithHint: true,
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Describe la actividad realizada o pendiente.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SegmentedButton<EstadoActividad>(
                segments: const [
                  ButtonSegment(
                    value: EstadoActividad.pendiente,
                    label: Text('Pendiente'),
                    icon: Icon(Icons.schedule_outlined),
                  ),
                  ButtonSegment(
                    value: EstadoActividad.realizada,
                    label: Text('Realizada'),
                    icon: Icon(Icons.task_alt_outlined),
                  ),
                ],
                selected: {_estado},
                showSelectedIcon: false,
                onSelectionChanged: (seleccion) {
                  setState(() => _estado = seleccion.first);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _seleccionarFecha,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('Fecha: $fechaTexto'),
              ),
              const SizedBox(height: 12),
              Text(
                'Fotografía de evidencia (opcional)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _seleccionarImagen(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Cámara'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _seleccionarImagen(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galería'),
                  ),
                ],
              ),
              if (_evidencia != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.image_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        path.basename(_evidencia!.path),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Quitar fotografía',
                      onPressed: () => setState(() => _evidencia = null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _guardar, child: const Text('Guardar')),
      ],
    );
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha != null && mounted) setState(() => _fecha = fecha);
  }

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final imagen = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (imagen != null && mounted) setState(() => _evidencia = imagen);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la fotografía.')),
      );
    }
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      ActividadFormResult(
        tipo: _tipo,
        descripcion: _descripcionController.text.trim(),
        estado: _estado,
        fecha: _fecha,
        evidencia: _evidencia,
      ),
    );
  }
}
