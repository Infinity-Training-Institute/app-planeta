# app_planeta

![Flutter](https://img.shields.io/badge/Flutter-3.7.2-blue?logo=flutter)
![Android](https://img.shields.io/badge/Android-Supported-green?logo=android)

## Descripción

**app_planeta** es una aplicación móvil diseñada para la facturación de libros, implementando reglas de descuento como:
- **3x2**
- **2x1**
- **50% de descuento**
- **Descuento por horas**

La aplicación está diseñada para ser utilizada en un dispositivo móvil POS para la generación de facturas.

## Dependencias

Las dependencias utilizadas en el proyecto son:

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
```

## Instalación

### 1. Clonar el repositorio
```sh
git clone https://github.com/tu_usuario/app_planeta.git
cd app_planeta
```

### 2. Instalar dependencias
```sh
flutter pub get
```

## Ejecución en un dispositivo físico o emulador

### Opción 1: Emulador
1. Abre **Android Studio** o **Visual Studio Code**.
2. Inicia un emulador desde AVD Manager (**Android Studio**) o usa el comando:
   ```sh
   flutter emulators --launch nombre_del_emulador
   ```
3. Ejecuta la aplicación:
   ```sh
   flutter run
   ```

### Opción 2: Dispositivo físico (Android)
1. Conecta un dispositivo físico con **Depuración USB** activada.
2. Verifica que el dispositivo está detectado:
   ```sh
   flutter devices
   ```
3. Ejecuta la aplicación:
   ```sh
   flutter run
   ```

Si tienes problemas de conexión, revisa los permisos de depuración y asegurarte de que el teléfono tiene **Depuración USB** activada en las opciones de desarrollador.

---

Ahora puedes empezar a desarrollar con **app_planeta** 🚀

