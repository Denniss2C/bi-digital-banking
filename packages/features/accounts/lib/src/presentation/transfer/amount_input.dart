final _plain = RegExp(r'^\d{1,7}([.,]\d{1,2})?$');
final _withThousands = RegExp(r'^\d{1,3}(,\d{3})+(\.\d{1,2})?$');

/// Parses what the user typed into cents, or `null` if it is not a valid
/// amount. Accepts `150`, `150.5`, `150,50` (decimal comma, common in
/// Ecuador) and `1,500.00` (thousands separator, as the app displays it).
int? parseAmountCents(String input) {
  var text = input.replaceAll(r'$', '').replaceAll(' ', '');
  if (text.isEmpty) return null;
  if (_withThousands.hasMatch(text)) {
    text = text.replaceAll(',', '');
  } else if (_plain.hasMatch(text)) {
    text = text.replaceAll(',', '.');
  } else {
    return null;
  }
  final parts = text.split('.');
  final units = int.parse(parts[0]);
  final decimals = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
  return units * 100 + int.parse(decimals);
}
