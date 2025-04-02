import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/presentation/components/modal_component.dart';
import 'package:app_planeta/services/ref_libro_services.dart';
import 'package:flutter/material.dart';
import 'package:app_planeta/utils/alert_utils.dart';
import 'package:app_planeta/utils/currency_formatter.dart';

class Product {
  final dynamic reference;
  final dynamic description;
  final double price;
  final double fairPrice;
  final String quantity;
  final double total;
  final String? tipo; // Variable opcional

  Product({
    required this.reference,
    required this.description,
    required this.price,
    required this.fairPrice,
    required this.quantity,
    required this.total,
    this.tipo, // Parámetro opcional
  });
}

class InvoceDetails extends StatefulWidget {
  final VoidCallback onSync;
  final double invoiceDiscount; // Nuevo parámetro opcional

  const InvoceDetails({
    super.key,
    required this.onSync,
    this.invoiceDiscount = 0.0, // Valor por defecto si no se envía
  });

  @override
  State<InvoceDetails> createState() => _InvoceDetails();
}

class _InvoceDetails extends State<InvoceDetails> {
  final List<Product> _products = [];
  List<Map<String, dynamic>> usuarios = [];
  int giftedBooks = 0;
  late double invoiceDiscount;

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

  int numRows = 0;
  int idRows = 0;
  int totalFinal = 0;
  List<dynamic> productos = [];
  int numPromos = 0;
  int porcDesc = 0;
  List<Map<String, dynamic>> promocionesCantidad = [];

  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: "1",
  );
  final TextEditingController _discountController = TextEditingController(
    text: "0",
  );

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
    invoiceDiscount = widget.invoiceDiscount; // Asignar valor recibido
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _quantityController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  // Función para mostrar información de promociones en la interfaz
  void showPromo(int numPromos, double porcDesc) {
    giftedBooks = numPromos > 0 ? numPromos : giftedBooks;
    invoiceDiscount = porcDesc > 0 ? porcDesc : invoiceDiscount;

    // ignore: avoid_print
    print("Gifted Books: $giftedBooks");
    // ignore: avoid_print
    print("Invoice Discount: $invoiceDiscount%");
  }

  void calcularPromociones(
    List<Map<String, dynamic>> productos,
    BuildContext context,
  ) {
    List<dynamic> n = []; // productos with class "N"
    List<dynamic> s = []; // productos with class "S"
    List<dynamic> d = []; // productos with class "D"
    List<dynamic> t = []; // productos with class "T"
    List<dynamic> y = []; // productos with class "Y"

    // This would be equivalent to getElementsByClassName in JS
    for (int i = 0; i < productos.length; i++) {
      String tipo = productos[i]['Tipo'] ?? '';
      print(tipo);
      if (tipo == 'N') n.add({'id': 'row$i', 'index': i});
      if (tipo == 'S') s.add({'id': 'row$i', 'index': i});
      if (tipo == 'D') d.add({'id': 'row$i', 'index': i});
      if (tipo == 'T') t.add({'id': 'row$i', 'index': i});
      if (tipo == 'Y') y.add({'id': 'row$i', 'index': i});
    }

    print(t);

    List<Map<String, dynamic>> valores = [];
    List<Map<String, dynamic>> val_res = [];
    List<Map<String, dynamic>> valores2 = [];
    List<Map<String, dynamic>> valores3 = [];
    List<Map<String, dynamic>> valores4 = [];
    List<Map<String, dynamic>> valores5 = [];
    List<int> indices = [];

    int num_promos = 0;
    int num_promos_a = 0;
    int num_promos_2 = 0;
    int num_promos_3 = 0;
    int num_promos_2a = 0;
    int cant_t = 0;
    int cant_s = 0;
    int cant_y = 0;
    int cant_d = 0;
    int cant_n = 0;
    int cant_g = 0;

    String getNumber(String str) {
      String number = "";
      while (RegExp(r'\d').hasMatch(str)) {
        int index = str.indexOf(RegExp(r'\d'));
        number += str[index];
        str = str.replaceFirst(RegExp(r'\d'), '\$');
      }
      return number;
    }

    //Suma las cantidades que hay del segundo con el 50 (Azul)
    //todo: aqui va el codigo

    //Todo: aqui va el codigo de y

    //todo: aqui va el codigo de t
    if (t.isNotEmpty) {
      //Suma las cantidades que hay del 3x2 (Naranja)
      for (int i = 0; i < t.length; i++) {
        String idT = t[i]['id'];
        int indice =
            int.tryParse(getNumber(idT)) ??
            0; // Convierte el valor a int de forma segura
        print(indice);
        // Validamos que `indice` esté dentro del rango de `productos`
        if (indice >= 0 && indice < productos.length) {
          valores2.add({
            "indice": indice,
            "precio": productos[indice]['Precio'],
            "cantidad": int.tryParse(_quantityController.text) ?? 0,
          });
          indices.add(indice);
        } else {
          print("Índice fuera de rango: $indice");
        }
      }
      int x = 0;
      while (x < valores2.length) {
        cant_t +=
            (valores2[x]['cantidad'] as num).toInt(); // Convierte num a int
        x++;
      }
      if (t.length >= 3) {
        int libs_prom = 0;
        int multipo = t.length % 3;
        if (multipo == 0) {
          libs_prom = t.length % 3;
        } else {
          libs_prom = t.length ~/ 3;
          int num_libs = (libs_prom * 3);
          int libs_rest = (t.length - num_libs) - 1;
        }
        print("Total de libros de 50% gratis: $libs_prom");
        x = 0;
        while (x < libs_prom) {
          num_promos_a++;
          x++;
        }
      }
    }

    //todo: AQUI VA LA LOGICA DEL S

    //TODO: aqui va la logica del n

    // sumatoria de los libros principales
    cant_g = cant_d + cant_s + cant_y + cant_t + cant_n - num_promos_a * 3;
    int multiplo = 0;
    int libs_prom = 0;

    print("Total de libros de 3*2 gratis: $num_promos_a");
    print("Total de libros para 3x2: ${t.length}");
    print("Total de libros general: $cant_g");

    valores.clear();
    val_res.clear();
    valores2.clear();
    valores3.clear();
    valores4.clear();
    valores5.clear();
    indices.clear();
    int x = 0;

    // valido si hay productos especiales

    // facturacion 3x2 incluyente con cantidad
    if (t.length >= 3) {
      List<Map<String, dynamic>> valRes = [];
      int multipo = t.length % 3;

      //valido para los productos tipo T
      for (int i = 0; i < t.length; i++) {
        String idT = t[i]["id"];
        int indice =
            int.tryParse(getNumber(idT)) ??
            0; // Convierte el valor a int de forma segura
      }
    }
  }

  void _buildRow(dynamic config, dynamic data) {
    idRows++;

    if (idRows < productos.length) {
      productos[idRows] = data;
    } else {
      productos.add(data);
    }

    String reference = _referenceController.text;
    String quantityText = _quantityController.text;

    int cantidad =
        (data['Tipo'] == 'D' || data['Tipo'] == 'T' || data['Tipo'] == 'Y')
            ? 1
            : int.tryParse(quantityText) ?? 1;

    double precio = double.tryParse(data['Precio'].toString()) ?? 0.0;
    double totalCalculado = precio * cantidad;

    setState(() {
      _products.add(
        Product(
          reference: reference,
          description: data['Desc_Referencia'],
          price: precio,
          fairPrice: precio,
          quantity: cantidad.toString(),
          total: totalCalculado,
          tipo: data.containsKey('Tipo') ? data['Tipo'] : null,
        ),
      );
    });

    // 🔹 Limpia los controladores DESPUÉS de actualizar la UI
    Future.delayed(Duration(milliseconds: 100), () {
      _referenceController.clear();
      _quantityController.clear();
    });
  }

  // funcion para cancelar factura
  void _clearProducts() {
    setState(() {
      _products.clear();
    });
  }

  // Obtener el color de fondo según el tipo
  Color _getColorByTipo(String tipo) {
    switch (tipo) {
      case "D":
        return const Color(0xFF85CDE8); // Azul - Libro Promoción 2 X 1
      case "T":
        return const Color(0xFFFFB100); // Ámbar - Libro Promoción 3 X 2
      case "N":
        return const Color(0xFF81E579); // Verde - Libro Productos especiales
      case "Y":
      default:
        return Colors.white; // Blanco - Libro Normal
    }
  }

  final RefLibroServices _refLibroService =
      RefLibroServices(); // Instancia del servicio

  void _addProduct(BuildContext context) async {
    if (_referenceController.text.isEmpty || _quantityController.text.isEmpty) {
      showAlert(context, "warning", "Por favor, llene todos los datos.");
      return;
    }

    int? quantity = int.tryParse(_quantityController.text);

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
    }

    String refLib = _referenceController.text.trim();

    try {
      final Map<String, dynamic> productData = await _refLibroService
          .fetchProduct(refLib);

      if (!context.mounted) return;

      List<Map<String, dynamic>> productos = [productData];

      //TODO: darle prioridad al tema de facturacion

      calcularPromociones(productos, context);
      // ignore: avoid_print
      print(productData);

      if (productData['Tipo'] == 'D' ||
          productData['Tipo'] == 'T' ||
          productData['Tipo'] == 'Y') {
        dynamic config = {
          "cantidad": _quantityController.text,
          "porc_desc": porcDesc,
        };
        int x = 0;
        // ignore: avoid_print
        print(_quantityController);
        while (x < (int.tryParse(_quantityController.text) ?? 0)) {
          _buildRow(config, productData);
          x++;
        }
      } else {
        dynamic config = {
          "cantidad": _quantityController.text,
          "porc_desc": porcDesc,
        };
        _buildRow(config, productData);
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching product: $e');
      if (context.mounted) {
        showAlert(
          context,
          "Error",
          "Error al obtener el producto. Intente de nuevo.",
        );
      }
    }
  }

  Future<void> _cargarUsuarios() async {
    debugPrint("Cargando usuarios...");

    final data = await AppDatabase.getUsuarios();

    setState(() {
      usuarios = data;
      isLoading = false;
    });
  }

  void _showPaymentModal(BuildContext context, double total) {
    if (_products.isEmpty) {
      showAlert(context, "Info", "No ha agregado ningún producto");
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PaymentModal(total: total),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<DataColumn> columns =
        headers.map((header) {
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

    // Obtener la factura interna del primer usuario + 1
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
                      child: _buildInfoCard(
                        "Factura Actual",
                        invoiceNumber.toString(),
                        Icons.receipt,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoCard(
                        "Descuento",
                        "${invoiceDiscount.toString()}%",
                        Icons.discount,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Un cuadro que ocupa todo el ancho con solo la leyenda
                _buildLegendCard3(),

                const SizedBox(height: 8),
                // Main Card with Invoice Entry
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
                      // Card Header
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
                                  maxHeight: (_products.length * 50)
                                      .toDouble()
                                      .clamp(300.0, 400.0),
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      Colors.grey.shade100,
                                    ),
                                    dataRowMinHeight: 45,
                                    dataRowMaxHeight: 64,
                                    columnSpacing: 16,
                                    columns: columns,
                                    rows: [
                                      if (_products.isEmpty)
                                        DataRow(
                                          cells: [
                                            DataCell(
                                              Center(
                                                child: Text(
                                                  'No hay productos registrados',
                                                  style: TextStyle(
                                                    color: Colors.blue,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            ...List.generate(
                                              6,
                                              (index) =>
                                                  const DataCell(SizedBox()),
                                            ),
                                          ],
                                        ),
                                      ..._products.map((product) {
                                        return DataRow(
                                          color:
                                              WidgetStateProperty.resolveWith<
                                                Color?
                                              >((Set<WidgetState> states) {
                                                return _getColorByTipo(
                                                  product.tipo ?? '',
                                                );
                                              }),
                                          cells: [
                                            DataCell(Text(product.reference)),
                                            DataCell(Text(product.description)),
                                            DataCell(
                                              Text(
                                                CurrencyFormatter.formatCOP(
                                                  product.price,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                CurrencyFormatter.formatCOP(
                                                  product.fairPrice,
                                                ),
                                              ),
                                            ),
                                            DataCell(Text(product.quantity)),
                                            DataCell(
                                              Text(
                                                CurrencyFormatter.formatCOP(
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
                                                    _products.remove(product);
                                                    productos.remove(product);
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
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          ...List.generate(
                                            3, // Ahora generamos solo 3 celdas vacías en lugar de 4
                                            (index) =>
                                                const DataCell(SizedBox()),
                                          ),
                                          DataCell(
                                            Text(
                                              _products
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
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              CurrencyFormatter.formatCOP(
                                                _products.fold<num>(
                                                  0,
                                                  (sum, item) =>
                                                      sum + item.total,
                                                ),
                                              ),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
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
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // input form
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
                                  onPressed:
                                      () => _showPaymentModal(context, 2000),
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
                                      onPressed:
                                          () => showAddProductDialog(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
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
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onSync,
        shape:
            const CircleBorder(), // Hace que el botón sea perfectamente redondo
        child: const Icon(Icons.sync),
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
                _buildLegendItem(Color(0xFF85CDE8), 'Libro Promoción 2 X 1'),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
