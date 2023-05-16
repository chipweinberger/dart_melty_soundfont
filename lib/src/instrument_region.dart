import 'loop_mode.dart';
import 'sample_header.dart';
import 'soundfont_math.dart';
import 'zone.dart';
import 'generator.dart';
import 'generator_type.dart';
import 'instrument.dart';
import 'utils/span.dart';

/// <summary>
/// Represents an instrument region.
/// </summary>
/// <remarks>
/// An instrument region contains all the parameters necessary to synthesize a note.
/// </remarks>
class InstrumentRegion {
  static InstrumentRegion defaults = InstrumentRegion();

  late final List<int> _gs; // short

  late SampleHeader _sample;

  InstrumentRegion({
    SampleHeader? sample,
  }) {
    _gs = List.filled(61, 0);
    _gs[GeneratorType.InitialFilterCutoffFrequency.value] = 13500;
    _gs[GeneratorType.DelayModulationLfo.value] = -12000;
    _gs[GeneratorType.DelayVibratoLfo.value] = -12000;
    _gs[GeneratorType.DelayModulationEnvelope.value] = -12000;
    _gs[GeneratorType.AttackModulationEnvelope.value] = -12000;
    _gs[GeneratorType.HoldModulationEnvelope.value] = -12000;
    _gs[GeneratorType.DecayModulationEnvelope.value] = -12000;
    _gs[GeneratorType.ReleaseModulationEnvelope.value] = -12000;
    _gs[GeneratorType.DelayVolumeEnvelope.value] = -12000;
    _gs[GeneratorType.AttackVolumeEnvelope.value] = -12000;
    _gs[GeneratorType.HoldVolumeEnvelope.value] = -12000;
    _gs[GeneratorType.DecayVolumeEnvelope.value] = -12000;
    _gs[GeneratorType.ReleaseVolumeEnvelope.value] = -12000;
    _gs[GeneratorType.KeyRange.value] = 0x7F00;
    _gs[GeneratorType.VelocityRange.value] = 0x7F00;
    _gs[GeneratorType.KeyNumber.value] = -1;
    _gs[GeneratorType.Velocity.value] = -1;
    _gs[GeneratorType.ScaleTuning.value] = 100;
    _gs[GeneratorType.OverridingRootKey.value] = -1;

    _sample = sample ?? SampleHeader.defaults;
  }

  factory InstrumentRegion.fromInstrument({
    required Instrument instrument,
    required Zone global,
    required Zone local,
    required List<SampleHeader> samples,
  }) {
    final instance = InstrumentRegion();

    for (final generator in global.generators) {
      instance.setParameter(generator);
    }

    for (final generator in local.generators) {
      instance.setParameter(generator);
    }

    var id = instance._gs[GeneratorType.SampleID.value];
    if (!(0 <= id && id < samples.length)) {
      throw "The instrument '${instrument.name}' contains an invalid sample ID '$id'.";
    }

    instance._sample = samples[id];

    return instance;
  }

  static List<InstrumentRegion> create(
    Instrument instrument,
    Span<Zone> zones,
    List<SampleHeader> samples,
  ) {
    // Is the first one the global zone?
    if (zones[0].generators.length == 0 ||
        zones[0].generators.last.type != GeneratorType.SampleID) {
      // The first one is the global zone.
      var global = zones[0];

      // The global zone is regarded as the base setting of subsequent zones.
      final count = zones.length - 1;
      final regions = <InstrumentRegion>[];
      for (var i = 0; i < count; i++) {
        final item = InstrumentRegion.fromInstrument(
          instrument: instrument,
          global: global,
          local: zones[i + 1],
          samples: samples,
        );
        regions.add(item);
      }
      return regions;
    } else {
      // No global zone.
      final count = zones.length;
      final regions = <InstrumentRegion>[];
      for (var i = 0; i < count; i++) {
        final item = InstrumentRegion.fromInstrument(
          instrument: instrument,
          global: Zone.empty,
          local: zones[i],
          samples: samples,
        );
        regions.add(item);
      }
      return regions;
    }
  }

