import 'package:app_planeta/infrastructure/local_db/dao/index.dart';
import 'package:app_planeta/presentation/components/invoce_details.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoiceService with ChangeNotifier {
  Future<pw.Document> generateInvoice(
    List<Product> products,
    int total,
    String payMethod,
    int? moneyMethod,
    int diference,
  ) async {
    final pdf = pw.Document();

    // obtenemos los datos necesarios para la factura
    final datosEmpresas = await DatosEmpresaDao().getEmpresas();
    final datosCliente = await DatosClienteDao().getClientes();
    final datosCaja = await DatosCajaDao().getCajas();

    print("datos empresa: ${datosEmpresas.first}");
    print("datos cliente: ${datosCliente.first}");
    print("datos caja: ${datosCaja.first}");

    // tomamos el primer registro si existe
    final empresa = datosEmpresas.isNotEmpty ? datosEmpresas.first : null;
    final caja = datosCaja.isNotEmpty ? datosCaja.first : null;
    final cliente = datosCliente.isNotEmpty ? datosCliente.first : null;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Ancho 58mm, alto dinámico
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // datos empresa si existen
              if (empresa != null) ...[
                pw.Text('Empresa: ${empresa.nombreEmpresa}'),
                pw.Text('NIT: ${empresa.nit}'),
                pw.Text('Dirección: ${empresa.direccion} PBX: 6079997'),
                pw.Text('Direccion Electronica: ${empresa.email}'),
              ],
              pw.SizedBox(height: 10),
              if (caja != null) ...[
                pw.Text(
                  'FACTURA ELECTRÓNICA DE VENTA ${caja.numeroCaja}-${caja.facturaActual}',
                ),
                pw.Text(
                  'FECHA: ${DateFormat('yyyy/MM/dd').format(DateTime.now())} HORA: ${DateFormat('hh:mm:ss a').format(DateTime.now())}',
                ),
              ],
              pw.SizedBox(height: 10),
              pw.Text('Nombre: ${cliente?.clnmcl}'),
              pw.Text('Cedula/NIT: ${cliente?.clcecl}'),
              pw.Text('Dirección: ${cliente?.cldire}'),
              pw.Text('Email: ${cliente?.clmail}'),
              pw.SizedBox(height: 10),

              // productos
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Primera fila con los encabezados
                  pw.Row(
                    children: [
                      pw.Text(
                        'Refer.',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Text(
                        'Descripción',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Text(
                        'Cant.',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(width: 40),
                      pw.Text(
                        'PVP/Pub',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(width: 40),
                      pw.Text(
                        'PVP/Fer',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                    ],
                  ),
                  // datos del producto
                  pw.ListView.builder(
                    itemCount:
                        products
                            .length, // Use widget.products if the products are passed to the widget
                    itemBuilder: (context, index) {
                      final product = products[index];
                      print(product.description);
                      return pw.Column(
                        children: [
                          // Primera fila: referencia y descripción
                          pw.Row(
                            children: [
                              pw.Text(product.reference),
                              pw.SizedBox(width: 20),
                              pw.Text(product.description),
                            ],
                          ),

                          // Segunda fila: cantidad, precio y total
                          pw.Row(
                            children: [
                              pw.Text(product.quantity.toString()),
                              pw.SizedBox(width: 50),
                              pw.Text(
                                '\$${product.price.toStringAsFixed(2)}',
                              ), // Ensure the price is formatted correctly
                              pw.SizedBox(width: 30),
                              pw.Text(
                                '\$${total.toStringAsFixed(2)}',
                              ), // Display the calculated total
                            ],
                          ),

                          pw.SizedBox(
                            height: 10,
                          ), // Espacio entre los productos
                        ],
                      );
                    },
                  ),
                  // informacion de pago
                  pw.SizedBox(height: 10),
                  pw.Text('Valor mercancía entregada: $total'),
                  pw.Text('Efectivo: $total'),
                  pw.Text('Cambio: $diference'),
                  pw.SizedBox(height: 10),
                  pw.Text('Cajero: cajero1 - Consecutivo 25 - Caja99'),
                  pw.Text('Forma de Pago: $moneyMethod'),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'AUTORIZACIÓN NUMERACIÓN DE FACTURACIÓN No ${caja?.numeroResolucion}',
                  ),
                  pw.Text(
                    'VIGENCIA: 24 MESES, PREFIJO ${caja?.numeroCaja}, AUTORIZA DESDE ${caja?.facturaInicio} AL ${caja?.facturaActual}',
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('CUFE:'),
                  pw.Text('84dbf9ba1ad573cb69b5431f27c072de'),
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: 'https://example.com/factura/FE99-61198',
                      width: 100,
                      height: 100,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Center(
                    child: pw.Text(
                      "Proveedor Tecnológico APG Consulting Colombia SAS",
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
