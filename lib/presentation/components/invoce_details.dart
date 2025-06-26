import 'dart:async';
import 'package:app_planeta/infrastructure/local_db/dao/index.dart';
import 'package:app_planeta/presentation/components/ean_scanner_component.dart';
import 'package:app_planeta/presentation/components/modal_component.dart';
import 'package:app_planeta/providers/type_factura_provider.dart';
import 'package:app_planeta/providers/user_provider.dart';
import 'package:app_planeta/services/promocion_cantidad_services.dart';
import 'package:app_planeta/services/ref_libro_especial.dart';
import 'package:app_planeta/services/ref_libro_services.dart';
import 'package:flutter/material.dart';
import 'package:app_planeta/utils/alert_utils.dart';
import 'package:app_planeta/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Product {
  final dynamic reference;
  final dynamic description;
  double price;
  double fairPrice;
  final String quantity;
  double total;
  String? tipo;
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
  final String? typeFactura;

  const InvoceDetails({
    super.key,
    required this.onSync,
    this.invoiceDiscount = 0, // Valor por defecto si no se envía
    this.typeFactura,
  });

  @override
  State<InvoceDetails> createState() => _InvoceDetails();
}

class _InvoceDetails extends State<InvoceDetails> {
  List<Product> products = [];
  List<Map<String, dynamic>> usuarios = [];
  late int invoiceDiscount;
  late dynamic typePromocion;

  // variables de la tabla
  int numRows = 0;
  int idRows = 0;
  dynamic totalFinal = 0;
  int numPromos = 0;
  int porcDescuento = 0;
  List<Map<String, dynamic>> promocionesCantidad = [];

  // Variables de la promoción
  DateTime? promoDate;
  String promoText = "";
  String horaDesde = "";
  String horaHasta = "";

  // Formateo de la fecha
  String? formattedDate;

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
  final RefLibroEspecial _refLibroServicesEspecial = RefLibroEspecial();