  void setParameter(Generator generator) {
    var index = generator.type.value;

    // Unknown generators should be ignored.
    if (0 != index && index < _gs.length) {
      _gs[index] = generator.value;
    }
  }

  /// <summary>
  /// Checks if the region covers the given key and velocity.
  /// </summary>
  /// <param name="key">The key of a note.</param>
  /// <param name="velocity">The velocity of a note.</param>
  /// <returns>
  /// <c>true</c> if the region covers the given key and velocity.
  /// </returns>
  bool contains(int key, int velocity) {
    final containsKey = keyRangeStart <= key && key <= keyRangeEnd;
    final containsVelocity =
        velocityRangeStart <= velocity && velocity <= velocityRangeEnd;
    return containsKey && containsVelocity;
  }

  /// <summary>
  /// Gets the string representation of the region.
  /// </summary>
  /// <returns>
  /// The string representation of the region.
  /// </returns>
  @override
  String toString() {
    return "${sample.name} (Key: ${keyRangeStart}-${keyRangeEnd}, Velocity: ${velocityRangeStart}-${velocityRangeEnd})";
  }

  int operator [](GeneratorType generatorType) {
    return _gs[generatorType.value];
  }

  /// <summary>
  /// The sample corresponding to the region.
  /// </summary>
  SampleHeader get sample => _sample;

  int get sampleStart => sample.start + startAddressOffset;
  int get sampleEnd => sample.end + endAddressOffset;
  int get sampleStartLoop => sample.startLoop + startLoopAddressOffset;
  int get sampleEndLoop => sample.endLoop + endLoopAddressOffset;

  int get startAddressOffset =>
      32768 * this[GeneratorType.StartAddressCoarseOffset] +
      this[GeneratorType.StartAddressOffset];
  int get endAddressOffset =>
      32768 * this[GeneratorType.EndAddressCoarseOffset] +
      this[GeneratorType.EndAddressOffset];
  int get startLoopAddressOffset =>
      32768 * this[GeneratorType.StartLoopAddressCoarseOffset] +
      this[GeneratorType.StartLoopAddressOffset];
  int get endLoopAddressOffset =>
      32768 * this[GeneratorType.EndLoopAddressCoarseOffset] +
      this[GeneratorType.EndLoopAddressOffset];

  int get modulationLfoToPitch => this[GeneratorType.ModulationLfoToPitch];
  int get vibratoLfoToPitch => this[GeneratorType.VibratoLfoToPitch];
  int get modulationEnvelopeToPitch =>
      this[GeneratorType.ModulationEnvelopeToPitch];
  double get initialFilterCutoffFrequency => SoundFontMath.centsToHertz(
      this[GeneratorType.InitialFilterCutoffFrequency].toDouble());
  double get initialFilterQ => 0.1 * this[GeneratorType.InitialFilterQ];
  int get modulationLfoToFilterCutoffFrequency =>
      this[GeneratorType.ModulationLfoToFilterCutoffFrequency];
  int get modulationEnvelopeToFilterCutoffFrequency =>
      this[GeneratorType.ModulationEnvelopeToFilterCutoffFrequency];

  double get modulationLfoToVolume =>
      0.1 * this[GeneratorType.ModulationLfoToVolume];

  double get chorusEffectsSend => 0.1 * this[GeneratorType.ChorusEffectsSend];
  double get reverbEffectsSend => 0.1 * this[GeneratorType.ReverbEffectsSend];
  double get pan => 0.1 * this[GeneratorType.Pan];

