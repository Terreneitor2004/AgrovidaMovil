import 'package:flutter/material.dart';

class DiagnosticoPage extends StatelessWidget {
  const DiagnosticoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Diagnóstico de banano',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Análisis preliminar de hojas para apoyar la inspección en campo.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Icon(
                    Icons.eco_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Módulo en preparación',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Podrás tomar o seleccionar una fotografía para obtener un resultado preliminar, con confianza y recomendaciones seguras.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Resultados que mostrará la aplicación',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const _ResultPreview(
            icon: Icons.check_circle_outline,
            title: 'Planta saludable',
            description:
                'La imagen no presenta una condición visible relevante.',
            tone: _ResultTone.healthy,
          ),
          const _ResultPreview(
            icon: Icons.warning_amber_rounded,
            title: 'Condición detectada',
            description:
                'Solicitará inspección visual y registro de evidencia.',
            tone: _ResultTone.warning,
          ),
          const _ResultPreview(
            icon: Icons.help_outline,
            title: 'Resultado no concluyente',
            description:
                'Indicará cómo tomar una nueva fotografía de mejor calidad.',
            tone: _ResultTone.inconclusive,
          ),
        ],
      ),
    );
  }
}

class _ResultPreview extends StatelessWidget {
  const _ResultPreview({
    required this.icon,
    required this.title,
    required this.description,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String description;
  final _ResultTone tone;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      _ResultTone.healthy => colorScheme.primary,
      _ResultTone.warning => colorScheme.tertiary,
      _ResultTone.inconclusive => colorScheme.onSurfaceVariant,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
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

enum _ResultTone { healthy, warning, inconclusive }
