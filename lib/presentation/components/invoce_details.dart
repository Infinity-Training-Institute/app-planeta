import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/presentation/components/ean_scanner_component.dart';
import 'package:app_planeta/presentation/components/modal_component.dart';
import 'package:app_planeta/services/promocion_cantidad_services.dart';
import 'package:app_planeta/services/ref_libro_services.dart';
import 'package:flutter/material.dart';
import 'package:app_planeta/utils/alert_utils.dart';
import 'package:app_planeta/utils/currency_formatter.dart';

class Product {
  final dynamic reference;
  final dynamic description;
  double price;
  double fairPrice;
  final String quantity;
  double total;
  final String? tipo;
  final int? porcentajeDescuento;

  Product({
    required this.reference,
    required this.description,
    required this.price,
    required this.fairPrice,
    required this.quantity,
    required this.total,
    this.tipo,
    this.porcentajeDescuento,
  });

  // Agregamos el método copyWith para actualizar solo un campo sin reescribir todo
  Product copyWith({
    dynamic reference,
    dynamic description,
    double? price,
    double? fairPrice,
    String? quantity,
    double? total,
    String? tipo,
  }) {
    return Product(
      reference: reference ?? this.reference,
      description: description ?? this.description,
      price: price ?? this.price,
      fairPrice: fairPrice ?? this.fairPrice,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
      tipo: tipo ?? this.tipo,
      porcentajeDescuento: porcentajeDescuento ?? porcentajeDescuento,
    );
  }

  // Método clone para duplicar productos
  factory Product.clone(Product original) {
    return Product(
      reference: original.reference,
      description: original.description,
      price: original.price,
      fairPrice: original.fairPrice,
      quantity: original.quantity,
      total: original.total,
      tipo: original.tipo,
      porcentajeDescuento: original.porcentajeDescuento ?? 0,
    );
  }
}

class InvoceDetails extends StatefulWidget {
  final VoidCallback onSync;
  final int invoiceDiscount; // Nuevo parámetro opcional

  const InvoceDetails({
    super.key,
    required this.onSync,
    this.invoiceDiscount = 0, // Valor por defecto si no se envía
  });

  @override
  State<InvoceDetails> createState() => _InvoceDetails();
}

class _InvoceDetails extends State<InvoceDetails> {
  List<Product> products = [];
  List<Map<String, dynamic>> usuarios = [];
  late int invoiceDiscount;

  // variables de la tabla
  int numRows = 0;
  int idRows = 0;
  dynamic totalFinal = 0;
  int numPromos = 0;
  int porcDescuento = 0;
  List<Map<String, dynamic>> promocionesCantidad = [];

