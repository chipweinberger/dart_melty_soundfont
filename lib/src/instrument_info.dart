import 'binary_reader.dart';
import 'binary_reader_ex.dart';

class InstrumentInfo {
  late final String name;
  late final int zoneStartIndex;
  late final int zoneEndIndex;

  InstrumentInfo(BinaryReader reader) {
    name = reader.readFixedLengthString(20);
    zoneStartIndex = reader.readUInt16();
  }

  static List<InstrumentInfo> readFromChunk(BinaryReader reader, int size) {
    if (size % 22 != 0) {
      throw "The instrument list is invalid.";
    }

    int count = size ~/ 22;

    List<InstrumentInfo> instruments = [];

    for (int i = 0; i < count; i++) {
      instruments.add(InstrumentInfo(reader));
    }

    for (int i = 0; i < count - 1; i++) {
      instruments[i].zoneEndIndex = instruments[i + 1].zoneStartIndex - 1;
    }

    return instruments;
  }
}
