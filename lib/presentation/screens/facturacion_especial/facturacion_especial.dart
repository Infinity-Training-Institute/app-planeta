import 'package:app_planeta/presentation/components/invoce_details.dart';
import 'package:app_planeta/presentation/components/invoice_component.dart';
import 'package:flutter/material.dart';
import 'package:app_planeta/providers/connectivity_provider.dart';
import 'package:app_planeta/utils/alert_utils.dart';
import 'package:provider/provider.dart';
import '../../../providers/syncronized_data.dart';

class FacturacionEspecial extends StatefulWidget {
  const FacturacionEspecial({super.key});

  @override
  State<FacturacionEspecial> createState() => _FacturacionEspecial();
}

class _FacturacionEspecial extends State<FacturacionEspecial> {
  double invoiceDiscount = 0.0;
  bool _isDialogCompleted = false; // Controla si ya se ingresó el descuento

  @override
  void initState() {
    super.initState();
    _showDiscountDialog();
  }

  void _showDiscountDialog() {
    TextEditingController discountController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false, // Evita cerrar tocando fuera
        builder: (context) {
          return AlertDialog(
            title: const Text("Entrada Facturación Especial"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("(%) Descuento"),
                TextField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Descuento"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Cierra la pantalla si cancela
                },
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    invoiceDiscount =
                        double.tryParse(discountController.text) ?? 0.0;
                    _isDialogCompleted = true; // Permite mostrar la pantalla
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Continuar"),
              ),
            ],
          );
        },
      );
    });
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

  void onSync(BuildContext context) async {
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
        showAlert(
          context,
          "Exito",
          Provider.of<SyncronizedData>(context, listen: false).message,
        );
      }
    } else {
      showAlert(
        context,
        "Error",
        "No se detecta conexión a internet. Conéctese a una red para descargar los datos.",
      );
    }
    return;
  }

  @override
  Widget build(BuildContext context) {
    // No muestra la UI hasta que el usuario haya completado el diálogo
    if (!_isDialogCompleted) {
      return const SizedBox();
    }

    return InvoiceComponent(
      title: "Facturación Especial",
      body: InvoceDetails(
        onSync: () => onSync(context),
        invoiceDiscount: invoiceDiscount,
      ),
    );
  }
}
