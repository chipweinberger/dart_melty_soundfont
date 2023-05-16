import 'dart:io';

import 'binary_reader.dart';
import 'midi_file.dart' show MidiFile;

MidiFile midiFileFromPath(String path) {
  final file = File(path);
  final bytes = file.readAsBytesSync();
  final reader = BinaryReader(bytes);
  return MidiFile(reader: reader);
}

Future<MidiFile> midiFileFromPathAsync(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  final reader = BinaryReader(bytes);
  return MidiFile(reader: reader);
}
