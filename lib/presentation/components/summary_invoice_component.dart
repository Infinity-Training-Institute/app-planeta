import 'dart:typed_data';

import 'package:app_planeta/infrastructure/local_db/models/datos_cliente_model.dart';
import 'package:app_planeta/presentation/components/ean_scanner_component.dart';
import 'package:app_planeta/presentation/components/invoce_details.dart';
import 'package:app_planeta/presentation/screens/home/home_screen.dart';
import 'package:app_planeta/providers/user_provider.dart';
import 'package:app_planeta/services/add_new_client.dart';
import 'package:app_planeta/services/print_invoices_services.dart';
import 'package:app_planeta/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class PaymentEntry {
  final String method;
  final String? typeCard;
  final String? typeCard2;
  final String? reference;
  final int amount;
  final String? numberPhone;
  final int? numberBono;
  final int? totalBono;
  final int? numberOfBonoUsed;

  PaymentEntry({
    required this.method,
    this.typeCard,
    this.typeCard2,
    required this.amount,
    this.reference,
    this.numberPhone,
    this.numberBono,
    this.totalBono,
    this.numberOfBonoUsed,
  });
}

class SummaryInvoiceComponent extends StatelessWidget {
  final int invoiceValue;
  final String? typeInvoice;
  final List<PaymentEntry> payments;
  final int mixedAmount; // Si usas mezcla de pagos
  final int changeAmount; // Cambio total si lo necesitas
  final List<Product> products;
  final List<DatosClienteModel> datosClientes = [];

  // Add these controllers at the class level
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _primerApellidoController =
      TextEditingController();
  final TextEditingController _segundoApellidoController =
      TextEditingController();
  final TextEditingController _primerNombreController = TextEditingController();
  final TextEditingController _segundoNombreController =
      TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  final ValueNotifier<bool> _createCustomerNotifier = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<String> _selectedPersonType = ValueNotifier<String>(
    'Natural',
  );

  SummaryInvoiceComponent({
    super.key,
    required this.invoiceValue,
    required this.payments,
    required this.products,
    this.mixedAmount = 0,
    this.changeAmount = 0,
    this.typeInvoice,
  });

