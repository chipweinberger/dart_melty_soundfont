import 'zone.dart';
import 'soundfont_math.dart';
import 'generator.dart';
import 'generator_type.dart';
import 'instrument.dart';

/// Represents a preset region.
/// A preset region indicates how the parameters of the instrument should be modified in the preset.
class PresetRegion {
  final Instrument instrument;

  final Map<GeneratorType, int> gs;

  PresetRegion({required this.instrument, required this.gs});

  factory PresetRegion.defaultPresetRegion() {
    return PresetRegion(instrument: Instrument.defaultInstrument(), gs: {});
  }

  factory PresetRegion.fromLists(
      {required List<Generator> global,
      required List<Generator> local,
      required List<Instrument> instruments})
  {
    // initialize default values
    Map<GeneratorType, int> gs = {};
    for (GeneratorType gType in GeneratorType.values) {
      gs[gType] = 0;
    }
    gs[GeneratorType.keyRange] = 0x7F00;
    gs[GeneratorType.velocityRange] = 0x7F00;

    for (Generator parameter in global) {
      gs[parameter.type] = castToShort(parameter.value);
    }

    for (Generator parameter in local) {
      gs[parameter.type] = castToShort(parameter.value);
    }

    Instrument inst;

    if (instruments.isNotEmpty) {

      int? id = gs[GeneratorType.instrument];

      if (id == null || id < 0 || id >= instruments.length) {
        throw "The preset contains an invalid instrument ID '$id'.";
      }

      inst = instruments[id];

    } else {

      inst = Instrument.defaultInstrument();
    }

    return PresetRegion(instrument: inst, gs: gs);
  }

  static List<PresetRegion> create(
      List<Zone> zones, List<Instrument> instruments) 
  {
    Zone? global;

    // Is the first one the global zone?
    if (zones[0].generators.isEmpty ||
        zones[0].generators.last.type != GeneratorType.instrument) {

      // The first one is the global zone.
      global = zones[0];

    }

    if (global != null) {

      // The global zone is regarded as the base setting of subsequent zones.
      List<PresetRegion> regions = [];

      int count = zones.length - 1;

      for (var i = 0; i < count; i++) {
        regions.add(PresetRegion.fromLists(
            global: global.generators,
            local: zones[i + 1].generators,
            instruments: instruments));
      }
      return regions;

    } else {
      // No global zone.
      List<PresetRegion> regions = [];

      int count = zones.length;

      for (var i = 0; i < count; i++) {
        regions.add(PresetRegion.fromLists(
            global: [],
            local: zones[i].generators,
            instruments: instruments));
      }
      return regions;
    }
  }

  /// Checks if the region covers the given key and velocity.
  /// arg: The key of a note.
  /// arg: The velocity of a note
  /// return true if the region covers the given key and velocity.
  bool contains(int key, int velocity) {
    bool containsKey = keyRangeStart() <= key && key <= keyRangeEnd();
    bool containsVelocity =
        velocityRangeStart() <= velocity && velocity <= velocityRangeEnd();
    return containsKey && containsVelocity;
  }

  @override
  String toString() {
    String s1 = "${instrument.name} (Key: ${keyRangeStart()}-${keyRangeEnd()},";
    String s2 = " Velocity: ${velocityRangeStart()}-${velocityRangeEnd()}";
    return s1 + s2;
  }

  int getGen(GeneratorType type) {
    return gs[type]!.toInt();
  }

  int modulationLfoToPitch() => gs[GeneratorType.modulationLfoToPitch]!;

  int vibratoLfoToPitch() => gs[GeneratorType.vibratoLfoToPitch]!;

  int modulationEnvelopeToPitch() =>
      gs[GeneratorType.modulationEnvelopeToPitch]!;

  double initialFilterCutoffFrequency() =>
      SoundFontMath.centsToMultiplyingFactor(
          gs[GeneratorType.initialFilterCutoffFrequency]!.toDouble());

  double initialFilterQ() => 0.1 * gs[GeneratorType.initialFilterQ]!;

  int modulationLfoToFilterCutoffFrequency() =>
      gs[GeneratorType.modulationLfoToFilterCutoffFrequency]!;

