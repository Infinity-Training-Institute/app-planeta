import 'dart:convert';

import 'package:app_planeta/infrastructure/local_db/dao/datos_mcabfa_dao.dart';
import 'package:app_planeta/infrastructure/local_db/dao/datos_mlinfa_dao.dart';
import 'package:app_planeta/infrastructure/local_db/dao/index.dart';
import 'package:app_planeta/infrastructure/local_db/models/datos_cliente_model.dart';
import 'package:app_planeta/infrastructure/local_db/models/mcabfa_model.dart';
import 'package:app_planeta/infrastructure/local_db/models/mlinfa_model.dart';
import 'package:app_planeta/presentation/components/invoce_details.dart';
import 'package:app_planeta/providers/type_factura_provider.dart';
import 'package:app_planeta/providers/user_provider.dart';
import 'package:app_planeta/services/ref_libro_especial.dart';
import 'package:app_planeta/utils/create_cufe.dart';
import 'package:app_planeta/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';

class InvoiceService with ChangeNotifier {
  Future<pw.Document?> generateInvoice(
    BuildContext context,
    List<Product> products,
    List<DatosClienteModel> clientes,
    int total,
    List<dynamic> payments,
    String? tipoFacturacion,
    int diference,
  ) async {
    // recuperamos el tipo de factura
    final tipoFacturacion = Provider.of<TypeFacturaProvider>(
      context,
      listen: false,
    );

    final pdf = pw.Document();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // obtenemos los datos necesarios para la factura
    final datosEmpresas = await DatosEmpresaDao().getEmpresas();
    final datosCliente = await DatosClienteDao().getClientes();
    final datosCaja = await DatosCajaDao().getCajas();
    final users = await UserDao().getUserByNickName(userProvider.username);

    // tomamos el primer registro si existe
    final empresa = datosEmpresas.isNotEmpty ? datosEmpresas.first : null;
    final caja = datosCaja.isNotEmpty ? datosCaja.first : null;
    final cliente = datosCliente.isNotEmpty ? datosCliente.first : null;

    // === Aquí generamos el mapa de métodos de pago ===
    final Map<String, int> paymentValues = {
      'Efectivo': 0,
      'Tarjeta': 0,
      'QR Banco': 0,
      'Bono': 0,
    };

    for (var payment in payments) {
      final method = payment.method;
      final amount = payment.amount;

      if (paymentValues.containsKey(method)) {
        paymentValues[method] = amount;
      }
    }

    String obtenerAlias(String metodo) {
      final aliasMap = {
        "Maestro": "MA",
        "Visa": "VI",
        "MasterCard": "MS",
        "American Express": "AM",
        "Diners Club": "DI",
        "Colsubsidio": "CO",
        "Visa Electron": "VE",
        "Nequi": "NQ",
        "Daviplata": "DP",
      };

      return aliasMap[metodo] ?? "NA"; // Retorna "NA" si no se encuentra
    }

    String getPaymentAbbreviation(Map<String, int> paymentValues) {
      final methods = paymentValues.keys.toList();

      if (methods.isEmpty) return '';

      if (methods.length > 1) return 'M';

      return {
            'Efectivo': 'E',
            'Tarjeta': 'T',
            'Bono': 'B',
            'QR Banco': 'C',
          }[methods.first] ??
          '';
    }

    final cufeData = CreateCufe().generateCufe(
      numeroCaja: caja?.numeroCaja ?? '',
      facturaActual: caja?.facturaActual ?? '',
      fechaHoy: DateFormat('yyyy/MM/dd').format(DateTime.now()),
      hora: DateFormat('HH:mm:ss').format(DateTime.now()),
      totalFactura: total.toString(),
      cedula: cliente?.clcecl ?? '',
      claveTecnica: caja?.claveTecnica ?? '',
    );

    final qrData = jsonEncode({
      'NumFac': caja?.facturaActual ?? '',
      'FecFac': DateFormat('yyyy/MM/dd').format(DateTime.now()),
      'HorFac': DateFormat('HH:mm:ss').format(DateTime.now()),
      'NitFac': empresa?.nit ?? '',
      'DocAdq': cliente?.clcecl ?? '',
      'ValFac': total.toString(),
      'ValIva': '0.00',
      'valotrolm': '0.00',
      'ValTolFac': total.toString(),
      'CUFE': cufeData['cufe'] ?? '',
      'QRCode': cufeData['linkVerificacionQr'] ?? '',
    });

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
                  pw.Text('NOMBRE: ${cliente.clnmcl} ${cliente.clpacl}'),
                  pw.Text('CEDULA/NIT: ${cliente.clcecl}'),
                  pw.Text('TELEFONO: ${cliente.cltele}'),
                  pw.Text('EMAIL: ${cliente.clmail}'),
                  pw.Text('DIRECCIÓN: ${cliente.cldire}'),
                  pw.Text('CIUDAD: ${cliente.clciud}'),
                  pw.SizedBox(height: 10),
                ],
              ] else ...[
                pw.SizedBox(height: 10),
                pw.Text('NOMBRE: Consumidor Final'),
                pw.Text('CEDULA/NIT: 222222222222'),
                pw.Text('TELEFONO:'),
                pw.Text('EMAIL: info@planetadelibros.com.co'),
                pw.Text('DIRECCIÓN: Cl. 73 #7-60'),
                pw.Text('CIUDAD: Bogotá D.C.'),
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
                            mainAxisAlignment: pw.MainAxisAlignment.start,
                            children: [
                              pw.Container(
                                width:
                                    100, // define un ancho fijo para la referencia
                                child: pw.Text(
                                  product.reference,
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ),
                              pw.SizedBox(width: 15),
                              pw.Expanded(
                                child: pw.Text(
                                  product.description,
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ),
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
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Cajero: ${users?.nickUsuario} - Consecutivo ${users?.facturaAlternaUsuario} - ${users?.cajaUsuario}',
                  ),

                  if (payments.length > 1) ...[
                    // Mostrar solo "Mixto" si hay más de un método
                    pw.Text('Forma de Pago: Mixto'),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      // ignore: prefer_interpolation_to_compose_strings
                      'Nu. Aut. Tarjeta ' +
                          [
                            for (var pay in payments)
                              if (pay.method.contains("Tarjeta") &&
                                  pay.typeCard != null &&
                                  pay.typeCard.isNotEmpty)
                                obtenerAlias(pay.typeCard),
                            for (var pay in payments)
                              if (pay.reference != null &&
                                  pay.reference.isNotEmpty)
                                pay.reference,
                            for (var pay in payments)
                              if (pay.numberPhone != null &&
                                  pay.numberPhone.isNotEmpty)
                                pay.numberPhone,
                          ].join(" - "),
                    ),
                  ] else ...[
                    for (var pay in payments) ...[
                      pw.Text('Forma de Pago: ${pay.method}'),
                      pw.SizedBox(height: 5),
                      if (pay.method.contains("Tarjeta")) ...[
                        pw.Text(
                          // ignore: prefer_interpolation_to_compose_strings
                          "Nu. Aut. Tarjeta - " +
                              [
                                if (pay.typeCard != null &&
                                    pay.typeCard.isNotEmpty)
                                  obtenerAlias(pay.typeCard),
                                if (pay.typeCard2 != null &&
                                    pay.typeCard2.isNotEmpty)
                                  obtenerAlias(pay.typeCard2),
                                if (pay.reference != null &&
                                    pay.reference.isNotEmpty)
                                  pay.reference,
                              ].join(" - "),
                        ),
                      ],
                      if (pay.method.contains("QR Banco")) ...[
                        pw.Text(
                          "Nu. Aut. Tarjeta - - ${pay.numberPhone ?? ''}",
                        ),
                      ],

                      if (pay.method.contains("Efectivo") ||
                          pay.method.contains("Bono")) ...[
                        pw.Text("Nu. Aut. Tarjeta --"),
                      ],
                    ],
                  ],
                  pw.SizedBox(height: 5),
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
                    'VIGENCIA: 24 MESES, PREFIJO ${caja?.numeroCaja}, AUTORIZA DESDE ${caja?.facturaInicio} AL ${caja?.facturaFinal}',
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 5),
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
                    cufeData['cufe'] ?? '',
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  // Contenedor con clip para evitar que el QR añada espacio extra
                  pw.Container(
                    height: 230, // Mantiene el tamaño original
                    width: 350, // Mantiene el tamaño original
                    padding: pw.EdgeInsets.zero,
                    alignment: pw.Alignment.center,
                    child: pw.ClipRect(
                      // Recorta cualquier desbordamiento
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: qrData,
                        width: 350, // Tamaño original
                        height: 350, // Tamaño original
                        drawText: false,
                        margin: pw.EdgeInsets.zero,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Center(
                    child: pw.Text(
                      "Proveedor Tecnológico APG\n Consulting Colombia SAS",
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 100),
                ],
              ),
            ],
          );
        },
      ),
    );

    double totalDiscount = 0;
    double totalPrice = 0;
    double maxDiscountPercent = 0;

    /**
      * Función para calcular el descuento entre el precio normal y el precio de feria
      * Retorna el porcentaje de descuento y el total de descuento
    */
    for (var product in products) {
      final price = double.parse(product.price.toString());
      final fairPrice = double.parse(product.fairPrice.toString());
      final quantity = double.parse(product.quantity.toString());

      // Verificar si fairPrice es válido (no es 0)
      if (fairPrice >= 0) {
        // Calcular el descuento
        final discount = price - fairPrice;
        totalDiscount += discount * quantity;
        totalPrice += price * quantity;

        // Calcular el porcentaje de descuento solo si hay un descuento real
        if (price > 0 && fairPrice < price) {
          final discountPercent = (discount / price) * 100;
          if (discountPercent > maxDiscountPercent) {
            maxDiscountPercent = discountPercent;
          }
        }
      }
    }

    // Calcular el porcentaje promedio de descuento global basado en los totales
    double averageDiscountPercent = 0;
    if (totalPrice > 0) {
      averageDiscountPercent = (totalDiscount / totalPrice) * 100;
    }

    final mcpode =
        averageDiscountPercent.round(); // Porcentaje promedio de descuento
    final mcvade = totalDiscount; // Valor total de descuento
    final mcvabr =
        totalPrice; // Monto total sin descuento (precio normal total)

    final bonoList = payments.where((p) => p.method == 'Bono').toList();
    dynamic bonoValue; // Valor unitario del bono
    dynamic bonoCount;
    dynamic totalBonos;
    if (bonoList.isNotEmpty) {
      final bonoPayment = bonoList.first;
      bonoValue = bonoPayment.amount; // Valor unitario del bono
      bonoCount = bonoPayment.numberBono ?? 0;
      totalBonos = bonoValue * bonoCount;
    }

    String? referenciaTarjeta;

    try {
      final tarjetaOMixto = payments.firstWhere(
        (p) => p.method.contains('Tarjeta') || p.method.contains('Mixto'),
      );
      referenciaTarjeta = tarjetaOMixto.reference ?? '';
    } catch (_) {
      referenciaTarjeta = '';
    }

    // insertamos el la tabla de mcabfa
    await DatosMcabfaDao().insertMcabfa(
      McabfaModel(
        mcnufa: int.tryParse(caja?.facturaActual ?? '') ?? 0,
        mcnuca: (caja?.numeroCaja.toString() ?? '0'),
        mccecl:
            clientes.isNotEmpty
                ? int.tryParse(clientes.first.clcecl) ?? 222222222222
                : 222222222222,
        mcfefa: int.parse(DateFormat('yyyyMMdd').format(DateTime.now())),
        mchora: DateFormat('hh:mm:ss').format(DateTime.now()),
        mcfopa: getPaymentAbbreviation(paymentValues),
        mcpode: mcpode,
        mcvade: mcvade.toInt(),
        mctifa: tipoFacturacion.tipoFactura == 1 ? 'N' : 'E',
        mcvabr: mcvabr.toInt(),
        mcvane: total,
        mcesta: "",
        mcvaef: paymentValues['Efectivo'] ?? 0,
        mcvach: paymentValues['QR Banco'] ?? 0,
        mcvata: paymentValues['Tarjeta'] ?? 0,
        mcvabo: bonoValue ?? 0,
        mctobo: totalBonos ?? 0, // si total de bonos = valor bono
        mcnubo: bonoCount.toString(),
        mcusua: users!.nickUsuario,
        mc_connotacre: "",
        mcusan: "",
        mchoan: 0,
        mcnuau: referenciaTarjeta.toString(),
        mcnufi: users.facturaAlternaUsuario,
        mccaja: caja?.numeroCaja as String,
        mcufe: cufeData['cufe'] ?? '',
        mstand: int.tryParse(caja?.stand ?? '') ?? 0,
        mnube: 0,
      ),
    );

    // inserto en el mlinfa
    String obsLinfa;
    int totalPvpInd;
    int totalFeriaInd;

    for (var i = 0; i < products.length; i++) {
      final dynamic tipoLibro = await RefLibroEspecial().getTipoLibro(
        products[i].reference,
      );
      if (products[i].fairPrice == 0) {
        obsLinfa = "S";
      } else {
        obsLinfa = "N";
      }
      totalPvpInd =
          (num.parse(products[i].price.toString()) *
                  num.parse(products[i].quantity.toString()))
              .toInt();
      totalFeriaInd =
          (num.parse(products[i].fairPrice.toString()) *
                  num.parse(products[i].quantity.toString()))
              .toInt();

      // insertamos en la tabla de mlinfa
      await DatosMlinfaDao().insertMlinfa(
        MlinfaModel(
          mlnufc: int.tryParse(caja?.facturaActual ?? '') ?? 0,
          mlnuca: caja?.numeroCaja as String,
          mlcdpr: products[i].reference,
          mlnmpr: products[i].description,
          mlpvpr: totalPvpInd,
          mlpvne: totalFeriaInd,
          mlcant: int.parse(products[i].quantity),
          mlesta: tipoLibro,
          mlestao: obsLinfa,
          mlfefa: int.parse(DateFormat('yyyyMMdd').format(DateTime.now())),
          mlestf: '',
          mlusua: users.nickUsuario,
          mlnufi: users.facturaAlternaUsuario,
          mlcaja: caja?.numeroCaja as String,
          mstand: int.tryParse(caja?.stand ?? '') ?? 0,
          mnube: 0,
        ),
      );
    }

    // actualizamos el numero de la factura alterna
    await UserDao().updateFacturaAlternaUsuario(
      users.nickUsuario,
      users.facturaAlternaUsuario + 1,
    );

    //actualizamos la factura actual de la caja
    await DatosCajaDao().updateFacturaActual(caja?.nickUsuario as String);

    return pdf;
  }
}
