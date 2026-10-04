import 'package:intl/intl.dart';

final _usd = NumberFormat.currency(locale: 'en_US', symbol: r'$');

/// Formats integer [cents] as US dollars, as the design shows them in
/// Ecuador: `$3,845.50`. Money is always kept in cents to avoid rounding
/// errors; this is the only place it becomes text.
String formatUsd(int cents) => _usd.format(cents / 100);

/// Same as [formatUsd] with an explicit sign: `+$350.00` / `-$64.30`.
String formatSignedUsd(int cents) =>
    cents < 0 ? '-${formatUsd(-cents)}' : '+${formatUsd(cents)}';
