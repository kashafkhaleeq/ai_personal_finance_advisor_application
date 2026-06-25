import 'package:intl/intl.dart';

/// App-wide currency formatting. Change [currencySymbol] to localise.
class Money {
  static const currencySymbol = 'Rs ';

  static String format(double value) =>
      '$currencySymbol${NumberFormat('#,##0').format(value)}';
}

/// App-wide date formatting helpers.
class Dates {
  static String short(DateTime d) => DateFormat('d MMM').format(d);
  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
}
