import 'src/generator_type.dart';
import 'instrument_region.dart';
import 'loop_mode.dart';
import 'preset_region.dart';
import 'soundfont_math.dart';

class RegionPair {
  final PresetRegion preset;
  final InstrumentRegion instrument;

  RegionPair({required this.preset, required this.instrument});

  int getGen(GeneratorType type) {
    return instrument.getGen(type) + preset.getGen(type);
  }

  int sampleStart() => instrument.sampleStart();

  int sampleEnd() => instrument.sampleEnd();

  int sampleStartLoop() => instrument.sampleStartLoop();

  int sampleEndLoop() => instrument.sampleEndLoop();

  int startAddressOffset() => instrument.startAddressOffset();

  int endAddressOffset() => instrument.endAddressOffset();

  int startLoopAddressOffset() => instrument.startLoopAddressOffset();

  int endLoopAddressOffset() => instrument.endLoopAddressOffset();

  int modulationLfoToPitch() => getGen(GeneratorType.ModulationLfoToPitch);

  int vibratoLfoToPitch() => getGen(GeneratorType.VibratoLfoToPitch);

  int modulationEnvelopeToPitch() =>
      getGen(GeneratorType.ModulationEnvelopeToPitch);

  double initialFilterCutoffFrequency() => SoundFontMath.centsToHertz(
      getGen(GeneratorType.InitialFilterCutoffFrequency).toDouble());

  double initialFilterQ() => 0.1 * getGen(GeneratorType.InitialFilterQ);

  int modulationLfoToFilterCutoffFrequency() =>
      getGen(GeneratorType.ModulationLfoToFilterCutoffFrequency);

  int modulationEnvelopeToFilterCutoffFrequency() =>
      getGen(GeneratorType.ModulationEnvelopeToFilterCutoffFrequency);

  double modulationLfoToVolume() =>
      0.1 * getGen(GeneratorType.ModulationLfoToVolume);

  double chorusEffectsSend() => 0.1 * getGen(GeneratorType.ChorusEffectsSend);

  double reverbEffectsSend() => 0.1 * getGen(GeneratorType.ReverbEffectsSend);

  double pan() => 0.1 * getGen(GeneratorType.Pan);

  double delayModulationLfo() => SoundFontMath.timecentsToSeconds(
      getGen(GeneratorType.DelayModulationLfo).toDouble());

  double frequencyModulationLfo() => SoundFontMath.centsToHertz(
      getGen(GeneratorType.FrequencyModulationLfo).toDouble());

  double delayVibratoLfo() => SoundFontMath.timecentsToSeconds(
      getGen(GeneratorType.DelayVibratoLfo).toDouble());

  double frequencyVibratoLfo() => SoundFontMath.centsToHertz(
      getGen(GeneratorType.FrequencyVibratoLfo).toDouble());

  double delayModulationEnvelope() => SoundFontMath.timecentsToSeconds(
      getGen(GeneratorType.DelayModulationEnvelope).toDouble());

  double attackModulationEnvelope() => SoundFontMath.timecentsToSeconds(
      getGen(GeneratorType.AttackModulationEnvelope).toDouble());

  double holdModulationEnvelope() => SoundFontMath.timecentsToSeconds(
      getGen(GeneratorType.HoldModulationEnvelope).toDouble());

  double decayModulationEnvelope() => SoundFontMath.timecentsToSeconds(
      getGen(GeneratorType.DecayModulationEnvelope).toDouble());

  double sustainModulationEnvelope() =>
      0.1 * getGen(GeneratorType.SustainModulationEnvelope);

  double releaseModulationEnvelope() => SoundFontMath.timecentsToSeconds(
      getGen(GeneratorType.ReleaseModulationEnvelope).toDouble());

  int keyNumberToModulationEnvelopeHold() =>
      getGen(GeneratorType.KeyNumberToModulationEnvelopeHold);

  int keyNumberToModulationEnvelopeDecay() =>
      getGen(GeneratorType.KeyNumberToModulationEnvelopeDecay);

  double delayVolumeEnvelope() => SoundFontMath.timecentsToSeconds(
      getGen(GeneratorType.DelayVolumeEnvelope).toDouble());

  double attackVolumeEnvelope() => SoundFontMath.timecentsToSeconds(
      getGen(GeneratorType.AttackVolumeEnvelope).toDouble());

  double holdVolumeEnvelope() => SoundFontMath.timecentsToSeconds(
      getGen(GeneratorType.HoldVolumeEnvelope).toDouble());

  double decayVolumeEnvelope() => SoundFontMath.timecentsToSeconds(
      getGen(GeneratorType.DecayVolumeEnvelope).toDouble());

  double sustainVolumeEnvelope() =>
      0.1 * getGen(GeneratorType.SustainVolumeEnvelope);

  double releaseVolumeEnvelope() => SoundFontMath.timecentsToSeconds(
      getGen(GeneratorType.ReleaseVolumeEnvelope).toDouble());

  int keyNumberToVolumeEnvelopeHold() =>
      getGen(GeneratorType.KeyNumberToVolumeEnvelopeHold);

  int keyNumberToVolumeEnvelopeDecay() =>
      getGen(GeneratorType.KeyNumberToVolumeEnvelopeDecay);

  double initialAttenuation() => 0.1 * getGen(GeneratorType.InitialAttenuation);

  int coarseTune() => getGen(GeneratorType.CoarseTune);

  int fineTune() =>
      getGen(GeneratorType.FineTune) + instrument.sample.pitchCorrection;

  LoopMode sampleModes() => instrument.sampleModes();

  int scaleTuning() => getGen(GeneratorType.ScaleTuning);

  int exclusiveClass() => instrument.exclusiveClass();

  int rootKey() => instrument.rootKey();

  // int KeyRangeStart => getGen(GeneratorParameterType.KeyRange) & 0xFF;
  // int KeyRangeEnd => (getGen(GeneratorParameterType.KeyRange) >> 8) & 0xFF;
  // int VelocityRangeStart => getGen(GeneratorParameterType.VelocityRange) & 0xFF;
  // int VelocityRangeEnd => (getGen(GeneratorParameterType.VelocityRange) >> 8) & 0xFF;
}
