import 'package:flutter/material.dart';

class PaymentModal extends StatefulWidget {
  final double total;

  const PaymentModal({super.key, required this.total});

  @override
  PaymentModalState createState() => PaymentModalState();
}

class PaymentModalState extends State<PaymentModal> {
  String _selectedPaymentMethod = 'Efectivo';
  String? _selectedCardType;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _authNumberController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _voucherValueController = TextEditingController();
  final TextEditingController _voucherCountController = TextEditingController();
  final TextEditingController _bonoValueController = TextEditingController();
  final TextEditingController _bonoQuantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.total.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _authNumberController.dispose();
    _phoneNumberController.dispose();
    _voucherValueController.dispose();
    _voucherCountController.dispose();
    _bonoValueController.dispose();
    _bonoQuantityController.dispose();
    super.dispose();
  }

  void _calculateRedemption() {
    double bonoValue = double.tryParse(_bonoValueController.text) ?? 0.0;
    int bonoQuantity = int.tryParse(_bonoQuantityController.text) ?? 0;
    double redimido = bonoValue * bonoQuantity;
    if (redimido > widget.total) {
      redimido = widget.total;
    }
    setState(() {
      _amountController.text = redimido.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              'Seleccionar Método de Pago',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
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
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ),
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
            if (_selectedPaymentMethod == 'Tarjeta' ||
                _selectedPaymentMethod == 'Mixto') ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCardType,
                items:
                    ['Maestro', 'Visa', 'Master', 'American Express', 'Diners']
                        .map(
                          (cardType) => DropdownMenuItem(
                            value: cardType,
                            child: Text(cardType),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCardType = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Tipo de Tarjeta',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: _authNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de Autorización',
                  prefixIcon: Icon(Icons.confirmation_number),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            // metodo qr
            if (_selectedPaymentMethod == 'QR Banco' ||
                _selectedPaymentMethod == 'Mixto') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Número de Celular',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
            // pago bono
            if (_selectedPaymentMethod == 'Bono' ||
                _selectedPaymentMethod == 'Mixto') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _bonoValueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor Bono(s)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _calculateRedemption(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bonoQuantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de Bono(s)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _calculateRedemption(),
              ),
            ],

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    double amount =
                        double.tryParse(_amountController.text) ?? 0.0;
                    Map<String, dynamic> paymentData = {
                      'monto': amount,
                      'metodo': _selectedPaymentMethod,
                    };
                    Navigator.pop(context, paymentData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Función para mostrar el modal
Future<void> showPaymentModal(BuildContext context, double total) async {
  final result = await showDialog(
    context: context,
    builder: (context) => PaymentModal(total: total),
  );

  if (result != null) {
    print('Método de pago: ${result['metodo']}');
    print('Monto: ${result['monto']}');
    if (result['metodo'] == 'Tarjeta') {
      print('Tipo de Tarjeta: ${result['tipoTarjeta']}');
      print('Número de Autorización: ${result['autorizacion']}');
    } else if (result['metodo'] == 'QR Banco') {
      print('Número de Celular: ${result['numeroCelular']}');
    } else if (result['metodo'] == 'Bono') {
      print('Valor de Bono: ${result['valorBono']}');
      print('Cantidad de Bonos: ${result['cantidadBonos']}');
      print('Total Redimido: ${result['totalRedimido']}');
    }
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
