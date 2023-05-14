import 'dart:math';

import 'package:dart_melty_soundfont/src/array_math.dart';
import 'package:test/test.dart';

import 'utils/test_case.dart';

void main() {
  group('Array math tests', () {
    testCases<int>(
      'Multiply add tests',
      [
        64,
        63,
        65,
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        100,
        123,
        127,
        128,
        129,
        130,
        41,
        57,
        278,
        314
      ],
      (length) {
        final random = Random(31415);

        final x1 = List<double>.generate(
          length,
          (_) => 2 * (random.nextDouble() - 0.5),
        );
        final x2 = List<double>.generate(
          length,
          (_) => 2 * (random.nextDouble() - 0.5),
        );
        final a = 1 + random.nextDouble();

        final expected = List<double>.generate(
          length,
          (i) => x1[i] + a * x2[i],
        );

        final actual = x1.toList();
        multiplyAdd(a, x2, actual);

        for (int i = 0; i < length; i++) {
          expect(expected[i], closeTo(actual[i], 1.0E-3));
        }
      },
    );
  });
}
