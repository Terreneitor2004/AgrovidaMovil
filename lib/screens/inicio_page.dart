import 'package:flutter/material.dart';

import '../state/terreno_store.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({
    super.key,
    required this.terrenoStore,
    required this.onOpenSection,
  });

  final TerrenoStore terrenoStore;
  final ValueChanged<int> onOpenSection;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'AgroVida',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Información',
                onPressed: () => showAboutDialog(
                  context: context,
                  applicationName: 'AgroVida',
                  applicationVersion: 'Prototipo Flutter',
                  children: const [
                    Text(
                      'Agricultura de precisión enfocada inicialmente en banano.',
                    ),
                  ],
                ),
                icon: const Icon(Icons.info_outline),
              ),
            ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.eco_outlined, color: Colors.white, size: 42),
                const SizedBox(height: 22),
                const Text(
                  'Cultivo inicial: banano',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Registra parcelas y observaciones desde el campo, incluso sin conexión.',
                  style: TextStyle(
                    color: Color(0xFFE8F5E9),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                AnimatedBuilder(
                  animation: terrenoStore,
                  builder: (context, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${terrenoStore.terrenos.length} terrenos guardados',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Funciones principales',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _HomeModule(
            icon: Icons.landscape_outlined,
            title: 'Mis terrenos',
            description: 'Crea, busca, edita y elimina terrenos sin Internet.',
            status: 'Disponible',
            onTap: () => onOpenSection(1),
          ),
          _HomeModule(
            icon: Icons.map_outlined,
            title: 'Mapa de parcelas',
            description: 'Ubica tus terrenos con cartografía de OpenStreetMap.',
            status: 'Disponible',
            onTap: () => onOpenSection(2),
          ),
          _HomeModule(
            icon: Icons.camera_alt_outlined,
            title: 'Diagnóstico de banano',
            description:
                'Captura una hoja para obtener un resultado preliminar.',
            status: 'Próximo avance',
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
    required this.status,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      status,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
