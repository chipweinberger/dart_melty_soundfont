import 'sample_header.dart';
import 'preset.dart';
import 'instrument.dart';
import 'binary_reader.dart';
import 'instrument_info.dart';
import 'zone.dart';
import 'generator.dart';
import 'zone_info.dart';
import 'preset_info.dart';
import 'modulator.dart';

class SoundFontParameters {
  final List<SampleHeader> sampleHeaders;
  final List<Preset> presets;
  final List<Instrument> instruments;

  SoundFontParameters(
      {required this.sampleHeaders,
      required this.presets,
      required this.instruments});

  factory SoundFontParameters.fromReader(BinaryReader reader) {
    String chunkId = reader.readFourCC();

    if (chunkId != "LIST") {
      throw "The LIST chunk was not found.";
    }

    int end = reader.readInt32();
    end += reader.pos;

    var listType = reader.readFourCC();

    if (listType != "pdta") {
      throw "The type of the LIST chunk must be 'pdta', but was '$listType'.";
    }

    List<PresetInfo> presetInfos = [];
    List<ZoneInfo> presetBag = [];
    List<Generator> presetGenerators = [];
    List<InstrumentInfo> instrumentInfos = [];
    List<ZoneInfo> instrumentBag = [];
    List<Generator> instrumentGenerators = [];
    List<SampleHeader> sampleHeaders = [];

    while (reader.pos < end) {
      String id = reader.readFourCC();
      int size = reader.readInt32();

      switch (id) {
        case "phdr":
          presetInfos = PresetInfo.readFromChunk(reader, size);
          break;
        case "pbag":
          presetBag = ZoneInfo.readFromChunk(reader, size);
          break;
        case "pmod":
          Modulator.discardData(reader, size);
          break;
        case "pgen":
          presetGenerators = Generator.readFromChunk(reader, size);
          break;
        case "inst":
          instrumentInfos = InstrumentInfo.readFromChunk(reader, size);
          break;
        case "ibag":
          instrumentBag = ZoneInfo.readFromChunk(reader, size);
          break;
        case "imod":
          Modulator.discardData(reader, size);
          break;
        case "igen":
          instrumentGenerators = Generator.readFromChunk(reader, size);
          break;
        case "shdr":
          sampleHeaders = SampleHeader.readFromChunk(reader, size);
          break;
        default:
          throw "The INFO list contains an unknown ID '$id'.";
      }
    }

    if (presetInfos.isEmpty) throw "The PHDR sub-chunk was not found.";
    if (presetBag.isEmpty) throw "The PBAG sub-chunk was not found.";
    if (presetGenerators.isEmpty) throw "The PGEN sub-chunk was not found.";
    if (instrumentInfos.isEmpty) throw "The INST sub-chunk was not found.";
    if (instrumentBag.isEmpty) throw "The IBAG sub-chunk was not found.";
    if (instrumentGenerators.isEmpty) throw "The IGEN sub-chunk was not found.";
    if (sampleHeaders.isEmpty) throw "The SHDR sub-chunk was not found.";

    List<Zone> instrumentZones =
        Zone.create(instrumentBag, instrumentGenerators);

    List<Instrument> instruments =
        Instrument.create(instrumentInfos, instrumentZones, sampleHeaders);

    List<Zone> presetZones = Zone.create(presetBag, presetGenerators);

    List<Preset> presets = Preset.create(presetInfos, presetZones, instruments);

    return SoundFontParameters(
        sampleHeaders: sampleHeaders,
        presets: presets,
        instruments: instruments);
  }
}