  // variables de la referecia y cantidad
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: "1",
  );

  final FocusNode _referenceFocusNode = FocusNode();
  bool isLoading = true;

  // cabecera de la tabla
  List<String> headers = [
    'Referencia',
    'Descripción',
    'P.V.P',
    'P.V.P Feria',
    'Cantidad',
    'P.V.P Total',
    'Borrar',
  ];

  List<DataColumn> columns = [];
  final RefLibroServices _refLibroServices = RefLibroServices();

  // funciones
  void _scanEAN13() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EanScannerComponent()),
    );

    if (result != null && result is String) {
      setState(() {
        _referenceController.text = result;
      });
    }
  }

  // funcion para pushear los libros
  void _buildRow(dynamic config, dynamic data) {
    idRows++;

    String reference = _referenceController.text.trim();
    String quantityText = _quantityController.text.trim();

    String tipoProducto = data["Tipo"] ?? "S";

    int cantidad =
        (tipoProducto == 'D' || tipoProducto == 'T' || tipoProducto == 'Y')
            ? 1
            : int.tryParse(quantityText) ?? 1;

    double precio = double.tryParse(data['Precio'].toString()) ?? 0.0;
    double totalCalculado = precio * cantidad;

    final nuevoProducto = Product(
      reference: reference,
      description: data['Desc_Referencia'],
      price: precio,
      fairPrice: precio,
      quantity: cantidad.toString(),
      total: totalCalculado,
      tipo: tipoProducto,
      porcentajeDescuento: data['Descuento_Especial'],
    );

    setState(() {
      if (tipoProducto == 'T') {
        products.add(nuevoProducto);
      } else {
        int countT = products.where((p) => p.tipo == 'T').length;
        int insertIndex = 2 - countT;
        if (insertIndex < 0) insertIndex = 0;

        int actualIndex = 0;
        int noTipoTCount = 0;

        while (actualIndex < products.length && noTipoTCount < insertIndex) {
          if (products[actualIndex].tipo != 'T') {
            noTipoTCount++;
          }
          actualIndex++;
        }

        products.insert(actualIndex, nuevoProducto);
      }

      totalFinal = products.fold<int>(
        0,
        (sum, item) => sum + (item.total > 0 ? item.total.toInt() : 0),
      );

      calcularPromociones();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _referenceController.text = "";
      _quantityController.text = "1";
    });
  }

  void calcularPromociones() async {
    // 1. Traer promociones (aquí solo usamos si está vacía)
    final promocionesCantidad =
        await PromocionCantidadService().fetchPromocionCantidad();

    // 2. Filtrar sólo productos tipo T
    final List<Product> tipoT = products.where((p) => p.tipo == 'T').toList();
    final List<Product> tipoN = products.where((p) => p.tipo == 'N').toList();

    // TIPO N
    for (final n in tipoN) {
      final qty = int.tryParse(n.quantity) ?? 1;
      final descuentoEspecial = n.porcentajeDescuento ?? 0;

      if (descuentoEspecial > 0) {
        final descuento = n.price * (1 - (descuentoEspecial / 100));
        n.fairPrice = descuento;
        n.total = descuento * qty;
      } else {
        n.fairPrice = n.price;
        n.total = n.price * qty;
      }
    }

    // 3. Si no hay promociones generales, arrancamos nuestras reglas
    if (promocionesCantidad.isEmpty) {
      invoiceDiscount = 0;

      // 3.1 Reiniciar fairPrice y total a sus valores originales
      for (var p in products) {
        p.fairPrice = p.price;
        p.total = p.price * (int.tryParse(p.quantity) ?? 1);
      }

      // 3.2 Agrupar por referencia
      final Map<String, List<Product>> gruposPorRef = {};
      for (var p in tipoT) {
        gruposPorRef.putIfAbsent(p.reference, () => []).add(p);
      }

      bool promoAplicada = false;

      // 3.3 Buscar un grupo de ≥ 3 misma referencia
      for (var entry in gruposPorRef.entries) {
        final lista = entry.value;
        if (lista.length >= 3) {
          // cuantos freebies toca: floor(length/3)
          final int freebies = lista.length ~/ 3;
          // otorgar a los últimos freebies items
          for (int i = 0; i < freebies; i++) {
            final int index = lista.length - 1 - i;
            lista[index].fairPrice = 0;
            lista[index].total = 0;
          }
          promoAplicada = true;
          break;
        }
      }

      // 3.4 Si no aplicamos promo por referencia, pero hay ≥ 3 tipoT de referencias distintas
      if (!promoAplicada && tipoT.length >= 3) {
        final int freebies = tipoT.length ~/ 3;
        tipoT.sort((a, b) => a.price.compareTo(b.price));
        // otorgar a los freebies más baratos
        for (int i = 0; i < freebies; i++) {
          final freeItem = tipoT[i];
          freeItem.fairPrice = 0;
          freeItem.total = 0;
        }
      }

      // 3.5 Reordenar para que los gratis queden al final (opcional)
      products.sort((a, b) {
        if (a.fairPrice == 0 && b.fairPrice != 0) return 1;
        if (a.fairPrice != 0 && b.fairPrice == 0) return -1;
        return 0;
      });

      setState(() {});
      return;
    }

    // Si hay promociones generales (en tu servicio), las manejarías aquí...
    setState(() {});

    // limpiamos el products actual y le damos el modificado

  }

  // funcion para cancelar un factura
  void _clearProducts() {
    setState(() {
      products.clear();
    });
  }

  // funcion para mostrar los metodos de pago disponibles
  void _showPaymentModal(BuildContext context, int total) {
    if (products.isEmpty) {
      showAlert(context, "Warning", "No ha agregado ningún producto");
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PaymentModal(
        total: total,
        productsData: products, // Pasar la lista de productos
      ),
    );
  }

  // funcion para añadir un producto nuevo
  void _addProduct(BuildContext context) async {
    final refText = _referenceController.text.trim();
    final quantityText = _quantityController.text.trim();

    if (refText.isEmpty || quantityText.isEmpty) {
      showAlert(context, "warning", "Por favor, llene todos los datos.");
      return;
    }

    int? quantity = int.tryParse(quantityText);
    if (quantity == null || quantity <= 0) {
      showAlert(
        context,
        "warning",
        "El número de libros debe ser mayor a cero",
      );
      return;
    }

    if (quantity >= 978) {
      _quantityController.text = "1";
      quantity = 1;
    }

    try {
      final productData = await _refLibroServices.fetchProduct(refText);

      if (productData == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró la referencia de este producto.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!context.mounted) return;

      final config = {
        "cantidad": quantity.toString(),
        "porc_desc": porcDescuento
      };

      final tipo = productData['Tipo'];
      final int repetitions =
          (tipo == 'D' || tipo == 'T' || tipo == 'Y') ? quantity : 1;

      for (int i = 0; i < repetitions; i++) {
        _buildRow(config, productData);
      }
    } catch (e) {
      print(e);
      if (context.mounted) {
        showAlert(
          context,
          "Error",
          "Error al obtener el producto. Intente de nuevo.",
        );
      }
    }
  }

  // cargamos el usuario localmente
  Future<void> _cargarUsuarios() async {
    debugPrint("Cargando usuarios...");

    final data = await AppDatabase.getUsuarios();

    setState(() {
      usuarios = data;
      isLoading = false;
    });
  }

  // obtenemos el color del fondo segun el tipo
  Color _getColorByTipo(String tipo) {
    switch (tipo) {
      case "D":
        return const Color(0xFF85CDE8); // Azul - Descuento (50%)
      case "T":
        return const Color(0xFFFFB100); // Ámbar - Promoción 3 X 2
      case "N":
        return const Color(0xFF81E579); // Verde - Productos especiales
      case "Y":
        return const Color(0xFFD4C9C9); // Gris - Promoción 2 X 1
      default:
        return Colors.white; // Blanco - Sin tipo definido
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
    invoiceDiscount = widget.invoiceDiscount;
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<DataColumn> columns = headers.map((header) {
      return DataColumn(
        label: Text(header, style: TextStyle(fontWeight: FontWeight.bold)),
        numeric: [
          'P.V.P',
          'P.V.P Feria',
          'Cantidad',
          'P.V.P Total',
        ].contains(header),
      );
    }).toList();

    if (usuarios.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ), // Muestra un cargador si no hay usuarios
      );
    }

    // obtenemos la factura interna del usuario y le sumamos 1
    int invoiceNumber = usuarios[0]['Factura_Alterna_Usuario'] + 1;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard("Factura Actual",
                          invoiceNumber.toString(), Icons.receipt, Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoCard(
                          "Descuento En Factura",
                          invoiceDiscount.toString(),
                          Icons.discount,
                          Colors.orange),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // un cuadro que ocupe todo el ancho para la leyenda
                _buildLegendCard3(),
                const SizedBox(height: 8),

                // card with invoice entry
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Entrada de Factura",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      // table products
                      Column(
                        children: [
                          Container(
                              padding: const EdgeInsets.all(8),
                              child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: 150,
                                        maxHeight: (products.length * 50)
                                            .toDouble()
                                            .clamp(300.0, 400.0),
                                      ),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.vertical,
                                        child: DataTable(
                                          headingRowColor:
                                              WidgetStateProperty.all(
                                            Colors.grey.shade100,
                                          ),
                                          dataRowMinHeight: 45,
                                          dataRowMaxHeight: 64,
                                          columnSpacing: 16,
                                          columns: columns,
                                          rows: [
                                            if (products.isEmpty)
                                              DataRow(
                                                cells: [
                                                  DataCell(
                                                    Center(
                                                      child: Text(
                                                        'No hay productos registrados',
                                                        style: TextStyle(
                                                          color: Colors.blue,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  ...List.generate(
                                                    6,
                                                    (index) => const DataCell(
                                                        SizedBox()),
                                                  ),
                                                ],
                                              ),
                                            ...products.map((product) {
                                              return DataRow(
                                                color: WidgetStateProperty
                                                    .resolveWith<Color?>(
                                                        (Set<WidgetState>
                                                            states) {
                                                  return _getColorByTipo(
                                                    product.tipo ?? '',
                                                  );
                                                }),
                                                cells: [
                                                  DataCell(
                                                      Text(product.reference)),
                                                  DataCell(Text(
                                                      product.description)),
                                                  DataCell(
                                                    Text(
                                                      CurrencyFormatter
                                                          .formatCOP(
                                                        product.price,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    Text(
                                                      CurrencyFormatter
                                                          .formatCOP(
                                                        product.fairPrice,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                      Text(product.quantity)),
                                                  DataCell(
                                                    Text(
                                                      CurrencyFormatter
                                                          .formatCOP(
                                                        product.total,
                                                      ),
                                                    ),
                                                  ),
                                                  DataCell(
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          products
                                                              .remove(product);
                                                          calcularPromociones(); // <- Aquí actualizas la promo después de eliminar
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }),
                                            // Footer Row
                                            // Footer Row
                                            DataRow(
                                              color: WidgetStateProperty.all(
                                                Colors.yellow.shade100,
                                              ),
                                              cells: [
                                                DataCell(
                                                  Text(
                                                    "Total Factura",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                ...List.generate(
                                                  3, // Ahora generamos solo 3 celdas vacías en lugar de 4
                                                  (index) => const DataCell(
                                                      SizedBox()),
                                                ),
                                                DataCell(
                                                  Text(
                                                    products
                                                        .fold<int>(
                                                          0,
                                                          (sum, item) =>
                                                              sum +
                                                              (int.tryParse(
                                                                    item.quantity,
                                                                  ) ??
                                                                  0),
                                                        )
                                                        .toString(),
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    CurrencyFormatter.formatCOP(
                                                      products.fold<num>(
                                                        0,
                                                        (sum, item) =>
                                                            sum + item.total,
                                                      ),
                                                    ),
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const DataCell(
                                                  SizedBox(),
                                                ), // Celda vacía en "Borrar"
                                              ],
                                            ),
                                          ],
                                        ),
                                      ))))
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // input form (reference and quantity)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Agregar Producto",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _referenceController,
                            focusNode: _referenceFocusNode,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Referencia',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ), // Espacio entre los campos

                          TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ), // Espacio entre el campo y el botón

                          Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => _addProduct(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF4CAF50),
                                    side: const BorderSide(
                                      color: Color(0xFF4CAF50),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text("Grabar"),
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ), // Espacio entre botones
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _showPaymentModal(
                                    context,
                                    totalFinal,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text("Facturar"),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => showAddProductDialog(
                                          context, _referenceController),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text("Crea Producto"),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _clearProducts(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text("Cancela Factura"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'eanReader',
            onPressed: _scanEAN13, // Enfoca el TextField para escanear
            shape: const CircleBorder(),
            tooltip: 'Leer EAN-13',
            child: const Icon(Icons.qr_code),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'syncButton',
            onPressed: widget.onSync,
            shape: const CircleBorder(),
            tooltip: 'Sincronizar',
            child: const Icon(Icons.sync),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (isFullWidth)
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 2), // Espacio mínimo
          Text(text, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildLegendCard3() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Leyenda",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildLegendItem(Colors.white, 'Libro Normal'),
                const SizedBox(width: 16),
                _buildLegendItem(
                  const Color(0xFF85CDE8),
                  'Segundo libro con 50%',
                ),
                const SizedBox(width: 16),
                _buildLegendItem(
                  const Color(0xFFFFB100),
                  'Libro Promoción 3 X 2',
                ),
                const SizedBox(width: 16),
                _buildLegendItem(
                  const Color(0xFF81E579),
                  'Libro Productos especiales',
                ),
                const SizedBox(width: 16),
                _buildLegendItem(
                  const Color(0xFFD4C9C9),
                  'Libro Promocion 2 X 1',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
