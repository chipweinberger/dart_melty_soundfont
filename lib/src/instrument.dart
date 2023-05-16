import 'instrument_info.dart';
import 'instrument_region.dart';
import 'sample_header.dart';
import 'zone.dart';
import 'utils/span.dart';

/// <summary>
/// Represents an instrument in the SoundFont.
/// </summary>
class Instrument {
  static Instrument defaults = Instrument();

  /// <summary>
  /// The name of the instrument.
  /// </summary>
  late String name;

  // Internally exposes the raw array for fast enumeration.
  late List<InstrumentRegion> regions;

  /// <summary>
  /// The regions of the instrument.
  /// </summary>
  List<InstrumentRegion> get regionsReadOnly => regions.toList();

  Instrument() {
    this.name = "Default";
    this.regions = [];
  }

  factory Instrument.fromInfo(
    InstrumentInfo info,
    List<Zone> zones,
    List<SampleHeader> samples,
  ) {
    final zoneCount = info.zoneEndIndex - info.zoneStartIndex + 1;
    if (zoneCount <= 0) {
      throw "The instrument '${info.name}' has no zone.";
    }

    final zoneSpan = zones.span(info.zoneStartIndex, zoneCount);

    final instance = Instrument();
    instance.name = info.name;
    instance.regions = InstrumentRegion.create(instance, zoneSpan, samples);
    return instance;
  }

  static List<Instrument> create(
    List<InstrumentInfo> infos,
    List<Zone> zones,
    List<SampleHeader> samples,
  ) {
    if (infos.length <= 1) {
      throw "No valid instrument was found.";
    }

    // The last one is the terminator.
    final count = infos.length - 1;

    final instruments = <Instrument>[];

    for (var i = 0; i < count; i++) {
      instruments.add(Instrument.fromInfo(infos[i], zones, samples));
    }

    return instruments;
  }

  /// <summary>
  /// Gets the name of the instrument.
  /// </summary>
  /// <returns>
  /// The name of the instrument.
  /// </returns>
  @override
  String toString() {
    return name;
  }
}
