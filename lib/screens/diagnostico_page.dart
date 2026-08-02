import 'package:flutter/material.dart';

class DiagnosticoPage extends StatelessWidget {
  const DiagnosticoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Diagnóstico de banano',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text('Este será el siguiente módulo funcional de AgroVida.'),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Próximo avance',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aquí podrás tomar o seleccionar una fotografía y recibir un resultado preliminar con recomendaciones claras.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const _ResultPreview(
            color: Color(0xFF2E7D32),
            icon: Icons.check_circle_outline,
            title: 'Planta saludable',
          ),
          const _ResultPreview(
            color: Color(0xFFF57C00),
            icon: Icons.warning_amber_rounded,
            title: 'Condición detectada',
          ),
          const _ResultPreview(
            color: Color(0xFF546E7A),
            icon: Icons.help_outline,
            title: 'Resultado no concluyente',
          ),
        ],
      ),
    );
  }
}

class _ResultPreview extends StatelessWidget {
  const _ResultPreview({
    required this.color,
    required this.icon,
    required this.title,
  });

  final Color color;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