  // funciones
  void _scanEAN13() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EanScannerComponent()),
    );

    if (result != null && result is String) {
      setState(() {
        _addProduct(context, result.toString());
      });
    }
  }

  // funcion para pushear los libros
  void _buildRow(dynamic config, dynamic data) async {
    idRows++;

    // si no hay promociones, calculamos las promociones normales
    final result = await PromocionesDao().countPromociones();
    final result2 = await PromocionHoraDao().countPromocionHoras();
    final List<Map<String, dynamic>> promoExist = [];

    if (result > 0) {
      final promos = await PromocionesDao().fetchPromociones();
      // Agregamos un identificador para saber de qué tipo son
      promoExist.addAll(promos.map((p) => {...p, 'tipo_fuente': 'normal'}));
    }

    if (result2 > 0) {
      final promoHoras = await PromocionHoraDao().fetchPromocionesHoras();
      // Agregamos un identificador para saber que son de tipo por hora
      promoExist.addAll(promoHoras.map((p) => {...p, 'tipo_fuente': 'hora'}));
    }

    for (var p in promoExist) {
      print(p);
    }

    String quantityText = _quantityController.text.trim();

    String tipoProducto = data["Tipo"] ?? "S";

    int cantidad =
        (tipoProducto == 'D' || tipoProducto == 'T' || tipoProducto == 'Y')
            ? 1
            : int.tryParse(quantityText) ?? 1;

    double precio = double.tryParse(data['Precio'].toString()) ?? 0.0;
    double totalCalculado = precio * cantidad;

    final nuevoProducto = Product(
      reference: data["Referencia"],
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

      if (promoExist.isNotEmpty) {
        // Si hay promociones, calculamos las promociones especiales
        final promo = promoExist[0];

        final fechaRaw = promo['Fecha_Promocion'];
        final horaDesdeRaw = promo['Hora_Desde'];
        final minutosDesdeRaw = promo['Minuto_Desde'];
        final horaHastaRaw = promo['Hora_Hasta'];
        final minutosHastaRaw = promo['Minuto_Hasta'];

        final fechaPromo = DateTime.parse(fechaRaw);
        final now = DateTime.now();

        // 1) Asegurarnos de que la promo sea para hoy
        final esHoy =
            now.year == fechaPromo.year &&
            now.month == fechaPromo.month &&
            now.day == fechaPromo.day;

        if (!esHoy) {
          calcularPromociones();
          return;
        }

        // 2) Construir DateTime de inicio (p.ej. 9:30 AM)
        final int desdeH = int.parse(horaDesdeRaw.toString());
        final int desdeM = int.parse((minutosDesdeRaw ?? '0').toString());
        final horaDesdeDateTime = DateTime(
          fechaPromo.year,
          fechaPromo.month,
          fechaPromo.day,
          desdeH,
          desdeM,
        );

        // 3) Construir DateTime de fin (p.ej. 6:50 PM)
        final int hastaRawH = int.parse(horaHastaRaw.toString());
        final int hastaRawM = int.parse((minutosHastaRaw ?? '0').toString());
        // si la hora de fin es <= hora de inicio, la tratamos como PM
        final int hastaH24 = (hastaRawH <= desdeH) ? hastaRawH + 12 : hastaRawH;
        final horaHastaDateTime = DateTime(
          fechaPromo.year,
          fechaPromo.month,
          fechaPromo.day,
          hastaH24,
          hastaRawM,
        );

        // 4) Validar rango
        if (now.isBefore(horaDesdeDateTime) || now.isAfter(horaHastaDateTime)) {
          // fuera de rango: hora actual < inicio  o > fin
          calcularPromociones();
        } else {
          // entre horaDesde y horaHasta
          calcularPromocionesEspeciales();
        }
      } else {
        calcularPromociones();
      }
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      _referenceController.text = "";
      _quantityController.text = "1";
    });
  }

  void _buildRowEspecial(dynamic config, dynamic data) async {
    idRows++;
    String quantityText = _quantityController.text.trim();

    int cantidad = int.tryParse(quantityText) ?? 1;
    double precio = double.tryParse(data['Precio'].toString()) ?? 0.0;

    double descuentoFactor = 1 - (widget.invoiceDiscount / 100);
    double fairPrice = precio * descuentoFactor;

    // calculamos el total de la factura de otra manera
    double totalCalculado = fairPrice * cantidad;

    print("Total calculado: $totalCalculado");

    final nuevoProducto = Product(
      reference: data["Referencia"],
      description: data['Desc_Referencia'],
      price: precio,
      fairPrice: fairPrice,
      quantity: cantidad.toString(),
      total: fairPrice * cantidad,
      tipo: 'S',
    );

    setState(() {
      products.add(nuevoProducto);

      totalFinal = products.fold<int>(
        0,
        (sum, item) => sum + (item.total > 0 ? item.total.toInt() : 0),
      );
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _referenceController.text = "";
      _quantityController.text = "1";
    });
  }

  void calcularPromociones() async {
    // reseteamos los precios antes de aplicar las promociones
    for (final pro in products) {
      pro.fairPrice = pro.price;
      pro.total = pro.price * int.parse(pro.quantity);
    }

    // Verificamos si queda al menos un producto válido (tipo t, s, d, o)
    final tieneProductoValido = products.any((producto) {
      final tipo = producto.tipo?.toLowerCase();
      return tipo == 'T' || tipo == 'S' || tipo == 'D' || tipo == 'Y';
    });

    if (!tieneProductoValido) {
      invoiceDiscount = 0;
    }

    // traemos las promociones (si hay)
    final promocionesCantidad =
        await PromocionCantidadService().fetchPromocionCantidad();

    // filtramos los siguientes tipo de productos (T D Y N S)
    final List<Product> tipoT = products.where((p) => p.tipo == 'T').toList();
    final List<Product> tipoD = products.where((p) => p.tipo == 'D').toList();
    final List<Product> tipoY = products.where((p) => p.tipo == 'Y').toList();
    final List<Product> tipoN = products.where((p) => p.tipo == 'N').toList();
    final List<Product> tipoS = products.where((p) => p.tipo == 'S').toList();

    if (promocionesCantidad.isEmpty) {
      // 3x2
      if (tipoT.isNotEmpty) {
        int numberOfDiscountedProducts = tipoT.length ~/ 3;

        if (numberOfDiscountedProducts > 0) {
          // Creamos una copia de la lista para ordenarla sin afectar el orden original
          List<Product> sortedProducts = List.from(tipoT);

          // Ordenamos los productos por precio (de menor a mayor)
          sortedProducts.sort((a, b) => a.price.compareTo(b.price));

          // Seleccionamos los productos más baratos (la mitad)
          List<Product> cheapestProducts = sortedProducts.sublist(
            0,
            numberOfDiscountedProducts,
          );

          // Aplicamos el descuento a los productos más baratos
          for (Product product in products) {
            if (cheapestProducts.any((p) => p == product)) {
              // Este es uno de los productos más baratos, aplica descuento
              product.fairPrice = 0; // Producto gratis
              product.total = 0;
            }
          }
        }
      }

      // 2x1
      if (tipoY.isNotEmpty) {
        int numberOfDiscountedProducts = tipoY.length ~/ 2;

        if (numberOfDiscountedProducts > 0) {
          // Creamos una copia de la lista para ordenarla sin afectar el orden original
          List<Product> sortedProducts = List.from(tipoY);

          // Ordenamos los productos por precio (de menor a mayor)
          sortedProducts.sort((a, b) => a.price.compareTo(b.price));

          // Seleccionamos los productos más baratos (la mitad)
          List<Product> cheapestProducts = sortedProducts.sublist(
            0,
            numberOfDiscountedProducts,
          );

          // Aplicamos el descuento a los productos más baratos
          for (Product product in products) {
            if (cheapestProducts.any((p) => p == product)) {
              // Este es uno de los productos más baratos, aplica descuento
              product.fairPrice = 0; // Producto gratis
              product.total = 0;
            }
          }
        }
      }

      // 50%
      if (tipoD.isNotEmpty) {
        int numberOfDiscountedProducts = tipoD.length ~/ 2;

        if (numberOfDiscountedProducts > 0) {
          // Creamos una copia de la lista para ordenarla sin afectar el orden original
          List<Product> sortedProducts = List.from(tipoD);

          // Ordenamos los productos por precio (de menor a mayor)
          sortedProducts.sort((a, b) => a.price.compareTo(b.price));

          // Seleccionamos los productos más baratos (la mitad)
          List<Product> cheapestProducts = sortedProducts.sublist(
            0,
            numberOfDiscountedProducts,
          );

          // Aplicamos el descuento a los productos más baratos
          for (Product product in products) {
            if (cheapestProducts.any((p) => p == product)) {
              // Este es uno de los productos más baratos, aplica descuento
              product.fairPrice =
                  product.price * 0.5; // 50% del precio original
              product.total = product.fairPrice * int.parse(product.quantity);
            }
          }
        }
      }

      // N (N) producto especial viene con un descuento (porcentajeDescuento)
      if (tipoN.isNotEmpty) {
        for (Product product in tipoN) {
          final int? porcentajeDescuento = product.porcentajeDescuento;
          if (porcentajeDescuento != null && porcentajeDescuento > 0) {
            product.fairPrice =
                product.price * (1 - (porcentajeDescuento / 100));
            product.total = product.fairPrice * int.parse(product.quantity);
          }
        }
      }

      // pasamos los productos baratos al final
      products.sort((a, b) {
        if (a.fairPrice == 0 && b.fairPrice != 0) return 1;
        if (a.fairPrice != 0 && b.fairPrice == 0) return -1;
        if (a.fairPrice < a.price && b.fairPrice == a.price) return 1;
        if (a.fairPrice == a.price && b.fairPrice < b.price) return -1;
        return 0;
      });

      // actualizamos el total final
      totalFinal = products.fold<int>(
        0,
        (sum, item) => sum + (item.total > 0 ? item.total.toInt() : 0),
      );

      setState(() {});
    }

    if (promocionesCantidad.isNotEmpty) {
      // Paso 1: Reiniciar precios de todos
      for (var product in products) {
        product.fairPrice = product.price;
        product.total =
            product.price * (double.tryParse(product.quantity) ?? 1);
      }

      // Paso 2: Separar productos por tipo
      List<Product> tipoT = products.where((p) => p.tipo == 'T').toList();
      List<Product> tipoY = products.where((p) => p.tipo == 'Y').toList();
      //List<Product> restoDescuentoCantidad =
      //    products.where((p) => p.tipo != 'T' && p.tipo != 'N').toList();

      // Paso 3: Aplicar 3x2 a productos tipo T
      List<Product> disponiblesT = List.from(tipoT);
      List<Product> fueraDeGrupoT = [];

      while (disponiblesT.length >= 3) {
        // ORDENAR cada vez para que los más caros estén adelante
        disponiblesT.sort((a, b) => b.price.compareTo(a.price));

        // Tomar los dos primeros productos por orden
        List<Product> grupo = disponiblesT.sublist(0, 2);

        // Buscar el más barato desde el índice 2 en adelante (resto productos)
        Product? masBaratoResto;
        if (disponiblesT.length > 2) {
          masBaratoResto = disponiblesT
              .sublist(2)
              .reduce((a, b) => a.price < b.price ? a : b);
        }

        // Agregar el más barato del resto para completar grupo de 3
        if (masBaratoResto != null) {
          grupo.add(masBaratoResto);
        } else {
          break;
        }

        // Obtener el precio mínimo del grupo
        double precioMin = grupo
            .map((p) => p.price)
            .reduce((a, b) => a < b ? a : b);

        // Aplicar precios: todos con precio mínimo quedan en 0
        // Aplicar precios: solo un producto con el precio mínimo tendrá fairPrice = 0
        bool descuentoAplicado = false;
        for (var p in grupo) {
          if (p.price == precioMin && !descuentoAplicado) {
            p.fairPrice = 0;
            p.total = 0;
            descuentoAplicado = true;
          } else {
            p.fairPrice = p.price;
            p.total = p.price * (double.tryParse(p.quantity) ?? 1);
          }
        }

        // Remover productos usados
        for (var p in grupo) {
          disponiblesT.remove(p);
        }
      }

      // Los tipo T que no entraron en grupo de 3x2
      fueraDeGrupoT = disponiblesT;

      // --------------------
      // Ahora para tipo Y aplicar 2x1 (grupos de 2)
      // --------------------

      List<Product> disponiblesY = List.from(tipoY)..sort(
        (a, b) => b.price.compareTo(a.price),
      ); // ⬅️ Solo esta línea agregada
      List<Product> fueraDeGrupoY = [];

      while (disponiblesY.length >= 2) {
        // Primer producto del listado
        Product primero = disponiblesY[0];

        // Buscar el más barato entre los demás productos (desde índice 1)
        Product masBaratoResto = disponiblesY
            .sublist(1)
            .reduce((a, b) => a.price < b.price ? a : b);

        List<Product> grupo = [primero, masBaratoResto];

        // Determinar el más barato del grupo (puede ser masBaratoResto o primero)
        Product masBarato = grupo.reduce((a, b) => a.price <= b.price ? a : b);

        // Aplicar precios — solo al objeto exacto del más barato
        for (var p in grupo) {
          if (identical(p, masBarato)) {
            p.fairPrice = 0;
            p.total = 0;
          } else {
            p.fairPrice = p.price;
            p.total = p.price * (double.tryParse(p.quantity) ?? 1);
          }
        }

        // Remover productos usados
        disponiblesY.remove(primero);
        disponiblesY.remove(masBaratoResto);
      }

      // Los tipo Y que no entraron en grupo de 2x1
      fueraDeGrupoY = disponiblesY;

      List<Product> disponiblesD = List.from(tipoD)..sort(
        (a, b) => b.price.compareTo(a.price),
      ); // ⬅️ Esta línea nueva es suficiente
      List<Product> fueraDeGrupoD = [];

      while (disponiblesD.length >= 2) {
        // Primer producto del listado
        Product primero = disponiblesD[0];

        // Buscar el más barato entre los demás productos (desde índice 1)
        Product masBaratoResto = disponiblesD
            .sublist(1)
            .reduce((a, b) => a.price < b.price ? a : b);

        List<Product> grupo = [primero, masBaratoResto];

        // Determinar el más barato del grupo
        Product masBarato = grupo.reduce((a, b) => a.price <= b.price ? a : b);

        // Aplicar descuento 50% al más barato, el otro precio normal
        for (var p in grupo) {
          if (identical(p, masBarato)) {
            p.fairPrice = p.price * 0.5;
            p.total = p.fairPrice * (double.tryParse(p.quantity) ?? 1);
          } else {
            p.fairPrice = p.price;
            p.total = p.price * (double.tryParse(p.quantity) ?? 1);
          }
        }

        // Remover productos usados
        disponiblesD.remove(primero);
        disponiblesD.remove(masBaratoResto);
      }

      fueraDeGrupoD = disponiblesD;
      
      // Paso 4: Aplicar descuento por cantidad a:
      // - tipo S
      // - tipo D
      // - tipo T que no entraron en 3x2
      // - tipo Y que no entraron en 2x1
      //
      List<Product> productosParaDescuentoCantidad = [
        ...fueraDeGrupoT.where((p) => p.tipo != 'N'),
        ...fueraDeGrupoY.where((p) => p.tipo != 'N'),
        ...fueraDeGrupoD.where((p) => p.tipo != 'N'),
        ...tipoS.where((p) => p.tipo != 'N'),
      ];

      // Calcular cantidad total de productos
      int cantidadTotal = productosParaDescuentoCantidad.fold<int>(
        0,
        (sum, p) => sum + (int.tryParse(p.quantity) ?? 0),
      );

      // Buscar promociones válidas por rango
      final promocionesAplicables =
          promocionesCantidad.where((promo) {
            int desde = promo['Productos_Desde'];
            int hasta = promo['Productos_Hasta'];
            return cantidadTotal >= desde && cantidadTotal <= hasta;
          }).toList();

      // Si hay promociones aplicables
      if (promocionesAplicables.isNotEmpty) {
        // Usar la de mayor porcentaje
        promocionesAplicables.sort(
          (a, b) => (b['Porcentaje_Descuento'] as int).compareTo(
            a['Porcentaje_Descuento'] as int,
          ),
        );

        int descuento = promocionesAplicables.first['Porcentaje_Descuento'];
        invoiceDiscount = descuento;

        // Ordenar por precio para priorizar visual o lógica si se requiere
        final productosOrdenados = List.from(productosParaDescuentoCantidad)
          ..sort((a, b) => a.price.compareTo(b.price));

        for (var p in productosOrdenados) {
          double cantidad = double.tryParse(p.quantity) ?? 1;
          double precioConDescuento = p.price * (1 - descuento / 100);
          p.fairPrice = precioConDescuento;
          p.total = precioConDescuento * cantidad;
        }
      }

      // N (N) producto especial viene con un descuento (porcentajeDescuento)
      if (tipoN.isNotEmpty) {
        for (Product product in tipoN) {
          final int? porcentajeDescuento = product.porcentajeDescuento;
          if (porcentajeDescuento != null && porcentajeDescuento > 0) {
            product.fairPrice =
                product.price * (1 - (porcentajeDescuento / 100));
            product.total = product.fairPrice * int.parse(product.quantity);
          }
        }
      }

      // Paso 5: Reordenar: primero los con precio, luego los gratis
      List<Product> conPrecio = products.where((p) => p.fairPrice > 0).toList();
      List<Product> gratis = products.where((p) => p.fairPrice == 0).toList();

      products
        ..clear()
        ..addAll([...conPrecio, ...gratis]);

      // Paso 6: Calcular total final
      totalFinal = products.fold<double>(0, (sum, item) => sum + item.total);

      setState(() {});
    }
  }

  //funcion por si hay promocion 50% y 3x2 y horas
  void calcularPromocionesEspeciales() async {
    invoiceDiscount = 0;
    final promociones = await PromocionesDao().fetchPromociones();
    final promocionesHoras = await PromocionHoraDao().fetchPromocionesHoras();

    final hoy = DateTime.now();
    final ahora = TimeOfDay.now();
    final nowMinutes = ahora.hour * 60 + ahora.minute;

    final promociones50 =
        promociones.where((p) => p['Tipo_Promocion'] == '50%').toList();

    final promociones3x2 =
        promociones.where((p) => p['Tipo_Promocion'] == '3x2').toList();

    final promocionesValidasHora =
        promocionesHoras.where((p) {
          final fecha = DateTime.tryParse(p['Fecha_Promocion']);
          final desde =
              (int.parse(p['Hora_Desde'].toString()) * 60) +
              int.parse(p['Minuto_Desde'].toString());
          final hasta =
              (int.parse(p['Hora_Hasta'].toString()) * 60) +
              int.parse(p['Minuto_Hasta'].toString());
          return fecha != null &&
              hoy.year == fecha.year &&
              hoy.month == fecha.month &&
              hoy.day == fecha.day &&
              nowMinutes >= desde &&
              nowMinutes <= hasta;
        }).toList();

    // Reiniciar productos
    for (final pro in products) {
      final qty = int.tryParse(pro.quantity) ?? 1;
      pro.fairPrice = pro.price;
      pro.total = pro.price * qty;
    }

    // === 3x2 ===
    if (promociones3x2.isNotEmpty) {
      for (var i = 0; i < products.length; i++) {
        products[i] = products[i].copyWith(tipo: 'T');
      }

      final tipoT = products.where((p) => p.tipo == 'T').toList();
      final discountedCount = tipoT.length ~/ 3;

      if (discountedCount > 0) {
        final sorted = List<Product>.from(tipoT)
          ..sort((a, b) => a.price.compareTo(b.price));
        final cheapest = sorted.take(discountedCount).toList();

        for (final p in cheapest) {
          p.fairPrice = 0;
          p.total = 0;
        }
      }
    }

    // === 50% ===
    if (promociones50.isNotEmpty) {
      for (var i = 0; i < products.length; i++) {
        products[i] = products[i].copyWith(tipo: 'D');
      }

      final tipoD = products.where((p) => p.tipo == 'D').toList();
      final discountedCount = tipoD.length ~/ 2;

      if (discountedCount > 0) {
        final sorted = List<Product>.from(tipoD)
          ..sort((a, b) => a.price.compareTo(b.price));
        final cheapest = sorted.take(discountedCount).toList();

        for (final p in cheapest) {
          p.fairPrice = p.price * 0.5;
          p.total = p.fairPrice * int.tryParse(p.quantity)!;
        }
      }
    }

    // === Promociones por hora ===
    if (promocionesValidasHora.isNotEmpty) {
      final promo = promocionesValidasHora.first;
      final descuento =
          int.tryParse(promo['Descuento_Promocion'].toString()) ?? 0;

      setState(() {
        invoiceDiscount = descuento;
      });

      for (var i = 0; i < products.length; i++) {
        final qty = int.tryParse(products[i].quantity) ?? 1;
        final precioDescuento = products[i].price * (1 - descuento / 100);
        products[i] = products[i].copyWith(
          tipo: 'S',
          fairPrice: precioDescuento,
          total: precioDescuento * qty,
        );
      }
    }

    // Si no hay ninguna promoción válida
    if (promociones50.isEmpty &&
        promociones3x2.isEmpty &&
        promocionesValidasHora.isEmpty) {
      calcularPromociones(); // Fallback
    }

    // Ordenar: productos gratis o rebajados al final
    products.sort((a, b) {
      if (a.fairPrice == 0 && b.fairPrice != 0) return 1;
      if (a.fairPrice != 0 && b.fairPrice == 0) return -1;
      if (a.fairPrice < a.price && b.fairPrice == b.price) return 1;
      if (a.fairPrice == a.price && b.fairPrice < b.price) return -1;
      return 0;
    });

    totalFinal = products.fold<int>(
      0,
      (sum, item) => sum + (item.total > 0 ? item.total.toInt() : 0),
    );

    setState(() {});
  }

  // funcion para cancelar un factura
  void _clearProducts() {
    setState(() {
      products.clear();
      invoiceDiscount = 0;
    });
  }

  // funcion para elm

  // funcion para mostrar los metodos de pago disponibles
  void _showPaymentModal(BuildContext context) {
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
      builder:
          (context) => PaymentModal(
            total: products.fold<int>(0, (sum, item) {
              int itemTotal = item.total > 0 ? item.total.round() : 0;
              return sum + itemTotal;
            }),
            typeOfInvoice: widget.typeFactura,
            productsData: products,
          ),
    );
  }

  // funcion para añadir un producto nuevo
  void _addProduct(BuildContext context, refText) async {
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

    // verificamos con el provider el tipo de factura
    // si es factura normal o especial
    TypeFacturaProvider typeFacturaProvider = Provider.of<TypeFacturaProvider>(
      context,
      listen: false,
    );

    if (typeFacturaProvider.tipoFactura == 1) {
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

          _referenceController.text = refText;
          return;
        }

        if (!context.mounted) return;

        final config = {
          "cantidad": quantity.toString(),
          "porc_desc": porcDescuento,
        };

        final tipo = productData['Tipo'];
        final int repetitions =
            (tipo == 'D' || tipo == 'T' || tipo == 'Y') ? quantity : 1;

        for (int i = 0; i < repetitions; i++) {
          _buildRow(config, productData);
        }
      } catch (e) {
        if (context.mounted) {
          showAlert(
            context,
            "Error",
            "Error al obtener el producto. Intente de nuevo.",
          );
        }
      }
    } else {
      try {
        final productData = await _refLibroServicesEspecial.fetchProduct(
          refText,
        );

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
          "porc_desc": porcDescuento,
        };

        _buildRowEspecial(config, productData); // Llamada única
      } catch (e) {
        if (context.mounted) {
          showAlert(
            context,
            "Error",
            "Error al obtener el producto. Intente de nuevo.",
          );
        }
      }
    }
  }

  // cargamos el usuario localmente
  Future<void> _cargarUsuarios() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final data = await UserDao().getUserByNickName(userProvider.username);

    if (!mounted) return;

    setState(() {
      usuarios = data != null ? [data.toMap()] : [];
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

  Future<void> _cargarPromocion() async {
    final promociones = await PromocionesDao().fetchPromociones();
    final promocionesHora = await PromocionHoraDao().fetchPromocionesHoras();

    print("Promociones Hora $promocionesHora");
    print("Promociones Normales $promociones");

    final ahora = DateTime.now();
    final DateFormat formatter = DateFormat("d 'de' MMMM 'de' y", 'es_ES');

    bool esHoy(DateTime fecha) {
      return ahora.year == fecha.year &&
          ahora.month == fecha.month &&
          ahora.day == fecha.day;
    }

    String formatHora(int? hora, int? minuto) {
      return "${(hora ?? 0).toString().padLeft(2, '0')}:${(minuto ?? 0).toString().padLeft(2, '0')}";
    }

    DateTime getHora(DateTime fecha, dynamic h, dynamic m) {
      int hora = int.tryParse(h.toString()) ?? 0;
      int minuto = int.tryParse(m?.toString() ?? '0') ?? 0;
      return DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora + (hora < 12 ? 12 : 0),
        minuto,
      );
    }

    void resetPromo() {
      if (!mounted) return;
      setState(() {
        promoText = '';
        horaDesde = '';
        horaHasta = '';
        promoDate = null;
        formattedDate = '';
      });
    }

    Future<bool> procesarPromo(
      Map<String, dynamic> promo, {
      bool esHora = false,
    }) async {
      final cod = promo['Cod_Promocion'];
      if (cod == null) return false;

      final fechaPromo = DateTime.tryParse(promo['Fecha_Promocion'] ?? '');
      if (fechaPromo == null || !esHoy(fechaPromo)) {
        resetPromo();
        return false;
      }

      final horaInicio = getHora(
        fechaPromo,
        promo['Hora_Desde'],
        promo['Minuto_Desde'],
      );
      final horaFin = getHora(
        fechaPromo,
        promo['Hora_Hasta'],
        promo['Minuto_Hasta'],
      );

      if (ahora.isBefore(horaInicio) || ahora.isAfter(horaFin)) {
        resetPromo();
        return false;
      }

      if (!mounted) return false;

      if (widget.typeFactura == '1') {
        setState(() {
          typePromocion = "Especial";
          promoText =
              esHora
                  ? "por horas"
                  : promo['Tipo_Promocion'] == '3x2'
                  ? 'Pague 2 Lleve 3'
                  : '50% en segundo producto';

          horaDesde = formatHora(
            int.tryParse(promo['Hora_Desde'].toString()) ?? 0,
            int.tryParse(promo['Minuto_Desde'].toString()) ?? 0,
          );
          horaHasta = formatHora(
            int.tryParse(promo['Hora_Hasta'].toString()) ?? 0,
            int.tryParse(promo['Minuto_Hasta'].toString()) ?? 0,
          );

          promoDate = fechaPromo;
          formattedDate = formatter.format(promoDate!);
        });
      }

      return true;
    }

    // Procesar promoción por horas primero
    if (promocionesHora.isNotEmpty) {
      bool ok = await procesarPromo(promocionesHora[0], esHora: true);
      if (ok) return;
    }

    // Luego procesar promoción normal
    if (promociones.isNotEmpty) {
      bool ok = await procesarPromo(promociones[0]);
      if (ok) return;
    }

    // Si ninguna promoción aplica, limpiar
    typePromocion = "Normal";
    resetPromo();
  }

  Timer? promoTimer;

  @override
  void initState() {
    super.initState();
    _init(); // ejecutamos el método async desde un método normal

    promoTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _cargarPromocion();
    });
  }

  void _init() async {
    await _cargarUsuarios();
    invoiceDiscount = widget.invoiceDiscount;
    await _cargarPromocion();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _quantityController.dispose();
    promoTimer?.cancel();
    super.dispose();
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

    int? invoiceNumber =
        usuarios.isNotEmpty
            ? int.tryParse(
                  usuarios.first['facturaAlternaUsuario'].toString(),
                )! +
                1
            : null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                promoText != "" &&
                        promoDate != null &&
                        horaDesde != "" &&
                        horaHasta != ""
                    ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            const TextSpan(text: "🎉 Promoción "),
                            TextSpan(
                              text: "$promoText ",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ")  "),
                            TextSpan(
                              text: "Desde $horaDesde - Hasta $horaHasta",
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : const SizedBox.shrink(),
                const SizedBox(height: 12),
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
                        "Descuento En Factura",
                        invoiceDiscount.toString(),
                        Icons.discount,
                        Colors.orange,
                      ),
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
                                    headingRowColor: WidgetStateProperty.all(
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
                                      ...products.map((product) {
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
                                                  if (typePromocion ==
                                                      'Normal') {
                                                    setState(() {
                                                      products.remove(product);

                                                      // miramos el tipo de factura
                                                      TypeFacturaProvider
                                                      typeFacturaProvider =
                                                          Provider.of<
                                                            TypeFacturaProvider
                                                          >(
                                                            context,
                                                            listen: false,
                                                          );

                                                      if (typeFacturaProvider
                                                              .tipoFactura ==
                                                          1) {
                                                        calcularPromociones();
                                                      }
                                                    });
                                                  } else {
                                                    products.remove(product);
                                                    calcularPromocionesEspeciales();
                                                  }
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
                                                fontWeight: FontWeight.bold,
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
                          ), // Espacio entre los campos
                          const SizedBox(
                            height: 16,
                          ), // Espacio entre el campo y el botón

                          Column(
                            children: [
                              // SizedBox(
                              //   width: double.infinity,
                              //   child: OutlinedButton.icon(
                              //     onPressed:
                              //         () => _addProduct(
                              //           context,
                              //           _referenceController.text,
                              //         ),
                              //     icon: const Icon(
                              //       Icons.qr_code_scanner,
                              //       size: 24,
                              //     ),
                              //     label: const Text("Grabar"),
                              //     style: OutlinedButton.styleFrom(
                              //       foregroundColor: const Color(0xFF4CAF50),
                              //       side: const BorderSide(
                              //         color: Color(0xFF4CAF50),
                              //       ),
                              //       padding: const EdgeInsets.symmetric(
                              //         vertical: 16,
                              //       ),
                              //       shape: RoundedRectangleBorder(
                              //         borderRadius: BorderRadius.circular(8),
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              const SizedBox(height: 10), //
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _scanEAN13(),
                                  icon: const Icon(
                                    Icons.qr_code_scanner,
                                    size: 24,
                                  ),
                                  label: const Text("Scanear EAN"),
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
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ), // Espacio entre botones
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _showPaymentModal(context),
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
                                          () => showAddProductDialog(
                                            context,
                                            _referenceController,
                                            TextEditingController(
                                              text: _referenceController.text,
                                            ),
                                          ),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
