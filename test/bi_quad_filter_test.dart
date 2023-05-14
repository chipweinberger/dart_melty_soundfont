import 'dart:math';

import 'package:darq/darq.dart';
import 'package:dart_melty_soundfont/bi_quad_filter.dart';
import 'package:dart_melty_soundfont/synthesizer.dart';
import 'package:test/test.dart';
import 'package:fftea/fftea.dart';

import 'utils/test_case.dart';
import 'utils/test_settings.dart';

void main() {
  group('Bi Quad Filter Tests', () {
    testCases<List<int>>(
      'Low pass filter test',
      [
        [44100, 1000],
        [44100, 500],
        [44100, 5000],
        [22050, 3000],
        [44100, 22050],
        [44100, 50000],
        [48000, 10000],
        [48000, 24000],
      ],
      (items) {
        final sampleRate = items[0];
        final cutoffFrequency = items[1];

        final synthesizer = Synthesizer.withSampleRate(
          TestSettings.defaultSoundFont,
          sampleRate,
        );

        final lpf = BiQuadFilter(synthesizer);
        lpf.setLowPassFilter(cutoffFrequency.toDouble(), 1);

        final block = List.filled(4096, 0.0);
        block[0] = 1;

        lpf.process(block);

        final reals = block.select((x, index) => x).toList();
        final fft = FFT(reals.length);
        final freq = fft.realFft(reals);

        final spectrum = freq.magnitudes().toList();

        for (var i = 0; i < spectrum.length / 2; i++) {
          final frequency = i / spectrum.length * sampleRate;

          if (frequency < cutoffFrequency - 1) {
            expect(spectrum[i] > 1 / sqrt(2), true);
          }

          if (frequency > cutoffFrequency + 1) {
            expect(spectrum[i] < 1 / sqrt(2), true);
          }

          if (frequency < cutoffFrequency / 10) {
            expect(spectrum[i], closeTo(1, 0.1));
          }
        }
      },
    );

    testCases<List<num>>(
      'Resonance tests',
      [
        [44100, 1000, 2.0],
        [44100, 500, 3.14],
        [44100, 5000, 5.7],
        [22050, 3000, 12.3],
        [48000, 500, 2.7],
      ],
      (items) {
        final sampleRate = items[0].toInt();
        final cutoffFrequency = items[1].toInt();
        final resonance = items[2].toDouble();

        final synthesizer = Synthesizer.withSampleRate(
          TestSettings.defaultSoundFont,
          sampleRate,
        );

        final lpf = BiQuadFilter(synthesizer);
        lpf.setLowPassFilter(cutoffFrequency.toDouble(), resonance);

        final block = List.filled(4096, 0.0);
        block[0] = 1;

        lpf.process(block);

        final reals = block.select((x, index) => x).toList();
        final fft = FFT(reals.length);
        final freq = fft.realFft(reals);

        final spectrum = freq.magnitudes().toList();

        for (var i = 0; i < spectrum.length / 2; i++) {
          final frequency = i / spectrum.length * sampleRate;

          if (frequency < cutoffFrequency / 10) {
            expect(spectrum[i], closeTo(1, 0.1));
          }
        }

        expect(resonance, closeTo(spectrum.max(), 0.03));
      },
    );
  });
}
