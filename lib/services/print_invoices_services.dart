import 'package:app_planeta/infrastructure/local_db/dao/index.dart';
import 'package:app_planeta/infrastructure/local_db/models/datos_cliente_model.dart';
import 'package:app_planeta/presentation/components/invoce_details.dart';
import 'package:app_planeta/utils/create_cufe.dart';
import 'package:app_planeta/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoiceService with ChangeNotifier {
  Future<pw.Document?> generateInvoice(
    List<Product> products,
    List<DatosClienteModel> clientes,
    int total,
    List<dynamic> payments,
    int diference,
  ) async {
    final pdf = pw.Document();

    // obtenemos los datos necesarios para la factura
    final datosEmpresas = await DatosEmpresaDao().getEmpresas();
    final datosCliente = await DatosClienteDao().getClientes();
    final datosCaja = await DatosCajaDao().getCajas();

    // tomamos el primer registro si existe
    final empresa = datosEmpresas.isNotEmpty ? datosEmpresas.first : null;
    final caja = datosCaja.isNotEmpty ? datosCaja.first : null;
    final cliente = datosCliente.isNotEmpty ? datosCliente.first : null;

    // === Aquí generamos el mapa de métodos de pago ===
    final Map<String, int> paymentValues = {
      'Efectivo': 0,
      'Tarjeta': 0,
      'QR': 0,
      'Bono': 0,
    };

    for (var payment in payments) {
      final method = payment.method;
      final amount = payment.amount;

      if (paymentValues.containsKey(method)) {
        paymentValues[method] = amount;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ponemos un espacio entre el encabezado y el resto de la factura
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
              if (clientes.isNotEmpty) ...[
                for (var cliente in clientes) ...[
                  pw.SizedBox(height: 10),
                  pw.Text('NOMBRE: ${cliente.clnmcl}'),
                  pw.Text('CEDULA/NIT: ${cliente.clcecl}'),
                  pw.Text('TELEFONO: ${cliente.cltele}'),
                  pw.Text('DIRECCIÓN: ${cliente.cldire}'),
                  pw.Text('EMAIL: ${cliente.clmail}'),
                ],
              ] else ...[
                pw.SizedBox(height: 10),
                pw.Text('NOMBRE: ${cliente?.clnmcl}'),
                pw.Text('CEDULA/NIT: ${cliente?.clcecl}'),
                pw.Text('TELEFONO: ${cliente?.cltele}'),
                pw.Text('DIRECCIÓN: ${cliente?.cldire}'),
                pw.Text('EMAIL: ${cliente?.clmail}'),
                pw.SizedBox(height: 10),
              ],
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
                      pw.SizedBox(width: 25),
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
                      pw.SizedBox(height: 10),
                    ],
                  ),
                  // datos de los productos
                  pw.ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return pw.Column(
                        children: [
                          // Primera fila: referencia y descripcion
                          pw.Row(
                            children: [
                              pw.Text(product.reference),
                              pw.SizedBox(width: 15),
                              pw.Text(product.description),
                            ],
                          ),

                          // Segunda fila: cantidad, precio y precia feria y total
                          pw.Row(
                            children: [
                              pw.Text(product.quantity.toString()),
                              pw.SizedBox(width: 30),
                              pw.Text(
                                CurrencyFormatter.formatCOP(product.price),
                              ), // Ensure the price is formatted correctly

                              pw.SizedBox(width: 30),
                              pw.Text(
                                CurrencyFormatter.formatCOP(product.fairPrice),
                              ), // Display the fair price Display the calculated total
                            ],
                          ),

                          // Espacio entre productos
                          pw.SizedBox(height: 10),
                        ],
                      );
                    },
                  ),

                  // PINTAMOS UNA LINEA
                  pw.Divider(color: PdfColors.black, thickness: 1),

                  // informacion de pago
                  pw.SizedBox(height: 10),
                  pw.Row(
                    children: [
                      pw.Text('Valor mercancía entregada'),
                      pw.Spacer(),
                      pw.Text(CurrencyFormatter.formatCOP(total)),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Column(
                    children: [
                      for (var entry in paymentValues.entries) ...[
                        pw.Row(
                          children: [
                            pw.Text('${entry.key}......'), // nombre del método
                            pw.Spacer(),
                            pw.Text(
                              CurrencyFormatter.formatCOP(entry.value),
                            ), // el valor formateado
                          ],
                        ),
                        pw.SizedBox(height: 5),
                      ],
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    children: [
                      pw.Text('Su Cambio......'),
                      pw.Spacer(),
                      pw.Text(CurrencyFormatter.formatCOP(diference)),
                    ],
                  ),

                  // TODO: PONER EL CAJERO
                  pw.SizedBox(height: 10),
                  pw.Text('Cajero: cajero1 - Consecutivo 25 - Caja99'),
                  pw.Text('Forma de Pago: ${paymentValues.keys.first}'),
                  pw.SizedBox(height: 10),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'La factura electrónica de venta fue remitida al correo electrónico suministrado por usted a Editorial Planeta Colombiana S.A.\n'
                    'En caso de no recibirla, por favor comunicarse al correo electrónico cartera@planeta.com.co',
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'AUTORIZACIÓN NUMERACIÓN DE FACTURACIÓN No ${caja?.numeroResolucion}',
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'VIGENCIA: 24 MESES, PREFIJO ${caja?.numeroCaja}, AUTORIZA DESDE ${caja?.facturaInicio} AL ${caja?.facturaActual}',
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Responsable del impuesto sobre las ventas\n Agente retenedor del IVA\n Código Actividad Económica ICABogotá D.C. 8551 Tarifa 9.66 X Mil\n',
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'CUFE:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    CreateCufe().generateCufe(
                          numeroCaja: caja?.numeroCaja ?? '',
                          facturaActual: caja?.facturaActual ?? '',
                          fechaHoy: DateFormat(
                            'yyyy/MM/dd',
                          ).format(DateTime.now()),
                          hora: DateFormat('hh:mm:ss a').format(DateTime.now()),
                          totalFactura: total.toString(),
                          cedula: cliente?.clcecl ?? '',
                          claveTecnica: caja?.claveTecnica ?? '',
                        )['cufe'] ??
                        '',
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    "Proveedor Tecnológico APG Consulting Colombia SAS",
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 60),
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
