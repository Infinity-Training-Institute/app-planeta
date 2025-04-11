import 'package:app_planeta/presentation/components/invoce_details.dart';
import 'package:app_planeta/presentation/components/summary_invoice_component.dart';
import 'package:app_planeta/utils/alert_utils.dart';
import 'package:flutter/material.dart';

class PaymentModal extends StatefulWidget {
  final int total;
  final List<Product> productsData;

  const PaymentModal({
    super.key,
    required this.total,
    required this.productsData,
  });

  @override
  PaymentModalState createState() => PaymentModalState();
}

class PaymentModalState extends State<PaymentModal> {
  String _selectedPaymentMethod = 'Efectivo';
  String? _selectedCardType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _amountMoneyController = TextEditingController();
  final TextEditingController _authNumberController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _voucherValueController = TextEditingController();
  final TextEditingController _voucherCountController = TextEditingController();
  final TextEditingController _bonoValueController = TextEditingController();
  final TextEditingController _bonoQuantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.total.toInt().toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _authNumberController.dispose();
    _amountMoneyController.dispose();
    _phoneNumberController.dispose();
    _voucherValueController.dispose();
    _voucherCountController.dispose();
    _bonoValueController.dispose();
    _bonoQuantityController.dispose();
    super.dispose();
  }

  void _payment(BuildContext context) async {
    if (['Efectivo', 'Mixto'].contains(_selectedPaymentMethod) ||
        _selectedCardType == 'Mixto') {
      int enteredAmount = int.tryParse(_amountMoneyController.text) ?? 0;
      int totalAmount = int.tryParse(_amountController.text) ?? 0;

      if (enteredAmount < totalAmount) {
        showAlert(
          context,
          'Error',
          'La cantidad ingresada es menor al monto total',
        );
        return;
      }

      int changeAmount =
          enteredAmount > totalAmount ? enteredAmount - totalAmount : 0;

      // Navegar a la pantalla de InvoiceSummary con el cambio calculado
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => InvoiceScreen(
                invoiceValue: totalAmount,
                cashAmount:
                    _selectedPaymentMethod == 'Efectivo' ? enteredAmount : 0,
                cardAmount:
                    _selectedPaymentMethod == 'Mixto'
                        ? totalAmount - enteredAmount
                        : 0,
                qrAmount: 0,
                voucherAmount: 0,
                changeAmount: changeAmount,
                products: widget.productsData,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Método de Pago'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Total a Pagar',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            items:
                ['Efectivo', 'Tarjeta', 'QR Banco', 'Bono', 'Mixto']
                    .map(
                      (method) =>
                          DropdownMenuItem(value: method, child: Text(method)),
                    )
                    .toList(),
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
                _selectedCardType = null;
              });
            },
            decoration: const InputDecoration(
              labelText: 'Método de Pago',
              border: OutlineInputBorder(),
            ),
          ),
          if (_selectedPaymentMethod == 'Efectivo') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _amountMoneyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total a Pagar',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => _payment(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

// modal para añadir de productos
void showAddProductDialog(BuildContext context) {
  TextEditingController barcodeController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController priceController = TextEditingController();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Agregar Producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Referencia',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: "9999999"),
            ),
            SizedBox(height: 12),
            TextField(
              controller: barcodeController,
              decoration: InputDecoration(
                labelText: 'Código de Barras (EAN)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nombre del Libro',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Precio de Venta',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Aquí puedes manejar la lógica para agregar el producto
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}
