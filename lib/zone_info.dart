import 'binary_reader.dart';

class ZoneInfo {
  final int generatorIndex;
  final int modulatorIndex;
  final int generatorCount;
  final int modulatorCount;

  ZoneInfo({
    required this.generatorIndex,
    required this.modulatorIndex,
    required this.generatorCount,
    required this.modulatorCount,
  });

  static List<ZoneInfo> readFromChunk(BinaryReader reader, int size) {
    if (size % 4 != 0) {
      throw 'The zone list is invalid.';
    }

    int count = size ~/ 4;

    List<ZoneInfo> z = [];

    for (var i = 0; i < count; i++) {
      int genIdx = reader.readUInt16();
      int modIdx = reader.readUInt16();

      z.add(
        ZoneInfo(
          generatorIndex: genIdx,
          modulatorIndex: modIdx,
          generatorCount: 0,
          modulatorCount: 0,
        ),
      );
    }

    List<ZoneInfo> zones = [];

    for (var i = 0; i < count - 1; i++) {
      int generatorCount = z[i + 1].generatorIndex - z[i].generatorIndex;
      int modulatorCount = z[i + 1].modulatorIndex - z[i].modulatorIndex;

      zones.add(
        ZoneInfo(
          generatorIndex: z[i].generatorIndex,
          modulatorIndex: z[i].modulatorIndex,
          generatorCount: generatorCount,
          modulatorCount: modulatorCount,
        ),
      );
    }

    // the last one stays the same
    zones.add(z[count - 1]);

    return zones;
  }
}
