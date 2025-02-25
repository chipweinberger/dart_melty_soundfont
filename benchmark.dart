import 'dart:io';
import 'dart:typed_data';

import 'lib/audio_renderer_ex.dart';
import 'lib/synthesizer.dart';
import 'lib/synthesizer_settings.dart';

void main() async {
  final bytes = await File('./example/assets/TimGM6mbEdit.sf2').readAsBytes();
  final byteData = ByteData.view(bytes.buffer);

  final settings = SynthesizerSettings(
    sampleRate: 44100,
    blockSize: 64,
    maximumPolyphony: 13,
    enableReverbAndChorus: true,
  );

  final synthesizer = Synthesizer.loadByteData(byteData, settings);

  final time = DateTime.now();

  print('Block size: ${synthesizer.blockSize}');
  final bufferSize = synthesizer.blockSize * 2;

  for (var i = 0; i < 1000000; i++) {
    final dest = Int16List(bufferSize);
    synthesizer.renderInterleavedInt16(dest);
  }

  final duration = DateTime.now().difference(time).inMilliseconds;

  print('Duration: $duration ms');
}
