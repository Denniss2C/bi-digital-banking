import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats cents as dollars with thousands separators', () {
    expect(formatUsd(384550), r'$3,845.50');
    expect(formatUsd(5), r'$0.05');
    expect(formatUsd(0), r'$0.00');
  });

  test('signed amounts show + for credits and - for debits', () {
    expect(formatSignedUsd(35000), r'+$350.00');
    expect(formatSignedUsd(-6430), r'-$64.30');
  });
}
