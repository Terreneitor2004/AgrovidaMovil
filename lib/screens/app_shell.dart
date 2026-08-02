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
    return Scaffold(
      body: switch (_selectedIndex) {
        0 => InicioPage(
          terrenoStore: widget.terrenoStore,
          onOpenSection: _selectSection,
        ),
        1 => TerrenosPage(terrenoStore: widget.terrenoStore),
        2 => MapaPage(terrenoStore: widget.terrenoStore),
        _ => const DiagnosticoPage(),
      },
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
            icon: Icon(Icons.landscape_outlined),
            selectedIcon: Icon(Icons.landscape),
            label: 'Terrenos',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
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
