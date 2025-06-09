import 'package:app_planeta/infrastructure/local_db/dao/index.dart';
import 'package:app_planeta/presentation/screens/downloads/downloads.dart';
import 'package:app_planeta/presentation/screens/facturacion_especial/facturacion_especial.dart';
import 'package:app_planeta/presentation/screens/home/home_screen.dart';
import 'package:app_planeta/presentation/screens/login/login_screen.dart';
import 'package:app_planeta/presentation/screens/sube_datos_nube/sube_datos_nube.dart';
import 'package:app_planeta/providers/auth_provider.dart';
import 'package:app_planeta/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DrawerComponent extends StatefulWidget {
  const DrawerComponent({super.key});

  @override
  State<DrawerComponent> createState() => _DrawerComponentState();
}

class _DrawerComponentState extends State<DrawerComponent> {
  List<Map<String, dynamic>> usuarios = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final data = await UserDao().getUserByNickName(userProvider.username);
    setState(() {
      usuarios = data != null ? [data.toMap()] : [];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Redirigir al login si no está autenticado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!authProvider.isAuthenticated) {
        Future.microtask(() {
          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        });
      }
    });

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Center(
                    child: Image.asset('assets/logo.webp', width: 240),
                  ),
                ),
                if (usuarios.isNotEmpty &&
                    usuarios.first["tipoUsuario"] == 3) ...[
                  ListTile(
                    leading: const Icon(Icons.trolley),
                    title: const Text('Facturación Normal'),
                    selected:
                        ModalRoute.of(context)?.settings.name ==
                        'facturacion_normal',
                    selectedTileColor: Colors.grey[300],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeScreen(),
                          settings: const RouteSettings(
                            name: 'facturacion_normal',
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.request_quote),
                    title: const Text('Facturación Especial'),
                    selected:
                        ModalRoute.of(context)?.settings.name ==
                        'facturacion_especial',
                    selectedTileColor: Colors.grey[300],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FacturacionEspecial(),
                          settings: const RouteSettings(
                            name: 'facturacion_especial',
                          ),
                        ),
                      );
                    },
                  ),
                ],

                if (usuarios.isNotEmpty &&
                    usuarios.first["tipoUsuario"] == 1) ...[
                  ListTile(
                    leading: const Icon(Icons.cloud_upload),
                    title: const Text('Sube datos nube'),
                    selected:
                        ModalRoute.of(context)?.settings.name ==
                        'sube_datos_nube',
                    selectedTileColor: Colors.grey[300],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubeDatosNube(),
                          settings: const RouteSettings(
                            name: 'sube_datos_nube',
                          ),
                        ),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Preferencias descarga'),
                    selected:
                        ModalRoute.of(context)?.settings.name == 'downloads',
                    selectedTileColor: Colors.grey[300],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DescargaScreen(),
                          settings: const RouteSettings(name: 'downloads'),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          _buildUserProfile(),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    final authProvider = Provider.of<AuthProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.account_circle),
          const SizedBox(width: 16),
          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : usuarios.isEmpty
                    ? const Text("No hay usuarios disponibles")
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          usuarios.map((usuario) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${usuario["nombreUsuario"]?.trim() ?? ""} ${usuario["apellidoUsuario"]?.trim() ?? "Sin nombre"}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  usuario['nickUsuario'] ?? 'Sin nick',
                                  style: TextStyle(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          }).toList(),
                    ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }
}
