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
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            color: Theme.of(context).colorScheme.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.eco_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AgroVida',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Agricultura de precisión',
                            style: TextStyle(color: Color(0xFFDCECE1)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Información de AgroVida',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.14),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => showAboutDialog(
                        context: context,
                        applicationName: 'AgroVida',
                        applicationVersion: 'Prototipo móvil',
                        children: const [
                          Text(
                            'Gestión de parcelas y evidencias para el cultivo de banano.',
                          ),
                        ],
                      ),
                      icon: const Icon(Icons.info_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Resumen de campo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Información disponible en este dispositivo.',
                  style: TextStyle(color: Color(0xFFE8F5E9)),
                ),
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: terrenoStore,
                  builder: (context, _) {
                    return Row(
                      children: [
                        Expanded(
                          child: _SummaryMetric(
                            value: '${terrenoStore.terrenos.length}',
                            label: 'Terrenos\nregistrados',
                            icon: Icons.grid_view_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: _SummaryMetric(
                            value: 'GPS',
                            label: 'Mapa y\ndelimitación',
                            icon: Icons.location_searching_outlined,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de campo',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _HomeModule(
                  icon: Icons.grid_view_rounded,
                  title: 'Gestión de parcelas',
                  description:
                      'Administra terrenos, responsables y coordenadas.',
                  status: 'Disponible',
                  onTap: () => onOpenSection(1),
                ),
                _HomeModule(
                  icon: Icons.location_on_outlined,
                  title: 'Mapa de parcelas',
                  description:
                      'Ubica y delimita los lotes directamente en el mapa.',
                  status: 'Disponible',
                  onTap: () => onOpenSection(2),
                ),
                _HomeModule(
                  icon: Icons.assignment_outlined,
                  title: 'Actividades y evidencias',
                  description:
                      'Registra labores y fotografías dentro de cada terreno.',
                  status: 'Por terreno',
                  onTap: () => onOpenSection(1),
                ),
                _HomeModule(
                  icon: Icons.eco_outlined,
                  title: 'Diagnóstico de banano',
                  description:
                      'Prepara el análisis preliminar de fotografías del cultivo.',
                  status: 'Próximamente',
                  onTap: () => onOpenSection(3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFDCECE1), size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Color(0xFFDCECE1))),
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
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'Disponible'
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: status == 'Disponible'
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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
