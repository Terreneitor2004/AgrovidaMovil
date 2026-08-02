# AgroVida móvil - Flutter

Nueva base multiplataforma de AgroVida para Android y iOS. El cultivo inicial
es banano y las primeras áreas previstas son trabajo de campo, diagnóstico por
imagen y funcionamiento sin conexión.

## Herramientas instaladas en Windows

- Flutter: `C:\Users\esant\develop\flutter`
- Android SDK: `C:\Users\esant\develop\android-sdk`
- Java: `C:\Program Files\Java\jdk-21.0.11`
- Editor: Visual Studio Code con las extensiones Flutter y Dart

Si VS Code estaba abierto durante la instalación, ciérralo y ábrelo otra vez
para que reconozca las nuevas variables de entorno.

## Abrir el proyecto

1. Abre Visual Studio Code.
2. Selecciona **Archivo > Abrir carpeta**.
3. Abre esta carpeta:

   `C:\Users\esant\Downloads\AgrovidaMovil-main\agrovida_flutter`

## Ejecutar en un teléfono Android

1. En el teléfono, activa las opciones de desarrollador.
2. Activa **Depuración por USB**.
3. Conecta el teléfono con un cable que transmita datos.
4. Acepta en el teléfono la autorización de depuración para esta computadora.
5. En la terminal de VS Code ejecuta:

   ```powershell
   flutter devices
   flutter run
   ```

Durante la ejecución, guardar cambios en `lib/main.dart` aplica recarga rápida.

## Validar y compilar

```powershell
flutter doctor -v
flutter analyze
flutter test
flutter build apk --debug
```

El APK de desarrollo queda en:

`build\app\outputs\flutter-apk\app-debug.apk`

## iPhone

La carpeta `ios` ya está creada. Para compilar, firmar y probar la versión de
iPhone se necesita una Mac con Xcode. El código Dart de `lib` será compartido
entre Android y iOS.

## Proyecto Android anterior

La aplicación Kotlin original se conserva en la carpeta vecina
`AgrovidaMovil-main`. Se utilizará como referencia mientras sus funciones se
migran gradualmente a Flutter.
