import 'binary_reader.dart';
import 'sample_type.dart';

/// Represents a sample in the SoundFont.
class SampleHeader {
  /// The name of the sample.
  final String name;

  /// The start point of the sample in the sample data.
  final int start;

  /// The end point of the sample in the sample data.
  final int end;

  /// The loop start point of the sample in the sample data.
  final int startLoop;

  /// The loop end point of the sample in the sample data.
  final int endLoop;

  /// The sample rate of the sample.
  final int sampleRate;

  /// The key number of the recorded pitch of the sample.
  final int originalPitch; // byte

  /// The pitch correction in cents that should be applied to the sample on playback.
  final int pitchCorrection; // signed byte

  final int link; // uint16
  final SampleType type;

  SampleHeader(
      {required this.name,
      required this.start,
      required this.end,
      required this.startLoop,
      required this.endLoop,
      required this.sampleRate,
      required this.originalPitch,
      required this.pitchCorrection,
      required this.link,
      required this.type});

  factory SampleHeader.defaultSampleHeader() {
    return SampleHeader(
      name: 'Default',
      start: 0,
      end: 0,
      startLoop: 0,
      endLoop: 0,
      sampleRate: 0,
      originalPitch: 0,
      pitchCorrection: 0,
      link: 0,
      type: SampleType.none,
    );
  }

  factory SampleHeader.fromReader(BinaryReader reader) {
    String name = reader.readFixedLengthString(20);
    int start = reader.readInt32();
    int end = reader.readInt32();
    int startLoop = reader.readInt32();
    int endLoop = reader.readInt32();
    int sampleRate = reader.readInt32();
    int originalPitch = reader.readUInt8();
    int pitchCorrection = reader.readInt8();
    int link = reader.readUInt16();
    SampleType type = sampleTypeFromInt(reader.readUInt16());

    return SampleHeader(
        name: name,
        start: start,
        end: end,
        startLoop: startLoop,
        endLoop: endLoop,
        sampleRate: sampleRate,
        originalPitch: originalPitch,
        pitchCorrection: pitchCorrection,
        link: link,
        type: type);
  }

  static List<SampleHeader> readFromChunk(BinaryReader reader, int size) {
    if (size % 46 != 0) {
      throw "The sample header list is invalid.";
    }

    int count = (size ~/ 46) - 1;

    // The last one is the terminator.
    List<SampleHeader> headers = [];

    for (int i = 0; i < count; i++) {
      headers.add(
        SampleHeader.fromReader(reader),
      );
    }

    // The last one is the terminator.
    SampleHeader.fromReader(reader);

    return headers;
  }

  /// The name of the sample.
  @override
  String toString() {
    return name;
  }
}
