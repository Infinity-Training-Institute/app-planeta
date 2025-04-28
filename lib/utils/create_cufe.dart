import 'dart:convert';
import 'package:crypto/crypto.dart';

class CreateCufe {
  Map<String, String> generateCufe({
    required String numeroCaja,
    required String facturaActual,
    required String fechaHoy,
    required String hora,
    required String totalFactura,
    required String cedula,
    required String claveTecnica,
  }) {
    final nitfe = "830077981";
    final imp1 = "01";
    final valimp1 = "0.00";
    final imp2 = "04";
    final valimp2 = "0.00";
    final imp3 = "03";
    final valimp3 = "0.00";
    final ambiente = "1"; // 1: Producción, 2: Pruebas
    final horaQr = "$hora-05:00";
    final totalFacturaQr = "$totalFactura.00";
    final facturaActualQr = "$numeroCaja$facturaActual";

    final cadena =
        facturaActualQr +
        fechaHoy +
        horaQr +
        totalFacturaQr +
        imp1 +
        valimp1 +
        imp2 +
        valimp2 +
        imp3 +
        valimp3 +
        totalFacturaQr +
        nitfe +
        cedula +
        claveTecnica +
        ambiente;

    final bytes = utf8.encode(cadena);
    final hash = sha384.convert(bytes);
    final cadena1 = hash.toString();

    final linkVerificacionQr =
        'https://catalogo-vpfe.dian.gov.co/document/searchqr?documentkey=$cadena1';

    return {'cufe': cadena1, 'linkVerificacionQr': linkVerificacionQr};
  }
}
