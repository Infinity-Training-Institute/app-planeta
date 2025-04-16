import 'package:app_planeta/infrastructure/local_db/app_database.dart';
import 'package:app_planeta/presentation/components/ean_scanner_component.dart';
import 'package:app_planeta/presentation/components/modal_component.dart';
import 'package:app_planeta/services/promocion_cantidad_services.dart';
import 'package:app_planeta/services/ref_libro_services.dart';
import 'package:flutter/material.dart';
import 'package:app_planeta/utils/alert_utils.dart';
import 'package:app_planeta/utils/currency_formatter.dart';

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
      porcentajeDescuento: porcentajeDescuento ?? this.porcentajeDescuento,
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
  final double invoiceDiscount; // Nuevo parámetro opcional

  const InvoceDetails({
    super.key,
    required this.onSync,
    this.invoiceDiscount = 0.0, // Valor por defecto si no se envía
  });

  @override
  State<InvoceDetails> createState() => _InvoceDetails();
}

class _InvoceDetails extends State<InvoceDetails> {
  List<Product> _products = [];
  List<Map<String, dynamic>> usuarios = [];
  int giftedBooks = 0;
  late double invoiceDiscount;

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

  int numRows = 0;
  int idRows = 0;
  dynamic totalFinal = 0;
  List<dynamic> productos = [];
  int numPromos = 0;
  int porcDesc = 0;
  List<Map<String, dynamic>> promocionesCantidad = [];

  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: "1",
  );
  final TextEditingController _discountController = TextEditingController(
    text: "0",
  );

  final FocusNode _referenceFocusNode = FocusNode();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
    invoiceDiscount = widget.invoiceDiscount; // Asignar valor recibido
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _quantityController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _scanEAN13() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EanScannerComponent()),
    );

    if (result != null && result is String) {
      setState(() {
        _referenceController.text = result;
      });
      print('Código escaneado: $result');
    }
  }

  void calcularPromociones() async {
    Product? _oldFreeProductoT;
    Product? _oldDiscountProductoT;

    // 1. Obtener la promoción desde el servicio
    final promocionesCantidad =
        await PromocionCantidadService().fetchPromocionCantidad();
    final promo = promocionesCantidad.firstWhere(
      (p) => p['Cod_Promocion'] != null,
      orElse: () => {},
    );

    print("isEmpty: $promo");

    // 2. Separar productos por tipo.
    final List<Product> tipoT = _products.where((p) => p.tipo == 'T').toList();
    final List<Product> tipoN = _products.where((p) => p.tipo == 'N').toList();
    final List<Product> tipoS = _products.where((p) => p.tipo == 'S').toList();
    final List<Product> tipoY = _products.where((p) => p.tipo == 'Y').toList();
    final List<Product> tipoD = _products.where((p) => p.tipo == 'D').toList();

    // TIPO N
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

    if (promo.isEmpty) {
      // 1. Agrupar productos tipo T secuencialmente en grupos de 3
      final int totalT = tipoT.length;
      final int grupos = totalT ~/ 3;
      final int resto = totalT % 3;

      for (int i = 0; i < grupos; i++) {
        List<Product> grupo = tipoT.sublist(i * 3, (i + 1) * 3);

        // 1. Encontrar precio mínimo
        double minPrice = grupo
            .map((p) => p.price)
            .reduce((a, b) => a < b ? a : b);

        // 2. Obtener todos con precio mínimo
        List<Product> candidatosGratis =
            grupo.where((p) => p.price == minPrice).toList();

        // 3. Elegir el último de esos
        Product prodGratis = candidatosGratis.last;

        for (var producto in grupo) {
          final int cantidad = int.tryParse(producto.quantity) ?? 1;
          if (producto.reference == prodGratis.reference) {
            producto.fairPrice = 0;
            producto.total = 0;
          } else {
            producto.fairPrice = producto.price;
            producto.total = producto.price * cantidad;
          }
        }
      }

      // 2. Procesar productos tipo T que sobran (no entraron en grupo)
      if (resto > 0) {
        List<Product> restoProductos = tipoT.sublist(grupos * 3);
        for (var producto in restoProductos) {
          final int cantidad = int.tryParse(producto.quantity) ?? 1;
          producto.fairPrice = producto.price;
          producto.total = producto.price * cantidad;
        }
      }

      // 1. Resetear todos los productos a su valor original.
      for (var producto in tipoY) {
        final int cantidad = int.tryParse(producto.quantity) ?? 1;
        producto.fairPrice = producto.price;
        producto.total = producto.price * cantidad;
      }

      final int total = tipoY.length;

      if (total < 2) {
        // Menos de dos productos: no se aplica promoción.
      } else {
        if (total % 2 == 0) {
          // Caso: total par (2, 4, 6, …). Se procesan todos en parejas.
          for (int i = 0; i < total; i += 2) {
            Product a = tipoY[i];
            Product b = tipoY[i + 1];

            // Comparar precios; si son iguales, se descuenta al segundo.
            if (a.price < b.price) {
              a.fairPrice = 0;
              a.total = 0;
            } else if (a.price > b.price) {
              b.fairPrice = 0;
              b.total = 0;
            } else {
              b.fairPrice = 0;
              b.total = 0;
            }
          }
        } else {
          // Caso: total impar (3, 5, 7, …)
          if (total == 3) {
            // Cuando hay 3 productos, se procesa el grupo completo.
            List<Product> grupo = tipoY.sublist(0, 3);
            double minPrice = grupo
                .map((p) => p.price)
                .reduce((a, b) => a < b ? a : b);
            List<Product> candidatos =
                grupo.where((p) => p.price == minPrice).toList();
            // Se toma el último de los que tienen el precio mínimo.
            Product descuento = candidatos.last;
            descuento.fairPrice = 0;
            descuento.total = 0;
          } else {
            // Para 5, 7, … productos:
            // Procesar primero los pares completos hasta que queden 3 elementos.
            final int numPares = (total - 3) ~/ 2;
            for (int i = 0; i < numPares; i++) {
              int idx = i * 2;
              Product a = tipoY[idx];
              Product b = tipoY[idx + 1];

              if (a.price < b.price) {
                a.fairPrice = 0;
                a.total = 0;
              } else if (a.price > b.price) {
                b.fairPrice = 0;
                b.total = 0;
              } else {
                b.fairPrice = 0;
                b.total = 0;
              }
            }
            // Procesar los últimos 3 elementos como un grupo.
            List<Product> ultimosTres = tipoY.sublist(total - 3);
            double minPrice = ultimosTres
                .map((p) => p.price)
                .reduce((a, b) => a < b ? a : b);
            List<Product> candidatos =
                ultimosTres.where((p) => p.price == minPrice).toList();
            Product descuento = candidatos.last;
            descuento.fairPrice = 0;
            descuento.total = 0;
          }
        }
      }

      // 4. Ordenar productos si se desea que los gratuitos estén al final
      _products.sort((a, b) {
        if (a.fairPrice == 0 && b.fairPrice != 0) return 1;
        if (a.fairPrice != 0 && b.fairPrice == 0) return -1;
        return 0;
      });

      // 5. Recalcular total final
      totalFinal = _products.fold(0.0, (sum, p) => sum + p.total).toInt();

      return;
    }

    final double porcentajeDescuento =
        (promo['Porcentaje_Descuento'] ?? 0).toDouble();

    invoiceDiscount = porcentajeDescuento;

    final int desde = int.tryParse(promo['Productos_Desde'].toString()) ?? 0;
    final int hasta = int.tryParse(promo['Productos_Hasta'].toString()) ?? 0;

    // 3. Capturar el estado previo de los productos T que estaban gratis.
    final List<Product> prevFreeT =
        tipoT.where((p) => p.fairPrice == 0).toList();

    // 4. Resetear precios y totales para todos los productos.
    for (var p in _products) {
      p.fairPrice = p.price;
      final int cantidad = int.tryParse(p.quantity) ?? 1;
      p.total = p.fairPrice * cantidad;
    }

    // 5. Procesar productos tipo T según la cantidad.
    if (tipoT.length == 3) {
      List<Product> ordenados = List.from(tipoT);
      ordenados.sort((a, b) => a.price.compareTo(b.price));
      Product productoMasBarato = ordenados.first;

      for (var producto in tipoT) {
        if (producto == productoMasBarato) {
          producto.fairPrice = 0;
          producto.total = 0;
        } else {
          producto.fairPrice = producto.price;
          final int cantidad = int.tryParse(producto.quantity) ?? 1;
          producto.total = producto.fairPrice * cantidad;
        }
      }
      _oldFreeProductoT = null;
      _oldDiscountProductoT = null;
    } else if (tipoT.length == 4) {
      List<Product> ordenados = List.from(tipoT);
      ordenados.sort((a, b) => a.price.compareTo(b.price));
      Product nuevoMasBarato = ordenados.first;

      Product? oldFree;
      if (prevFreeT.isNotEmpty) {
        oldFree = prevFreeT.first;
      }

      for (var producto in tipoT) {
        if (producto == nuevoMasBarato) {
          producto.fairPrice = 0;
          producto.total = 0;
        } else if (oldFree != null &&
            producto == oldFree &&
            producto != nuevoMasBarato) {
          producto.fairPrice = producto.price * (1 - porcentajeDescuento / 100);
          final int cantidad = int.tryParse(producto.quantity) ?? 1;
          producto.total = producto.fairPrice * cantidad;
        } else {
          producto.fairPrice = producto.price;
          final int cantidad = int.tryParse(producto.quantity) ?? 1;
          producto.total = producto.fairPrice * cantidad;
        }
      }

      _oldFreeProductoT = nuevoMasBarato;
      _oldDiscountProductoT = oldFree;
    } else if (tipoT.length >= 5) {
      List<Product> productosOriginales = List.from(tipoT);
      int total = productosOriginales.length;

      // Caso A: EXACTAMENTE 5 productos.
      if (total == 5) {
        // Los dos primeros (índices 0 y 1) se dejan sin modificar.
        // Los últimos 3 (índices 2, 3 y 4) forman el grupo de promoción.
        List<Product> grupoPromo = productosOriginales.sublist(2);
        var prodGratis = grupoPromo.reduce((a, b) => a.price < b.price ? a : b);

        for (var producto in productosOriginales) {
          final int cantidad = int.tryParse(producto.quantity) ?? 1;
          if (grupoPromo.contains(producto)) {
            if (producto == prodGratis) {
              // Producto gratis en 3×2.
              producto.fairPrice = 0;
              producto.total = 0;
            } else {
              // Los otros dos del grupo reciben descuento.
              producto.fairPrice =
                  producto.price * (1 - (porcentajeDescuento / 100));
              producto.total = producto.fairPrice * cantidad;
            }
          } else {
            // Los dos primeros se cobran a precio normal.
            producto.fairPrice = producto.price;
            producto.total = producto.price * cantidad;
          }
        }
      }
      // Caso B: EXACTAMENTE 6 productos.
      else if (total == 6) {
        // Formamos dos grupos completos:
        // Grupo1: índices 0,1,2; Grupo2: índices 3,4,5.
        for (int i = 0; i < total; i += 3) {
          var grupo = productosOriginales.sublist(i, i + 3);
          var prodGratis = grupo.reduce((a, b) => a.price < b.price ? a : b);
          for (var producto in grupo) {
            final int cantidad = int.tryParse(producto.quantity) ?? 1;
            if (producto == prodGratis) {
              producto.fairPrice = 0;
              producto.total = 0;
            } else {
              producto.fairPrice = producto.price;
              producto.total = producto.price * cantidad;
            }
          }
        }
      }
      // Caso C: EXACTAMENTE 7 productos.
      else if (total == 7) {
        // Según tu requerimiento:
        // - Grupo 1: índices 0,1,2 (promoción 3×2).
        // - El producto en la 4ª posición (índice 3) quedará fuera y recibirá descuento.
        // - Grupo 2: índices 4,5,6 (promoción 3×2).

        // Grupo 1:
        List<Product> grupo1 = productosOriginales.sublist(0, 3);
        var prodGratis1 = grupo1.reduce((a, b) => a.price < b.price ? a : b);
        // Grupo 2:
        List<Product> grupo2 = productosOriginales.sublist(4, 7);
        var prodGratis2 = grupo2.reduce((a, b) => a.price < b.price ? a : b);

        for (int i = 0; i < total; i++) {
          final int cantidad =
              int.tryParse(productosOriginales[i].quantity) ?? 1;
          if (i < 3) {
            // Pertenece a grupo 1.
            if (productosOriginales[i] == prodGratis1) {
              productosOriginales[i].fairPrice = 0;
              productosOriginales[i].total = 0;
            } else {
              productosOriginales[i].fairPrice = productosOriginales[i].price;
              productosOriginales[i].total =
                  productosOriginales[i].price * cantidad;
            }
          } else if (i == 3) {
            // El producto en 4ª posición recibe descuento.
            productosOriginales[i].fairPrice =
                productosOriginales[i].price *
                (1 - (porcentajeDescuento / 100));
            productosOriginales[i].total =
                productosOriginales[i].fairPrice * cantidad;
          } else {
            // i en 4,5,6 pertenecen a grupo 2.
            if (productosOriginales[i] == prodGratis2) {
              productosOriginales[i].fairPrice = 0;
              productosOriginales[i].total = 0;
            } else {
              productosOriginales[i].fairPrice = productosOriginales[i].price;
              productosOriginales[i].total =
                  productosOriginales[i].price * cantidad;
            }
          }
        }
      }
      // Caso D: EXACTAMENTE 8 productos.
      else if (total == 8) {
        // Podemos asignar de la siguiente manera (por ejemplo):
        // - Grupo 1: índices 0,1,2 (promoción 3×2).
        // - El producto en posición 4 (índice 3) recibe descuento.
        // - Grupo 2: índices 4,5,6 (promoción 3×2).
        // - El producto en posición 8 (índice 7) recibe descuento.
        List<Product> grupo1 = productosOriginales.sublist(0, 3);
        var prodGratis1 = grupo1.reduce((a, b) => a.price < b.price ? a : b);
        List<Product> grupo2 = productosOriginales.sublist(4, 7);
        var prodGratis2 = grupo2.reduce((a, b) => a.price < b.price ? a : b);

        for (int i = 0; i < total; i++) {
          final int cantidad =
              int.tryParse(productosOriginales[i].quantity) ?? 1;
          if (i < 3) {
            // Grupo 1
            if (productosOriginales[i] == prodGratis1) {
              productosOriginales[i].fairPrice = 0;
              productosOriginales[i].total = 0;
            } else {
              productosOriginales[i].fairPrice = productosOriginales[i].price;
              productosOriginales[i].total =
                  productosOriginales[i].price * cantidad;
            }
          } else if (i == 3) {
            // Índice 3 recibe descuento.
            productosOriginales[i].fairPrice =
                productosOriginales[i].price *
                (1 - (porcentajeDescuento / 100));
            productosOriginales[i].total =
                productosOriginales[i].fairPrice * cantidad;
          } else if (i < 7) {
            // Grupo 2: índices 4,5,6
            if (productosOriginales[i] == prodGratis2) {
              productosOriginales[i].fairPrice = 0;
              productosOriginales[i].total = 0;
            } else {
              productosOriginales[i].fairPrice = productosOriginales[i].price;
              productosOriginales[i].total =
                  productosOriginales[i].price * cantidad;
            }
          } else {
            // Índice 7 recibe descuento.
            productosOriginales[i].fairPrice =
                productosOriginales[i].price *
                (1 - (porcentajeDescuento / 100));
            productosOriginales[i].total =
                productosOriginales[i].fairPrice * cantidad;
          }
        }
      }
      // Caso E: 9 o más productos (multiplo de 3 o sobrante)
      else {
        // Aquí agrupamos de forma estándar: se forman grupos completos de 3 a partir del inicio.
        int gruposCompletos = total ~/ 3;
        int productosEnGrupo = gruposCompletos * 3;
        int sobrantes = total - productosEnGrupo; // Estos recibirán descuento.

        print(sobrantes);

        // Para los grupos completos:
        for (int i = 0; i < productosEnGrupo; i += 3) {
          var grupo = productosOriginales.sublist(i, i + 3);
          var prodGratis = grupo.reduce((a, b) => a.price < b.price ? a : b);
          for (var producto in grupo) {
            final int cantidad = int.tryParse(producto.quantity) ?? 1;
            if (producto == prodGratis) {
              producto.fairPrice = 0;
              producto.total = 0;
            } else {
              producto.fairPrice = producto.price;
              producto.total = producto.price * cantidad;
            }
          }
        }
        // Para los sobrantes:
        for (int i = productosEnGrupo; i < total; i++) {
          final int cantidad =
              int.tryParse(productosOriginales[i].quantity) ?? 1;
          productosOriginales[i].fairPrice =
              productosOriginales[i].price * (1 - (porcentajeDescuento / 100));
          productosOriginales[i].total =
              productosOriginales[i].fairPrice * cantidad;
        }
      }
    } else if (tipoT.isNotEmpty) {
      for (var producto in tipoT) {
        producto.fairPrice = producto.price * (1 - porcentajeDescuento / 100);
        final int cantidad = int.tryParse(producto.quantity) ?? 1;
        producto.total = producto.fairPrice * cantidad;
      }
    }

    // 6. Mantener precio original para productos tipo N y S.
    for (var p in tipoS) {
      p.fairPrice = p.price;
      final int cantidad = int.tryParse(p.quantity) ?? 1;
      p.total = p.fairPrice * cantidad;
    }

    // 7. Ordenar productos para que los gratuitos aparezcan al final.
    _products.sort((a, b) {
      if (a.fairPrice == 0 && b.fairPrice != 0) return 1;
      if (a.fairPrice != 0 && b.fairPrice == 0) return -1;
      return 0;
    });

    // 8. Recalcular total final
    totalFinal = _products.fold(0.0, (sum, p) => sum + p.total).toInt();
  }

  void _buildRow(dynamic config, dynamic data) {
    idRows++;

    if (idRows < productos.length) {
      productos[idRows] = data;
    } else {
      productos.add(data);
    }

    String reference = _referenceController.text.trim();
    String quantityText = _quantityController.text.trim();

    String tipoProducto = data['Tipo'] ?? '3';

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
        _products.add(nuevoProducto);
      } else {
        int countT = _products.where((p) => p.tipo == 'T').length;

        // Calcular posición deseada en base a cantidad de productos T
        int insertIndex = 2 - countT;

        if (insertIndex < 0) insertIndex = 0;

        // Contamos productos no-T y buscamos su posición real en la lista
        int actualIndex = 0;
        int noTipoTCount = 0;

        while (actualIndex < _products.length && noTipoTCount < insertIndex) {
          if (_products[actualIndex].tipo != 'T') {
            noTipoTCount++;
          }
          actualIndex++;
        }

        _products.insert(actualIndex, nuevoProducto);
      }

      // 🧮 Total final
      totalFinal = _products.fold<int>(
        0,
        (sum, item) => sum + (item.total > 0 ? item.total.toInt() : 0),
      );

      calcularPromociones();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _referenceController.clear();
      _quantityController.text = "1";
    });
  }

  // funcion para cancelar factura
  void _clearProducts() {
    setState(() {
      _products.clear();
    });
  }

  // Obtener el color de fondo según el tipo
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

  final RefLibroServices _refLibroService =
      RefLibroServices(); // Instancia del servicio

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

    try {
      final productData = await _refLibroService.fetchProduct(refText);

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

      final config = {"cantidad": quantity.toString(), "porc_desc": porcDesc};

      final tipo = productData['Tipo'];
      final int repetitions =
          (tipo == 'D' || tipo == 'T' || tipo == 'Y') ? quantity : 1;

      for (int i = 0; i < repetitions; i++) {
        _buildRow(config, productData);
      }
    } catch (e) {
      print(e);
      if (context.mounted) {
        showAlert(
          context,
          "Error",
          "Error al obtener el producto. Intente de nuevo.",
        );
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

  void _showPaymentModal(BuildContext context, int total) {
    if (_products.isEmpty) {
      showAlert(context, "Info", "No ha agregado ningún producto");
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
            productsData: _products, // Pasar la lista de productos
          ),
    );
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

    // Obtener la factura interna del primer usuario + 1
    int invoiceNumber = usuarios[0]['Factura_Alterna_Usuario'] + 1;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        "Descuento en Factura",
                        "${invoiceDiscount.toString()}%",
                        Icons.discount,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Un cuadro que ocupa todo el ancho con solo la leyenda
                _buildLegendCard3(),

                const SizedBox(height: 8),
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
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: 150,
                                  maxHeight: (_products.length * 50)
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
                                      if (_products.isEmpty)
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
                                      ..._products.map((product) {
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
                                                    _products.remove(product);
                                                    productos.remove(product);
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
                                              _products
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
                                                _products.fold<num>(
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
                            onSubmitted: (value) {
                              if (value.isNotEmpty && value.length >= 8) {
                                print('Código leído: $value');
                                // Aquí pones tu lógica cuando se escanee o escriba el código
                              }
                            },
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
                                        totalFinal,
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
                                          () => showAddProductDialog(context),
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
            child: const Icon(Icons.qr_code),
            tooltip: 'Leer EAN-13',
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'syncButton',
            onPressed: widget.onSync,
            shape: const CircleBorder(),
            child: const Icon(Icons.sync),
            tooltip: 'Sincronizar',
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