  double get delayModulationLfo => SoundFontMath.timecentsToSeconds(
      this[GeneratorType.DelayModulationLfo].toDouble());
  double get frequencyModulationLfo => SoundFontMath.centsToHertz(
      this[GeneratorType.FrequencyModulationLfo].toDouble());
  double get delayVibratoLfo => SoundFontMath.timecentsToSeconds(
      this[GeneratorType.DelayVibratoLfo].toDouble());
  double get frequencyVibratoLfo => SoundFontMath.centsToHertz(
      this[GeneratorType.FrequencyVibratoLfo].toDouble());
  double get delayModulationEnvelope => SoundFontMath.timecentsToSeconds(
      this[GeneratorType.DelayModulationEnvelope].toDouble());
  double get attackModulationEnvelope => SoundFontMath.timecentsToSeconds(
      this[GeneratorType.AttackModulationEnvelope].toDouble());
  double get holdModulationEnvelope => SoundFontMath.timecentsToSeconds(
      this[GeneratorType.HoldModulationEnvelope].toDouble());
  double get decayModulationEnvelope => SoundFontMath.timecentsToSeconds(
      this[GeneratorType.DecayModulationEnvelope].toDouble());
  double get sustainModulationEnvelope =>
      0.1 * this[GeneratorType.SustainModulationEnvelope];
  double get releaseModulationEnvelope => SoundFontMath.timecentsToSeconds(
      this[GeneratorType.ReleaseModulationEnvelope].toDouble());
  int get keyNumberToModulationEnvelopeHold =>
      this[GeneratorType.KeyNumberToModulationEnvelopeHold];
  int get keyNumberToModulationEnvelopeDecay =>
      this[GeneratorType.KeyNumberToModulationEnvelopeDecay];
  double get delayVolumeEnvelope => SoundFontMath.timecentsToSeconds(
      this[GeneratorType.DelayVolumeEnvelope].toDouble());
  double get attackVolumeEnvelope => SoundFontMath.timecentsToSeconds(
      this[GeneratorType.AttackVolumeEnvelope].toDouble());
  double get holdVolumeEnvelope => SoundFontMath.timecentsToSeconds(
      this[GeneratorType.HoldVolumeEnvelope].toDouble());
  double get decayVolumeEnvelope => SoundFontMath.timecentsToSeconds(
      this[GeneratorType.DecayVolumeEnvelope].toDouble());
  double get sustainVolumeEnvelope =>
      0.1 * this[GeneratorType.SustainVolumeEnvelope];
  double get releaseVolumeEnvelope => SoundFontMath.timecentsToSeconds(
      this[GeneratorType.ReleaseVolumeEnvelope].toDouble());
  int get keyNumberToVolumeEnvelopeHold =>
      this[GeneratorType.KeyNumberToVolumeEnvelopeHold];
  int get keyNumberToVolumeEnvelopeDecay =>
      this[GeneratorType.KeyNumberToVolumeEnvelopeDecay];

  int get keyRangeStart => this[GeneratorType.KeyRange] & 0xFF;
  int get keyRangeEnd => (this[GeneratorType.KeyRange] >> 8) & 0xFF;
  int get velocityRangeStart => this[GeneratorType.VelocityRange] & 0xFF;
  int get velocityRangeEnd => (this[GeneratorType.VelocityRange] >> 8) & 0xFF;

  double get initialAttenuation => 0.1 * this[GeneratorType.InitialAttenuation];

  int get coarseTune => this[GeneratorType.CoarseTune];
  int get fineTune => this[GeneratorType.FineTune] * sample.pitchCorrection;
  LoopMode get sampleModes => this[GeneratorType.SampleModes] != 2
      ? loopModeFromInt(this[GeneratorType.SampleModes])!
      : LoopMode.NoLoop;

  int get scaleTuning => this[GeneratorType.ScaleTuning];
  int get exclusiveClass => this[GeneratorType.ExclusiveClass];
  int get rootKey => this[GeneratorType.OverridingRootKey] != -1
      ? this[GeneratorType.OverridingRootKey]
      : sample.originalPitch;
}
