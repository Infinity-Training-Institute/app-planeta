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

    for (var p in products) {
      print(
        'Producto: ${p.description}, Precio Normal: \$${p.price.toStringAsFixed(2)}, Precio Feria: \$${p.fairPrice.toStringAsFixed(2)}, Cantidad: ${p.quantity}',
      );
    }

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

    print(products);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // damos un espacio
              pw.SizedBox(height: 10),
              // datos empresa si existen
              if (empresa != null) ...[
                pw.Text('EMPRESA: ${empresa.nombreEmpresa}'),
                pw.Text('NIT: ${empresa.nit}'),
                pw.Text('DIRECCION: ${empresa.direccion} PBX: 6079997'),
                pw.Text('DIRECCION ELECTRONICA: ${empresa.email}'),
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
              //TODO: si agregamos un cliente mostrarlo si no dejar el default
              pw.SizedBox(height: 10),
              pw.Text('NOMBRE: ${cliente?.clnmcl}'),
              pw.Text('CEDULA/NIT: ${cliente?.clcecl}'),
              pw.Text('DIRECCIÓN: ${cliente?.cldire}'),
              pw.Text('EMAIL: ${cliente?.clmail}'),
              pw.SizedBox(
                height: 10,
              ), // por ahora se deja el cliente por defecto
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
                      pw.SizedBox(width: 20),
                      pw.Text(
                        'PVP/Pub',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Text(
                        'PVP/Fer',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                    ],
                  ),
                  // datos de los productos
                  pw.ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return pw.Column(children: [pw.Row()]);
                    },
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
