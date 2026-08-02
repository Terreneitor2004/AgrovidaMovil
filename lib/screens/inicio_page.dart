import 'package:flutter/material.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({super.key, required this.onOpenSection});

  final ValueChanged<int> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          const Text(
            'AgroVida',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.eco_outlined, color: Colors.white, size: 42),
                SizedBox(height: 22),
                Text(
                  'Cultivo inicial: banano',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Base multiplataforma para registrar y consultar información desde el campo.',
                  style: TextStyle(
                    color: Color(0xFFE8F5E9),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Módulos planificados',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _HomeModule(
            icon: Icons.landscape_outlined,
            title: 'Mis terrenos',
            description: 'Registro local de parcelas y responsables.',
            onTap: () => onOpenSection(1),
          ),
          _HomeModule(
            icon: Icons.map_outlined,
            title: 'Mapa de parcelas',
            description: 'Ubicación visual de los terrenos registrados.',
            onTap: () => onOpenSection(2),
          ),
          _HomeModule(
            icon: Icons.camera_alt_outlined,
            title: 'Diagnóstico de banano',
            description: 'Clasificación preliminar a partir de una fotografía.',
            onTap: () => onOpenSection(3),
          ),
        ],
      ),
    );
  }
}

class _HomeModule extends StatelessWidget {
  const _HomeModule({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
