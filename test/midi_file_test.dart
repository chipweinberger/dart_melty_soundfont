import 'package:dart_melty_soundfont/src/midi_file.dart';
import 'package:dart_melty_soundfont/src/midi_file_io.dart';
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
  });
}
