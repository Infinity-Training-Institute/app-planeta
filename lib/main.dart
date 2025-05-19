import 'package:app_planeta/infrastructure/local_db/dao/index.dart';
import 'package:app_planeta/presentation/screens/sube_datos_nube/sube_datos_nube.dart';
import 'package:app_planeta/providers/syncronized_data.dart';
import 'package:app_planeta/providers/type_factura_provider.dart';
import 'package:app_planeta/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/login/login_screen.dart';

// libreria para los permisos
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solicitar permisos necesarios al iniciar la app
  await requestPermissions();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SyncronizedData()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => StandProvider()),
        ChangeNotifierProvider(create: (_) => TypeFacturaProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> requestPermissions() async {
  // solicitamos permisos de
  /* 
    1. Acceso a la camara
    2. Acesso al bluethoot
    3. Acesso al internet 
    4. Acesso al almacenamiento interno
    5. Acesso al nfc
  */

  await Permission.camera.request();

  // Bluetooth (especial para Android 12+)
  await Permission.bluetooth.request();
  await Permission.bluetoothConnect.request();
  await Permission.bluetoothScan.request();

  // Almacenamiento
  await Permission.storage.request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: Stack(
        children: [
          const ConnectionWrapper(),
          if (!isAuthenticated) const ConnectionBadge(), // Solo en LoginScreen
        ],
      ),
    );
  }
}

class ConnectionWrapper extends StatelessWidget {
  const ConnectionWrapper({super.key});

  Future<int?> _getTipoUsuario(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final usuario = await UserDao().getUserByNickName(userProvider.username);

    if (usuario != null) {
      final tipo = usuario.tipoUsuario;
      return tipo ;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return FutureBuilder<int?>(
      future: _getTipoUsuario(context), // Aquí se pasa el context
      builder: (context, snapshot) {
        final tipoUsuario = snapshot.data;

        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (tipoUsuario == 1) {
          return const SubeDatosNube();
        } else if (tipoUsuario == 3) {
          return const HomeScreen();
        }

        // Fallback
        return const Center(child: Text('Usuario no autorizado'));
      },
    );
  }
}

class ConnectionBadge extends StatelessWidget {
  const ConnectionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final isConnected = context.watch<ConnectivityProvider>().isConnected;
    final currentScreen =
        context.watch<AuthProvider>().isAuthenticated ? 'home' : 'login';

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: currentScreen == 'home' ? 20 : null,
      right: currentScreen == 'home' ? null : 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isConnected ? Colors.green.shade600 : Colors.red.shade600,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              isConnected ? 'Online' : 'Offline',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}