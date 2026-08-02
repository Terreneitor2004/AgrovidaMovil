import 'package:flutter/material.dart';

import 'data/terreno_repository.dart';
import 'screens/app_shell.dart';
import 'state/terreno_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgroVidaApp());
}

class AgroVidaApp extends StatelessWidget {
  const AgroVidaApp({super.key, this.terrenoStore});

  final TerrenoStore? terrenoStore;

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF2E7D32);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgroVida',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8F3),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E7DC)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: AppShell(
        terrenoStore:
            terrenoStore ?? TerrenoStore(SqliteTerrenoRepository.instance),
        ownsStore: terrenoStore == null,
      ),
    );
  }
}
