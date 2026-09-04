import 'package:flutter/material.dart';

import '../state/terreno_store.dart';
import 'diagnostico_page.dart';
import 'inicio_page.dart';
import 'mapa_page.dart';
import 'terrenos_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.terrenoStore,
    required this.ownsStore,
  });

  final TerrenoStore terrenoStore;
  final bool ownsStore;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.terrenoStore.cargar();
  }

  @override
  void dispose() {
    if (widget.ownsStore) widget.terrenoStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = switch (_selectedIndex) {
      0 => InicioPage(
        terrenoStore: widget.terrenoStore,
        onOpenSection: _selectSection,
      ),
      1 => TerrenosPage(terrenoStore: widget.terrenoStore),
      2 => MapaPage(terrenoStore: widget.terrenoStore),
      _ => const DiagnosticoPage(),
    };

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        reverseDuration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final scale = Tween<double>(begin: 0.985, end: 1).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
        child: KeyedSubtree(key: ValueKey(_selectedIndex), child: page),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectSection,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Terrenos',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.eco_outlined),
            selectedIcon: Icon(Icons.eco),
            label: 'Diagnóstico',
          ),
        ],
      ),
    );
  }

  void _selectSection(int index) {
    setState(() => _selectedIndex = index);
  }
}
