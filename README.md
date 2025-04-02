# App Planeta

![Flutter](https://img.shields.io/badge/Flutter-3.7.2-blue?logo=flutter)
![Android](https://img.shields.io/badge/Android-Supported-green?logo=android)

## Descripción

Aplicación móvil para facturar libros siguiendo reglas de descuento. Las reglas aplicadas son:
- **3x2**
- **2x1**
- **50% de descuento**
- **Descuento por horas**

La aplicación está diseñada para ser utilizada en dispositivos móviles POS para la gestión de facturas.

## Dependencias

Este proyecto usa las siguientes dependencias:

```yaml
dependencies:
  connectivity_plus: ^6.1.3
  cupertino_icons: ^1.0.8
  dio: ^5.8.0+1
  flutter:
    sdk: flutter
  flutter_launcher_icons: ^0.14.3
  flutter_spinkit: ^5.2.1
  google_fonts: ^6.2.1
  intl: ^0.20.2
  path: ^1.9.1
  provider: ^6.1.2
  shimmer: ^3.0.0
  sqflite: ^2.4.2
  permission_handler: ^11.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/
```

## Instalación

Sigue estos pasos para descargar y ejecutar la aplicación en tu entorno local:

1. Clona el repositorio:
   ```sh
   git clone https://github.com/Infinity-Training-Institute/app-planeta
   cd app_planeta
   ```

2. Instala las dependencias:
   ```sh
   flutter pub get
   ```

3. Ejecuta la aplicación en un emulador o dispositivo físico:
   ```sh
   flutter run
   ```

## Configuración Adicional

Si necesitas regenerar los íconos de la aplicación, usa:
```sh
flutter pub run flutter_launcher_icons:main
```

---

¡Listo! Ahora puedes comenzar a usar **App Planeta** 📚🚀.