  int modulationEnvelopeToFilterCutoffFrequency() =>
      gs[GeneratorType.modulationEnvelopeToFilterCutoffFrequency]!;

  double modulationLfoToVolume() =>
      0.1 * gs[GeneratorType.modulationLfoToVolume]!;

  double chorusEffectsSend() => 0.1 * gs[GeneratorType.chorusEffectsSend]!;

  double reverbEffectsSend() => 0.1 * gs[GeneratorType.reverbEffectsSend]!;

  double pan() => 0.1 * gs[GeneratorType.pan]!;

  double delayModulationLfo() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.delayModulationLfo]!.toDouble());

  double frequencyModulationLfo() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.frequencyModulationLfo]!.toDouble());

  double delayVibratoLfo() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.delayVibratoLfo]!.toDouble());

  double frequencyVibratoLfo() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.frequencyVibratoLfo]!.toDouble());

  double delayModulationEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.delayModulationEnvelope]!.toDouble());

  double attackModulationEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.attackModulationEnvelope]!.toDouble());

  double holdModulationEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.holdModulationEnvelope]!.toDouble());

  double decayModulationEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.decayModulationEnvelope]!.toDouble());

  double sustainModulationEnvelope() =>
      0.1 * gs[GeneratorType.sustainModulationEnvelope]!;

  double releaseModulationEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.releaseModulationEnvelope]!.toDouble());

  int keyNumberToModulationEnvelopeHold() =>
      gs[GeneratorType.keyNumberToModulationEnvelopeHold]!;

  int keyNumberToModulationEnvelopeDecay() =>
      gs[GeneratorType.keyNumberToModulationEnvelopeDecay]!;

  double delayVolumeEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.delayVolumeEnvelope]!.toDouble());

  double attackVolumeEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.attackVolumeEnvelope]!.toDouble());

  double holdVolumeEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.holdVolumeEnvelope]!.toDouble());

  double decayVolumeEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.decayVolumeEnvelope]!.toDouble());

  double sustainVolumeEnvelope() =>
      0.1 * gs[GeneratorType.sustainVolumeEnvelope]!;

  double releaseVolumeEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.releaseVolumeEnvelope]!.toDouble());

  int keyNumberToVolumeEnvelopeHold() =>
      gs[GeneratorType.keyNumberToVolumeEnvelopeHold]!;

  int keyNumberToVolumeEnvelopeDecay() =>
      gs[GeneratorType.keyNumberToVolumeEnvelopeDecay]!;

  int keyRangeStart() => gs[GeneratorType.keyRange]! & 0xFF;

  int keyRangeEnd() => (gs[GeneratorType.keyRange]! >> 8) & 0xFF;

  int velocityRangeStart() => gs[GeneratorType.velocityRange]! & 0xFF;

  int velocityRangeEnd() => (gs[GeneratorType.velocityRange]! >> 8) & 0xFF;

  double initialAttenuation() => 0.1 * gs[GeneratorType.initialAttenuation]!;

  int coarseTune() => gs[GeneratorType.coarseTune]!;

  int fineTune() => gs[GeneratorType.fineTune]!;

  int scaleTuning() => gs[GeneratorType.scaleTuning]!;

  // LoopMode SampleModes =>
  //  gs[GeneratorType.SampleModes];

  // int ExclusiveClass =>
  //  gs[GeneratorType.ExclusiveClass];

  // int RootKey =>
  //  gs[GeneratorType.OverridingRootKey];

  // int StartAddressOffset =>
  //  32768 * gs[GeneratorType.StartAddressCoarseOffset] +
  //  gs[GeneratorType.StartAddressOffset];

  // int EndAddressOffset =>
  //  32768 * gs[GeneratorType.EndAddressCoarseOffset] +
  //  gs[GeneratorType.EndAddressOffset];

  // int StartLoopAddressOffset =>
  //  32768 * gs[GeneratorType.StartLoopAddressCoarseOffset] +
  //  gs[GeneratorType.StartLoopAddressOffset];

  // int EndLoopAddressOffset =>
  //  32768 * gs[GeneratorType.EndLoopAddressCoarseOffset] +
  //  gs[GeneratorType.EndLoopAddressOffset];

}
