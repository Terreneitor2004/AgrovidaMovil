import 'package:flutter/material.dart';

/// Resumen del dibujo. Las medidas son orientativas, no catastrales.
class LoteEditorPanel extends StatelessWidget {
  const LoteEditorPanel({
    super.key,
    required this.puntos,
    required this.hectareas,
    required this.perimetroMetros,
    required this.onUndo,
    required this.onCancel,
    required this.onSave,
  });

  final int puntos;
  final double hectareas;
  final double perimetroMetros;
  final VoidCallback onUndo;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final listo = puntos >= 3;
    return Material(
      color: colors.surface,
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.draw_outlined, color: colors.primary, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Delimitar lote',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                ),
                IconButton(
                  tooltip: 'Cancelar delimitación',
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Text(
              listo
                  ? 'Añada más vértices o guarde el contorno.'
                  : 'Toque las esquinas del lote: mínimo 3 vértices.',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Wrap(
                spacing: 22,
                runSpacing: 10,
                children: [
                  _Measure(label: 'Vértices', value: '$puntos'),
                  _Measure(
                    label: 'Área aprox.',
                    value: listo ? '${hectareas.toStringAsFixed(2)} ha' : '—',
                  ),
                  _Measure(
                    label: listo ? 'Perímetro aprox.' : 'Trazo aprox.',
                    value: puntos < 2
                        ? '—'
                        : perimetroMetros >= 1000
                        ? '${(perimetroMetros / 1000).toStringAsFixed(2)} km'
                        : '${perimetroMetros.toStringAsFixed(1)} m',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: puntos == 0 ? null : onUndo,
                  icon: const Icon(Icons.undo_rounded, size: 19),
                  label: const Text('Deshacer'),
                ),
                FilledButton.icon(
                  onPressed: listo ? onSave : null,
                  icon: const Icon(Icons.check_rounded, size: 19),
                  label: const Text('Guardar lote'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Measure extends StatelessWidget {
  const _Measure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
