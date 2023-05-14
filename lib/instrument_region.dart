import 'src/generator.dart';
import 'src/generator_type.dart';
import 'loop_mode.dart';
import 'sample_header.dart';
import 'soundfont_math.dart';
import 'zone.dart';

/// Represents an instrument region.
/// An instrument region contains all the parameters necessary to synthesize a note.
class InstrumentRegion {
  final SampleHeader sample;
  final Map<GeneratorType, int> gs;

  InstrumentRegion({required this.sample, required this.gs});

  factory InstrumentRegion.fromLists(
      {required List<Generator> global,
      required List<Generator> local,
      required List<SampleHeader> samples}) {
    // initialize default values
    Map<GeneratorType, int> gs = {};
    for (GeneratorType gType in GeneratorType.values) {
      gs[gType] = 0;
    }
    gs[GeneratorType.InitialFilterCutoffFrequency] = 13500;
    gs[GeneratorType.DelayModulationLfo] = -12000;
    gs[GeneratorType.DelayVibratoLfo] = -12000;
    gs[GeneratorType.DelayModulationEnvelope] = -12000;
    gs[GeneratorType.AttackModulationEnvelope] = -12000;
    gs[GeneratorType.HoldModulationEnvelope] = -12000;
    gs[GeneratorType.DecayModulationEnvelope] = -12000;
    gs[GeneratorType.ReleaseModulationEnvelope] = -12000;
    gs[GeneratorType.DelayVolumeEnvelope] = -12000;
    gs[GeneratorType.AttackVolumeEnvelope] = -12000;
    gs[GeneratorType.HoldVolumeEnvelope] = -12000;
    gs[GeneratorType.DecayVolumeEnvelope] = -12000;
    gs[GeneratorType.ReleaseVolumeEnvelope] = -12000;
    gs[GeneratorType.KeyRange] = 0x7F00;
    gs[GeneratorType.VelocityRange] = 0x7F00;
    gs[GeneratorType.KeyNumber] = -1;
    gs[GeneratorType.Velocity] = -1;
    gs[GeneratorType.ScaleTuning] = 100;
    gs[GeneratorType.OverridingRootKey] = -1;

    for (Generator parameter in global) {
      gs[parameter.type] = castToShort(parameter.value);
    }

    for (Generator parameter in local) {
      gs[parameter.type] = castToShort(parameter.value);
    }

    SampleHeader sampleH = SampleHeader.defaultSampleHeader();

    if (samples.isNotEmpty) {
      int? id = gs[GeneratorType.SampleID];

      if (id == null || id < 0 || id >= samples.length) {
        throw "The instrument contains an invalid sample ID '$id'.";
      }

      sampleH = samples[id];
    }

    return InstrumentRegion(gs: gs, sample: sampleH);
  }

  static List<InstrumentRegion> create(
      List<Zone> zones, List<SampleHeader> samples) {
    Zone? global;

    // Is the first one the global zone?
    if (zones[0].generators.isEmpty ||
        zones[0].generators.last.type != GeneratorType.SampleID) {
      // The first one is the global zone.
      global = zones[0];
    }

    if (global != null) {
      // The global zone is regarded as the base setting of subsequent zones.
      List<InstrumentRegion> regions = [];

      int count = zones.length - 1;

      for (var i = 0; i < count; i++) {
        regions.add(InstrumentRegion.fromLists(
            global: global.generators,
            local: zones[i + 1].generators,
            samples: samples));
      }
      return regions;
    } else {
      // No global zone.
      int count = zones.length;

      List<InstrumentRegion> regions = [];

      for (var i = 0; i < count; i++) {
        regions.add(InstrumentRegion.fromLists(
            global: [], local: zones[i].generators, samples: samples));
      }
      return regions;
    }
  }

  void setParameter(Generator parameter) {
    gs[parameter.type] = castToShort(parameter.value);
  }

  /// Checks if the region covers the given key and velocity.
  /// Arg: The key of a note.
  /// Arg: The velocity of a note.
  /// Retursn true if the region covers the given key and velocity.
  bool contains(int key, int velocity) {
    bool containsKey = keyRangeStart() <= key && key <= keyRangeEnd();
    bool containsVelocity =
        velocityRangeStart() <= velocity && velocity <= velocityRangeEnd();
    return containsKey && containsVelocity;
  }

