import 'package:app_planeta/infrastructure/local_db/dao/datos_mcabfa_dao.dart';
import 'package:app_planeta/infrastructure/local_db/dao/datos_mlinfa_dao.dart';
import 'package:app_planeta/infrastructure/local_db/dao/index.dart';
import 'package:app_planeta/presentation/components/drawer_component.dart';
import 'package:app_planeta/providers/connectivity_provider.dart';
import 'package:app_planeta/services/upload_data_to_cloud.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SubeDatosNube extends StatefulWidget {
  const SubeDatosNube({Key? key}) : super(key: key);

  @override
  _SubeDatosNubeState createState() => _SubeDatosNubeState();
}

class _SubeDatosNubeState extends State<SubeDatosNube>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // Datos simulados para las bases de datos
  int mclienteCount = 0;
  int mlinfaCount = 0;
  int mcabfaCount = 0;
  int productosCount = 0;
  bool isLoading = false;
  bool isRefreshing = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  Future<void> obtenerDatos() async {
    if (isRefreshing) return;

    // Primera setState: no hay await antes, así que el widget sigue montado.
    setState(() {
      isRefreshing = true;
    });

    // Simula carga
    await Future.delayed(const Duration(milliseconds: 1500));

    // Cargas reales
    final countMcabfa = await DatosMcabfaDao().getCountMcabfa();
    final countMlinfa = await DatosMlinfaDao().getCountMlinfa();
    final countMcliente = await DatosClienteDao().getCountClientes();
    final countProducto = await ProductsDao().getCountProductosNoNube();

    print(countMlinfa);

    // Comprueba que el State siga montado
    if (!mounted) return;

    // Segunda setState: seguro porque chequeamos mounted
    setState(() {
      mcabfaCount = countMcabfa;
      mlinfaCount = countMlinfa;
      mclienteCount = countMcliente;
      productosCount = countProducto;
      isRefreshing = false;
    });
  }

  // Función para subir a la nube
  Future<void> subirDatosNube() async {
    setState(() {
      isLoading = true;
    });

    // verificamos la conexión a internet
    final connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );

    if (!connectivityProvider.isConnected) {
      setState(() {
        isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Necesita conexión a internet',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // consultamos mcabfa, mlinfa y mclient
    final dataMcabfa = await DatosMcabfaDao().getAllMcabfa();
    final dataMlinfa = await DatosMlinfaDao().getAllMlinfa();
    final dataClient =
        await DatosClienteDao().getClientesPendientesDeSincronizar();
    final dataProducts = await ProductsDao().getProductsNotSynced();

    try {
      if (dataMcabfa.isEmpty && dataMlinfa.isEmpty && dataClient.isEmpty) {
        setState(() {
          isLoading =
              false; // Detener el loading si no hay datos para sincronizar
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'No hay datos para sincronizar',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            backgroundColor: Colors.blue.shade600,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      } else {
        // final uploader = UploadDataToCloud();

        // setState(() {
        //   isLoading = true; // Mostrar el loading mientras se suben los datos
        // });

        // await uploader
        //     .uploadAllData(
        //       mcabfa: dataMcabfa.map((e) => e.toJson()).toList(),
        //       mlinfa: dataMlinfa.map((e) => e.toJson()).toList(),
        //       mclient:
        //           dataClient.map((e) {
        //             // Creamos un Map a partir del objeto y eliminamos el campo 'cl_nube'
        //             final clienteMap = Map<String, dynamic>.from(e);
        //             clienteMap.remove('cl_nube');
        //             return clienteMap;
        //           }).toList(),
        //       products: dataProducts.map((e) => e.toJson()).toList(),
        //     )
        //     .then((_) async {
        //       setState(() {
        //         isLoading =
        //             false; // Detener el loading después de que se complete la inserción
        //       });

        //       // Actualizar las tablas con los valores de 'mnube' y 'cl_nube'
        //       for (var item in dataMcabfa) {
        //         await DatosMcabfaDao().updateMnube(item.mcnufa);
        //       }
        //       for (var item in dataMlinfa) {
        //         await DatosMlinfaDao().updateMnube(item.mlnufc);
        //       }
        //       for (var item in dataClient) {
        //         await DatosClienteDao().updateClienteNube(item['clcecl']);
        //       }
        //       for (var item in dataProducts) {
        //         await ProductsDao().updateProducto(
        //           item.id,
        //         ); // Llamamos al método de actualización para productos
        //       }

        //       obtenerDatos();

        //       // Mostrar mensaje de éxito
        //       if (!mounted) return;
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         SnackBar(
        //           content: Row(
        //             children: const [
        //               Icon(Icons.check_circle, color: Colors.white),
        //               SizedBox(width: 12),
        //               Expanded(
        //                 child: Text(
        //                   'Datos sincronizados exitosamente',
        //                   style: TextStyle(fontSize: 16),
        //                   overflow: TextOverflow.ellipsis,
        //                 ),
        //               ),
        //             ],
        //           ),
        //           backgroundColor: Colors.green,
        //           duration: Duration(seconds: 3),
        //           behavior: SnackBarBehavior.floating,
        //           shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(10),
        //           ),
        //         ),
        //       );

        //       // Esperar unos segundos para que el usuario vea el mensaje antes de continuar
        //       await Future.delayed(const Duration(seconds: 3));

        //       // Aquí no navegamos a otra pantalla, solo mostramos el mensaje
        //     })
        //     .catchError((error) {
        //       // Si ocurre un error al enviar los datos
        //       setState(() {
        //         isLoading = false; // Detener el loading si ocurre un error
        //       });
        //       if (!mounted) return;
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         SnackBar(
        //           content: Row(
        //             children: const [
        //               Icon(Icons.error, color: Colors.white),
        //               SizedBox(width: 12),
        //               Text(
        //                 'Error al sincronizar los datos',
        //                 style: TextStyle(fontSize: 16),
        //               ),
        //             ],
        //           ),
        //           backgroundColor: Colors.red.shade600,
        //           duration: const Duration(seconds: 3),
        //           behavior: SnackBarBehavior.floating,
        //           shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(10),
        //           ),
        //         ),
        //       );
        //     });

        print(dataMcabfa.map((e) => e.toJson()).toList());
      }
    } catch (e) {
      // Manejo de errores generales
      setState(() {
        isLoading = false; // Detener el loading si ocurre un error
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Error al sincronizar los datos',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
  }

  @override
  void initState() {
    super.initState();

    // Configurar la animación
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Cargar datos al inicio
    obtenerDatos();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'Subir Datos a la Nube',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon:
                isRefreshing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Icon(Icons.refresh),
            onPressed: isRefreshing ? null : obtenerDatos,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      drawer: DrawerComponent(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDarkMode
                    ? [Colors.grey.shade900, Colors.black]
                    : [Colors.indigo.shade50, Colors.grey.shade100],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _animation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 24),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  Expanded(child: _buildDataCards()),
                  const SizedBox(height: 24),
                  _buildSyncButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Resumen de Datos',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.indigo.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataCards() {
    return ListView(
      children: [
        _buildDataCounter('mcliente', mclienteCount, Icons.people, Colors.blue),
        const SizedBox(height: 2),
        _buildDataCounter(
          'mcabfa',
          mcabfaCount,
          Icons.assessment,
          Colors.orange,
        ),
        const SizedBox(height: 2),
        _buildDataCounter(
          'mlinfa',
          mlinfaCount,
          Icons.inventory_2,
          Colors.green,
        ),
        const SizedBox(height: 2),
        _buildDataCounter(
          'Productos',
          productosCount,
          Icons.inventory,
          Colors.blueGrey,
        ),
        const SizedBox(height: 2),
        Card(
          elevation: 0,
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800.withOpacity(0.5)
                  : Colors.white.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total de registros',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.indigo.shade900
                                : Colors.indigo.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${mclienteCount + mlinfaCount + mcabfaCount}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.indigo.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataCounter(
    String tableName,
    int count,
    IconData icon,
    MaterialColor color,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color:
          isDarkMode
              ? Colors.grey.shade800.withOpacity(0.5)
              : Colors.white.withOpacity(0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? color.shade900 : color.shade200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isDarkMode ? color.shade900 : color.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 30,
                color: isDarkMode ? color.shade200 : color.shade700,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tableName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Registros disponibles',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? color.shade900 : color.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? color.shade200 : color.shade800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : subirDatosNube,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.indigo.shade700
                : Colors.indigo.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 12),
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          else
            const Icon(Icons.cloud_upload_outlined, size: 24),
          const SizedBox(width: 12),
          Text(
            isLoading ? 'Sincronizando...' : 'Sincronizar con la nube',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
