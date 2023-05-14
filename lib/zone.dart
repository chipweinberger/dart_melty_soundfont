import 'src/generator.dart';
import 'zone_info.dart';

class Zone {
  final List<Generator> generators;

  Zone({required this.generators});

  static List<Zone> create(List<ZoneInfo> infos, List<Generator> generators) {
    if (infos.length <= 1) {
      throw "No valid zone was found.";
    }

    // The last one is the terminator.
    int count = infos.length - 1;

    List<Zone> zones = [];

    for (var i = 0; i < count; i++) {
      ZoneInfo f = infos[i];

      zones.add(Zone(
          generators: generators.sublist(
              f.generatorIndex, f.generatorIndex + f.generatorCount)));
    }

    return zones;
  }

  static Zone empty = Zone(generators: []);
}
