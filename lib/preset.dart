import 'preset_region.dart';
import 'preset_info.dart';
import 'zone.dart';
import 'src/instrument.dart';

/// Represents a preset in the SoundFont.
class Preset {
  final String name;
  final int patchNumber;
  final int bankNumber;
  final int library;
  final int genre;
  final int morphology;
  final List<PresetRegion> regions;

  Preset({
    required this.name,
    required this.patchNumber,
    required this.bankNumber,
    required this.library,
    required this.genre,
    required this.morphology,
    required this.regions,
  });

  factory Preset.defaultPreset() {
    return Preset(
      name: "Default",
      patchNumber: 0,
      bankNumber: 0,
      library: 0,
      genre: 0,
      morphology: 0,
      regions: [],
    );
  }

  factory Preset.fromInfo(
      PresetInfo info, List<Zone> zones, List<Instrument> instruments) {
    var zoneCount = info.zoneEndIndex - info.zoneStartIndex + 1;
    if (zoneCount <= 0) {
      throw "The preset '${info.name}' has no zone.";
    }

    List<Zone> zoneSpan =
        zones.sublist(info.zoneStartIndex, info.zoneStartIndex + zoneCount);

    List<PresetRegion> regions = PresetRegion.create(zoneSpan, instruments);

    return Preset(
      name: info.name,
      patchNumber: info.patchNumber,
      bankNumber: info.bankNumber,
      library: info.library,
      genre: info.genre,
      morphology: info.morphology,
      regions: regions,
    );
  }

  static List<Preset> create(
      List<PresetInfo> infos, List<Zone> zones, List<Instrument> instruments) {
    if (infos.length <= 1) {
      throw "No valid preset was found.";
    }

    // The last one is the terminator.
    int count = infos.length - 1;

    List<Preset> presets = [];

    for (var i = 0; i < count; i++) {
      presets.add(Preset.fromInfo(infos[i], zones, instruments));
    }

    return presets;
  }

  @override
  String toString() {
    return name;
  }

  //IReadOnlyList<PresetRegion> Regions => regions;

  //PresetRegion[] RegionArray => regions;
}
