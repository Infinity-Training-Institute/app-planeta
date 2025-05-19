import 'package:app_planeta/presentation/components/invoce_details.dart';
import 'package:app_planeta/presentation/components/invoice_component.dart';
import 'package:app_planeta/providers/type_factura_provider.dart';
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
  int invoiceDiscount = 0;
  bool _isDialogCompleted = false; // Controla si ya se ingresó el descuento

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDiscountDialog();

      // guardamos en un provider el tipo de factura
      Provider.of<TypeFacturaProvider>(
        context,
        listen: false,
      ).setTipoFactura(2); // 1: Factura normal, 2: Factura especial
    });
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
                    final text = discountController.text;
                    // Asegúrate de que `text` sea válido como entero
                    invoiceDiscount =
                        int.tryParse(text) ??
                        0; // Si no se puede convertir, asigna 0
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
        typeFactura: "2",
      ),
    );
  }
}
