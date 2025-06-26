// creamos el provider para el tipo de factura
import 'package:flutter/material.dart';

class TypeFacturaProvider with ChangeNotifier {
  int _tipoFactura = 1; // 1: Factura normal, 2: Factura especial

  int get tipoFactura => _tipoFactura;

  void setTipoFactura(int tipo) {
    _tipoFactura = tipo;
    notifyListeners();
  }
}