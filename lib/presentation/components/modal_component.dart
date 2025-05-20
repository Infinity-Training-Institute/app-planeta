import 'package:app_planeta/presentation/components/invoce_details.dart';
import 'package:app_planeta/presentation/components/summary_invoice_component.dart';
import 'package:app_planeta/services/add_new_product.dart';
import 'package:app_planeta/utils/alert_utils.dart';
import 'package:flutter/material.dart';

class PaymentModal extends StatefulWidget {
  final int total;
  final List<Product> productsData;
  final String? typeOfInvoice;

  const PaymentModal({
    super.key,
    required this.total,
    required this.productsData,
    this.typeOfInvoice,
  });

  @override
  PaymentModalState createState() => PaymentModalState();
}

class PaymentModalState extends State<PaymentModal> {
  String _selectedPaymentMethod = 'Efectivo';
  String? _selectedCardType;
  String? _selectedCardType2;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _amountMoneyController = TextEditingController();
  final TextEditingController _amountCardController = TextEditingController();
  final TextEditingController _amountQrController = TextEditingController();
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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SummaryInvoiceComponent(
                invoiceValue: totalAmount,
                payments: [
                  PaymentEntry(
                    method: _selectedPaymentMethod,
                    amount: enteredAmount,
                    reference:
                        (_selectedPaymentMethod.contains('Tarjeta') ||
                                _selectedPaymentMethod.contains('QR Banco'))
                            ? _phoneNumberController.text.trim()
                            : _authNumberCard.text.trim(),
                  ),
                ],
                products: widget.productsData,
                changeAmount: changeAmount,
              ),
        ),
      );
    }

    if (['Tarjeta', 'QR Banco'].contains(_selectedPaymentMethod)) {
      String cardType = _selectedCardType ?? '';
      String cardType2 = _selectedCardType2 ?? '';

      if (['Tarjeta'].contains(_selectedPaymentMethod) &&
          cardType.isEmpty &&
          cardType2.isEmpty) {
        showAlert(context, 'Error', 'Seleccione el tipo de tarjeta');
        return;
      }

      if (['QR Banco'].contains(_selectedPaymentMethod) &&
          _phoneNumberController.text.isEmpty) {
        showAlert(context, 'Error', 'Ingrese el número de celular');
        return;
      }

      if (['QR Banco'].contains(_selectedPaymentMethod) &&
              _phoneNumberController.text.length < 10 ||
          _phoneNumberController.text.length > 10) {
        showAlert(
          context,
          'Error',
          'El número de celular debe tener al menos 10 dígitos.',
        );
        return;
      }

      String authNumber = _authNumberCard.text.trim();
      if (['Tarjeta'].contains(_selectedPaymentMethod) && authNumber.isEmpty) {
        showAlert(context, 'Error', 'Ingrese el número de autorización');
        return;
      }

      if (['Tarjeta'].contains(_selectedPaymentMethod) &&
              authNumber.length < 6 ||
          authNumber.length > 6) {
        showAlert(
          context,
          'Error',
          'El número de autorización debe tener al menos 6 caracteres.',
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SummaryInvoiceComponent(
                invoiceValue: totalAmount,
                payments: [
                  PaymentEntry(
                    method: _selectedPaymentMethod,
                    typeCard: _selectedCardType,
                    numberPhone: _phoneNumberController.text,
                    typeCard2: _selectedCardType2,
                    amount: totalAmount,
                    reference: authNumber,
                  ),
                ],
                products: widget.productsData,
                typeInvoice: widget.typeOfInvoice,
              ),
        ),
      );
    }

    if (['Bono'].contains(_selectedPaymentMethod)) {
      int bonoValue = int.tryParse(_bonoValueController.text) ?? 0;
      int bonoCount = int.tryParse(_bonoQuantityController.text) ?? 0;

      if (bonoValue <= 0 || bonoCount <= 0) {
        showAlert(context, 'Error', 'Ingrese el valor y la cantidad del bono');
        return;
      }

      int totalBono = bonoValue * bonoCount;
      if (totalBono < totalAmount) {
        showAlert(
          context,
          'Error',
          'El monto del bono es menor al monto total',
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SummaryInvoiceComponent(
                invoiceValue: totalAmount,
                payments: [
                  PaymentEntry(
                    method: _selectedPaymentMethod,
                    amount: totalAmount,
                    numberBono: bonoCount,
                    totalBono: bonoValue,
                    numberOfBonoUsed: bonoCount,
                    reference: _bonoValueController.text.trim(),
                  ),
                ],
                products: widget.productsData,
                typeInvoice: widget.typeOfInvoice,
              ),
        ),
      );
    }

    if (['Mixto'].contains(_selectedPaymentMethod)) {
      int cashAmount = int.tryParse(_amountMoneyController.text) ?? 0;
      int cardAmount = int.tryParse(_amountCardController.text) ?? 0;
      int qrAmount = int.tryParse(_amountQrController.text) ?? 0;
      int bonoValue = int.tryParse(_bonoValueController.text) ?? 0;
      int bonoCount = int.tryParse(_bonoQuantityController.text) ?? 0;

      if (cashAmount <= 0 && cardAmount <= 0 && bonoValue <= 0) {
        showAlert(context, 'Error', 'Ingrese al menos un método de pago');
        return;
      }

      int totalPago =
          cashAmount + qrAmount + cardAmount + (bonoValue * bonoCount);

      if (totalPago < totalAmount) {
        showAlert(
          context,
          'Error',
          'La suma de los métodos de pago es menor al monto total',
        );
        return;
      }

      if (bonoValue > 0 && bonoCount <= 0) {
        showAlert(context, 'Error', 'Ingrese la cantidad de bonos');
        return;
      }

      if (bonoCount > 0 && bonoValue <= 0) {
        showAlert(context, 'Error', 'Ingrese el valor del bono');
        return;
      }

      List<PaymentEntry> payments = [];

      if (cashAmount > 0) {
        payments.add(PaymentEntry(method: 'Efectivo', amount: cashAmount));
      }

      int cambio = totalPago - totalAmount;

      if (cambio > 0) {
        if (cashAmount < cambio) {
          showAlert(
            context,
            'Error',
            'El cambio es mayor al pago en efectivo. El cambio solo puede darse si el efectivo cubre el excedente.',
          );
          return;
        }
      }

      if (cardAmount > 0) {
        payments.add(
          PaymentEntry(
            method: 'Tarjeta',
            amount: cardAmount,
            typeCard: _selectedCardType,
            reference: _authNumberCard.text.trim(),
          ),
        );
      }

      if (bonoValue > 0) {
        payments.add(
          PaymentEntry(
            method: 'Bono',
            amount: bonoValue,
            numberBono: bonoCount,
            totalBono: bonoValue,
            numberOfBonoUsed: bonoCount,
          ),
        );
      }

      if (qrAmount > 0) {
        payments.add(
          PaymentEntry(
            method: 'QR Banco',
            amount: qrAmount,
            numberPhone: _phoneNumberController.text,
          ),
        );
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SummaryInvoiceComponent(
                invoiceValue: totalAmount,
                payments: payments,
                changeAmount:
                    cashAmount +
                    qrAmount +
                    cardAmount +
                    bonoValue -
                    totalAmount,
                products: widget.productsData,
                typeInvoice: widget.typeOfInvoice,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seleccionar Método de Pago'),
      content: SingleChildScrollView(
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
                  _amountCardController.clear();
                  _amountQrController.clear();
                  _bonoValueController.clear();
                  _bonoQuantityController.clear();
                  _phoneNumberController.clear();
                  _selectedCardType2 = null;
                  _authNumberCard.clear();
                  _amountMoneyController.clear();
                });
              },
              decoration: const InputDecoration(
                labelText: 'Método de Pago',
                border: OutlineInputBorder(),
              ),
            ),

            // Efectivo
            if (_selectedPaymentMethod == 'Efectivo') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _amountMoneyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto Efectivo',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            // tarjeta
            if (_selectedPaymentMethod == 'Tarjeta') ...[
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
              DropdownButtonFormField<String>(
                value: _selectedCardType2,
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
                    _selectedCardType2 = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Tipo de tarjeta 2',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _authNumberCard,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Numero De Autorización',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            //QR Banco
            if (_selectedPaymentMethod == 'QR Banco') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Numero de celular',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            // Bono
            if (_selectedPaymentMethod == 'Bono') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _bonoValueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor del Bono',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bonoQuantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de Bonos',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            // Mixto
            if (_selectedPaymentMethod == 'Mixto') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _amountMoneyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto Efectivo',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountCardController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto Tarjeta',
                  border: OutlineInputBorder(),
                ),
              ),
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
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Numero De Autorización',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bonoValueController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor del Bono',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bonoQuantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de Bonos',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountQrController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto QR',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Numero de celular',
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
