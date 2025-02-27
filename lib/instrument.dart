import 'instrument_region.dart';
import 'sample_header.dart';
import 'instrument_info.dart';
import 'zone.dart';

/// Represents an instrument in the SoundFont.
class Instrument {
  final String name;
  final List<InstrumentRegion> regions;

  Instrument({required this.name, required this.regions});

  factory Instrument.defaultInstrument() {
    return Instrument(name: "Default", regions: []);
  }

  factory Instrument.fromInfo(
      InstrumentInfo info, List<Zone> zones, List<SampleHeader> samples) {
    int zoneCount = info.zoneEndIndex - info.zoneStartIndex + 1;
    if (zoneCount <= 0) {
      throw "The instrument '${info.name}' has no zone.";
    }

    List<Zone> zoneSpan =
        zones.sublist(info.zoneStartIndex, info.zoneStartIndex + zoneCount);

    List<InstrumentRegion> regions = InstrumentRegion.create(zoneSpan, samples);

    return Instrument(name: info.name, regions: regions);
  }

  static List<Instrument> create(List<InstrumentInfo> infos, List<Zone> zones,
      List<SampleHeader> samples) {
    if (infos.length <= 1) {
      throw "No valid instrument was found.";
    }

    // The last one is the terminator.
    int count = infos.length - 1;

    List<Instrument> instruments = [];

    for (var i = 0; i < count; i++) {
      instruments.add(Instrument.fromInfo(infos[i], zones, samples));
    }

    return instruments;
  }

  /// Gets the name of the instrument.
  @override
  String toString() {
    return name;
  }
}
