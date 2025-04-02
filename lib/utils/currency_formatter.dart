import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String formatCOP(num value) {
    final format = NumberFormat("#,##0", "es_CO");
    return "\$${format.format(value)}";
  }
}
