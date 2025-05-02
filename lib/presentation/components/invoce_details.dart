import 'dart:async';
import 'package:app_planeta/infrastructure/local_db/dao/index.dart';
import 'package:app_planeta/infrastructure/local_db/models/index.dart';
import 'package:app_planeta/presentation/components/ean_scanner_component.dart';
import 'package:app_planeta/presentation/components/modal_component.dart';
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
  final String? tipo;
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
        _referenceController.text = result;
      });
    }
  }

  // funcion para pushear los libros
  void _buildRow(dynamic config, dynamic data) async {
    idRows++;

    // si no hay promociones, calculamos las promociones normales
    final result = await PromocionesDao().countPromociones();
    final List<Map<String, dynamic>> promoExist = [];
    if (result > 0) {
      promoExist.addAll(await PromocionesDao().fetchPromociones());
      print(promoExist);
    }

    String reference = _referenceController.text.trim();
    String quantityText = _quantityController.text.trim();

    String tipoProducto = data["Tipo"] ?? "S";

    int cantidad =
        (tipoProducto == 'D' || tipoProducto == 'T' || tipoProducto == 'Y')
            ? 1
            : int.tryParse(quantityText) ?? 1;

    double precio = double.tryParse(data['Precio'].toString()) ?? 0.0;
    double totalCalculado = precio * cantidad;

    final nuevoProducto = Product(
      reference: reference,
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

    String reference = _referenceController.text.trim();
    String quantityText = _quantityController.text.trim();

    int cantidad = int.tryParse(quantityText) ?? 1;
    double precio = double.tryParse(data['Precio'].toString()) ?? 0.0;

    double descuentoFactor = 1 - (widget.invoiceDiscount / 100.0);
    double fairPrice = precio * descuentoFactor;
    double totalCalculado = fairPrice * cantidad;

    final nuevoProducto = Product(
      reference: reference,
      description: data['Desc_Referencia'],
      price: precio,
      fairPrice: fairPrice,
      quantity: cantidad.toString(),
      total: totalCalculado,
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
    // 1. Traer promociones (aquí solo usamos si está vacía)
    final promocionesCantidad =
        await PromocionCantidadService().fetchPromocionCantidad();

    // 2. Filtrar sólo productos tipo T y N
    final List<Product> tipoT = products.where((p) => p.tipo == 'T').toList();
    final List<Product> tipoD = products.where((p) => p.tipo == 'D').toList();
    final List<Product> tipoY = products.where((p) => p.tipo == 'Y').toList();
    final List<Product> tipoN = products.where((p) => p.tipo == 'N').toList();

    // Primero procesamos productos tipo N
    for (final n in tipoN) {
      final qty = int.tryParse(n.quantity) ?? 1;
      final descuentoEspecial = n.porcentajeDescuento ?? 0;

      if (descuentoEspecial > 0) {
        final descuento = n.price * (1 - (descuentoEspecial / 100));
        n.fairPrice = descuento;
        n.total = descuento * qty;
      } else {
        n.fairPrice = n.price;
        n.total = n.price * qty;
      }
    }

    // Inicializamos todos los productos tipo T con su precio normal
    // Esto es importante para "resetear" cualquier descuento previo
    for (final t in tipoT) {
      final qty = int.tryParse(t.quantity) ?? 1;
      t.fairPrice = t.price;
      t.total = t.price * qty;
    }

    for (final y in tipoY) {
      final qty = int.tryParse(y.quantity) ?? 1;
      y.fairPrice = y.price;
      y.total = y.price * qty;
    }

    // 3. Si no hay promociones generales, arrancamos nuestras reglas
    if (promocionesCantidad.isEmpty) {
      invoiceDiscount = 0;

      // Solo procesamos productos tipo T si hay suficientes para formar un grupo
      if (tipoT.length >= 3) {
        // Calculate how many complete groups of 3 we have
        int completeGroups = tipoT.length ~/ 3;
        List<Product> discountedProducts = [];

        // Process each complete group of 3
        for (int i = 0; i < completeGroups; i++) {
          int startIndex = i * 3;
          List<Product> group = tipoT.sublist(startIndex, startIndex + 3);

          // Check if all products in the group have the same reference
          bool sameReference = group.every(
            (p) => p.reference == group[0].reference,
          );

          Product productToDiscount;

          if (sameReference) {
            // If same reference, choose the last one
            productToDiscount = group[2];
          } else {
            // If different references, find the cheapest one
            productToDiscount = group.reduce(
              (a, b) => a.price < b.price ? a : b,
            );
          }

          // Add to our tracking list for debugging
          discountedProducts.add(productToDiscount);

          // Apply the discount
          productToDiscount.fairPrice = 0;
          productToDiscount.total = 0;
        }
      }

      // solo procesamos productos tipo Y si hay suficientes para formar un grupo
      if (tipoY.length >= 2) {
        int completeGroupsY = tipoY.length ~/ 2;
        List<Product> discountedProductsY = [];

        for (int i = 0; i < completeGroupsY; i++) {
          int startIndex = i * 2;
          List<Product> group = tipoY.sublist(startIndex, startIndex + 2);

          // Para tipo Y siempre buscamos el más barato sin importar referencias
          Product productToDiscount = group.reduce(
            (a, b) => a.price < b.price ? a : b,
          );

          discountedProductsY.add(productToDiscount);
          productToDiscount.fairPrice = 0;
          productToDiscount.total = 0;
        }
      }

      // Procesamos productos tipo D (grupos de 2 con 50% de descuento)
      if (tipoD.length >= 2) {
        int completeGroupsD = tipoD.length ~/ 2;
        List<Product> discountedProductsD = [];

        for (int i = 0; i < completeGroupsD; i++) {
          int startIndex = i * 2;
          List<Product> group = tipoD.sublist(startIndex, startIndex + 2);

          // Para tipo D buscamos el más barato para aplicar 50% de descuento
          Product productToDiscount = group.reduce(
            (a, b) => a.price < b.price ? a : b,
          );

          discountedProductsD.add(productToDiscount);

          // Aplicamos 50% de descuento (no cero)
          final qty = int.tryParse(productToDiscount.quantity) ?? 1;
          productToDiscount.fairPrice =
              productToDiscount.price * 0.5; // 50% del precio original
          productToDiscount.total = productToDiscount.fairPrice * qty;
        }
      }

      // 3.5 Reordenar para que los gratis queden al final (opcional)
      products.sort((a, b) {
        if (a.fairPrice == 0 && b.fairPrice != 0) return 1;
        if (a.fairPrice != 0 && b.fairPrice == 0) return -1;
        if (a.fairPrice < a.price && b.fairPrice == b.price) return 1;
        if (a.fairPrice == a.price && b.fairPrice < b.price) return -1;
        return 0;
      });

      setState(() {});
      return;
    }

    if (promocionesCantidad.isNotEmpty && products.isNotEmpty) {
      print(promocionesCantidad);

      // 1. Filtrar productos tipo T
      final List<Product> tipoT = products.where((p) => p.tipo == 'T').toList();
      final Set<Product> productosEnGruposT = {};

      bool seFormaronGruposT = false;

      // 2. Aplicar regla para productos tipo T en grupos de 3
      if (tipoT.length >= 3) {
        tipoT.sort((a, b) => a.fairPrice.compareTo(b.fairPrice));
        int gruposCompletosT = tipoT.length ~/ 3;

        if (gruposCompletosT > 0) {
          seFormaronGruposT = true;

          for (int i = 0; i < gruposCompletosT; i++) {
            int startIndex = i * 3;

            // Restaurar precios originales del grupo
            for (int j = startIndex; j < startIndex + 3; j++) {
              int index = products.indexWhere((p) => p == tipoT[j]);
              if (index != -1) {
                products[index].fairPrice = products[index].price;
                productosEnGruposT.add(products[index]);
              }
            }

            // Poner fairPrice del más barato en 0
            int cheapestIndex = startIndex;
            for (int j = startIndex + 1; j < startIndex + 3; j++) {
              if (tipoT[j].fairPrice < tipoT[cheapestIndex].fairPrice) {
                cheapestIndex = j;
              }
            }

            int originalIndex = products.indexWhere(
              (p) => p == tipoT[cheapestIndex],
            );
            if (originalIndex != -1) {
              products[originalIndex].fairPrice = 0;
            }
          }
        }
      }

      // 3. Filtrar productos tipo Y
      final List<Product> tipoY = products.where((p) => p.tipo == 'Y').toList();
      final Set<Product> productosEnGruposY = {};

      bool seFormaronGruposY = false;

      // 4. Aplicar regla para productos tipo Y en grupos de 2
      if (tipoY.length >= 2) {
        tipoY.sort((a, b) => a.fairPrice.compareTo(b.fairPrice));
        int gruposCompletosY = tipoY.length ~/ 2;

        if (gruposCompletosY > 0) {
          seFormaronGruposY = true;

          for (int i = 0; i < gruposCompletosY; i++) {
            int startIndex = i * 2;

            // Restaurar precios originales del grupo
            for (int j = startIndex; j < startIndex + 2; j++) {
              int index = products.indexWhere((p) => p == tipoY[j]);
              if (index != -1) {
                products[index].fairPrice = products[index].price;
                productosEnGruposY.add(products[index]);
              }
            }

            // Poner fairPrice del más barato en 0
            int cheapestIndex = startIndex;
            for (int j = startIndex + 1; j < startIndex + 2; j++) {
              if (tipoY[j].fairPrice < tipoY[cheapestIndex].fairPrice) {
                cheapestIndex = j;
              }
            }

            int originalIndex = products.indexWhere(
              (p) => p == tipoY[cheapestIndex],
            );
            if (originalIndex != -1) {
              products[originalIndex].fairPrice = 0;
            }
          }
        }
      }

      // 5. Filtrar productos tipo D
      final List<Product> tipoD = products.where((p) => p.tipo == 'D').toList();
      final Set<Product> productosEnGruposD = {};

      bool seFormaronGruposD = false;

      // 6. Aplicar regla para productos tipo D en grupos de 3
      if (tipoD.length >= 3) {
        tipoD.sort((a, b) => a.fairPrice.compareTo(b.fairPrice));
        int gruposCompletosD = tipoD.length ~/ 3;

        if (gruposCompletosD > 0) {
          seFormaronGruposD = true;

          for (int i = 0; i < gruposCompletosD; i++) {
            int startIndex = i * 3;

            // Restaurar precios originales del grupo
            for (int j = startIndex; j < startIndex + 3; j++) {
              int index = products.indexWhere((p) => p == tipoD[j]);
              if (index != -1) {
                products[index].fairPrice = products[index].price;
                productosEnGruposD.add(products[index]);
              }
            }

            // Poner fairPrice del más barato con un descuento del 50%
            int cheapestIndex = startIndex;
            for (int j = startIndex + 1; j < startIndex + 3; j++) {
              if (tipoD[j].fairPrice < tipoD[cheapestIndex].fairPrice) {
                cheapestIndex = j;
              }
            }

            int originalIndex = products.indexWhere(
              (p) => p == tipoD[cheapestIndex],
            );
            if (originalIndex != -1) {
              // Aplicar descuento del 50%
              products[originalIndex].fairPrice =
                  products[originalIndex].price * 0.5;
            }
          }
        }
      }

      // 7. Aplicar descuento por cantidad SOLO a productos que NO están en grupos tipo T, Y o D
      final List<Map<String, dynamic>> promocionesOrdenadas =
          List<Map<String, dynamic>>.from(promocionesCantidad);

      // Ordenar las promociones según el rango de productos
      promocionesOrdenadas.sort((a, b) {
        int desdeA =
            int.tryParse(
              a['productos_desde']?.toString() ??
                  a['Productos_Desde']?.toString() ??
                  '0',
            ) ??
            0;

        int desdeB =
            int.tryParse(
              b['productos_desde']?.toString() ??
                  b['Productos_Desde']?.toString() ??
                  '0',
            ) ??
            0;

        return desdeB.compareTo(desdeA);
      });

      final productosSinGrupoT_Y_D =
          products
              .where(
                (p) =>
                    !productosEnGruposT.contains(p) &&
                    !productosEnGruposY.contains(p) &&
                    !productosEnGruposD.contains(p),
              )
              .toList();

      Map<String, dynamic>? promocionAplicable;

      // Buscar la promoción aplicable
      for (var promocion in promocionesOrdenadas) {
        int productoDesde =
            int.tryParse(
              promocion['productos_desde']?.toString() ??
                  promocion['Productos_Desde']?.toString() ??
                  '0',
            ) ??
            0;

        int productoHasta =
            int.tryParse(
              promocion['productos_hasta']?.toString() ??
                  promocion['Productos_Hasta']?.toString() ??
                  '0',
            ) ??
            0;

        // Validar si el número de productos está dentro del rango de "productos_desde" y "productos_hasta"
        if (productosSinGrupoT_Y_D.length >= productoDesde &&
            productosSinGrupoT_Y_D.length <= productoHasta) {
          promocionAplicable = promocion;
          break; // Si encontramos una promoción válida, salimos del bucle
        }
      }

      // Si la promoción es válida, se aplica el descuento
      if (promocionAplicable != null) {
        final double porcentaje =
            double.tryParse(
              promocionAplicable['porcentaje_descuento']?.toString() ??
                  promocionAplicable['Porcentaje_Descuento']?.toString() ??
                  '0',
            ) ??
            0;

        print(
          'Aplicando descuento del $porcentaje% a productos fuera de los grupos tipo T, Y y D',
        );

        // Aplicar descuento a los productos fuera de los grupos tipo T, Y y D
        for (var product in productosSinGrupoT_Y_D) {
          double descuento = product.price * (porcentaje / 100);
          product.fairPrice = product.price - descuento;
        }

        // Establecer el descuento de la factura (widget.invoiceDiscount)
        invoiceDiscount = porcentaje.toInt();
      } else {
        // Si no hay promoción válida, dejar los precios originales
        for (var product in productosSinGrupoT_Y_D) {
          product.fairPrice = product.price; // Restaurar el precio original
        }
      }

      // 8. Calcular total final para cada producto
      for (var product in products) {
        double cantidad = double.tryParse(product.quantity) ?? 1.0;
        product.total = product.fairPrice * cantidad;
      }

      // 3.5 Reordenar para que los gratis queden al final (opcional)
      products.sort((a, b) {
        if (a.fairPrice == 0 && b.fairPrice != 0) return 1;
        if (a.fairPrice != 0 && b.fairPrice == 0) return -1;
        if (a.fairPrice < a.price && b.fairPrice == b.price) return 1;
        if (a.fairPrice == a.price && b.fairPrice < b.price) return -1;
        return 0;
      });
    }

    // Si hay promociones generales (en tu servicio), las manejarías aquí...
    setState(() {});
  }

  //funcion por si hay promocion 50% y 3x2
  void calcularPromocionesEspeciales() async {
    // traemos las promociones que hayan
    final promociones = await PromocionesDao().fetchPromociones();

    final promociones50 =
        promociones.where((p) => p['Tipo_Promocion'] == '50%').toList();

    final promociones3x2 =
        promociones.where((p) => p['Tipo_Promocion'] == '3x2').toList();

    for (final pro in products) {
      final qty = int.tryParse(pro.quantity) ?? 1;
      pro.fairPrice = pro.price;
      pro.total = pro.price * qty;
    }

    if (promociones50.isNotEmpty) {
      // cambiamos los tipos de los productos a D
      for (var i = 0; i < products.length; i++) {
        products[i] = products[i].copyWith(tipo: 'D');
      }

      // Calculamos cuántos productos deben recibir descuento (la mitad del total)
      int numberOfDiscountedProducts = products.length ~/ 2;

      if (numberOfDiscountedProducts > 0) {
        // Creamos una copia de la lista para ordenarla sin afectar el orden original
        List<Product> sortedProducts = List.from(products);

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
            final qty = int.tryParse(product.quantity) ?? 1;
            product.fairPrice = product.price * 0.5; // 50% del precio original
            product.total = product.fairPrice * qty;
          }
        }
      }
    }

    if (promociones3x2.isNotEmpty) {
      // cambiamos todos los tipos a T sin importar el tipo original
      for (var i = 0; i < products.length; i++) {
        products[i] = products[i].copyWith(tipo: 'T');
      }

      // Calculamos cuántos productos recibirán descuento (uno por cada grupo de 3)
      int numberOfDiscountedProducts = products.length ~/ 3;

      if (numberOfDiscountedProducts > 0) {
        // Crear una copia para ordenar sin afectar el orden original
        List<Product> sortedProducts = List.from(products);

        // Ordenar los productos por precio (de menor a mayor)
        sortedProducts.sort((a, b) => a.price.compareTo(b.price));

        // Seleccionar los productos más baratos que recibirán descuento
        // Tomamos exactamente la cantidad calculada (numberOfDiscountedProducts)
        List<Product> cheapestProducts = sortedProducts.sublist(
          0,
          numberOfDiscountedProducts,
        );

        // Aplicar el descuento a los productos seleccionados en la lista original
        for (Product product in products) {
          if (cheapestProducts.any(
            (p) =>
                identical(p, product) ||
                (p.reference == product.reference &&
                    p.reference == product.reference),
          )) {
            // Este es uno de los productos más baratos, aplicamos descuento
            product.fairPrice = 0; // Producto gratis
            product.total = 0;
          }
        }
      }
    }

    if (promociones50.isEmpty && promociones3x2.isEmpty) {
      calcularPromociones();
    }

    // Reordenar para que los gratis queden al final (opcional)
    products.sort((a, b) {
      if (a.fairPrice == 0 && b.fairPrice != 0) return 1;
      if (a.fairPrice != 0 && b.fairPrice == 0) return -1;
      if (a.fairPrice < a.price && b.fairPrice == b.price) return 1;
      if (a.fairPrice == a.price && b.fairPrice < b.price) return -1;
      return 0;
    });

    // Actualizamos el total final
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
    });
  }

  // funcion para mostrar los metodos de pago disponibles
  void _showPaymentModal(BuildContext context, int total) {
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
            total: total,
            typeOfInvoice: widget.typeFactura,
            productsData: products, // Pasar la lista de productos
          ),
    );
  }

  // funcion para añadir un producto nuevo
  void _addProduct(BuildContext context) async {
    final refText = _referenceController.text.trim();
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

    if (widget.typeFactura == '1') {
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
    if (promociones.isEmpty) return;

    final promo = promociones[0];
    if (promo['Cod_Promocion'] == null) return;

    final fechaRaw = promo['Fecha_Promocion'];
    final horaDesdeRaw = promo['Hora_Desde'];
    final minutosDesdeRaw = promo['Minuto_Desde'];
    final horaHastaRaw = promo['Hora_Hasta'];
    final minutosHastaRaw = promo['Minuto_Hasta'];

    final fechaPromo = DateTime.parse(fechaRaw);

    final ahora = DateTime.now();
    final esHoy =
        ahora.year == fechaPromo.year &&
        ahora.month == fechaPromo.month &&
        ahora.day == fechaPromo.day;

    if (!esHoy) {
      if (!mounted) return;

      // No es para hoy
      setState(() {
        promoText = '';
        horaDesde = '';
        horaHasta = '';
        promoDate = null;
        formattedDate = '';
      });
      return;
    }

    // Hora de inicio de la promoción: 9:30 AM
    final horaDesdeDateTime = DateTime(
      fechaPromo.year,
      fechaPromo.month,
      fechaPromo.day,
      int.parse(horaDesdeRaw.toString()),
      int.parse((minutosDesdeRaw ?? '0').toString()),
    );

    // Hora de fin de la promoción: 6:50 PM (convertir "6" a "18")
    final horaHastaDateTime = DateTime(
      fechaPromo.year,
      fechaPromo.month,
      fechaPromo.day,
      int.parse(horaHastaRaw.toString()) +
          (int.parse(horaHastaRaw.toString()) < 12 ? 12 : 0),
      int.parse((minutosHastaRaw ?? '0').toString()),
    );

    // Si antes de empezar o después de terminar, ocultar
    if (ahora.isBefore(horaDesdeDateTime) || ahora.isAfter(horaHastaDateTime)) {
      setState(() {
        promoText = '';
        horaDesde = '';
        horaHasta = '';
        promoDate = null;
        formattedDate = '';
      });
    } else {
      if (widget.typeFactura == '1') {
        // Estamos entre 9:30 AM y 6:50 PM
        setState(() {
          promoText =
              promo['Tipo_Promocion'] == '3x2'
                  ? 'Pague 2 Lleve 3'
                  : '50% en segundo producto';

          horaDesde =
              "${horaDesdeRaw.toString().padLeft(2, '0')}:${(minutosDesdeRaw ?? 0).toString().padLeft(2, '0')}";
          horaHasta =
              "${horaHastaRaw.toString().padLeft(2, '0')}:${(minutosHastaRaw ?? 0).toString().padLeft(2, '0')}";

          promoDate = fechaPromo;
          formattedDate = DateFormat(
            "d 'de' MMMM 'de' y",
            'es_ES',
          ).format(promoDate!);
        });
      }
    }
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

    // obtenemos la factura interna del usuario y le sumamos 1
    int? invoiceNumber =
        usuarios.isNotEmpty
            ? int.tryParse(usuarios.first['facturaAlternaUsuario'].toString())
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
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: "("),
                            TextSpan(
                              text: formattedDate,
                              style: const TextStyle(
                                color: Colors.red,
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
                                                  setState(() {
                                                    products.remove(product);
                                                    calcularPromociones(); // <- Aquí actualizas la promo después de eliminar
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
                                      () => _showPaymentModal(
                                        context,
                                        // Actualizamos el total final
                                        totalFinal = products.fold<int>(
                                          0,
                                          (sum, item) =>
                                              sum +
                                              (item.total > 0
                                                  ? item.total.toInt()
                                                  : 0),
                                        ),
                                      ),
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
          FloatingActionButton(
            heroTag: 'eanReader',
            onPressed: _scanEAN13, // Enfoca el TextField para escanear
            shape: const CircleBorder(),
            tooltip: 'Leer EAN-13',
            child: const Icon(Icons.qr_code),
          ),
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
