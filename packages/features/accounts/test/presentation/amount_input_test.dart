import 'package:accounts/src/presentation/transfer/amount_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses whole amounts and decimals into cents', () {
    expect(parseAmountCents('150'), 15000);
    expect(parseAmountCents('150.5'), 15050);
    expect(parseAmountCents('150.05'), 15005);
    expect(parseAmountCents('0.01'), 1);
    expect(parseAmountCents('0'), 0);
  });

  test('accepts the decimal comma used in Ecuador', () {
    expect(parseAmountCents('150,50'), 15050);
    expect(parseAmountCents('1,5'), 150);
  });

  test(r'accepts the thousands format the app displays, with or without $', () {
    expect(parseAmountCents('1,500'), 150000);
    expect(parseAmountCents('1,500.25'), 150025);
    expect(parseAmountCents(r'$ 1,234,567.89'), 123456789);
    expect(parseAmountCents(' 20 '), 2000);
  });

  test('rejects anything that is not an amount', () {
    for (final input in [
      '',
      ' ',
      r'$',
      'abc',
      '-5',
      '1.234',
      '1.',
      '.5',
      '1,50,0',
      '1.500,00',
      '12345678',
      '1e3',
    ]) {
      expect(parseAmountCents(input), isNull, reason: input);
    }
  });
}
