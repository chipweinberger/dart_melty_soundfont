import 'dart:typed_data';

import 'binary_reader.dart';

class SoundFontSampleData {
  final int bitsPerSample;
  final Int16List samples;

  SoundFontSampleData({required this.bitsPerSample, required this.samples});

  factory SoundFontSampleData.fromReader(BinaryReader reader) {
    String chunkId = reader.readFourCC();

    if (chunkId != 'LIST') {
      throw 'The LIST chunk was not found.';
    }

    int end = reader.readInt32();
    end += reader.pos;

    String listType = reader.readFourCC();

    if (listType != 'sdta') {
      throw "The type of the LIST chunk must be 'sdta', but was '$listType'.";
    }

    int? bitsPerSample;
    Int16List? samples;

    while (reader.pos < end) {
      String id = reader.readFourCC();
      int size = reader.readInt32();

      switch (id) {
        case 'smpl':
          if (samples != null) {
            throw 'found more than one smpl chunk';
          }

          bitsPerSample = 16;

          // Read raw bytes and convert to Int16List
          ByteData? data = reader.read(size);
          if (data == null) {
            throw 'Failed to read sample data';
          }

          // Create Int16List with the correct size
          int numSamples = size ~/ 2; // 2 bytes per sample
          samples = Int16List(numSamples);

          // Convert bytes to Int16 samples with proper endianness
          for (int i = 0; i < numSamples; i++) {
            samples[i] = data.getInt16(i * 2, Endian.little);
          }
          break;

        case 'sm24':
          // 24 bit audio is not supported.
          reader.skip(size);
          break;

        default:
          throw "The INFO list contains an unknown ID '$id'.";
      }
    }

    if (samples == null || bitsPerSample == null) {
      throw 'No valid sample data was found.';
    }

    return SoundFontSampleData(bitsPerSample: bitsPerSample, samples: samples);
  }
}
