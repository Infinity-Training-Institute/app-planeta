import 'package:app_planeta/infrastructure/local_db/dao/index.dart';
import 'package:app_planeta/infrastructure/local_db/models/index.dart';
import 'package:app_planeta/presentation/components/invoce_details.dart';
import 'package:app_planeta/presentation/components/invoice_component.dart';
import 'package:app_planeta/providers/connectivity_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../providers/syncronized_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ignore: unused_field
  List<ProductsModel> _productos = [];
  final UpdateDao _updateDao = UpdateDao();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Obtener fecha actual en formato YYYY-MM-DD
      String fechaHoy = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Verificar si ya hay una actualización con la fecha de hoy
      UpdateModel? existingUpdate = await _updateDao.getInfoByDate(fechaHoy);

      if (existingUpdate == null) {
        _syncData(context);
      }
    });
  }

  void _syncData(BuildContext context) async {
    if (!context.mounted) return;
    // Verificar conexión a internet
    final connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );

    if (connectivityProvider.isConnected) {
      _showLoadingDialog(context);

      await Provider.of<SyncronizedData>(
        context,
        listen: false,
      ).getDataToCloud(context);

      if (context.mounted) {
        Navigator.pop(context);
        _loadProducts();
        _showAlert(
          context,
          Provider.of<SyncronizedData>(context, listen: false).message,
        );
      }
    }
    return;
  }

  void _loadProducts() async {
    final productsDao = ProductsDao();
    List<ProductsModel> productos = await productsDao.getAllProducts();

    if (mounted) {
      setState(() {
        _productos = productos;
      });
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            title: Text("Sincronización"),
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Sincronizando datos..."),
              ],
            ),
          ),
    );
  }

  void _showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Sincronización"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InvoiceComponent(
      title: "Facturación Normal",
      body: InvoceDetails(onSync: () => _syncData(context)),
    );
  }
}
