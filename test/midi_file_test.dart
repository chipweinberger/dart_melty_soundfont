import 'dart:io';

import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';
import 'package:dart_melty_soundfont/soundfont_io.dart';
import 'package:dart_melty_soundfont/src/midi_file.dart';
import 'package:dart_melty_soundfont/src/midi_file_io.dart';
import 'package:dart_melty_soundfont/src/midi_file_sequencer.dart';
import 'package:dart_melty_soundfont/src/utils/span.dart';
import 'package:dart_melty_soundfont/synthesizer.dart';
import 'package:test/test.dart';

import 'utils/test_case.dart';

void main() {
  group('Midi File Tests', () {
    testCases<double>(
      'Time cents to seconds test',
      [
        0.0,
        1.1,
        1.11,
        1.111,
        1.1111,
        1.11111,
        3.1415,
      ],
      (value) {
        final actual = MidiFile.getTimeSpanFromSeconds(value);
        final expected = Duration(seconds: value.toInt());

        expect(actual.inSeconds, expected.inSeconds);
      },
    );

    testCases<MapEntry<String, double>>(
      'Read test',
      [
        MapEntry("flourish.mid", 87.5),
        // MapEntry("onestop.mid", 247.4),
        // MapEntry("town.mid", 79.0),
      ],
      (value) {
        final path = './test/test_data/${value.key}';
        final length = value.value;

        final actual = midiFileFromPath(path).length.inSeconds;
        final expected = length;

        expect(actual, closeTo(expected, .1));
      },
    );

    test('Create', () {
      final path = './test/test_data/flourish.mid';
      final midiFile = midiFileFromPath(path);
      final soundFont = soundFontFromPath('./test/test_data/Piano.sf2');
      final settings = SynthesizerSettings(
        sampleRate: 44100,
        blockSize: 64,
        maximumPolyphony: 64,
        enableReverbAndChorus: false,
      );
      final synth = Synthesizer.load(soundFont, settings);
      synth.noteOn(channel: 0, key: 60, velocity: 100);
      synth.noteOff(channel: 0, key: 60);
      final bytes = synth.pcm(4);
      final outLFile = File('./test/test_data/testL.pcm');
      outLFile.writeAsBytes(bytes);
    });
  });
}

extension on Synthesizer {
  Uint8List pcm(int seconds) {
    final buf16 = ArrayInt16.zeros(numShorts: 44100 * seconds);
    renderMonoInt16(buf16);
    return buf16.bytes.buffer.asUint8List();
  }
}
