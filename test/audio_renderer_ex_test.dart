import 'dart:math';

import 'package:darq/darq.dart';
import 'package:dart_melty_soundfont/src/i_audio_renderer.dart';
import 'package:dart_melty_soundfont/src/i_audio_renderer_ex.dart';
import 'package:dart_melty_soundfont/src/utils/short.dart';
import 'package:dart_melty_soundfont/src/utils/span.dart';

import 'package:test/test.dart';

import 'utils/test_case.dart';

void main() {
  group('Audio renderer tests', () {
    final lengths = [64, 63, 65, 41, 57, 278, 314];

    testCases<int>(
      'Render interleaved tests',
      lengths,
      (length) {
        final random = Random(31415);

        final srcLeft = List<double>.generate(
          length,
          (_) => 2 * (random.nextDouble() - 0.5),
        );
        final srcRight = List<double>.generate(
          length,
          (_) => 2 * (random.nextDouble() - 0.5),
        );
        final renderer = DummyRenderer(srcLeft, srcRight);

        final expected = srcLeft //
            .zip<double, List<double>>(srcRight, (x, y) => [x, y])
            .selectMany((x, index) => x)
            .toList();

        final actual = List<double>.generate(2 * length, (_) => 0.0).toSpan();
        renderer.renderInterleaved(actual);

        for (int i = 0; i < length; i++) {
          expect(expected[i], closeTo(actual[i], 1.0E-6));
        }
      },
    );

    testCases<int>(
      'Render mono tests',
      lengths,
      (length) {
        final random = Random(31415);

        final srcLeft = List<double>.generate(
          length,
          (_) => 2 * (random.nextDouble() - 0.5),
        );
        final srcRight = List<double>.generate(
          length,
          (_) => 2 * (random.nextDouble() - 0.5),
        );
        final renderer = DummyRenderer(srcLeft, srcRight);

        final expected = srcLeft //
            .zip<double, double>(srcRight, (x, y) => (x + y) / 2)
            .toList();

        final actual = List<double>.generate(length, (_) => 0.0).toSpan();
        renderer.renderMono(actual);

        for (int i = 0; i < length; i++) {
          expect(expected[i], closeTo(actual[i], 1.0E-6));
        }
      },
    );

    testCases<int>(
      'Render Int16 tests',
      lengths,
      (length) {
        final random = Random(31415);

        final srcLeft = List<double>.generate(
          length,
          (_) => 4 * (random.nextDouble() - 0.5),
        );
        final srcRight = List<double>.generate(
          length,
          (_) => 4 * (random.nextDouble() - 0.5),
        );
        final renderer = DummyRenderer(srcLeft, srcRight);

        final expectedLeft = srcLeft
            .select(
              (x, index) => ToShort(x),
            )
            .toList();
        final expectedRight = srcRight
            .select(
              (x, index) => ToShort(x),
            )
            .toList();

        final actualLeft = Span.filled(length, 0);
        final actualRight = Span.filled(length, 0);

        renderer.renderInt16(actualLeft, actualRight);

        for (int i = 0; i < length; i++) {
          expect(expectedLeft[i], actualLeft[i]);
          expect(expectedRight[i], actualRight[i]);
        }
      },
    );

    testCases<int>(
      'Render Interleaved Int16 tests',
      lengths,
      (length) {
        final random = Random(31415);

        final srcLeft = List<double>.generate(
          length,
          (_) => 4 * (random.nextDouble() - 0.5),
        );
        final srcRight = List<double>.generate(
          length,
          (_) => 4 * (random.nextDouble() - 0.5),
        );
        final renderer = DummyRenderer(srcLeft, srcRight);

        final expected = srcLeft //
            .zip<double, List<int>>(
                srcRight, (x, y) => [ToShort(x), ToShort(y)])
            .selectMany((x, index) => x)
            .toList();

        final actual = Span.filled(2 * length, 0);

        renderer.renderInterleavedInt16(actual);

        for (int i = 0; i < length; i++) {
          expect(expected[i], actual[i]);
        }
      },
    );

    testCases<int>(
      'Render Mono Int16 tests',
      lengths,
      (length) {
        final random = Random(31415);

        final srcLeft = List<double>.generate(
          length,
          (_) => 4 * (random.nextDouble() - 0.5),
        );
        final srcRight = List<double>.generate(
          length,
          (_) => 4 * (random.nextDouble() - 0.5),
        );
        final renderer = DummyRenderer(srcLeft, srcRight);

        final expected = srcLeft //
            .zip<double, int>(srcRight, (x, y) => ToShort((x + y) / 2))
            .toList();

        final actual = Span.filled(length, 0);

        renderer.renderMonoInt16(actual);

        for (int i = 0; i < length; i++) {
          expect(expected[i], actual[i]);
        }
      },
    );
  });
}

int ToShort(double value) {
  return clamp((32768 * value).toInt(), Short.MinValue, Short.MaxValue);
}

int clamp(int value, int min, int max) {
  if (value < min) {
    return min;
  } else if (value > max) {
    return max;
  } else {
    return value;
  }
}

class DummyRenderer implements IAudioRenderer {
  final List<double> srcLeft, srcRight;

  DummyRenderer(this.srcLeft, this.srcRight);

  void render(
    Span<double> left,
    Span<double> right,
  ) {
    for (int i = 0; i < left.length; i++) {
      left[i] = srcLeft[i];
    }
    for (int i = 0; i < right.length; i++) {
      right[i] = srcRight[i];
    }
  }
}
