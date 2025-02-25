import 'binary_reader.dart';

class InstrumentInfo {
  final String name;
  final int zoneStartIndex;
  final int zoneEndIndex;

  InstrumentInfo({required this.name, required this.zoneStartIndex, required this.zoneEndIndex});

  factory InstrumentInfo.empty() {
    return InstrumentInfo(name: "", zoneStartIndex: 0, zoneEndIndex: 0);
  }

  static List<InstrumentInfo> readFromChunk(BinaryReader reader, int size) {
    if (size % 22 != 0) {
      throw "The instrument list is invalid.";
    }

    int count = size ~/ 22;

    List<InstrumentInfo> p = [];

    for (int i = 0; i < count; i++) {
      p.add(
          InstrumentInfo(name: reader.readFixedLengthString(20), zoneStartIndex: reader.readUInt16(), zoneEndIndex: 0));
    }

    List<InstrumentInfo> instruments = [];

    for (int i = 0; i < count - 1; i++) {
      int zoneIndexEnd = p[i + 1].zoneStartIndex - 1;

      instruments.add(InstrumentInfo(name: p[i].name, zoneStartIndex: p[i].zoneStartIndex, zoneEndIndex: zoneIndexEnd));
    }

    // the last one stays the same
    instruments.add(p[count - 1]);

    return instruments;
  }
}
