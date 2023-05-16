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
    return PresetRegion(instrument: Instrument.defaults, gs: {});
  }

  factory PresetRegion.fromLists(
      {required List<Generator> global,
      required List<Generator> local,
      required List<Instrument> instruments}) {
    // initialize default values
    Map<GeneratorType, int> gs = {};
    for (GeneratorType gType in GeneratorType.values) {
      gs[gType] = 0;
    }
    gs[GeneratorType.KeyRange] = 0x7F00;
    gs[GeneratorType.VelocityRange] = 0x7F00;

    for (Generator parameter in global) {
      gs[parameter.type] = castToShort(parameter.value);
    }

    for (Generator parameter in local) {
      gs[parameter.type] = castToShort(parameter.value);
    }

    Instrument inst;

    if (instruments.isNotEmpty) {
      int? id = gs[GeneratorType.Instrument];

      if (id == null || id < 0 || id >= instruments.length) {
        throw "The preset contains an invalid instrument ID '$id'.";
      }

      inst = instruments[id];
    } else {
      inst = Instrument.defaults;
    }

    return PresetRegion(instrument: inst, gs: gs);
  }

  static List<PresetRegion> create(
      List<Zone> zones, List<Instrument> instruments) {
    Zone? global;

    // Is the first one the global zone?
    if (zones[0].generators.isEmpty ||
        zones[0].generators.last.type != GeneratorType.Instrument) {
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
            global: [], local: zones[i].generators, instruments: instruments));
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

  int modulationLfoToPitch() => gs[GeneratorType.ModulationLfoToPitch]!;

  int vibratoLfoToPitch() => gs[GeneratorType.VibratoLfoToPitch]!;

  int modulationEnvelopeToPitch() =>
      gs[GeneratorType.ModulationEnvelopeToPitch]!;

  double initialFilterCutoffFrequency() =>
      SoundFontMath.centsToMultiplyingFactor(
          gs[GeneratorType.InitialFilterCutoffFrequency]!.toDouble());

  double initialFilterQ() => 0.1 * gs[GeneratorType.InitialFilterQ]!;

  int modulationLfoToFilterCutoffFrequency() =>
      gs[GeneratorType.ModulationLfoToFilterCutoffFrequency]!;

  int modulationEnvelopeToFilterCutoffFrequency() =>
      gs[GeneratorType.ModulationEnvelopeToFilterCutoffFrequency]!;

  double modulationLfoToVolume() =>
      0.1 * gs[GeneratorType.ModulationLfoToVolume]!;

  double chorusEffectsSend() => 0.1 * gs[GeneratorType.ChorusEffectsSend]!;

  double reverbEffectsSend() => 0.1 * gs[GeneratorType.ReverbEffectsSend]!;

  double pan() => 0.1 * gs[GeneratorType.Pan]!;

  double delayModulationLfo() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.DelayModulationLfo]!.toDouble());

  double frequencyModulationLfo() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.FrequencyModulationLfo]!.toDouble());

  double delayVibratoLfo() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.DelayVibratoLfo]!.toDouble());

  double frequencyVibratoLfo() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.FrequencyVibratoLfo]!.toDouble());

  double delayModulationEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.DelayModulationEnvelope]!.toDouble());

  double attackModulationEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.AttackModulationEnvelope]!.toDouble());

  double holdModulationEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.HoldModulationEnvelope]!.toDouble());

  double decayModulationEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.DecayModulationEnvelope]!.toDouble());

  double sustainModulationEnvelope() =>
      0.1 * gs[GeneratorType.SustainModulationEnvelope]!;

  double releaseModulationEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.ReleaseModulationEnvelope]!.toDouble());

  int keyNumberToModulationEnvelopeHold() =>
      gs[GeneratorType.KeyNumberToModulationEnvelopeHold]!;

  int keyNumberToModulationEnvelopeDecay() =>
      gs[GeneratorType.KeyNumberToModulationEnvelopeDecay]!;

  double delayVolumeEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.DelayVolumeEnvelope]!.toDouble());

  double attackVolumeEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.AttackVolumeEnvelope]!.toDouble());

  double holdVolumeEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.HoldVolumeEnvelope]!.toDouble());

  double decayVolumeEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.DecayVolumeEnvelope]!.toDouble());

  double sustainVolumeEnvelope() =>
      0.1 * gs[GeneratorType.SustainVolumeEnvelope]!;

  double releaseVolumeEnvelope() => SoundFontMath.centsToMultiplyingFactor(
      gs[GeneratorType.ReleaseVolumeEnvelope]!.toDouble());

  int keyNumberToVolumeEnvelopeHold() =>
      gs[GeneratorType.KeyNumberToVolumeEnvelopeHold]!;

  int keyNumberToVolumeEnvelopeDecay() =>
      gs[GeneratorType.KeyNumberToVolumeEnvelopeDecay]!;

  int keyRangeStart() => gs[GeneratorType.KeyRange]! & 0xFF;

  int keyRangeEnd() => (gs[GeneratorType.KeyRange]! >> 8) & 0xFF;

  int velocityRangeStart() => gs[GeneratorType.VelocityRange]! & 0xFF;

  int velocityRangeEnd() => (gs[GeneratorType.VelocityRange]! >> 8) & 0xFF;

  double initialAttenuation() => 0.1 * gs[GeneratorType.InitialAttenuation]!;

  int coarseTune() => gs[GeneratorType.CoarseTune]!;

  int fineTune() => gs[GeneratorType.FineTune]!;

  int scaleTuning() => gs[GeneratorType.ScaleTuning]!;

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