  /// Gets the string representation of the region.
  @override
  String toString() {
    String s1 = "${sample.name} (Key: ${keyRangeStart()}-${keyRangeEnd()},";
    String s2 = " Velocity: ${velocityRangeStart()}-${velocityRangeEnd()})";
    return s1 + s2;
  }

  int getGen(GeneratorType type) {
    return gs[type]!.toInt();
  }

  int sampleStart() => sample.start + startAddressOffset();

  int sampleEnd() => sample.end + endAddressOffset();

  int sampleStartLoop() => sample.startLoop + startLoopAddressOffset();

  int sampleEndLoop() => sample.endLoop + endLoopAddressOffset();

  int startAddressOffset() =>
      32768 * gs[GeneratorType.StartAddressCoarseOffset]! +
      gs[GeneratorType.StartAddressOffset]!;

  int endAddressOffset() =>
      32768 * gs[GeneratorType.EndAddressCoarseOffset]! +
      gs[GeneratorType.EndAddressOffset]!;

  int startLoopAddressOffset() =>
      32768 * gs[GeneratorType.StartLoopAddressCoarseOffset]! +
      gs[GeneratorType.StartLoopAddressOffset]!;

  int endLoopAddressOffset() =>
      32768 * gs[GeneratorType.EndLoopAddressCoarseOffset]! +
      gs[GeneratorType.EndLoopAddressOffset]!;

  int modulationLfoToPitch() => gs[GeneratorType.ModulationLfoToPitch]!;

  int vibratoLfoToPitch() => gs[GeneratorType.VibratoLfoToPitch]!;

  int modulationEnvelopeToPitch() =>
      gs[GeneratorType.ModulationEnvelopeToPitch]!;

  double initialFilterCutoffFrequency() => SoundFontMath.centsToHertz(
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

  double delayModulationLfo() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.DelayModulationLfo]!.toDouble());

  double frequencyModulationLfo() => SoundFontMath.centsToHertz(
      gs[GeneratorType.FrequencyModulationLfo]!.toDouble());

  double delayVibratoLfo() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.DelayVibratoLfo]!.toDouble());

  double frequencyVibratoLfo() => SoundFontMath.centsToHertz(
      gs[GeneratorType.FrequencyVibratoLfo]!.toDouble());

  double delayModulationEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.DelayModulationEnvelope]!.toDouble());

  double attackModulationEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.AttackModulationEnvelope]!.toDouble());

  double holdModulationEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.HoldModulationEnvelope]!.toDouble());

  double decayModulationEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.DecayModulationEnvelope]!.toDouble());

  double sustainModulationEnvelope() =>
      0.1 * gs[GeneratorType.SustainModulationEnvelope]!;

  double releaseModulationEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.ReleaseModulationEnvelope]!.toDouble());

  int keyNumberToModulationEnvelopeHold() =>
      gs[GeneratorType.KeyNumberToModulationEnvelopeHold]!;

  int keyNumberToModulationEnvelopeDecay() =>
      gs[GeneratorType.KeyNumberToModulationEnvelopeDecay]!;

  double delayVolumeEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.DelayVolumeEnvelope]!.toDouble());

  double attackVolumeEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.AttackVolumeEnvelope]!.toDouble());

  double holdVolumeEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.HoldVolumeEnvelope]!.toDouble());

  double decayVolumeEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.DecayVolumeEnvelope]!.toDouble());

  double sustainVolumeEnvelope() =>
      0.1 * gs[GeneratorType.SustainVolumeEnvelope]!;

  double releaseVolumeEnvelope() => SoundFontMath.timecentsToSeconds(
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

  int fineTune() => gs[GeneratorType.FineTune]! + sample.pitchCorrection;

  LoopMode sampleModes() => gs[GeneratorType.SampleModes]! != 2
      ? loopModeFromInt(gs[GeneratorType.SampleModes]!)
      : LoopMode.noLoop;

  int scaleTuning() => gs[GeneratorType.ScaleTuning]!;

  int exclusiveClass() => gs[GeneratorType.ExclusiveClass]!;

  int rootKey() => gs[GeneratorType.OverridingRootKey]! != -1
      ? gs[GeneratorType.OverridingRootKey]!
      : sample.originalPitch;
}
