import 'dart:convert';
import 'dart:developer';

import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/infrastructure/local_db/models/products_model.dart';
import 'package:app_planeta/services/ref_libro_services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Product {
  final String reference;
  final String description;
  final double price;
  final double fairPrice;
  final int quantity;
  final double discount;

  Product({
    required this.reference,
    required this.description,
    required this.price,
    required this.fairPrice,
    required this.quantity,
    required this.discount,
  });

  double get total => price * quantity * (1 - discount / 100);
}

class InvoceDetails extends StatefulWidget {
  final VoidCallback onSync; // Función que se pasará como parámetro

  const InvoceDetails({super.key, required this.onSync});

  @override
  State<InvoceDetails> createState() => _InvoceDetails();
}

class _InvoceDetails extends State<InvoceDetails> {
  final List<ProductsModel> _products = [];
  List<Map<String, dynamic>> usuarios = [];
  int giftedBooks = 0;
  double invoiceDiscount = 0.0;

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

    print("Gifted Books: $giftedBooks");
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

  void _showAlert(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }

  final RefLibroServices _refLibroService =
      RefLibroServices(); // Instancia del servicio

  void _addProduct(BuildContext context) async {
    if (_referenceController.text.isEmpty || _quantityController.text.isEmpty) {
      _showAlert(context, "Por favor, llene todos los datos.");
      return;
    }

    int? quantity = int.tryParse(_quantityController.text);

    if (quantity == null || quantity <= 0) {
      _showAlert(context, "El número de libros debe ser mayor a cero");
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
      String productosJson = jsonEncode(productos);

      // TODO: DALE PRIORIDAD AL TEMA DE FACTURACION

      calcularPromociones(productos, context);
      print(productData);
    } catch (e) {
      print('Error fetching product: $e');
      if (context.mounted) {
        _showAlert(context, "Error al obtener el producto. Intente de nuevo.");
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

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInfoCard(
                            "Factura Actual",
                            "$invoiceNumber",
                            Icons.receipt,
                            Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoCard(
                            "Descuento en Factura",
                            "$invoiceDiscount%",
                            Icons.discount,
                            Colors.orange,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoCard(
                            "Libros Obsequiados",
                            "$giftedBooks",
                            Icons.book,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

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
                      Container(
                        height: 300,
                        padding: const EdgeInsets.all(8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(
                              Colors.grey.shade100,
                            ),
                            dataRowMinHeight: 48,
                            dataRowMaxHeight: 64,
                            columnSpacing: 16,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  'Referencia',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Descripción',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'P.V.P',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Text(
                                  'P.V.P Feria',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Text(
                                  'Cantidad',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Text(
                                  'P.V.P Total',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                numeric: true,
                              ),
                              DataColumn(
                                label: Text(
                                  'Borrar',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows:
                                _products.isEmpty
                                    ? [
                                      DataRow(
                                        cells: [
                                          const DataCell(
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
                                    ]
                                    : [
                                      ..._products.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final product = entry.value;
                                        return DataRow(
                                          color:
                                              MaterialStateProperty.resolveWith<
                                                Color?
                                              >((Set<MaterialState> states) {
                                                return index % 2 == 0
                                                    ? Colors.grey.shade50
                                                    : null;
                                              }),
                                          cells: [
                                            DataCell(Text(product.referencia)),
                                            DataCell(
                                              Text(product.descReferencia),
                                            ),
                                            DataCell(
                                              Text(
                                                '${product.precio.toStringAsFixed(2)}',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                '${product.precio.toStringAsFixed(2)}',
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),

                                      // Total row
                                      DataRow(
                                        color: MaterialStateProperty.all(
                                          Colors.yellow.shade100,
                                        ),
                                        cells: [
                                          const DataCell(SizedBox()),
                                          const DataCell(SizedBox()),
                                          const DataCell(SizedBox()),
                                          const DataCell(SizedBox()),
                                          const DataCell(
                                            Text(
                                              'Total Factura',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                              textAlign: TextAlign.right,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '1',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                          const DataCell(SizedBox()),
                                        ],
                                      ),
                                    ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                //legend
                Container(
                  padding: const EdgeInsets.all(12),
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
                        "Leyenda",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildLegendItem(Colors.white, 'Libro Normal'),
                          _buildLegendItem(
                            Colors.blue.shade200,
                            'Libro Promoción 2 X 1',
                          ),
                          _buildLegendItem(
                            Colors.amber.shade200,
                            'Libro Promoción 3 X 2',
                          ),
                          _buildLegendItem(
                            Colors.green.shade200,
                            'Libro Productos especiales',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

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

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _addProduct(context);
                              },
                              icon: const Icon(Icons.save),
                              label: const Text('GRABAR'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
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
        child: const Icon(Icons.sync),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 146),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
