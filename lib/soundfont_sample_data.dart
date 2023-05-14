import 'src/binary_reader.dart';
import 'src/binary_reader_ex.dart';
import 'src/utils/array_int16.dart';

class SoundFontSampleData {
  final int bitsPerSample;
  final ArrayInt16 samples;

  SoundFontSampleData({required this.bitsPerSample, required this.samples});

  factory SoundFontSampleData.fromReader(BinaryReader reader) {
    String chunkId = reader.readFourCC();

    if (chunkId != "LIST") {
      throw "The LIST chunk was not found.";
    }

    int end = reader.pos + reader.readInt32();

    String listType = reader.readFourCC();

    if (listType != "sdta") {
      throw "The type of the LIST chunk must be 'sdta', but was '$listType'.";
    }

    int? bitsPerSample;
    ArrayInt16? samples;

    while (reader.pos < end) {
      String id = reader.readFourCC();
      int size = reader.readInt32();

      switch (id) {
        case "smpl":
          if (samples != null) {
            throw "found more than one smpl chunk";
          }

          bitsPerSample = 16;
          samples = ArrayInt16.fromReader(reader, size ~/ 2);

          break;

        case "sm24":
          // 24 bit audio is not supported.
          reader.skip(size);
          break;

        default:
          throw "The INFO list contains an unknown ID '$id'.";
      }
    }

    if (samples == null || bitsPerSample == null) {
      throw "No valid sample data was found.";
    }

    return SoundFontSampleData(bitsPerSample: bitsPerSample, samples: samples);
  }
}
