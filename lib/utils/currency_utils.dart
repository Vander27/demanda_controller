import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _brlFormatter =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ', decimalDigits: 2);

  static String formatBRL(double value) {
    return _brlFormatter.format(value).replaceAll('\u00A0', ' ');
  }
}
