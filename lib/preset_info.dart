import 'binary_reader.dart';

class PresetInfo {
  final String name;
  final int patchNumber;
  final int bankNumber;
  final int zoneStartIndex;
  final int zoneEndIndex;
  final int library;
  final int genre;
  final int morphology;

  PresetInfo(
      {required this.name,
      required this.patchNumber,
      required this.bankNumber,
      required this.zoneStartIndex,
      required this.zoneEndIndex,
      required this.library,
      required this.genre,
      required this.morphology});

  static List<PresetInfo> readFromChunk(BinaryReader reader, int size) {
    if (size % 38 != 0) {
      throw "The preset list is invalid.";
    }

    int count = size ~/ 38;

    List<PresetInfo> p = [];

    for (int i = 0; i < count; i++) {
      String name = reader.readFixedLengthString(20);
      int patchNumber = reader.readUInt16();
      int bankNumber = reader.readUInt16();
      int zoneStartIndex = reader.readUInt16();
      int library = reader.readInt32();
      int genre = reader.readInt32();
      int morphology = reader.readInt32();

      p.add(PresetInfo(
        name: name,
        patchNumber: patchNumber,
        bankNumber: bankNumber,
        zoneStartIndex: zoneStartIndex,
        zoneEndIndex: 0,
        library: library,
        genre: genre,
        morphology: morphology,
      ));
    }

    List<PresetInfo> presets = [];

    for (int i = 0; i < count - 1; i++) {
      int zoneIndexEnd = p[i + 1].zoneStartIndex - 1;

      presets.add(PresetInfo(
        name: p[i].name,
        patchNumber: p[i].patchNumber,
        bankNumber: p[i].bankNumber,
        zoneStartIndex: p[i].zoneStartIndex,
        zoneEndIndex: zoneIndexEnd,
        library: p[i].library,
        genre: p[i].genre,
        morphology: p[i].morphology,
      ));
    }

    // the last one stays the same
    presets.add(p[count - 1]);

    return presets;
  }
}
