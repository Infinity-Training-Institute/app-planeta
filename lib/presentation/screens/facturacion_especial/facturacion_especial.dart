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
  final _discountFormKey = GlobalKey<FormState>();

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
    final discountController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text("Entrada Facturación Especial"),
            content: Form(
              key: _discountFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("(%) Descuento"),
                  TextFormField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Descuento"),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa un número';
                      }
                      final parsed = int.tryParse(value);
                      if (parsed == null) {
                        return 'Debe ser un número entero';
                      }
                      if (parsed < 1 || parsed > 100) {
                        return 'Los rangos permitidos son 1 a 100';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_discountFormKey.currentState!.validate()) {
                    setState(() {
                      invoiceDiscount = int.parse(discountController.text);
                      _isDialogCompleted = true;
                    });
                    Navigator.pop(context);
                  }
                  // Si no pasa la validación, el error se muestra automáticamente.
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
