import 'dart:io';

import 'package:flutter/material.dart';

import '../data/actividad_repository.dart';
import '../data/evidencia_local_storage.dart';
import '../data/observacion_repository.dart';
import '../models/actividad.dart';
import '../models/observacion.dart';
import '../models/terreno.dart';
import '../state/actividad_store.dart';
import '../state/observacion_store.dart';
import '../widgets/actividad_form_dialog.dart';

class TerrenoDetallePage extends StatefulWidget {
  const TerrenoDetallePage({super.key, required this.terreno});

  final Terreno terreno;

  @override
  State<TerrenoDetallePage> createState() => _TerrenoDetallePageState();
}

class _TerrenoDetallePageState extends State<TerrenoDetallePage> {
  late final ObservacionStore _store;
  late final ActividadStore _actividadStore;

  @override
  void initState() {
    super.initState();
    _store = ObservacionStore(
      SqliteObservacionRepository.instance,
      terrenoId: widget.terreno.id!,
    )..cargar();
    _actividadStore = ActividadStore(
      SqliteActividadRepository.instance,
      terrenoId: widget.terreno.id!,
    )..cargar();
  }

  @override
  void dispose() {
    _store.dispose();
    _actividadStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.terreno.nombre)),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_store, _actividadStore]),
          builder: (context, _) {
            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([_store.cargar(), _actividadStore.cargar()]);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                children: [
                  _TerrenoSummary(terreno: widget.terreno),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Actividades',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text('${_actividadStore.actividades.length} registros'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_actividadStore.cargando &&
                      _actividadStore.actividades.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_actividadStore.error != null)
                    _ActividadEmpty(
                      icon: Icons.error_outline,
                      message: _actividadStore.error!,
                      actionLabel: 'Reintentar',
                      onAction: _actividadStore.cargar,
                    )
                  else if (_actividadStore.actividades.isEmpty)
                    _ActividadEmpty(
                      icon: Icons.assignment_outlined,
                      message: 'Todavía no hay actividades para este terreno.',
                      actionLabel: 'Crear la primera',
                      onAction: _showActividadDialog,
                    )
                  else
                    for (final actividad in _actividadStore.actividades)
                      _ActividadCard(
                        actividad: actividad,
                        onMarkAsDone:
                            actividad.estado == EstadoActividad.pendiente
                            ? () => _marcarActividadRealizada(actividad)
                            : null,
                        onDelete: () => _deleteActividad(actividad),
                      ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Observaciones',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text('${_store.observaciones.length} registros'),
                      IconButton(
                        tooltip: 'Nueva observación',
                        onPressed: _showObservationDialog,
                        icon: const Icon(Icons.add_comment_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_store.cargando && _store.observaciones.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_store.error != null)
                    _ObservacionEmpty(
                      icon: Icons.error_outline,
                      message: _store.error!,
                      actionLabel: 'Reintentar',
                      onAction: _store.cargar,
                    )
                  else if (_store.observaciones.isEmpty)
                    _ObservacionEmpty(
                      icon: Icons.notes_outlined,
                      message:
                          'Todavía no hay observaciones para este terreno.',
                      actionLabel: 'Agregar la primera',
                      onAction: () => _showObservationDialog(),
                    )
                  else
                    for (final observacion in _store.observaciones)
                      _ObservacionCard(
                        observacion: observacion,
                        onEdit: () => _showObservationDialog(observacion),
                        onDelete: () => _deleteObservation(observacion),
                      ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showActividadDialog,
        icon: const Icon(Icons.add_task_outlined),
        label: const Text('Nueva actividad'),
      ),
    );
  }

  Future<void> _showObservationDialog([Observacion? observacion]) async {
    final controller = TextEditingController(text: observacion?.texto ?? '');
    final formKey = GlobalKey<FormState>();
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          observacion == null ? 'Nueva observación' : 'Editar observación',
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: '¿Qué observaste en el terreno?',
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Escribe una observación.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || !mounted) return;

    await _runAction(
      () => observacion == null
          ? _store.crear(text)
          : _store.actualizar(observacion, text),
      successMessage: observacion == null
          ? 'Observación guardada.'
          : 'Observación actualizada.',
    );
  }

  Future<void> _showActividadDialog() async {
    final actividad = await showActividadFormDialog(context);
    if (actividad == null || !mounted) return;

    await _runAction(() async {
      String? evidenciaRuta;
      try {
        if (actividad.evidencia != null) {
          evidenciaRuta = await EvidenciaLocalStorage.instance.guardar(
            actividad.evidencia!,
            terrenoId: widget.terreno.id!,
          );
        }
        await _actividadStore.crear(
          tipo: actividad.tipo,
          descripcion: actividad.descripcion,
          estado: actividad.estado,
          fecha: actividad.fecha,
          evidenciaRuta: evidenciaRuta,
        );
      } catch (_) {
        await EvidenciaLocalStorage.instance.eliminar(evidenciaRuta);
        rethrow;
      }
    }, successMessage: 'Actividad guardada en el teléfono.');
  }

  Future<void> _marcarActividadRealizada(Actividad actividad) async {
    await _runAction(
      () => _actividadStore.actualizarEstado(
        actividad,
        EstadoActividad.realizada,
      ),
      successMessage: 'Actividad marcada como realizada.',
    );
  }

  Future<void> _deleteActividad(Actividad actividad) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar actividad'),
        content: const Text(
          'Se eliminará la actividad y su fotografía de evidencia local.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || actividad.id == null) return;

    await _runAction(() async {
      await _actividadStore.eliminar(actividad.id!);
      await EvidenciaLocalStorage.instance.eliminar(actividad.evidenciaRuta);
    }, successMessage: 'Actividad eliminada.');
  }

  Future<void> _deleteObservation(Observacion observacion) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar observación'),
        content: const Text('¿Deseas eliminar este registro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || observacion.id == null) return;
    await _runAction(
      () => _store.eliminar(observacion.id!),
      successMessage: 'Observación eliminada.',
    );
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo completar la operación.')),
      );
    }
  }
}

