import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: 'PKR ',
    decimalDigits: 2,
  );
  
  static final NumberFormat _numberFormat = NumberFormat('#,##0.00');
  static final NumberFormat _litersFormat = NumberFormat('#,##0.00 L');

  static String formatPKR(dynamic val) {
    if (val == null) return 'PKR 0.00';
    num n = 0;
    if (val is num) {
      n = val;
    } else {
      n = num.tryParse(val.toString()) ?? 0;
    }
    return _currencyFormat.format(n);
  }

  static String formatNumber(dynamic val) {
    if (val == null) return '0.00';
    num n = 0;
    if (val is num) {
      n = val;
    } else {
      n = num.tryParse(val.toString()) ?? 0;
    }
    return _numberFormat.format(n);
  }

  static String formatLiters(dynamic val) {
    if (val == null) return '0.00 L';
    num n = 0;
    if (val is num) {
      n = val;
    } else {
      n = num.tryParse(val.toString()) ?? 0;
    }
    return '${_numberFormat.format(n)} L';
  }

  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('EEE, MMM d, yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  static String formatMonthYear(int year, int month) {
    try {
      final dt = DateTime(year, month, 1);
      return DateFormat('MMMM yyyy').format(dt);
    } catch (_) {
      return '$month/$year';
    }
  }
}
