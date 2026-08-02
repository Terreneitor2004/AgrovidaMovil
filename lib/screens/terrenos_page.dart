import 'package:flutter/material.dart';

class TerrenosPage extends StatelessWidget {
  const TerrenosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlannedModule(
      icon: Icons.landscape_outlined,
      title: 'Mis terrenos',
      description: 'El registro local de terrenos será el siguiente avance.',
    );
  }
}

class _PlannedModule extends StatelessWidget {
  const _PlannedModule({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(description, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
