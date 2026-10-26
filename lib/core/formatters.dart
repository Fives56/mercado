import 'package:intl/intl.dart';

final _money = NumberFormat.currency(
  locale: 'es',
  symbol: r'$',
  decimalDigits: 2,
);

String formatPrice(double value) => _money.format(value);

String slugify(String input) {
  const map = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
    'Á': 'a',
    'É': 'e',
    'Í': 'i',
    'Ó': 'o',
    'Ú': 'u',
    'Ü': 'u',
    'Ñ': 'n',
  };
  var value = input.trim().toLowerCase();
  map.forEach((key, replacement) => value = value.replaceAll(key, replacement));
  value = value.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return value.replaceAll(RegExp(r'^-+|-+$'), '');
}

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