  /* 
    funcion para scanear el codigo qr del cliente
    url creacion del codigo: https://prologics.co/fact_elect/
  */
  Future<void> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  void _scanQrBarcode(BuildContext context) async {
    await _checkCameraPermission();

    if (!context.mounted) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerComponent()),
    );

    if (result != null && result is String) {
      _llenarControllersDesdeQR(result);
    }
  }

  void _llenarControllersDesdeQR(String data) {
    String cleaned = data.trim().replaceAll(RegExp(r'\s+'), ' ');
    List<String> parts = cleaned.split(' ');

    if (parts.length < 9) {
      print("Datos insuficientes para procesar");
      return;
    }

    _cedulaController.text = parts[0];
    _primerApellidoController.text = parts[1];
    _segundoApellidoController.text = parts[2];
    _primerNombreController.text = parts[3];
    _segundoNombreController.text = parts[4];

    // Buscar el índice del correo
    int correoIndex = parts.indexWhere((part) => part.contains('@'));
    if (correoIndex == -1 || correoIndex + 3 > parts.length) {
      print("Correo no encontrado o datos mal formados");
      return;
    }

    _correoController.text = parts[correoIndex];

    // Dirección: desde correoIndex + 1 hasta length - 3
    _direccionController.text = parts
        .sublist(correoIndex + 1, parts.length - 2)
        .join(' ');
    _ciudadController.text = parts[parts.length - 2];
    _telefonoController.text = parts[parts.length - 1];

    print("Cédula: ${_cedulaController.text}");
    print("Primer Apellido: ${_primerApellidoController.text}");
    print("Segundo Apellido: ${_segundoApellidoController.text}");
    print("Primer Nombre: ${_primerNombreController.text}");
    print("Segundo Nombre: ${_segundoNombreController.text}");
    print("Correo: ${_correoController.text}");
    print("Dirección: ${_direccionController.text}");
    print("Ciudad: ${_ciudadController.text}");
    print("Teléfono: ${_telefonoController.text}");
  }

  void _clearForm() {
    _cedulaController.clear();
    _primerApellidoController.clear();
    _segundoApellidoController.clear();
    _primerNombreController.clear();
    _segundoNombreController.clear();
    _correoController.clear();
    _direccionController.clear();
    _ciudadController.clear();
    _telefonoController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Factura'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCreateCustomer(),
              ValueListenableBuilder<bool>(
                valueListenable: _createCustomerNotifier,
                builder: (context, createCustomer, child) {
                  return createCustomer
                      ? _buildCustomerForm(context)
                      : const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),
              _buildInvoiceCard(),
              const SizedBox(height: 16),
              _buildTransactionSummary(),
              const SizedBox(height: 20),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Valor Factura:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              CurrencyFormatter.formatCOP(invoiceValue),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSummary() {
    // Inicializa todos los métodos en $0
    final amounts = {'Efectivo': 0, 'Tarjeta': 0, 'QR Banco': 0, 'Bono': 0};
    // Llena solo el que venga en payments
    for (var p in payments) {
      if (amounts.containsKey(p.method)) {
        amounts[p.method] = p.amount;
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de la Transacción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTransactionRow('Efectivo', amounts['Efectivo']!),
            _buildTransactionRow('Tarjeta', amounts['Tarjeta']!),
            _buildTransactionRow('QR', amounts['QR Banco']!),
            _buildTransactionRow('Bono', amounts['Bono']!),
            const Divider(thickness: 1),
            _buildTransactionRow('Total', invoiceValue, isBold: true),
            _buildTransactionRow(
              'Cambio',
              changeAmount,
              isBold: true,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow(
    String label,
    int amount, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            CurrencyFormatter.formatCOP(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateCustomer() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Desea Crear Cliente',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(
            valueListenable: _createCustomerNotifier,
            builder: (context, createCustomer, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: _createCustomerNotifier.value,
                    onChanged: (val) {
                      _createCustomerNotifier.value = val!;
                      // No se limpia el formulario si se selecciona "Sí"
                    },
                  ),
                  const Text("Sí"),
                  Radio<bool>(
                    value: false,
                    groupValue: _createCustomerNotifier.value,
                    onChanged: (val) {
                      _createCustomerNotifier.value = val!;
                      if (val == false) {
                        _clearForm(); // Limpiar si se selecciona "No"
                      }
                    },
                  ),
                  const Text("No"),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // form cliente
  Widget _buildCustomerForm(BuildContext context) {
    return Center(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tipo de Persona',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<String>(
                valueListenable: _selectedPersonType,
                builder: (context, selectedValue, child) {
                  return DropdownButtonFormField<String>(
                    value: selectedValue,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Natural",
                        child: Text("Natural"),
                      ),
                      DropdownMenuItem(
                        value: "Jurídica",
                        child: Text("Jurídica"),
                      ),
                    ],
                    onChanged: (value) => _selectedPersonType.value = value!,
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildInputField(
                "Cédula",
                controller: _cedulaController,
                keyboardType: TextInputType.number,
              ),
              _buildInputField(
                "P. Apellido",
                controller: _primerApellidoController,
              ),
              _buildInputField(
                "S. Apellido",
                controller: _segundoApellidoController,
              ),
              _buildInputField(
                "P. Nombre",
                controller: _primerNombreController,
              ),
              _buildInputField(
                "S. Nombre",
                controller: _segundoNombreController,
              ),
              _buildInputField(
                "Correo Electrónico",
                keyboardType: TextInputType.emailAddress,
                controller: _correoController,
              ),
              _buildInputField("Dirección", controller: _direccionController),
              _buildInputField("Ciudad", controller: _ciudadController),
              _buildInputField(
                "Teléfono",
                keyboardType: TextInputType.phone,
                controller: _telefonoController,
              ),

              ElevatedButton.icon(
                onPressed: () => _scanQrBarcode(context),
                icon: Icon(Icons.qr_code_scanner),
                label: Text('Escanear QR'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label, {
    TextInputType keyboardType = TextInputType.text,
    TextEditingController? controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final InvoiceService invoiceService =
        InvoiceService(); // Instancia del servicio

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            // si existe datos del client se crea el cliente
            onPressed: () async {
              if (_createCustomerNotifier.value) {
                try {
                  final userProvider = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  );
                  // Create a DatosClienteModel properly using the fromMap constructor or manually
                  final clientModel = DatosClienteModel(
                    clcecl: _cedulaController.text,
                    clnmcl: _primerNombreController.text,
                    clpacl: _primerApellidoController.text,
                    clsacl: _segundoApellidoController.text,
                    clmail: _correoController.text,
                    cldire: _direccionController.text,
                    clciud: _ciudadController.text,
                    cltele: _telefonoController.text,
                    clusua: userProvider.username,
                    cltipo:
                        _selectedPersonType
                            .value, // Pass the string value directly
                    clfecha: DateTime.now().toString(),
                    cl_nube: '0',
                  );

                  // Use the client service to add the client
                  final clienService = AddNewClient();
                  final clientId = await clienService.addClient(clientModel);

                  if (clientId > 0) {
                    // Successfully added the client
                    datosClientes.add(clientModel);

                    // Show success message
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Cliente creado correctamente con ID: $clientId',
                          ),
                        ),
                      );
                    }
                  } else {
                    // Handle case where client wasn't added properly
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo crear el cliente'),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  // Handle any errors that occur during client creation
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error al crear el cliente: ${e.toString()}',
                        ),
                      ),
                    );
                  }
                }
              }
              if (!context.mounted) return;
              final pdf = await invoiceService.generateInvoice(
                context,
                products,
                datosClientes,
                invoiceValue,
                payments,
                typeInvoice,
                changeAmount,
              ); // Generar PDF
              await Printing.layoutPdf(
                onLayout: (format) async => pdf?.save() ?? Uint8List(0),
              );

              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => HomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Imprimir Factura',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              'Cancelar Factura',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
