import 'dart:typed_data';

import 'binary_reader.dart';
import 'instrument.dart';
import 'instrument_region.dart';
import 'loop_mode.dart';
import 'preset.dart';
import 'sample_header.dart';
import 'soundfont_info.dart';
import 'soundfont_parameters.dart';
import 'soundfont_sample_data.dart';

class SoundFont {
  final SoundFontInfo info;

  // is always 16
  final int bitsPerSample;

  /// This single array contains all the waveform data in the SoundFont.
  final Int16List waveData;

  /// An instance of 'SampleHeader' corresponds to a slice of
  /// the waveData array. i.e a sample.
  final List<SampleHeader> sampleHeaders;

  final List<Preset> presets;
  final List<Instrument> instruments;

  SoundFont({
    required this.info,
    required this.bitsPerSample,
    required this.waveData,
    required this.sampleHeaders,
    required this.presets,
    required this.instruments,
  });

  /// Loads a SoundFont from the file.
  factory SoundFont.fromFile(String path) {
    BinaryReader reader = BinaryReader.fromFile(path);
    return SoundFont.fromBinaryReader(reader);
  }

  factory SoundFont.fromByteData(ByteData bytes) {
    BinaryReader reader = BinaryReader.fromByteData(bytes);
    return SoundFont.fromBinaryReader(reader);
  }

  factory SoundFont.fromBinaryReader(BinaryReader reader) {
    String chunkId = reader.readFourCC();
    if (chunkId != 'RIFF') {
      throw 'The RIFF chunk was not found.';
    }

    // ignore: unused_local_variable
    int size = reader.readInt32();

    String formType = reader.readFourCC();
    if (formType != 'sfbk') {
      throw "The type of the RIFF chunk must be 'sfbk', but was '$formType'.";
    }

    var info = SoundFontInfo.fromReader(reader);
    var sampleData = SoundFontSampleData.fromReader(reader);
    var parameters = SoundFontParameters.fromReader(reader);

    SoundFont sf = SoundFont(
      info: info,
      bitsPerSample: sampleData.bitsPerSample,
      waveData: sampleData.samples,
      sampleHeaders: parameters.sampleHeaders,
      presets: parameters.presets,
      instruments: parameters.instruments,
    );

    sf._checkSamples();
    sf._checkRegions();

    return sf;
  }

  /// Gets the name of the SoundFont.
  @override
  String toString() {
    return info.bankName;
  }

  void _checkSamples() {
    // This offset is to ensure that out of range access is safe.
    var sampleCount = waveData.length -
        2; // Changed from bytes.lengthInBytes to length and adjusted for Int16

    for (SampleHeader sample in sampleHeaders) {
      if (!(0 <= sample.start && sample.start < sampleCount)) {
        throw "The start position of the sample '${sample.name}' is out of range.";
      }

      if (!(0 <= sample.startLoop && sample.startLoop < sampleCount)) {
        throw "The loop start position of the sample '${sample.name}' is out of range.";
      }

      if (!(0 < sample.end && sample.end <= sampleCount)) {
        throw "The end position of the sample '${sample.name}' is out of range.";
      }

      if (!(0 <= sample.endLoop && sample.endLoop <= sampleCount)) {
        throw "The loop end position of the sample '${sample.name}' is out of range.";
      }
    }
  }

  void _checkRegions() {
    // This offset is to ensure that out of range access is safe.
    var sampleCount = waveData.length -
        2; // Changed from bytes.lengthInBytes to length and adjusted for Int16

    for (Instrument instrument in instruments) {
      for (InstrumentRegion region in instrument.regions) {
        if (!(0 <= region.sampleStart() &&
            region.sampleStart() < sampleCount)) {
          throw "'sampleStart' is out of range. '${region.sample.name}'.'${instrument.name}'.";
        }

        if (!(0 <= region.sampleStartLoop() &&
            region.sampleStartLoop() < sampleCount)) {
          throw "'sampleStartLoop' is out of range. '${region.sample.name}'.'${instrument.name}'.";
        }

        if (!(0 < region.sampleEnd() && region.sampleEnd() <= sampleCount)) {
          throw "'sampleEnd' is out of range. '${region.sample.name}'.'${instrument.name}'.";
        }

        if (!(0 <= region.sampleEndLoop() &&
            region.sampleEndLoop() <= sampleCount)) {
          throw "'sampleEndLoop' is out of range. '${region.sample.name}'.'${instrument.name}'.";
        }

        switch (region.sampleModes()) {
          case LoopMode.noLoop:
          case LoopMode.continuous:
          case LoopMode.loopUntilNoteOff:
            break;
          default:
            throw "invalid loop mode. '${region.sample.name}'.'${instrument.name}'.";
        }
      }
    }
  }
}
