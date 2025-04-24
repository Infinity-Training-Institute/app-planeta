import 'package:app_planeta/presentation/components/invoce_details.dart';
import 'package:app_planeta/presentation/components/summary_invoice_component.dart';
import 'package:app_planeta/services/add_new_product.dart';
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
  final TextEditingController _authNumberCard = TextEditingController();
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
    _authNumberCard.dispose();
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
    int totalAmount = int.tryParse(_amountController.text) ?? 0;

    if (['Efectivo'].contains(_selectedPaymentMethod)) {
      int enteredAmount = int.tryParse(_amountMoneyController.text) ?? 0;

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

    if (["Tarjeta"].contains(_selectedPaymentMethod)) {
      if (_selectedCardType == "Maestro" || _selectedCardType!.isEmpty) {
        showAlert(
          context,
          "Error",
          "Debes escoger un tipo de tarjeta para continuar",
        );
        return;
      }

      if (_authNumberCard.text.isEmpty) {
        showAlert(
          context,
          "Error",
          "El numero de autorizacion no puede estar vacio",
        );
        return;
      }

      // navegamos a la pantalla
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => InvoiceScreen(
                invoiceValue: totalAmount,
                cashAmount: 0,
                cardAmount: totalAmount,
                qrAmount: 0,
                voucherAmount: 0,
                changeAmount: 0,
                products: widget.productsData,
              ),
        ),
      );
    }

    // qr banco
    if (["QR Banco"].contains(_selectedPaymentMethod)) {
      if (_phoneNumberController.text.isEmpty) {
        showAlert(context, "Error", "Numero de telefono no debe estar vacio");
        return;
      }

      if (_phoneNumberController.text.length < 10) {
        showAlert(context, "Warning", "Numero de telefono invalido");
        return;
      }

      if (_authNumberController.text.isEmpty) {
        showAlert(
          context,
          "Error",
          "Numero de autorizacion no debe estar vacio",
        );
        return;
      }

      // navegamos a la pantalla
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => InvoiceScreen(
                invoiceValue: totalAmount,
                cashAmount: 0,
                cardAmount: 0,
                qrAmount: totalAmount,
                voucherAmount: 0,
                changeAmount: 0,
                products: widget.productsData,
              ),
        ),
      );
    }

    // select type bono
    if (["Bono"].contains(_selectedPaymentMethod)) {
      if (_bonoValueController.text.isEmpty) {
        showAlert(context, "Error", "El valor del bono no debe estar vacio");
        return;
      }

      if (_bonoQuantityController.text.isEmpty) {
        showAlert(context, "Error", "La cantidad de bonos no debe estar vacio");
        return;
      }

      int bonoValue = int.tryParse(_bonoValueController.text) ?? 0;
      int bonoQuantity = int.tryParse(_bonoQuantityController.text) ?? 0;

      if (bonoValue * bonoQuantity < totalAmount) {
        showAlert(
          context,
          "Error",
          "El valor del bono no es suficiente para cubrir el total",
        );
        return;
      }

      // navegamos a la pantalla
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => InvoiceScreen(
                invoiceValue: totalAmount,
                cashAmount: 0,
                cardAmount: 0,
                qrAmount: 0,
                voucherAmount: bonoValue * bonoQuantity,
                changeAmount: 0,
                products: widget.productsData,
              ),
        ),
      );
    }

    // select type mixto
    if (["Mixto"].contains(_selectedPaymentMethod)) {
      if (_selectedCardType == "Maestro" || _selectedCardType!.isEmpty) {
        showAlert(
          context,
          "Error",
          "Debes escoger un tipo de tarjeta para continuar",
        );
        return;
      }

      if (_authNumberCard.text.isEmpty) {
        showAlert(
          context,
          "Error",
          "El numero de autorizacion no puede estar vacio",
        );
        return;
      }
      
      if (_phoneNumberController.text.isEmpty) {
        showAlert(context, "Error", "Numero de telefono no debe estar vacio");
        return;
      }

      if (_phoneNumberController.text.length < 10) {
        showAlert(context, "Warning", "Numero de telefono invalido");
        return;
      }

      if (_authNumberController.text.isEmpty) {
        showAlert(
          context,
          "Error",
          "Numero de autorizacion no debe estar vacio",
        );
        return;
      }

      if (_bonoValueController.text.isEmpty) {
        showAlert(context, "Error", "El valor del bono no debe estar vacio");
        return;
      }

      if (_bonoQuantityController.text.isEmpty) {
        showAlert(context, "Error", "La cantidad de bonos no debe estar vacio");
        return;
      }

      // TODO: terminar la logica de pago mixto

    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Método de Pago'),
      content: SingleChildScrollView(
        // Add SingleChildScrollView here
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
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

            // selectedPaymentMethod == Efectivo
            if (_selectedPaymentMethod == "Efectivo" ||
                _selectedPaymentMethod == "Mixto") ...[
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

            // selectedmethod == tarjeta
            if (_selectedPaymentMethod == "Tarjeta" ||
                _selectedPaymentMethod == "Mixto") ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCardType,
                items:
                    [
                          "Maestro",
                          "Visa",
                          "MasterCard",
                          "American Express",
                          "Diners Club",
                          "Colsubsidio",
                          "Visa Electron",
                          "Nequi",
                          "Daviplata",
                        ]
                        .map(
                          (method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCardType = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Tipo de tarjeta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _authNumberCard,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Numero De Autorización',
                  prefixIcon: Icon(Icons.done),
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            // selected type qr banco
            if (_selectedPaymentMethod == "QR Banco" ||
                _selectedPaymentMethod == "Mixto") ...[
              const SizedBox(height: 16),
              TextField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Numero de celular',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _authNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Numero De Autorización',
                  prefixIcon: Icon(Icons.done),
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            // selected type bono
            if (_selectedPaymentMethod == "Bono" ||
                _selectedPaymentMethod == "Mixto") ...[
              const SizedBox(height: 16),
              TextField(
                controller: _bonoValueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor Del Bono',
                  prefixIcon: Icon(Icons.check),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bonoQuantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad del bono',
                  prefixIcon: Icon(Icons.production_quantity_limits),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
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

void showAddProductDialog(
  BuildContext context,
  TextEditingController referenceController,
) {
  final barcodeController = TextEditingController();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final referenciaController = TextEditingController(text: "9999999");

  final productService = AddNewProductService();

  showDialog(
    context: context,
    builder: (BuildContext context) {
      // Calcula el padding inferior según el teclado
      final bottomInset = MediaQuery.of(context).viewInsets.bottom;

      return AlertDialog(
        scrollable: true, // hace scroll si el contenido sobrepasa
        title: Text('Agregar Producto'),
        content: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Referencia',
                  border: OutlineInputBorder(),
                ),
                controller: referenciaController,
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final referencia = referenciaController.text.trim();
              final ean = barcodeController.text.trim();
              final nombreLibro = nameController.text.trim();
              final precioText = priceController.text.trim();

              if (ean.isEmpty || nombreLibro.isEmpty || precioText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Por favor complete todos los campos'),
                  ),
                );
                return;
              }

              final precio = double.tryParse(precioText);
              if (precio == null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Precio inválido')));
                return;
              }

              await productService.addProduct(
                referencia: referencia,
                ean: ean,
                nombreLibro: nombreLibro,
                precio: precio,
              );

              referenceController.text = ean;

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Producto agregado correctamente')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Agregar', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}
