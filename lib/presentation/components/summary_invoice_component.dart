import 'package:app_planeta/presentation/components/invoce_details.dart';
import 'package:app_planeta/presentation/screens/home/home_screen.dart';
import 'package:app_planeta/services/print_invoices_services.dart';
import 'package:app_planeta/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

class InvoiceScreen extends StatelessWidget {
  final int invoiceValue;
  final int cashAmount;
  final int cardAmount;
  final int qrAmount;
  final int voucherAmount;
  final int changeAmount;
  final List<Product> products;

  final ValueNotifier<bool> _createCustomerNotifier = ValueNotifier<bool>(
    false,
  );
  final ValueNotifier<String> _selectedPersonType = ValueNotifier<String>(
    'Natural',
  );

  InvoiceScreen({
    super.key,
    required this.invoiceValue,
    required this.cashAmount,
    required this.cardAmount,
    required this.qrAmount,
    required this.voucherAmount,
    required this.changeAmount,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de Factura'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCreateCustomerOption(),
              ValueListenableBuilder<bool>(
                valueListenable: _createCustomerNotifier,
                builder: (context, createCustomer, child) {
                  return createCustomer
                      ? _buildCustomerForm()
                      : const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 16),
              _buildInvoiceCard(),
              const SizedBox(height: 16),
              _buildTransactionSummary(),
              const SizedBox(height: 24),
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
            _buildTransactionRow('Efectivo', cashAmount),
            _buildTransactionRow('Tarjeta', cardAmount),
            _buildTransactionRow('QR', qrAmount),
            _buildTransactionRow('Bono', voucherAmount),
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

  Widget _buildCreateCustomerOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Desea Crear Cliente',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 10),
        Row(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _createCustomerNotifier,
              builder: (context, createCustomer, child) {
                return Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: createCustomer,
                      onChanged: (val) => _createCustomerNotifier.value = val!,
                    ),
                    const Text("Sí"),
                    Radio<bool>(
                      value: false,
                      groupValue: createCustomer,
                      onChanged: (val) => _createCustomerNotifier.value = val!,
                    ),
                    const Text("No"),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Número de Teléfono',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
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
                    DropdownMenuItem(value: "Natural", child: Text("Natural")),
                    DropdownMenuItem(
                      value: "Jurídica",
                      child: Text("Jurídica"),
                    ),
                  ],
                  onChanged: (value) => _selectedPersonType.value = value!,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(context) {
    final InvoiceService invoiceService =
        InvoiceService(); // Instancia del servicio

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final pdf = await invoiceService.generateInvoice(
                products,
                cashAmount,
                cashAmount == 0 ? 'Efectivo' : "tarjeta",
                cashAmount,
                changeAmount,
              ); // Generar PDF
              await Printing.layoutPdf(
                onLayout:
                    (format) async => pdf.save(), // Mostrar vista de impresión
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