class _TerrenoSummary extends StatelessWidget {
  const _TerrenoSummary({required this.terreno});

  final Terreno terreno;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.grid_view_outlined,
              size: 38,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    terreno.nombre,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text('Responsable: ${terreno.propietario}'),
                  const SizedBox(height: 3),
                  Text(
                    '${terreno.latitud.toStringAsFixed(6)}, '
                    '${terreno.longitud.toStringAsFixed(6)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ObservacionCard extends StatelessWidget {
  const _ObservacionCard({
    required this.observacion,
    required this.onEdit,
    required this.onDelete,
  });

  final Observacion observacion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = observacion.creadoEn.toLocal();
    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notes, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(observacion.texto, style: const TextStyle(height: 1.4)),
                  const SizedBox(height: 8),
                  Text(
                    formattedDate,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActividadCard extends StatelessWidget {
  const _ActividadCard({
    required this.actividad,
    required this.onMarkAsDone,
    required this.onDelete,
  });

  final Actividad actividad;
  final VoidCallback? onMarkAsDone;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = actividad.fecha.toLocal();
    final fechaTexto =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    final realizada = actividad.estado == EstadoActividad.realizada;
    final colorEstado = realizada
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.tertiary;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              realizada ? Icons.task_alt : Icons.schedule_outlined,
              color: colorEstado,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          actividad.tipo,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _ActividadStatus(estado: actividad.estado),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    actividad.descripcion,
                    style: const TextStyle(height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fechaTexto,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (actividad.evidenciaRuta != null) ...[
                    const SizedBox(height: 10),
                    _EvidenciaPreview(ruta: actividad.evidenciaRuta!),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'done') onMarkAsDone?.call();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                if (onMarkAsDone != null)
                  const PopupMenuItem(
                    value: 'done',
                    child: Text('Marcar realizada'),
                  ),
                const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActividadStatus extends StatelessWidget {
  const _ActividadStatus({required this.estado});

  final EstadoActividad estado;

  @override
  Widget build(BuildContext context) {
    final realizada = estado == EstadoActividad.realizada;
    final backgroundColor = realizada
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.tertiaryContainer;
    final foregroundColor = realizada
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onTertiaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.label,
        style: TextStyle(color: foregroundColor, fontSize: 12),
      ),
    );
  }
}

class _EvidenciaPreview extends StatelessWidget {
  const _EvidenciaPreview({required this.ruta});

  final String ruta;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.file(
        File(ruta),
        height: 96,
        width: 128,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 76,
          width: 128,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: const Text('Foto no disponible', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _ActividadEmpty extends StatelessWidget {
  const _ActividadEmpty({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _ObservacionEmpty extends StatelessWidget {
  const _ObservacionEmpty({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
