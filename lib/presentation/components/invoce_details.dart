import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/infrastructure/local_db/models/products_model.dart';
import 'package:flutter/material.dart';

class InvoceDetails extends StatefulWidget {
  final VoidCallback onSync; // Función que se pasará como parámetro

  const InvoceDetails({super.key, required this.onSync});

  @override
  State<InvoceDetails> createState() => _InvoceDetails();
}

class _InvoceDetails extends State<InvoceDetails> {
  final List<ProductsModel> _products = [];
  List<Map<String, dynamic>> usuarios = [];

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
    int giftedBooks = 0;
    double invoiceDiscount = 0.0;

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
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
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
                          ),
                          const SizedBox(
                            width: 16,
                          ), // Space between the two text fields
                          Expanded(
                            child: TextField(
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
