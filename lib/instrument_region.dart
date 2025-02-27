import 'zone.dart';
import 'loop_mode.dart';
import 'soundfont_math.dart';
import 'sample_header.dart';
import 'generator.dart';
import 'generator_type.dart';

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
    gs[GeneratorType.initialFilterCutoffFrequency] = 13500;
    gs[GeneratorType.delayModulationLfo] = -12000;
    gs[GeneratorType.delayVibratoLfo] = -12000;
    gs[GeneratorType.delayModulationEnvelope] = -12000;
    gs[GeneratorType.attackModulationEnvelope] = -12000;
    gs[GeneratorType.holdModulationEnvelope] = -12000;
    gs[GeneratorType.decayModulationEnvelope] = -12000;
    gs[GeneratorType.releaseModulationEnvelope] = -12000;
    gs[GeneratorType.delayVolumeEnvelope] = -12000;
    gs[GeneratorType.attackVolumeEnvelope] = -12000;
    gs[GeneratorType.holdVolumeEnvelope] = -12000;
    gs[GeneratorType.decayVolumeEnvelope] = -12000;
    gs[GeneratorType.releaseVolumeEnvelope] = -12000;
    gs[GeneratorType.keyRange] = 0x7F00;
    gs[GeneratorType.velocityRange] = 0x7F00;
    gs[GeneratorType.keyNumber] = -1;
    gs[GeneratorType.velocity] = -1;
    gs[GeneratorType.scaleTuning] = 100;
    gs[GeneratorType.overridingRootKey] = -1;

    for (Generator parameter in global) {
      gs[parameter.type] = castToShort(parameter.value);
    }

    for (Generator parameter in local) {
      gs[parameter.type] = castToShort(parameter.value);
    }

    SampleHeader sampleH = SampleHeader.defaultSampleHeader();

    if (samples.isNotEmpty) {
      int? id = gs[GeneratorType.sampleID];

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
        zones[0].generators.last.type != GeneratorType.sampleID) {
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
      32768 * gs[GeneratorType.startAddressCoarseOffset]! +
      gs[GeneratorType.startAddressOffset]!;

  int endAddressOffset() =>
      32768 * gs[GeneratorType.endAddressCoarseOffset]! +
      gs[GeneratorType.endAddressOffset]!;

  int startLoopAddressOffset() =>
      32768 * gs[GeneratorType.startLoopAddressCoarseOffset]! +
      gs[GeneratorType.startLoopAddressOffset]!;

  int endLoopAddressOffset() =>
      32768 * gs[GeneratorType.endLoopAddressCoarseOffset]! +
      gs[GeneratorType.endLoopAddressOffset]!;

  int modulationLfoToPitch() => gs[GeneratorType.modulationLfoToPitch]!;

  int vibratoLfoToPitch() => gs[GeneratorType.vibratoLfoToPitch]!;

  int modulationEnvelopeToPitch() =>
      gs[GeneratorType.modulationEnvelopeToPitch]!;

  double initialFilterCutoffFrequency() => SoundFontMath.centsToHertz(
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

  double delayModulationLfo() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.delayModulationLfo]!.toDouble());

  double frequencyModulationLfo() => SoundFontMath.centsToHertz(
      gs[GeneratorType.frequencyModulationLfo]!.toDouble());

  double delayVibratoLfo() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.delayVibratoLfo]!.toDouble());

  double frequencyVibratoLfo() => SoundFontMath.centsToHertz(
      gs[GeneratorType.frequencyVibratoLfo]!.toDouble());

  double delayModulationEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.delayModulationEnvelope]!.toDouble());

  double attackModulationEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.attackModulationEnvelope]!.toDouble());

  double holdModulationEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.holdModulationEnvelope]!.toDouble());

  double decayModulationEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.decayModulationEnvelope]!.toDouble());

  double sustainModulationEnvelope() =>
      0.1 * gs[GeneratorType.sustainModulationEnvelope]!;

  double releaseModulationEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.releaseModulationEnvelope]!.toDouble());

  int keyNumberToModulationEnvelopeHold() =>
      gs[GeneratorType.keyNumberToModulationEnvelopeHold]!;

  int keyNumberToModulationEnvelopeDecay() =>
      gs[GeneratorType.keyNumberToModulationEnvelopeDecay]!;

  double delayVolumeEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.delayVolumeEnvelope]!.toDouble());

  double attackVolumeEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.attackVolumeEnvelope]!.toDouble());

  double holdVolumeEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.holdVolumeEnvelope]!.toDouble());

  double decayVolumeEnvelope() => SoundFontMath.timecentsToSeconds(
      gs[GeneratorType.decayVolumeEnvelope]!.toDouble());

  double sustainVolumeEnvelope() =>
      0.1 * gs[GeneratorType.sustainVolumeEnvelope]!;

  double releaseVolumeEnvelope() => SoundFontMath.timecentsToSeconds(
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

  int fineTune() => gs[GeneratorType.fineTune]! + sample.pitchCorrection;

  LoopMode sampleModes() => gs[GeneratorType.sampleModes]! != 2
      ? loopModeFromInt(gs[GeneratorType.sampleModes]!)
      : LoopMode.noLoop;

  int scaleTuning() => gs[GeneratorType.scaleTuning]!;

  int exclusiveClass() => gs[GeneratorType.exclusiveClass]!;

  int rootKey() => gs[GeneratorType.overridingRootKey]! != -1
      ? gs[GeneratorType.overridingRootKey]!
      : sample.originalPitch;
}
