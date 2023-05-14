import 'dart:io';

import 'soundfont.dart' show SoundFont;

SoundFont soundFontFromPath(String path) {
  final file = File(path);
  final bytes = file.readAsBytesSync();
  final byteData = bytes.buffer.asByteData();
  return SoundFont.fromByteData(byteData);
}

Future<SoundFont> soundFontFromPathAsync(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  final byteData = bytes.buffer.asByteData();
  return SoundFont.fromByteData(byteData);
}
