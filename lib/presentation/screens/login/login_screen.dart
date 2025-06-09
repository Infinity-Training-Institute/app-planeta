import 'package:another_flushbar/flushbar.dart';
import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/infrastructure/local_db/dao/datos_mcabfa_dao.dart';
import 'package:app_planeta/presentation/screens/sube_datos_nube/sube_datos_nube.dart';
import 'package:app_planeta/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  List<Map<String, dynamic>> usuarios = [];
  int nFacturasPendientes = 0;

  @override
  void initState() {
    super.initState();
    _getPendingInvoices();
  }

  Future<void> _getPendingInvoices() async {
    int count = await DatosMcabfaDao().getCountMcabfa();
    if (!mounted) return;
    setState(() {
      nFacturasPendientes = count;
    });
  }

  void _submitLogin(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Guardar el valor del email en el provider
      userProvider.setUsername(_emailController.text.trim());

      final data = await AppDatabase.getUsuarios();

      if (!context.mounted) return; // Verifica si el contexto sigue disponible
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        context,
      );

      if (!context.mounted) return;
      if (authProvider.isAuthenticated) {
        final filteredUser = data.firstWhere(
          (user) => user['Nick_Usuario'] == _emailController.text.trim(),
          orElse: () => {},
        );

        print("user $filteredUser");

        // verificamos que no sea nulo
        if (filteredUser.isNotEmpty) {
          final tipoUsuario = filteredUser["Tipo_Usuario"];

          switch (tipoUsuario) {
            case 1:
              {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SubeDatosNube()),
                );
              }
              break;
            case 3:
              {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
              break;
            default:
              {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'El usuario ${{_emailController.text}} no tiene autorización.',
                    ),
                  ),
                );
              }
          }
        }
      } else {
        Flushbar(
          message: authProvider.message,
          duration: const Duration(seconds: 3),
          flushbarPosition: FlushbarPosition.TOP, // 👈 Esto lo pone arriba
          margin: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(8),
        ).show(context);

        _passwordController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('es', null);

    final authProvider = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset:
          false, // <-- Desactiva el push-up al abrir teclado
      body: Stack(
        children: [
          // Fondo con degradado
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(
                    255,
                    245,
                    245,
                    245,
                  ), // Azul claro en la parte inferior
                  Color(0xFF123D6F), // Azul intermedio
                  Color(0xFF0A1F44), // Azul muy oscuro en la parte superior
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Contenido principal
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo.webp', width: 240),
                  const SizedBox(height: 10),
                  Text(
                    "Bienvenido",
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: "Usuario",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? "Ingrese un usuario"
                                        : null,
                          ),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Contraseña",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                          ),
                          const SizedBox(height: 25),
                          authProvider.isLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  onPressed: () => _submitLogin(context),
                                  child: Text(
                                    "Iniciar Sesión",
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (nFacturasPendientes > 0) ...[
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(230), // 0.9 * 255 ≈ 230
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(26), // 0.1 * 255 ≈ 26
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    nFacturasPendientes == 1
                        ? 'Tienes $nFacturasPendientes factura pendiente por subir al servidor'
                        : 'Tienes $nFacturasPendientes facturas pendientes por subir al servidor',
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
